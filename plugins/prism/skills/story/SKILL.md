---
name: story
description: >
  Run the full Prism story lifecycle directly in the host with Beads-backed
  phase state and role-aligned Specify, Design, Breakdown, Human, Apply, and
  Verify contracts. Use when the user runs $prism:story, /prism:story,
  /prism-story, explicitly targets a Prism story, or asks to continue one story.
---

# Prism story lifecycle

Run one full role-aligned Prism story lifecycle in the current host. Do not
invoke Callee. Use `$prism:light`, `/prism:light`, or `/prism-light` only when
the user explicitly requests the concise workflow.

| Layer | Owns |
| --- | --- |
| **Beads** | Story description, acceptance, design, child tasks, status, assignee, labels, comments |
| **This skill** | Host execution of the full phase/role contract plus all `bd` writes |
| **Prism Callee pack** | Read-only behavioral source from which the bundled story contracts are projected |
| **Prism Callee skill** | Actual `callee agent run prism/...` execution |

**Invoke:** Codex `$prism:story`, Claude Code `/prism:story`, or flat slash `/prism-story`.

Lifecycle graph: [references/lifecycle.md](references/lifecycle.md). Keep lifecycle
diagrams vertical with Mermaid `flowchart TB`.

## Durable lifecycle state

Exactly one supported story label is the active phase:

| Phase | Story label | Host role sequence |
| --- | --- | --- |
| Specify | `phase:story:specify` | interviewer → readiness gate → Human clarification → extract |
| Design | `phase:story:design` | explorer → architect |
| Breakdown | `phase:story:breakdown` | implementation planner → Beads normalizer |
| Human | `phase:story:human` | approval prompt → intent classifier → decision check |
| Apply | `phase:story:apply` | implementer → independent reviewer, repeat as needed |
| Verify | `phase:story:verify` | story reviewer → close or phase-specific bounce |

`prism` marks membership. `human:approved` is the only authorization for Apply.
Story assignees never encode lifecycle phases. Within Apply, child-task assignees
move from `prism/apply/implementer` to `prism/apply/reviewer`.

Supported global phase labels are the `phase:story:*` set above and the sibling
Epic skill's `phase:epic:*` set. Ignore any other phase-like label as absent; do
not migrate it. An Epic phase on a story is type-invalid and fails closed. When
no supported global phase exists, initialize the story with
`prism,phase:story:specify` and remove stale authorization.

## Phase references

Load exactly one phase-local instruction:

- Specify: [references/specify.md](references/specify.md)
- Design: [references/design.md](references/design.md)
- Breakdown: [references/breakdown.md](references/breakdown.md)
- Human: [references/human.md](references/human.md)
- Apply: [references/apply.md](references/apply.md)
- Verify: [references/verify.md](references/verify.md)

Each reference contains a compact contract projection. Execute its logical roles
in order even though one host session performs them. Do not weaken required
outputs or skip a gate because Callee is not running.

## Output boundary

Normal host Story output — target resolution, phase progress, status, errors,
blockers, and normal phase results — MUST NOT emit a standalone ### Acceptance criteria heading,
including a bullet-wrapped form such as `- ### Acceptance criteria`, or an unsolicited user-facing
approval-format acceptance block.

This boundary applies only to user-facing Markdown output. It does not prohibit
internal or machine-readable acceptance artifacts such as requirements
documents, the Beads acceptance field, or `ACCEPTANCE_CRITERIA:` sections in a
normal phase result. The informed Human approval request remains the exception
and MUST present the complete current-Story acceptance first. An explicit
operator request for acceptance criteria is also allowed.

## Prerequisites

1. `bd` is available and the repository has a Beads workspace.
2. The repository and its native verification tools are inspectable.
3. Callee is not required. To execute actual Callee agents, use
   `$prism-callee:lifecycle`, `/prism-callee:lifecycle`, or `/prism-callee-lifecycle`.

## Entry

1. Resolve Beads with `bd where`; follow the Beads skill or `bd prime` when needed.
2. Resolve the target story:
   - use an explicitly named story ID and require `issue_type=story`;
   - otherwise resume exactly one open Prism story;
   - otherwise create one from the raw user request:

     ```bash
     bd create "<derived title>" --type=story -l prism,phase:story:specify \
       --description="<raw user request>" --priority=2 --silent
     ```

3. Load `bd show <story> --long` and `bd children <story>`.
4. Classify phase-like labels against both supported namespaces:
   - ignore labels outside both supported namespaces;
   - fail closed on any `phase:epic:*` label or multiple `phase:story:*` labels;
   - when no supported phase remains, write `prism,phase:story:specify` and
     clear `human:approved` through replacement;
   - otherwise use the single `phase:story:*` label.
5. Load the matching phase reference and execute its full contract.
6. Persist its result, re-read story and children, then continue immediately
   after successful Specify or Design. After Breakdown, enter Human and present
   the informed approval request in the same invocation.
7. Stop only for Human authorization/refinement, genuinely missing input,
   invalid state, exhausted role loop, or failed required verification.

## Hard rules

1. Never invoke `callee agent run prism/...`; this is host execution.
2. Never edit, regenerate, format, rename, or relocate `pack/callee/**`.
3. Preserve the ordered role passes and required outputs in each phase reference.
4. Beads is the only durable lifecycle store.
5. Do not implement without `human:approved`.
6. Persist approval only after unambiguous human authorization.
7. `--set-labels` replaces all labels: retain `prism`, exactly one story phase,
   and `human:approved` after the gate.
8. Ask only for genuinely missing product intent, never for routine phase confirmation.
9. Apply exactly one ready child at a time. Review the actual diff and checks
   independently of the implementation narrative.
10. Do not close a task when checks or review fail.
11. Verify is close-or-bounce and never repairs implementation.
12. Do not commit or push without the authority provided by the repository and user.

## Phase selection

| Condition, in priority order | Action |
| --- | --- |
| Missing usable requirements or acceptance | Specify |
| `phase:story:verify`, or approved with no open children | Verify |
| `phase:story:apply` with approval and open children | Apply |
| Open children without approval, or `phase:story:human` | Human |
| `phase:story:breakdown`, or design exists without children | Breakdown |
| `phase:story:design`, or requirements exist without design | Design |
| `phase:story:specify` | Specify |

## Advance loop

Within one invocation:

1. derive the phase from the single supported story label;
2. load one matching reference;
3. execute every logical role and gate in that reference;
4. persist and re-read Beads;
5. continue through successful pre-approval phases;
6. stop at explicit reference stop conditions.

## Safety

- Never invent requirements, approval, repository evidence, review findings, or test results.
- Treat the Callee pack as a read-only source during lifecycle execution.
- Preserve existing child state during design/breakdown reconciliation.
- Close a story only after every child is closed and Verify passes.
