#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$repo_root" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
errors: list[str] = []


def record(condition: bool, message: str) -> None:
    if condition:
        print(f"PASS: {message}")
    else:
        errors.append(message)
        print(f"FAIL: {message}")


def load_json(path: pathlib.Path) -> dict:
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError as exc:
        record(False, f"{path.relative_to(root)} is valid JSON: {exc}")
        return {}


mapping_path = root / "docs/lifecycle-ownership.json"
record(mapping_path.is_file(), "docs/lifecycle-ownership.json exists")
mapping = load_json(mapping_path) if mapping_path.is_file() else {}
record(mapping.get("version") == 3, "lifecycle ownership schema version is 3")
record(mapping.get("lifecycle_ref") == "prism/lifecycle", "lifecycle ref is prism/lifecycle")
manual_entrypoints = mapping.get("manual_host_entrypoints", {})
automated_entrypoints = mapping.get("automated_host_entrypoints", {})
record(
    manual_entrypoints.get("codex") == "$prism:lifecycle",
    "manual host Codex entrypoint is $prism:lifecycle",
)
record(
    manual_entrypoints.get("claude") == "/prism:lifecycle",
    "manual host Claude entrypoint is /prism:lifecycle",
)
record(
    manual_entrypoints.get("flat") == "/prism-lifecycle",
    "manual host flat entrypoint is /prism-lifecycle",
)
record(
    automated_entrypoints.get("codex") == "$prism-callee:lifecycle",
    "automated host Codex entrypoint is $prism-callee:lifecycle",
)
record(
    automated_entrypoints.get("claude") == "/prism-callee:lifecycle",
    "automated host Claude entrypoint is /prism-callee:lifecycle",
)
record(
    automated_entrypoints.get("flat") == "/prism-callee-lifecycle",
    "automated host flat entrypoint is /prism-callee-lifecycle",
)

expected_story_phases = ["specify", "design", "plan", "human", "apply", "verify"]
expected_task_states = ["implementation", "review"]

story_phases = mapping.get("story_phases", [])
task_states = mapping.get("task_states", [])

record(
    [item.get("phase") for item in story_phases] == expected_story_phases,
    "story phases are specify -> design -> plan -> human -> apply -> verify",
)
record(
    [item.get("state") for item in task_states] == expected_task_states,
    "task states are implementation -> review",
)

preferred = mapping.get("preferred_assignee_encoding", {})
record(
    preferred.get("namespace") == "prism" and preferred.get("delimiter") == "/",
    "preferred assignee encoding is prism/<owner>",
)

aliases = mapping.get("accepted_assignee_aliases", [])
record(
    any(alias.get("namespace") == "prism" and alias.get("delimiter") == ":" for alias in aliases),
    "accepted alias encoding includes prism:<owner>",
)

for phase in story_phases:
    phase_name = phase.get("phase")
    owner = phase.get("owner")
    assignee = phase.get("assignee")
    executor = phase.get("executor", {})
    phase_label = f"phase:{phase_name}"

    if owner == "human":
        record(assignee == "human", f"{phase_label} assignee is human")
    else:
        record(assignee == f"prism/{owner}", f"{phase_label} assignee is prism/{owner}")
        record(
            f"prism:{owner}" in phase.get("aliases", []),
            f"{phase_label} accepts alias prism:{owner}",
        )

    record(bool(executor.get("kind")), f"{phase_label} declares an executor kind")
    manual_phase_reference = executor.get("manual_phase_reference")
    record(
        "manual_skill" not in executor,
        f"{phase_label} does not use stale manual_skill metadata",
    )
    record(bool(manual_phase_reference), f"{phase_label} declares a manual_phase_reference")
    if manual_phase_reference:
        manual_phase_path = root / manual_phase_reference
        record(
            manual_phase_path.is_file(),
            f"{phase_label} manual_phase_reference exists: {manual_phase_reference}",
        )
    public_ref = executor.get("public_ref")
    if phase_name == "human":
        record(bool(public_ref), f"{phase_label} declares a public_ref")
        if public_ref:
            public_path = root / "pack/callee" / (public_ref + ".md")
            record(public_path.is_file(), f"{phase_label} public_ref exists: {public_ref}")
    else:
        record(bool(public_ref), f"{phase_label} declares a public_ref")
        if public_ref:
            public_path = root / "pack/callee" / (public_ref + ".md")
            record(public_path.is_file(), f"{phase_label} public_ref exists: {public_ref}")
    for ref in executor.get("internal_refs", []):
        agent_path = root / "pack/callee" / (ref + ".md")
        record(agent_path.is_file(), f"{phase_label} internal ref exists: {ref}")

docs_checks = [
    (
        root / "README.md",
        [
            "/prism:lifecycle",
            "/prism-callee:lifecycle",
            "Beads assignee is the current phase owner",
            "Apply closes remaining story work one ready child task at a time.",
            "Verify is a close-or-bounce story decision.",
            "docs/architecture-host-lifecycle.md",
            "docs/architecture-callee-lifecycle.md",
        ],
    ),
    (
        root / "plugins/prism/skills/lifecycle/SKILL.md",
        [
            "/prism:lifecycle",
            "story-level operational closure",
            "close-or-bounce decision phase",
            "prism/interviewer",
            "prism/reviewer",
            "references/specify.md",
            "references/design.md",
            "references/plan.md",
            "references/human.md",
            "references/apply.md",
            "references/verify.md",
            "The phase references, not this file, own the phase-local procedure.",
        ],
    ),
    (
        root / "plugins/prism/prefixed-skills/prism-lifecycle/SKILL.md",
        [
            "/prism:lifecycle",
            "story-level operational closure",
            "close-or-bounce decision phase",
            "/prism-callee-lifecycle",
            "references/specify.md",
            "references/design.md",
            "references/plan.md",
            "references/human.md",
            "references/apply.md",
            "references/verify.md",
            "The phase references, not this file, own the phase-local procedure.",
        ],
    ),
    (
        root / "plugins/prism-callee/skills/lifecycle/SKILL.md",
        [
            "/prism-callee:lifecycle",
            "prism/lifecycle",
            "prism/phases/human",
            "prism/phases/apply",
            "outer story loop",
            "one-task implementer/reviewer loop",
            "close-or-bounce decision",
            "references/promptkit.md",
        ],
    ),
    (
        root / "plugins/prism-callee/prefixed-skills/prism-callee-lifecycle/SKILL.md",
        [
            "/prism-callee:lifecycle",
            "prism/lifecycle",
            "prism/phases/human",
            "prism/phases/apply",
            "outer story loop",
            "one-task implementer/reviewer loop",
            "close-or-bounce decision",
            "../../skills/lifecycle/references/promptkit.md",
        ],
    ),
    (
        root / "docs/architecture-host-lifecycle.md",
        [
            "$prism:lifecycle",
            "/prism:lifecycle",
            "/prism-lifecycle",
        ],
    ),
    (
        root / "docs/architecture-callee-lifecycle.md",
        [
            "$prism-callee:lifecycle",
            "/prism-callee:lifecycle",
            "/prism-callee-lifecycle",
        ],
    ),
    (
        root / "plugins/prism/skills/lifecycle/references/lifecycle.md",
        [
            "story-level operational closure",
            "close-or-bounce story decision"
        ],
    ),
]

for path, snippets in docs_checks:
    record(path.is_file(), f"{path.relative_to(root)} exists")
    text = path.read_text() if path.is_file() else ""
    for snippet in snippets:
        record(snippet in text, f"{path.relative_to(root)} mentions: {snippet}")

for path in [
    root / "plugins/prism/skills/lifecycle/SKILL.md",
    root / "plugins/prism/prefixed-skills/prism-lifecycle/SKILL.md",
]:
    text = path.read_text() if path.is_file() else ""
    for stale_heading in [
        "### 1. Intake / specify",
        "### 2. Design",
        "### 3. Plan",
        "### 4. Human gate (human only)",
        "### 5. Apply",
        "### 6. Verify + close",
    ]:
        record(
            stale_heading not in text,
            f"{path.relative_to(root)} omits duplicated phase recipe heading: {stale_heading}",
        )

for phase_ref in [
    root / "plugins/prism/skills/lifecycle/references/specify.md",
    root / "plugins/prism/skills/lifecycle/references/design.md",
    root / "plugins/prism/skills/lifecycle/references/plan.md",
    root / "plugins/prism/skills/lifecycle/references/human.md",
    root / "plugins/prism/skills/lifecycle/references/apply.md",
    root / "plugins/prism/skills/lifecycle/references/verify.md",
    root / "plugins/prism/prefixed-skills/prism-lifecycle/references/specify.md",
    root / "plugins/prism/prefixed-skills/prism-lifecycle/references/design.md",
    root / "plugins/prism/prefixed-skills/prism-lifecycle/references/plan.md",
    root / "plugins/prism/prefixed-skills/prism-lifecycle/references/human.md",
    root / "plugins/prism/prefixed-skills/prism-lifecycle/references/apply.md",
    root / "plugins/prism/prefixed-skills/prism-lifecycle/references/verify.md",
    root / "plugins/prism-callee/skills/lifecycle/references/promptkit.md",
]:
    record(phase_ref.is_file(), f"{phase_ref.relative_to(root)} exists")

phase_contract_sections = [
    "## Required inputs",
    "## Persist and advance",
    "## Stop when",
    "## Never",
]

for phase_ref in [
    root / "plugins/prism/skills/lifecycle/references/specify.md",
    root / "plugins/prism/skills/lifecycle/references/design.md",
    root / "plugins/prism/skills/lifecycle/references/plan.md",
    root / "plugins/prism/skills/lifecycle/references/human.md",
    root / "plugins/prism/skills/lifecycle/references/apply.md",
    root / "plugins/prism/skills/lifecycle/references/verify.md",
    root / "plugins/prism/prefixed-skills/prism-lifecycle/references/specify.md",
    root / "plugins/prism/prefixed-skills/prism-lifecycle/references/design.md",
    root / "plugins/prism/prefixed-skills/prism-lifecycle/references/plan.md",
    root / "plugins/prism/prefixed-skills/prism-lifecycle/references/human.md",
    root / "plugins/prism/prefixed-skills/prism-lifecycle/references/apply.md",
    root / "plugins/prism/prefixed-skills/prism-lifecycle/references/verify.md",
]:
    text = phase_ref.read_text() if phase_ref.is_file() else ""
    for section in phase_contract_sections:
        record(
            section in text,
            f"{phase_ref.relative_to(root)} mentions: {section}",
        )

for stale_ref in [
    root / "plugins/prism/skills/lifecycle/references/promptkit.md",
    root / "plugins/prism/prefixed-skills/prism-lifecycle/references/promptkit.md",
]:
    record(not stale_ref.exists(), f"{stale_ref.relative_to(root)} was removed from manual host skill references")

for workflow_ref in [
    root / "pack/callee/prism/lifecycle.md",
]:
    record(workflow_ref.is_file(), f"{workflow_ref.relative_to(root)} exists")

mirror_dir = root / ".callee/prism"
mirror_lifecycle = mirror_dir / "lifecycle.md"
if mirror_dir.exists():
    record(
        mirror_lifecycle.is_file(),
        ".callee/prism/lifecycle.md exists when the optional .callee/prism mirror directory is present",
    )
else:
    record(True, ".callee/prism mirror directory is absent; mirror remains optional")

for phase_ref in [
    root / "pack/callee/prism/phases/specify.md",
    root / "pack/callee/prism/phases/design.md",
    root / "pack/callee/prism/phases/breakdown.md",
    root / "pack/callee/prism/phases/human.md",
    root / "pack/callee/prism/phases/apply.md",
    root / "pack/callee/prism/phases/verify.md",
    root / "pack/callee/prism/human/prompt.md",
    root / "pack/callee/prism/human/check.md",
]:
    record(phase_ref.is_file(), f"{phase_ref.relative_to(root)} exists")

if (root / "pack/callee/prism/lifecycle.md").is_file():
    lifecycle_text = (root / "pack/callee/prism/lifecycle.md").read_text()
    record(
        "kind: Sequential" in lifecycle_text,
        "pack/callee/prism/lifecycle.md is Sequential",
    )
    for snippet in [
        "alias: specify",
        "alias: design",
        "alias: breakdown",
        "alias: human",
        "ref: prism/phases/human",
        "ref: prism/phases/apply",
        "ref: prism/phases/verify",
    ]:
        record(
            snippet in lifecycle_text,
            f"pack/callee/prism/lifecycle.md includes {snippet}",
        )

if errors:
    print(f"\nValidation failed with {len(errors)} error(s).")
    sys.exit(1)

print("\nValidation passed.")
PY
