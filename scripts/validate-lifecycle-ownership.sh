#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$repo_root" <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
errors = []


def record(condition, message):
    print(f"{'PASS' if condition else 'FAIL'}: {message}")
    if not condition:
        errors.append(message)


def load_json(path):
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        record(False, f"{path.relative_to(root)} parses as JSON: {exc}")
        return {}


def normalized_skill(path):
    lines = path.read_text().splitlines(keepends=True)
    for index, line in enumerate(lines):
        if line.startswith("name: "):
            lines[index] = "name: lifecycle\n"
            break
    return "".join(lines)


mapping_path = root / "docs/lifecycle-ownership.json"
record(mapping_path.is_file(), "lifecycle ownership mapping exists")
mapping = load_json(mapping_path) if mapping_path.is_file() else {}

phase_labels = [
    "phase:specify",
    "phase:design",
    "phase:breakdown",
    "phase:human",
    "phase:apply",
    "phase:verify",
]
record(mapping.get("version") == 8, "ownership schema version is 8")
record(
    mapping.get("lifecycle_labels") == ["prism", "human:approved", *phase_labels],
    "lifecycle labels contain membership, approval, and every supported phase",
)
record(mapping.get("phase_labels") == phase_labels, "phase labels declare the supported lifecycle sequence")
retired_mapping_key = "impact_" + "lens"
record(retired_mapping_key not in mapping, "ownership schema has no retired P5 contract")
human_gate = mapping.get("human_gate", {})
record(
    human_gate.get("summary_order")
    == ["Design summary", "Task summary", "Approval request"],
    "human gate summary covers design, tasks, then approval",
)
record(
    human_gate.get("approval_scope") == ["design", "tasks"],
    "human approval covers design and tasks",
)
record(
    mapping.get("entry_resolution") == {
        "explicit_story_id": "resume",
        "single_open_prism_story": "resume",
        "otherwise": "create",
        "new_story": {
            "labels": ["prism", "phase:specify"],
            "description": "raw_user_request",
        },
    },
    "entry resolution resumes explicit or sole stories and otherwise creates phase:specify",
)

expected_story = [
    ("specify", "phase:specify"),
    ("design", "phase:design"),
    ("breakdown", "phase:breakdown"),
    ("human", "phase:human"),
    ("apply", "phase:apply"),
    ("verify", "phase:verify"),
]
story_phases = mapping.get("story_phases", [])
record(
    [(item.get("phase"), item.get("label")) for item in story_phases] == expected_story,
    "story labels encode specify -> design -> breakdown -> human -> apply -> verify",
)

for phase in story_phases:
    name = phase.get("phase")
    record("assignee" not in phase, f"{name} has no story-phase assignee")
    record("aliases" not in phase, f"{name} has no assignee aliases")
    executor = phase.get("executor", {})
    manual_ref = executor.get("manual_phase_reference")
    public_ref = executor.get("public_ref")
    record(bool(executor.get("kind")), f"{name} declares executor kind")
    record(bool(manual_ref) and (root / manual_ref).is_file(), f"{name} manual phase reference exists")
    record(
        bool(public_ref) and (root / "pack/callee" / f"{public_ref}.md").is_file(),
        f"{name} public Callee phase exists",
    )
    for internal_ref in executor.get("internal_refs", []):
        record(
            (root / "pack/callee" / f"{internal_ref}.md").is_file(),
            f"{name} internal Callee ref exists: {internal_ref}",
        )

expected_task_states = [
    ("implementation", "prism/apply/implementer"),
    ("review", "prism/apply/reviewer"),
]
record(
    [(item.get("state"), item.get("assignee")) for item in mapping.get("task_states", [])] == expected_task_states,
    "apply child-task states use nested assignees",
)

for skill_path in [
    root / "plugins/prism/skills/lifecycle/SKILL.md",
    root / "plugins/prism/prefixed-skills/prism-lifecycle/SKILL.md",
    root / "plugins/prism-callee/skills/lifecycle/SKILL.md",
    root / "plugins/prism-callee/prefixed-skills/prism-callee-lifecycle/SKILL.md",
]:
    text = skill_path.read_text() if skill_path.is_file() else ""
    record(skill_path.is_file(), f"{skill_path.relative_to(root)} exists")
    for phase_label in phase_labels:
        record(phase_label in text, f"{skill_path.relative_to(root)} mentions {phase_label}")
    record("exactly one" in text and "phase:*" in text, f"{skill_path.relative_to(root)} requires exactly one phase label")
    for snippet in [
        "story ID",
        "exactly one open Prism stor",
        "--type=story -l prism,phase:specify",
        "raw user request",
    ]:
        record(snippet in text, f"{skill_path.relative_to(root)} documents lifecycle-owned story creation: {snippet}")

skill_pairs = [
    (
        root / "plugins/prism/skills/lifecycle/SKILL.md",
        root / "plugins/prism/prefixed-skills/prism-lifecycle/SKILL.md",
        "host lifecycle skills differ only by frontmatter name",
    ),
    (
        root / "plugins/prism-callee/skills/lifecycle/SKILL.md",
        root / "plugins/prism-callee/prefixed-skills/prism-callee-lifecycle/SKILL.md",
        "Callee lifecycle skills differ only by frontmatter name",
    ),
]
for canonical, prefixed, message in skill_pairs:
    record(
        canonical.is_file()
        and prefixed.is_file()
        and normalized_skill(canonical) == normalized_skill(prefixed),
        message,
    )

reference_pairs = [
    (
        root / "plugins/prism/skills/lifecycle/references",
        root / "plugins/prism/prefixed-skills/prism-lifecycle/references",
        ["specify.md", "design.md", "breakdown.md", "human.md", "apply.md", "verify.md", "lifecycle.md"],
        "host lifecycle reference",
    ),
    (
        root / "plugins/prism-callee/skills/lifecycle/references",
        root / "plugins/prism-callee/prefixed-skills/prism-callee-lifecycle/references",
        ["promptkit.md", "breakdown.md"],
        "Callee lifecycle reference",
    ),
]
for canonical_dir, prefixed_dir, filenames, label in reference_pairs:
    canonical_files = sorted(path.name for path in canonical_dir.iterdir() if path.is_file())
    prefixed_files = sorted(path.name for path in prefixed_dir.iterdir() if path.is_file())
    record(
        canonical_files == sorted(filenames) and prefixed_files == sorted(filenames),
        f"{label} directories contain exactly the required files",
    )
    for filename in filenames:
        canonical = canonical_dir / filename
        prefixed = prefixed_dir / filename
        record(
            canonical.is_file()
            and prefixed.is_file()
            and canonical.read_bytes() == prefixed.read_bytes(),
            f"{label} is identical in canonical and prefixed skills: {filename}",
        )

readme_path = root / "README.md"
readme_text = readme_path.read_text() if readme_path.is_file() else ""
record("bd create" not in readme_text, "README does not require manual story creation")
for internal_workflow in ["documentation-maintenance", "documentation/workflows/maintain", "pack/callee/documentation/"]:
    record(internal_workflow not in readme_text, f"README omits internal workflow reference: {internal_workflow}")

retired_contract_tokens = [
    "Prism " + "Impact Lens",
    "Product, " + "Process, " + "People, " + "Planet, " + "Prosperity",
    "impact_" + "lens",
]
retired_scan_roots = [
    root / "README.md",
    root / "docs",
    root / "plugins/prism",
    root / "plugins/prism-callee",
    root / "pack/callee/prism",
]
for token in retired_contract_tokens:
    offenders = []
    for scan_root in retired_scan_roots:
        paths = [scan_root] if scan_root.is_file() else scan_root.rglob("*")
        for path in paths:
            if not path.is_file() or path.suffix not in {".md", ".json", ".yaml", ".yml"}:
                continue
            if token in path.read_text():
                offenders.append(str(path.relative_to(root)))
    record(
        not offenders,
        f"active lifecycle artifacts omit retired P5 token {token!r}"
        + (f": {', '.join(offenders)}" if offenders else ""),
    )

for architecture_path in [
    root / "docs/architecture-host-lifecycle.md",
    root / "docs/architecture-callee-lifecycle.md",
]:
    architecture_text = architecture_path.read_text() if architecture_path.is_file() else ""
    record("exactly one open Prism story" in architecture_text, f"{architecture_path.relative_to(root)} documents sole-story resume")
    record("phase:specify" in architecture_text, f"{architecture_path.relative_to(root)} documents new-story phase label")

for reference in ["specify", "design", "breakdown", "human", "apply", "verify"]:
    for base in [
        root / "plugins/prism/skills/lifecycle/references",
        root / "plugins/prism/prefixed-skills/prism-lifecycle/references",
    ]:
        path = base / f"{reference}.md"
        text = path.read_text() if path.is_file() else ""
        record(path.is_file(), f"{path.relative_to(root)} exists")
        for heading in ["## Stop when", "## Never"]:
            record(heading in text, f"{path.relative_to(root)} includes {heading}")

for human_path in [
    root / "plugins/prism/skills/lifecycle/references/human.md",
    root / "plugins/prism/prefixed-skills/prism-lifecycle/references/human.md",
]:
    text = human_path.read_text() if human_path.is_file() else ""
    relative = human_path.relative_to(root)
    summary_markers = [
        "`### Design summary`",
        "`### Task summary`",
        "`### Approval request`",
    ]
    summary_positions = [text.find(marker) for marker in summary_markers]
    record(
        all(position >= 0 for position in summary_positions)
        and summary_positions == sorted(summary_positions),
        f"{relative} presents design summary, task summary, then approval request",
    )
    for snippet, contract in [
        ("cover **every** current child task", "covers every child task"),
        ("dependencies, blockers, or execution order", "shows task dependencies and blockers"),
        ("ordinary free-form language", "accepts free-form approval"),
        ("unambiguously authorizes implementation", "requires unambiguous approval intent"),
        (
            "bd update <story> --set-labels prism,phase:apply,human:approved",
            "persists approval and apply phase atomically",
        ),
        ("Then re-read the story", "re-reads persisted approval"),
        ("ambiguous, conditional", "fails closed for ambiguous or conditional intent"),
        (
            "merely discusses how approval should work",
            "does not mistake approval discussion for approval",
        ),
    ]:
        record(snippet in text, f"{relative} {contract}")

for base in [
    root / "plugins/prism/skills/lifecycle/references",
    root / "plugins/prism/prefixed-skills/prism-lifecycle/references",
]:
    breakdown_text = (base / "breakdown.md").read_text()
    for snippet in [
        "preserve every open and closed child",
        "never auto-delete, auto-close, or reopen a child",
    ]:
        record(snippet in breakdown_text, f"{(base / 'breakdown.md').relative_to(root)} enforces reconciliation: {snippet}")

for skill_path in [
    root / "plugins/prism-callee/skills/lifecycle/SKILL.md",
    root / "plugins/prism-callee/prefixed-skills/prism-callee-lifecycle/SKILL.md",
]:
    text = skill_path.read_text()
    for snippet in [
        "exact order: `### Design summary`, `### Task summary`, `### Approval request`",
        "exact `APPROVE` classifier decision",
        "Never automatically delete, close, or reopen children",
    ]:
        record(snippet in text, f"{skill_path.relative_to(root)} documents lifecycle contract: {snippet}")

callee_contracts = {
    "pack/callee/prism/lifecycle.md": [
        "### Design summary",
        "### Task summary",
        "### Approval request",
    ],
    "pack/callee/prism/phases/human.md": ["prism/human/intent", "approval_intent"],
    "pack/callee/prism/human/intent.md": ["mode: deny", "Output exactly `APPROVE`", "Output exactly `WITHHOLD`"],
    "pack/callee/prism/human/check.md": ['[ "$normalized" = "APPROVE" ]', "APPROVAL_INTENT"],
}
for relative_path, snippets in callee_contracts.items():
    path = root / relative_path
    text = path.read_text() if path.is_file() else ""
    record(path.is_file(), f"{relative_path} exists")
    for snippet in snippets:
        record(snippet in text, f"{relative_path} contains contract marker: {snippet}")

callee_lifecycle_text = (root / "pack/callee/prism/lifecycle.md").read_text()
callee_summary_positions = [
    callee_lifecycle_text.find(marker)
    for marker in ["### Design summary", "### Task summary", "### Approval request"]
]
record(
    all(position >= 0 for position in callee_summary_positions)
    and callee_summary_positions == sorted(callee_summary_positions),
    "Callee lifecycle presents design summary, task summary, then approval request",
)

record(
    not (root / "plugins/prism/skills/lifecycle/references/plan.md").exists(),
    "canonical plan reference was removed",
)
record(
    not (root / "plugins/prism/prefixed-skills/prism-lifecycle/references/plan.md").exists(),
    "prefixed plan reference was removed",
)

for phase in ["specify", "design", "breakdown", "human", "apply", "verify"]:
    path = root / "pack/callee/prism/phases" / f"{phase}.md"
    record(path.is_file(), f"public Callee phase exists: prism/phases/{phase}")

stale_tokens = [
    "phase:plan",
    "references/plan.md",
    "prism/interviewer",
    "prism/designer",
    "prism/planner",
    "prism/implementer",
    "prism/reviewer",
]
scan_roots = [
    root / "README.md",
    root / "docs",
    root / "plugins/prism",
    root / "plugins/prism-callee",
    root / "pack/callee/prism",
]
for scan_root in scan_roots:
    paths = [scan_root] if scan_root.is_file() else scan_root.rglob("*")
    for path in paths:
        if not path.is_file() or path.suffix not in {".md", ".json", ".yaml", ".yml"}:
            continue
        text = path.read_text()
        for token in stale_tokens:
            record(token not in text, f"{path.relative_to(root)} omits stale token {token}")

story_phase_assignees = [
    "prism/specify",
    "prism/design",
    "prism/breakdown",
    "prism/human",
    "prism/apply",
    "prism/verify",
]
for scan_root in scan_roots:
    paths = [scan_root] if scan_root.is_file() else scan_root.rglob("*")
    for path in paths:
        if not path.is_file() or path.suffix not in {".md", ".json", ".yaml", ".yml"}:
            continue
        text = path.read_text()
        for assignee in story_phase_assignees:
            encoded_assignee = re.compile(
                rf"(?:-a|--assignee|assignee:)\s+{re.escape(assignee)}(?!/)"
            )
            record(
                encoded_assignee.search(text) is None,
                f"{path.relative_to(root)} does not encode story phase with assignee {assignee}",
            )

if errors:
    print(f"\nValidation failed with {len(errors)} error(s).")
    sys.exit(1)

print("\nValidation passed.")
PY
