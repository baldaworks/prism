#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$repo_root" <<'PY'
import json
import pathlib
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


mapping_path = root / "docs/lifecycle-ownership.json"
record(mapping_path.is_file(), "lifecycle ownership mapping exists")
mapping = load_json(mapping_path) if mapping_path.is_file() else {}

record(mapping.get("version") == 6, "ownership schema version is 6")
record(mapping.get("lifecycle_labels") == ["prism", "human:approved"], "only prism and human:approved are lifecycle labels")
impact_lens = mapping.get("impact_lens", {})
record(impact_lens.get("design_heading") == "## Prism Impact Lens", "Impact Lens has the durable design heading")
record(
    impact_lens.get("dimensions") == ["Product", "Process", "People", "Planet", "Prosperity"],
    "Impact Lens owns exactly the five Prism dimensions",
)
record(
    impact_lens.get("ratings") == ["positive", "negative", "mixed", "not-material", "unknown"],
    "Impact Lens ratings are qualitative and closed",
)
record(impact_lens.get("numeric_score") is False, "Impact Lens forbids a numeric score")
record(impact_lens.get("unknown_blocks_transition") == "breakdown", "unknown impact blocks Breakdown")
record(
    impact_lens.get("human_summary_order")
    == ["Design summary", "Prism Impact Lens", "Task summary", "Approval request"],
    "human summary order includes the Impact Lens before tasks",
)
record(
    impact_lens.get("open_story_migration")
    == {
        "missing_or_invalid": "design",
        "clear_human_approval": True,
        "preserve_child_statuses": True,
        "reconcile_children_in": "breakdown",
    },
    "open legacy stories return to Design and preserve children for reconciliation",
)
record(impact_lens.get("closed_story_migration") == "unchanged", "closed stories are not migrated")
record(
    mapping.get("entry_resolution") == {
        "explicit_story_id": "resume",
        "single_open_prism_story": "resume",
        "otherwise": "create",
        "new_story": {
            "labels": ["prism"],
            "assignee": "prism/specify",
            "description": "raw_user_request",
        },
    },
    "entry resolution resumes explicit or sole stories and otherwise creates prism/specify",
)

expected_story = [
    ("specify", "prism/specify"),
    ("design", "prism/design"),
    ("breakdown", "prism/breakdown"),
    ("human", "prism/human"),
    ("apply", "prism/apply"),
    ("verify", "prism/verify"),
]
story_phases = mapping.get("story_phases", [])
record(
    [(item.get("phase"), item.get("assignee")) for item in story_phases] == expected_story,
    "story assignees encode specify -> design -> breakdown -> human -> apply -> verify",
)

for phase in story_phases:
    name = phase.get("phase")
    assignee = phase.get("assignee")
    record(phase.get("aliases") == [assignee.replace("/", ":")], f"{name} has a matching colon alias")
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
    for assignee in [value for _, value in expected_story]:
        record(assignee in text, f"{skill_path.relative_to(root)} mentions {assignee}")
    record("phase:*" in text, f"{skill_path.relative_to(root)} forbids phase labels")
    for snippet in [
        "story ID",
        "exactly one open Prism stor",
        "--type=story -a prism/specify -l prism",
        "raw user request",
    ]:
        record(snippet in text, f"{skill_path.relative_to(root)} documents lifecycle-owned story creation: {snippet}")

readme_path = root / "README.md"
readme_text = readme_path.read_text() if readme_path.is_file() else ""
record("bd create" not in readme_text, "README does not require manual story creation")
for internal_workflow in ["documentation-maintenance", "documentation/workflows/maintain", "pack/callee/documentation/"]:
    record(internal_workflow not in readme_text, f"README omits internal workflow reference: {internal_workflow}")

for architecture_path in [
    root / "docs/architecture-host-lifecycle.md",
    root / "docs/architecture-callee-lifecycle.md",
]:
    architecture_text = architecture_path.read_text() if architecture_path.is_file() else ""
    record("exactly one open Prism story" in architecture_text, f"{architecture_path.relative_to(root)} documents sole-story resume")
    record("prism/specify" in architecture_text, f"{architecture_path.relative_to(root)} documents new-story assignee")

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
        "`### Prism Impact Lens`",
        "`### Task summary`",
        "`### Approval request`",
    ]
    summary_positions = [text.find(marker) for marker in summary_markers]
    record(
        all(position >= 0 for position in summary_positions)
        and summary_positions == sorted(summary_positions),
        f"{relative} presents design summary, Impact Lens, task summary, then approval request",
    )
    for snippet, contract in [
        ("cover **every** current child task", "covers every child task"),
        ("dependencies, blockers, or execution order", "shows task dependencies and blockers"),
        ("ordinary free-form language", "accepts free-form approval"),
        ("unambiguously authorizes implementation", "requires unambiguous approval intent"),
        (
            "bd update <story> -a prism/apply --set-labels prism,human:approved",
            "persists approval and apply assignee atomically",
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
    design_text = (base / "design.md").read_text()
    for snippet in [
        "## Prism Impact Lens",
        "| Dimension | Rating | Rationale / evidence | Mitigation / verification |",
        "`positive`, `negative`, `mixed`",
        "`not-material`, and `unknown`",
        "Do not advance while any rating is `unknown`",
    ]:
        record(snippet in design_text, f"{(base / 'design.md').relative_to(root)} enforces Impact Lens contract: {snippet}")

    breakdown_text = (base / "breakdown.md").read_text()
    for snippet in [
        "Every actionable Impact Lens mitigation",
        "preserve every open and closed child",
        "never auto-delete, auto-close, or reopen a child",
    ]:
        record(snippet in breakdown_text, f"{(base / 'breakdown.md').relative_to(root)} enforces reconciliation: {snippet}")

    apply_text = (base / "apply.md").read_text()
    verify_text = (base / "verify.md").read_text()
    record("Impact Lens mitigation" in apply_text, f"{(base / 'apply.md').relative_to(root)} honors mitigation criteria")
    record("actionable Impact Lens mitigation" in verify_text, f"{(base / 'verify.md').relative_to(root)} verifies mitigation evidence")

for skill_path in [
    root / "plugins/prism-callee/skills/lifecycle/SKILL.md",
    root / "plugins/prism-callee/prefixed-skills/prism-callee-lifecycle/SKILL.md",
]:
    text = skill_path.read_text()
    for snippet in [
        "missing, invalid, or `unknown` Impact Lens",
        "`### Design summary`, `### Prism Impact Lens`",
        "exact `APPROVE` classifier decision",
        "Never automatically delete, close, or reopen children",
    ]:
        record(snippet in text, f"{skill_path.relative_to(root)} documents automated Impact Lens contract: {snippet}")

callee_contracts = {
    "pack/callee/prism/roles/architect.md": ["## Prism Impact Lens", "| Product |", "| Prosperity |", "No Impact Lens rating is `unknown`"],
    "pack/callee/prism/phases/breakdown.md": ["Every actionable Impact Lens mitigation", "never auto-delete, close, or reopen"],
    "pack/callee/prism/apply/loop.md": ["Prism Impact Lens", "mitigation adherence"],
    "pack/callee/prism/verify/review.md": ["every actionable", "residual impacts"],
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
    "phase:specify",
    "phase:design",
    "phase:plan",
    "phase:breakdown",
    "phase:human",
    "phase:apply",
    "phase:verify",
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

if errors:
    print(f"\nValidation failed with {len(errors)} error(s).")
    sys.exit(1)

print("\nValidation passed.")
PY
