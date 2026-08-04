#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$repo_root" <<'PY'
import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys

root = pathlib.Path(sys.argv[1])
errors: list[str] = []


def record(condition: bool, message: str) -> None:
    print(f"{'PASS' if condition else 'FAIL'}: {message}")
    if not condition:
        errors.append(message)


def load_json(path: pathlib.Path) -> dict:
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        record(False, f"{path.relative_to(root)} parses as JSON: {exc}")
        return {}


def aggregate(paths: list[pathlib.Path], anchor: pathlib.Path) -> str:
    digest = hashlib.sha256()
    for path in sorted(paths, key=lambda item: item.relative_to(anchor).as_posix()):
        relative = path.relative_to(anchor).as_posix().encode()
        digest.update(relative)
        digest.update(b"\0")
        digest.update(path.read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()


def verify_integrity(
    label: str,
    section: dict,
    anchor: pathlib.Path,
    discovered: list[pathlib.Path],
) -> None:
    record(section.get("mutation_policy") == "digest-locked", f"{label} uses digest-locked mutation policy")
    sources = section.get("sources", [])
    declared = [item.get("path") for item in sources]
    actual = sorted(path.relative_to(anchor).as_posix() for path in discovered)
    record(declared == actual, f"{label} source inventory is exact and sorted")
    for source in sources:
        relative = source.get("path", "")
        path = anchor / relative
        record(path.is_file(), f"{label} source exists: {relative}")
        if path.is_file():
            current = hashlib.sha256(path.read_bytes()).hexdigest()
            record(current == source.get("sha256"), f"{label} source digest matches: {relative}")
    if all(path.is_file() for path in discovered):
        record(
            aggregate(discovered, anchor) == section.get("aggregate_sha256"),
            f"{label} aggregate digest matches",
        )


def normalized_markdown(text: str, canonical_name: str, flat_name: str, surface: str) -> str:
    text = text.replace(f"name: {canonical_name}\n", f"name: {flat_name}\n", 1)
    if surface == "router":
        text = text.replace("../story/SKILL.md", "../prism-story/SKILL.md")
        text = text.replace("../epic/SKILL.md", "../prism-epic/SKILL.md")
    if surface == "epic":
        text = text.replace("../story/SKILL.md", "../prism-story/SKILL.md")
        text = text.replace("../../story/SKILL.md", "../../prism-story/SKILL.md")
    return text


def normalized_contract(text: str) -> str:
    return " ".join(text.split())


mapping_path = root / "docs/lifecycle-ownership.json"
record(mapping_path.is_file(), "lifecycle ownership mapping exists")
mapping = load_json(mapping_path)
record(mapping.get("version") == 19, "ownership schema version is 19")

expected_interfaces = {
    "router": {"codex": "$prism:lifecycle", "claude": "/prism:lifecycle", "flat": "/prism-lifecycle"},
    "story": {"codex": "$prism:story", "claude": "/prism:story", "flat": "/prism-story"},
    "epic": {"codex": "$prism:epic", "claude": "/prism:epic", "flat": "/prism-epic"},
    "light": {
        "codex": "$prism-light:lifecycle",
        "claude": "/prism-light:lifecycle",
        "flat": "/prism-light",
    },
    "callee_lifecycle": {
        "codex": "$prism-callee:lifecycle",
        "claude": "/prism-callee:lifecycle",
        "flat": "/prism-callee-lifecycle",
    },
    "direct_callee": 'callee agent run prism/lifecycle --message "$envelope"',
}
record(mapping.get("interfaces") == expected_interfaces, "ownership schema declares every public interface")

story_phases = [
    "phase:story:specify",
    "phase:story:design",
    "phase:story:breakdown",
    "phase:story:human",
    "phase:story:apply",
    "phase:story:verify",
]
epic_phases = [
    "phase:epic:frame",
    "phase:epic:architecture",
    "phase:epic:roadmap",
    "phase:epic:approval",
    "phase:epic:delivery",
    "phase:epic:validation",
]
beads = mapping.get("beads", {})
record(beads.get("membership_label") == "prism", "Prism membership label is declared")
record(beads.get("approval_label") == "human:approved", "approval label is declared")
record(beads.get("story_phases") == story_phases, "Story phase namespace is complete")
record(beads.get("epic_phases") == epic_phases, "Epic phase namespace is complete")
record(
    beads.get("unsupported_phase_policy") == "treat-as-absent-no-migration",
    "unsupported phase labels are absent and never migrated",
)
record(
    beads.get("missing_phase_initialization")
    == {"story": "phase:story:specify", "epic": "phase:epic:frame", "clear_approval": True},
    "missing supported phase initializes by item type without approval",
)
record(
    beads.get("hierarchy")
    == {"epic_children": "story", "story_children": "task", "nested_epics": False, "direct_epic_tasks": False},
    "ownership schema enforces Epic to Story to Task hierarchy",
)

routing = mapping.get("routing", {})
record(routing.get("light_is_explicit_only") is True, "Light is explicit-only")
record(
    routing.get("priority")
    == [
        "explicit-open-epic-batch",
        "explicit-story-or-epic-id",
        "task-parent-story",
        "unambiguous-single-item-resume",
        "clear-multi-story-intent",
        "ordinary-story-intent",
    ],
    "router priority is deterministic",
)
record(
    routing.get("open_epic_batch")
    == {
        "selection": "one invocation-start snapshot of open epic items labeled prism",
        "order": ["priority", "created_at", "id"],
        "visit": "exactly-once-sequential",
        "continue_after_item_local_stop": True,
        "rescan": False,
        "approval_transfer": False,
        "empty_snapshot": "report-and-create-nothing",
        "output": "one-outcome-row-per-snapshot-id",
    },
    "open-Epic batch contract is complete",
)

approval = mapping.get("approval", {})
record(
    approval.get("host_story_order")
    == ["Design summary", "Task summary", "Approval request"],
    "full host Story approval order omits unsolicited acceptance",
)
record(
    approval.get("host_epic_order")
    == ["Architecture summary", "Story roadmap", "Approval request"],
    "full host Epic approval order omits unsolicited acceptance",
)
record(
    approval.get("host_acceptance_output")
    == "explicit-request-only-complete-untruncated-current-item-only",
    "full host acceptance output requires an explicit request for the current item",
)
record(approval.get("epic_approval_cascades_to_stories") is False, "Epic approval never cascades")

child_graph = mapping.get("child_graph", {})
record(child_graph.get("numeric_minimum") is None, "child graph has no numeric minimum")
record(child_graph.get("numeric_maximum") is None, "child graph has no numeric maximum")
for key in ["one_child_can_pass", "more_than_twelve_can_pass", "incomplete_graph_fails", "separable_mega_item_fails"]:
    record(child_graph.get(key) is True, f"child graph declares {key}")

ownership = mapping.get("surface_ownership", {})
surface_specs = {
    "router": ("lifecycle", "prism-lifecycle", "lifecycle", "prism-lifecycle"),
    "story": ("story", "prism-story", "story", "prism-story"),
    "epic": ("epic", "prism-epic", "epic", "prism-epic"),
    "light": ("lifecycle", "prism-light", "lifecycle", "prism-light"),
    "callee_lifecycle": ("lifecycle", "prism-callee-lifecycle", "lifecycle", "prism-callee-lifecycle"),
}

host_sources: list[pathlib.Path] = []
for surface, (canonical_name, flat_name, frontmatter_name, flat_frontmatter_name) in surface_specs.items():
    item = ownership.get(surface, {})
    canonical_dir = root / item.get("canonical", "__missing__")
    flat_dir = root / item.get("flat", "__missing__")
    record(canonical_dir.is_dir(), f"{surface} canonical skill directory exists")
    record(flat_dir.is_dir(), f"{surface} flat skill directory exists")
    canonical_files = sorted(path.relative_to(canonical_dir) for path in canonical_dir.rglob("*.md")) if canonical_dir.is_dir() else []
    flat_files = sorted(path.relative_to(flat_dir) for path in flat_dir.rglob("*.md")) if flat_dir.is_dir() else []
    record(canonical_files == flat_files, f"{surface} canonical and flat Markdown inventories agree")
    for relative in canonical_files:
        canonical_path = canonical_dir / relative
        flat_path = flat_dir / relative
        host_sources.append(canonical_path)
        expected = normalized_markdown(canonical_path.read_text(), frontmatter_name, flat_frontmatter_name, surface)
        record(expected == flat_path.read_text(), f"{surface} mirror matches: {relative}")

direct_callee = ownership.get("direct_callee", {})
record(direct_callee.get("graphs") == ["story", "epic"], "direct Callee exposes Story and Epic graphs")
record(direct_callee.get("router") is True, "direct Callee exposes an Epic Router")
record(
    direct_callee.get("authorized_behavior_change")
    == "hierarchical Story/Epic routing, approval boundaries, and explicit open-Epic batches",
    "canonical Callee change scope covers hierarchical routing and batches",
)

integrity = mapping.get("integrity", {})
record(
    integrity.get("aggregate_algorithm")
    == "sha256 over sorted source path UTF-8, NUL, file bytes, NUL",
    "aggregate digest algorithm is explicit",
)
verify_integrity("host", integrity.get("host_sources", {}), root, host_sources)

for path in host_sources:
    if "references" in path.parts and len(path.read_text().splitlines()) > 100:
        record("## Contents" in path.read_text(), f"{path.relative_to(root)} has navigation when longer than 100 lines")

pack_section = integrity.get("callee_pack", {})
pack_anchor = root / pack_section.get("root", "__missing__")
pack_sources = sorted((pack_anchor / "prism").rglob("*.md")) if (pack_anchor / "prism").is_dir() else []
verify_integrity("Callee pack", pack_section, pack_anchor, pack_sources)

router_text = (root / "plugins/prism/skills/lifecycle/SKILL.md").read_text()
router_contract = normalized_contract(router_text)
record(
    "Do not use for explicit Prism Light or Prism Callee requests" in router_contract,
    "router trigger metadata excludes explicit alternate plugins",
)
record("/prism," not in router_text.split("---", 2)[1], "router trigger metadata contains no undocumented /prism alias")
for marker in [
    "bd list --label prism --status=open --type=epic --limit 0 --json",
    "priority ascending",
    "exactly once",
    "Do not rescan",
    "transfer `human:approved`",
    "one outcome row",
]:
    record(marker in router_text, f"router documents batch invariant: {marker}")

host_scan_roots = [
    root / "plugins/prism",
    root / "plugins/prism-callee",
    root / "plugins/prism-light",
]
legacy_pattern = re.compile(r"phase:(specify|design|breakdown|human|apply|verify)(?!:)")
legacy_offenders = []
for scan_root in host_scan_roots:
    for path in scan_root.rglob("*"):
        if path.is_file() and path.suffix in {".md", ".yaml", ".yml", ".json"}:
            if legacy_pattern.search(path.read_text()):
                legacy_offenders.append(str(path.relative_to(root)))
record(not legacy_offenders, "host lifecycle surfaces contain no legacy phase labels" + (f": {legacy_offenders}" if legacy_offenders else ""))

for path in [
    root / "plugins/prism/skills/story/SKILL.md",
    root / "plugins/prism/skills/epic/SKILL.md",
    root / "plugins/prism-light/skills/lifecycle/SKILL.md",
    root / "plugins/prism-callee/skills/lifecycle/SKILL.md",
]:
    text = path.read_text()
    record("absent" in text and "migrat" in text, f"{path.relative_to(root)} documents unsupported-label behavior")

host_approval_contracts = {
    root / "plugins/prism/skills/story/references/human.md": [
        "### Design summary", "### Task summary", "### Approval request"
    ],
    root / "plugins/prism/skills/epic/references/approval.md": [
        "### Architecture summary", "### Story roadmap", "### Approval request"
    ],
}
for path, markers in host_approval_contracts.items():
    text = path.read_text()
    positions = [text.find(marker) for marker in markers]
    record(all(position >= 0 for position in positions) and positions == sorted(positions), f"{path.relative_to(root)} host approval order is correct")
    record("### Acceptance criteria" not in text, f"{path.relative_to(root)} omits unsolicited acceptance")
    record("acceptance" in text.lower() and "readiness" in text.lower(), f"{path.relative_to(root)} retains internal acceptance readiness")

acceptance_first_approval_contracts = {
    root / "plugins/prism-light/skills/lifecycle/references/human.md": [
        "### Acceptance criteria", "### Design summary", "### Task summary", "### Approval request"
    ],
    root / "plugins/prism-callee/skills/lifecycle/SKILL.md": [
        "### Acceptance criteria", "### Design summary", "### Task summary", "### Approval request"
    ],
}
for path, markers in acceptance_first_approval_contracts.items():
    text = path.read_text()
    positions = [text.find(marker) for marker in markers]
    record(all(position >= 0 for position in positions) and positions == sorted(positions), f"{path.relative_to(root)} approval order is correct")
    record("complete" in text.lower() and "untruncated" in text.lower(), f"{path.relative_to(root)} requires complete untruncated acceptance")

retired_graph_pattern = re.compile(r"(?:3\s*[-–]\s*12|2\s*[-–]\s*12|three[- ]to[- ]twelve)", re.IGNORECASE)
graph_offenders = []
for scan_root in [
    root / "plugins/prism",
    root / "plugins/prism-callee",
    root / "plugins/prism-light",
    root / "pack/callee/prism",
]:
    for path in scan_root.rglob("*"):
        if path.is_file() and path.suffix in {".md", ".yaml", ".yml", ".json"} and retired_graph_pattern.search(path.read_text()):
            graph_offenders.append(str(path.relative_to(root)))
record(not graph_offenders, "active lifecycle contracts contain no retired numeric child limits" + (f": {graph_offenders}" if graph_offenders else ""))

graph_contracts = [
    root / "plugins/prism/skills/story/references/breakdown.md",
    root / "plugins/prism-light/skills/lifecycle/references/breakdown.md",
    root / "plugins/prism/skills/epic/references/roadmap.md",
    root / "plugins/prism-callee/skills/lifecycle/references/breakdown.md",
    root / "pack/callee/prism/phases/breakdown.md",
]
for path in graph_contracts:
    text = path.read_text().lower()
    checks = {
        "no numeric minimum": "no numeric minimum" in text,
        "one child may pass": ("one task" in text if "roadmap.md" not in str(path) else "one story" in text),
        "more than twelve may pass": re.search(r"more than\s+twelve", text) is not None,
        "separable mega-item fails": "separable" in text and "mega" in text,
    }
    for marker, present in checks.items():
        record(present, f"{path.relative_to(root)} qualitative graph marker: {marker}")

epic_text = (root / "plugins/prism/skills/epic/SKILL.md").read_text()
for marker in ["Direct Epic children are Stories", "direct Tasks", "nested Epics", "never cascades", "one ready Story at a time"]:
    record(marker in epic_text, f"Epic hierarchy/approval marker: {marker}")

pack_lifecycle_text = (root / "pack/callee/prism/lifecycle.md").read_text()
record(
    "kind: Router" in pack_lifecycle_text
    and "prism/story" in pack_lifecycle_text
    and "prism/epic" in pack_lifecycle_text,
    "canonical Callee lifecycle is a Story/Epic Router",
)

for path, markers in {
    root / "pack/callee/prism/story.md": [
        "kind: Sequential",
        "prism/phases/specify",
        "prism/phases/verify",
        "### Acceptance criteria",
        "Do not emit this section outside",
    ],
    root / "pack/callee/prism/epic.md": [
        "kind: Sequential",
        "prism/epic/phases/frame",
        "prism/epic/phases/validation",
        "### Acceptance criteria",
        "Do not emit this section outside",
    ],
}.items():
    text = path.read_text() if path.is_file() else ""
    record(path.is_file(), f"{path.relative_to(root)} exists")
    for marker in markers:
        record(marker in text, f"{path.relative_to(root)} contains Callee contract: {marker}")

output_contracts = {
    root / "plugins/prism/skills/story/SKILL.md": [
        "## Output boundary",
        "MUST NOT emit a standalone ### Acceptance criteria heading",
        "unsolicited user-facing approval-format acceptance block",
        "machine-readable acceptance artifacts",
        "explicit operator request for acceptance criteria",
        "Story Human pre-approve request",
    ],
    root / "plugins/prism/skills/epic/SKILL.md": [
        "## Output boundary",
        "MUST NOT emit a standalone ### Acceptance criteria heading",
        "unsolicited user-facing approval-format acceptance block",
        "machine-readable acceptance artifacts",
        "explicit operator request for acceptance criteria",
        "Epic Approval pre-approve request",
    ],
    root / "plugins/prism-callee/skills/lifecycle/SKILL.md": [
        "Normal host output",
        "MUST NOT emit a standalone ### Acceptance criteria heading",
        "unsolicited user-facing approval-format acceptance block",
        "machine-readable acceptance artifacts",
        "explicit operator request for acceptance criteria",
    ],
}
for path, markers in output_contracts.items():
    text = normalized_contract(path.read_text())
    for marker in markers:
        record(marker in text, f"{path.relative_to(root)} output boundary contains: {marker}")
    record(
        "complete acceptance block" not in text,
        f"{path.relative_to(root)} does not use the broad acceptance-block prohibition",
    )

callee_host_text = normalized_contract((root / "plugins/prism-callee/skills/lifecycle/SKILL.md").read_text())
for marker in [
    "Story Human request, in exact order",
    "Epic Approval request, in exact order",
    "one invocation-start snapshot",
    "exactly-once ledger",
]:
    record(marker in callee_host_text, f"prism-callee host contract contains: {marker}")

callee_skill = root / "plugins/prism-callee/skills/lifecycle/SKILL.md"
callee_skill_text = normalized_contract(callee_skill.read_text())
for marker in [
    "[PromptKit authoring contract](references/promptkit.md)",
    "[Breakdown normalization contract](references/breakdown.md)",
    "Do not load it for normal lifecycle execution",
    "Read when a Story reaches Breakdown or when reconciling its task graph",
    "Require all three public roots",
    "Story-only `Sequential` lifecycle is a stale catalog",
    "callee agent import baldaworks/prism --path pack/callee/prism --prefix prism --force",
    "Do not bypass a stale catalog by invoking a direct graph",
]:
    record(marker in callee_skill_text, f"{callee_skill.relative_to(root)} reference contract contains: {marker}")
record(
    'callee agent run prism/lifecycle --message "$envelope"' in callee_skill.read_text(),
    f"{callee_skill.relative_to(root)} runs imported Callee resources through the default catalog",
)
record(
    'callee agent run prism/lifecycle --agent-root pack/callee' not in callee_skill.read_text(),
    f"{callee_skill.relative_to(root)} runtime does not require a repository checkout",
)

breakdown = root / "plugins/prism-callee/skills/lifecycle/references/breakdown.md"
breakdown_text = breakdown.read_text()
for marker in [
    "## Contents",
    "[Goal](#goal)",
    "[Required output shape](#required-output-shape)",
    "[Host procedure (strict)](#host-procedure-strict)",
    "[Reject](#reject)",
    "[Stop when](#stop-when)",
    "[Never](#never)",
]:
    record(marker in breakdown_text, f"{breakdown.relative_to(root)} TOC contains: {marker}")
record(len(breakdown_text.splitlines()) > 100, f"{breakdown.relative_to(root)} remains a long reference with navigation")

promptkit = root / "plugins/prism-callee/skills/lifecycle/references/promptkit.md"
discovery_commands = [
    line for line in promptkit.read_text().splitlines()
    if "callee agent view " in line or "callee agent list" in line
]
record(bool(discovery_commands), f"{promptkit.relative_to(root)} has discovery examples")
record(
    all("--agent-root pack/callee" in line for line in discovery_commands),
    f"{promptkit.relative_to(root)} discovery examples use explicit Callee root",
)

expected_task_states = [
    {"state": "implementing", "assignee": "prism/apply/implementer"},
    {"state": "reviewing", "assignee": "prism/apply/reviewer"},
]
record(mapping.get("task_states") == expected_task_states, "child Task assignee states are preserved")

human_check = root / "pack/callee/prism/human/check.md"
parts = human_check.read_text().split("---", 2) if human_check.is_file() else []
record(len(parts) == 3, "Callee human decision check has executable body")
if len(parts) == 3:
    body = parts[2].lstrip()
    for decision, code in [("APPROVE", 0), ("REFINE_DESIGN", 2), ("WITHHOLD", 1)]:
        env = os.environ.copy()
        env["APPROVAL_INTENT"] = decision
        result = subprocess.run(["sh"], input=body, text=True, capture_output=True, cwd=root, env=env, check=False)
        record(result.returncode == code, f"Callee human decision check returns {code} for {decision}")

if errors:
    print(f"\n{len(errors)} lifecycle ownership check(s) failed", file=sys.stderr)
    raise SystemExit(1)

print("\nPASS: lifecycle ownership contract is synchronized")
PY
