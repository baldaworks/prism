#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$repo_root" <<'PY'
import json
import hashlib
import os
import pathlib
import re
import subprocess
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
record(mapping.get("version") == 13, "ownership schema version is 13")
record(
    mapping.get("direct_callee_invocation")
    == 'callee agent run prism/lifecycle --message "..."',
    "ownership schema declares direct Callee binary invocation",
)
record(
    mapping.get("full_host_entrypoints")
    == {
        "codex": "$prism:lifecycle",
        "claude": "/prism:lifecycle",
        "flat": "/prism-lifecycle",
    },
    "ownership schema declares full host entrypoints",
)
record(
    mapping.get("light_host_entrypoints")
    == {
        "codex": "$prism:light",
        "claude": "/prism:light",
        "flat": "/prism-light",
    },
    "ownership schema declares Light entrypoints",
)
record(
    mapping.get("automated_host_entrypoints")
    == {
        "codex": "$prism-callee:lifecycle",
        "claude": "/prism-callee:lifecycle",
        "flat": "/prism-callee-lifecycle",
    },
    "ownership schema preserves Callee host entrypoints",
)
callee_pack = mapping.get("callee_pack", {})
record(
    callee_pack.get("path") == "pack/callee"
    and callee_pack.get("mutation_policy") == "forbidden",
    "ownership schema makes the Callee pack an immutable source",
)
baseline_tree = callee_pack.get("baseline_git_tree", "")
tree_result = subprocess.run(
    ["git", "rev-parse", "HEAD:pack/callee"],
    cwd=root,
    text=True,
    capture_output=True,
    check=False,
)
record(
    tree_result.returncode == 0 and tree_result.stdout.strip() == baseline_tree,
    "committed Callee pack matches the immutable baseline tree",
)
pack_diff = subprocess.run(
    ["git", "diff", "--quiet", "HEAD", "--", "pack/callee"],
    cwd=root,
    check=False,
)
record(pack_diff.returncode == 0, "working tree does not modify the Callee pack")
root_source = callee_pack.get("root_source", {})
root_source_path = root / root_source.get("path", "")
record(root_source_path.is_file(), "Callee lifecycle root source exists")
if root_source_path.is_file():
    record(
        hashlib.sha256(root_source_path.read_bytes()).hexdigest()
        == root_source.get("sha256"),
        "Callee lifecycle root source matches its frozen digest",
    )
record(
    mapping.get("lifecycle_labels") == ["prism", "human:approved", *phase_labels],
    "lifecycle labels contain membership, approval, and every supported phase",
)
record(mapping.get("phase_labels") == phase_labels, "phase labels declare the supported lifecycle sequence")
record(
    mapping.get("advance_policy") == {
        "pre_approval_phases": ["specify", "design", "breakdown"],
        "mode": "continuous_through_human_request",
        "confirmation_between_phases": False,
    },
    "pre-approval phases advance continuously without confirmation",
)
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
    human_gate.get("classifier_decisions")
    == ["APPROVE", "REFINE_DESIGN", "WITHHOLD"],
    "human classifier exposes approval, refinement, and withhold decisions",
)
record(
    human_gate.get("refine_stop_marker")
    == "PRISM_HUMAN_DECISION=REFINE_DESIGN",
    "human refinement has a machine-readable fail-closed stop marker",
)
record(
    human_gate.get("decisions") == {
        "approve": {
            "transition": "apply",
            "approval_label": "human:approved",
        },
        "refine_design": {
            "transition": "design",
            "clear_approval": True,
            "preserve_children": True,
        },
        "withhold": {"transition": "human"},
    },
    "human gate declares approval, design refinement, and withhold outcomes",
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
human_phase = next(
    (item for item in story_phases if item.get("phase") == "human"),
    {},
)
specify_phase = next(
    (item for item in story_phases if item.get("phase") == "specify"),
    {},
)
specify_loop = specify_phase.get("executor", {}).get("clarification_loop", {})
record(
    specify_loop == {
        "ref": "prism/specify/loop",
        "kind": "Loop",
        "normalizer_ref": "prism/roles/interviewer",
        "gate_ref": "prism/specify/gate",
        "human_ref": "prism/specify/questions",
        "ready_transition": "exit",
        "clarification_transition": "repeat",
        "max_iterations": 5,
        "on_exhausted": "fail",
    },
    "specify declares its Human clarification loop contract",
)
record(
    human_phase.get("decision_transitions") == {
        "approve": "apply",
        "refine_design": "design",
        "withhold": "human",
    },
    "human phase can return design for refinement without authorizing apply",
)

for phase in story_phases:
    name = phase.get("phase")
    record("assignee" not in phase, f"{name} has no story-phase assignee")
    record("aliases" not in phase, f"{name} has no assignee aliases")
    executor = phase.get("executor", {})
    full_ref = executor.get("full_host_reference")
    full_ref_sha256 = executor.get("full_host_reference_sha256")
    light_ref = executor.get("light_host_reference")
    public_ref = executor.get("public_ref")
    record(bool(executor.get("kind")), f"{name} declares executor kind")
    record(
        bool(full_ref) and (root / full_ref).is_file(),
        f"{name} full host phase reference exists",
    )
    full_ref_path = root / full_ref if full_ref else root / "__missing__"
    record(
        isinstance(full_ref_sha256, str)
        and re.fullmatch(r"[0-9a-f]{64}", full_ref_sha256) is not None,
        f"{name} declares a frozen full-host reference digest",
    )
    if full_ref_path.is_file():
        record(
            hashlib.sha256(full_ref_path.read_bytes()).hexdigest()
            == full_ref_sha256,
            f"{name} full host reference matches its reviewed semantic digest",
        )
    record(
        bool(light_ref) and (root / light_ref).is_file(),
        f"{name} Light phase reference exists",
    )
    record(
        bool(public_ref) and (root / "pack/callee" / f"{public_ref}.md").is_file(),
        f"{name} public Callee phase exists",
    )
    for internal_ref in executor.get("internal_refs", []):
        record(
            (root / "pack/callee" / f"{internal_ref}.md").is_file(),
            f"{name} internal Callee ref exists: {internal_ref}",
        )
    source_files = executor.get("source_files", [])
    record(bool(source_files), f"{name} declares ordered Callee contract sources")
    for source in source_files:
        source_path = root / source.get("path", "")
        record(source_path.is_file(), f"{name} Callee source exists: {source.get('path')}")
        if source_path.is_file():
            record(
                hashlib.sha256(source_path.read_bytes()).hexdigest()
                == source.get("sha256"),
                f"{name} Callee source matches frozen digest: {source.get('path')}",
            )

    host_contract = executor.get("host_contract", {})
    record(
        host_contract.get("id") == f"{name}-v1"
        and bool(host_contract.get("steps"))
        and bool(host_contract.get("required_outputs"))
        and isinstance(host_contract.get("max_iterations"), int)
        and bool(host_contract.get("on_exhausted")),
        f"{name} declares a complete full-host contract projection",
    )
    if name == "specify":
        record(
            host_contract.get("required_inputs")
            == [
                "story-record",
                "raw-user-intent",
                "human-clarifications",
                "system-context",
            ],
            "specify projection preserves its required inputs",
        )
        record(
            host_contract.get("quality_gates")
            == [
                "readiness-invariants",
                "minimum-blocking-questions",
                "self-verification",
                "non-empty-requirements-extract",
            ],
            "specify projection preserves its quality gates",
        )
        record(
            host_contract.get("protocol")
            == {
                "normalizer_sections": [
                    "SPECIFY_DECISION",
                    "MISSING_DIMENSIONS",
                    "FOLLOW_UP_QUESTIONS",
                    "REQUIREMENTS_DOCUMENT",
                ],
                "gate_sections": [
                    "SPECIFY_GATE_DECISION",
                    "GATE_SUMMARY",
                    "MISSING_DIMENSIONS",
                    "FOLLOW_UP_QUESTIONS",
                    "REQUIREMENTS_RISKS",
                ],
                "requirements_sections": [
                    "Pre-Authoring Analysis",
                    "Overview",
                    "Scope",
                    "Definitions and Glossary",
                    "Requirements",
                    "Dependencies",
                    "Assumptions",
                    "Risks",
                    "Revision History",
                ],
                "epistemic_labels": [
                    "KNOWN",
                    "INFERRED",
                    "ASSUMED",
                    "UNKNOWN",
                ],
                "human_response": "numbered-follow-ups-or-UNKNOWN",
                "extract": "non-empty-REQUIREMENTS_DOCUMENT",
            },
            "specify projection preserves output envelopes and protocol obligations",
        )
    for reference_path in [
        full_ref_path,
        root
        / "plugins/prism/prefixed-skills/prism-lifecycle/references"
        / f"{name}.md",
    ]:
        text = reference_path.read_text() if reference_path.is_file() else ""
        match = re.search(
            r"## Contract projection\s+```json\s+(\{.*?\})\s+```",
            text,
            re.DOTALL,
        )
        parsed_contract = {}
        if match:
            try:
                parsed_contract = json.loads(match.group(1))
            except json.JSONDecodeError:
                pass
        record(
            parsed_contract == host_contract,
            f"{reference_path.relative_to(root)} matches the {name} Callee projection",
        )
    light_text = (root / light_ref).read_text() if light_ref and (root / light_ref).is_file() else ""
    record(
        "## Contract projection" not in light_text,
        f"{name} Light reference remains outside full Callee parity",
    )

specify_loop_path = root / "pack/callee/prism/specify/loop.md"
specify_questions_path = root / "pack/callee/prism/specify/questions.md"
specify_loop_text = specify_loop_path.read_text() if specify_loop_path.is_file() else ""
specify_questions_text = (
    specify_questions_path.read_text() if specify_questions_path.is_file() else ""
)
for snippet, message in [
    ("kind: Loop", "specify executor is a Loop"),
    ("alias: normalizer", "specify loop runs the normalizer"),
    ("alias: gate", "specify loop runs the readiness gate"),
    ("canEscalate: true", "specify ready gate can exit the loop"),
    ("alias: clarifications", "specify loop reaches Human clarification"),
    ('index .State.outputs "clarifications"', "specify feeds Human answers into the next iteration"),
    ("maxIterations: 5", "specify loop allows five iterations"),
    ("onExhausted: fail", "specify loop fails closed on exhaustion"),
]:
    record(snippet in specify_loop_text, message)
record("kind: Human" in specify_questions_text, "specify clarification ref is a Human agent")

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
    root / "plugins/prism/skills/light/SKILL.md",
    root / "plugins/prism/prefixed-skills/prism-light/SKILL.md",
    root / "plugins/prism-callee/skills/lifecycle/SKILL.md",
    root / "plugins/prism-callee/prefixed-skills/prism-callee-lifecycle/SKILL.md",
]:
    text = skill_path.read_text() if skill_path.is_file() else ""
    lower_text = text.lower()
    record(skill_path.is_file(), f"{skill_path.relative_to(root)} exists")
    for phase_label in phase_labels:
        record(phase_label in text, f"{skill_path.relative_to(root)} mentions {phase_label}")
    record("exactly one" in lower_text and "phase:*" in text, f"{skill_path.relative_to(root)} requires exactly one phase label")
    for snippet in [
        "story ID",
        "exactly one open Prism stor",
        "--type=story -l prism,phase:specify",
        "raw user request",
    ]:
        record(snippet in text, f"{skill_path.relative_to(root)} documents lifecycle-owned story creation: {snippet}")
    record(
        "pre-approval" in lower_text and "human" in lower_text,
        f"{skill_path.relative_to(root)} documents continuous pre-approval progression into Human",
    )

skill_pairs = [
    (
        root / "plugins/prism/skills/lifecycle/SKILL.md",
        root / "plugins/prism/prefixed-skills/prism-lifecycle/SKILL.md",
        "full host lifecycle skills differ only by frontmatter name",
    ),
    (
        root / "plugins/prism/skills/light/SKILL.md",
        root / "plugins/prism/prefixed-skills/prism-light/SKILL.md",
        "Light lifecycle skills differ only by frontmatter name",
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
        "full host lifecycle reference",
    ),
    (
        root / "plugins/prism/skills/light/references",
        root / "plugins/prism/prefixed-skills/prism-light/references",
        ["specify.md", "design.md", "breakdown.md", "human.md", "apply.md", "verify.md", "lifecycle.md"],
        "Light lifecycle reference",
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

host_lifecycle_diagrams = [
    root / "README.md",
    root / "plugins/prism/skills/lifecycle/references/lifecycle.md",
    root / "plugins/prism/prefixed-skills/prism-lifecycle/references/lifecycle.md",
]
for diagram_path in host_lifecycle_diagrams:
    text = diagram_path.read_text() if diagram_path.is_file() else ""
    lower_text = text.lower()
    relative = diagram_path.relative_to(root)
    record(
        "specify gate" in lower_text or "readiness gate" in lower_text,
        f"{relative} shows the Specify readiness gate",
    )
    record(
        "needs clarification" in text and "Human clarification" in text,
        f"{relative} shows the Specify Human clarification branch",
    )
    record(
        re.search(r"Q\s*-->.*S", text) is not None,
        f"{relative} returns Human clarification to Specify",
    )

host_specify_references = [
    root / "plugins/prism/skills/light/references/specify.md",
    root / "plugins/prism/prefixed-skills/prism-light/references/specify.md",
]
for specify_path in host_specify_references:
    text = specify_path.read_text() if specify_path.is_file() else ""
    relative = specify_path.relative_to(root)
    record(
        re.search(r"return\s+to step 2", text) is not None
        and "clarification loop" in text,
        f"{relative} repeats Specify after Human clarification",
    )
    record(
        "phase-transition approval" in text,
        f"{relative} distinguishes clarification from Human approval",
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
    root / "docs/architecture-light-lifecycle.md",
    root / "docs/architecture-callee-lifecycle.md",
]:
    architecture_text = architecture_path.read_text() if architecture_path.is_file() else ""
    record("exactly one open Prism story" in architecture_text, f"{architecture_path.relative_to(root)} documents sole-story resume")
    record("phase:specify" in architecture_text, f"{architecture_path.relative_to(root)} documents new-story phase label")

for reference in ["specify", "design", "breakdown", "human", "apply", "verify"]:
    for base in [
        root / "plugins/prism/skills/lifecycle/references",
        root / "plugins/prism/prefixed-skills/prism-lifecycle/references",
        root / "plugins/prism/skills/light/references",
        root / "plugins/prism/prefixed-skills/prism-light/references",
    ]:
        path = base / f"{reference}.md"
        text = path.read_text() if path.is_file() else ""
        record(path.is_file(), f"{path.relative_to(root)} exists")
        for heading in ["## Stop when", "## Never"]:
            record(heading in text, f"{path.relative_to(root)} includes {heading}")

for human_path in [
    root / "plugins/prism/skills/light/references/human.md",
    root / "plugins/prism/prefixed-skills/prism-light/references/human.md",
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
            "discusses how approval should work",
            "does not mistake approval discussion for approval",
        ),
        (
            "bd update <story> --set-labels prism,phase:design",
            "returns explicit design refinement to Design and clears approval",
        ),
        (
            "Preserve every existing child task",
            "preserves child state for design refinement",
        ),
        (
            "automatically runs Design and Breakdown",
            "documents automatic refinement cycle",
        ),
    ]:
        record(snippet in text, f"{relative} {contract}")

for base in [
    root / "plugins/prism/skills/light/references",
    root / "plugins/prism/prefixed-skills/prism-light/references",
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
        "bd update <story> --set-labels prism,phase:design",
        "Preserve every existing child task",
        "automatically runs Design and Breakdown",
        "PRISM_HUMAN_DECISION=REFINE_DESIGN",
    ]:
        record(snippet in text, f"{skill_path.relative_to(root)} documents lifecycle contract: {snippet}")

lifecycle_graph_paths = [
    root / "plugins/prism/skills/light/references/lifecycle.md",
    root / "plugins/prism/prefixed-skills/prism-light/references/lifecycle.md",
]
for path in lifecycle_graph_paths:
    text = path.read_text() if path.is_file() else ""
    record(
        'H -->|"approve"| A' in text,
        f"{path.relative_to(root)} diagrams Human approval to Apply",
    )
    record(
        'H -->|"request design refinement; clear approval"| D' in text,
        f"{path.relative_to(root)} diagrams Human design refinement to Design",
    )

for path in [
    root / "plugins/prism/skills/lifecycle/references/lifecycle.md",
    root / "plugins/prism/prefixed-skills/prism-lifecycle/references/lifecycle.md",
]:
    text = path.read_text() if path.is_file() else ""
    record('C -->|"approve"| W' in text, f"{path.relative_to(root)} diagrams approval to Apply")
    record(
        'C -->|"refine design"| E' in text,
        f"{path.relative_to(root)} diagrams design refinement",
    )
    record(
        'R -->|"repair, max 5"| W' in text,
        f"{path.relative_to(root)} diagrams the bounded review repair loop",
    )

direct_callee_command = "callee agent run prism/lifecycle"
for path in [
    root / "README.md",
    root / "docs/architecture-callee-lifecycle.md",
    root / "docs/architecture-spec.md",
]:
    text = path.read_text() if path.is_file() else ""
    record(
        direct_callee_command in text,
        f"{path.relative_to(root)} documents direct Callee binary execution",
    )

for snippet in [
    "$prism-callee:lifecycle",
    "/prism-callee:lifecycle",
    "/prism-callee-lifecycle",
]:
    record(
        snippet in readme_text,
        f"README preserves Callee skill entrypoint: {snippet}",
    )
    architecture_spec_text = (root / "docs/architecture-spec.md").read_text()
    record(
        snippet in architecture_spec_text,
        f"architecture spec preserves Callee skill entrypoint: {snippet}",
    )

callee_contracts = {
    "pack/callee/prism/lifecycle.md": [
        "### Design summary",
        "### Task summary",
        "### Approval request",
    ],
    "pack/callee/prism/phases/human.md": ["prism/human/intent", "approval_intent"],
    "pack/callee/prism/human/intent.md": [
        "mode: deny",
        "Output exactly `APPROVE`",
        "Output exactly `REFINE_DESIGN`",
        "Output exactly `WITHHOLD`",
    ],
    "pack/callee/prism/human/check.md": [
        "APPROVAL_INTENT",
        "REFINE_DESIGN)",
        "PRISM_HUMAN_DECISION=REFINE_DESIGN",
        "exit 2",
    ],
}
for relative_path, snippets in callee_contracts.items():
    path = root / relative_path
    text = path.read_text() if path.is_file() else ""
    record(path.is_file(), f"{relative_path} exists")
    for snippet in snippets:
        record(snippet in text, f"{relative_path} contains contract marker: {snippet}")

human_check_path = root / "pack/callee/prism/human/check.md"
human_check_text = human_check_path.read_text()
human_check_parts = human_check_text.split("---", 2)
record(
    len(human_check_parts) == 3,
    "human decision check has executable script body",
)
if len(human_check_parts) == 3:
    human_check_body = human_check_parts[2].lstrip()
    decision_cases = [
        ("APPROVE", 0, "APPROVE", ""),
        (
            "REFINE_DESIGN",
            2,
            "",
            "PRISM_HUMAN_DECISION=REFINE_DESIGN",
        ),
        ("WITHHOLD", 1, "", "withheld approval: WITHHOLD"),
    ]
    for decision, expected_code, stdout_marker, stderr_marker in decision_cases:
        env = os.environ.copy()
        env["APPROVAL_INTENT"] = decision
        result = subprocess.run(
            ["sh"],
            input=human_check_body,
            text=True,
            capture_output=True,
            cwd=root,
            env=env,
            check=False,
        )
        record(
            result.returncode == expected_code,
            f"human decision check returns {expected_code} for {decision}",
        )
        if stdout_marker:
            record(
                stdout_marker in result.stdout,
                f"human decision check emits stdout marker for {decision}",
            )
        if stderr_marker:
            record(
                stderr_marker in result.stderr,
                f"human decision check emits stderr marker for {decision}",
            )

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
