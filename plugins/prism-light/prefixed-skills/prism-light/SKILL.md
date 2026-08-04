---
name: prism-light
description: >
  Run the simplified Prism Light story lifecycle directly in the host. Beads stores story state,
  and exactly one supported phase:story:* label is the current lifecycle phase. Use when the user runs
  $prism-light:lifecycle, /prism-light:lifecycle, /prism-light, asks for Prism Light, or explicitly
  requests the concise host-only lifecycle instead of the full role-aligned workflow.
---

# Prism Light lifecycle

| Layer | Owns |
| --- | --- |
| **Beads** | Story description, acceptance, design, child tasks, status, assignee, labels, comments |
| **This skill** | Label-driven phase machine, repository work, and `bd` writes |
| **Prism Callee workflow** | Specialized `prism/*` subagents with phase-specific roles and settings; owns all `callee agent run prism/...` execution |

**Invoke:** Codex `$prism-light:lifecycle`, Claude Code `/prism-light:lifecycle`, or flat slash `/prism-light`.

Lifecycle diagram: [references/lifecycle.md](references/lifecycle.md). Keep lifecycle diagrams vertical with Mermaid `flowchart TB`.

## Durable lifecycle state

Exactly one supported story label is the only source of its active lifecycle phase:

| Phase | Story label |
| --- | --- |
| Specify | `phase:story:specify` |
| Design | `phase:story:design` |
| Breakdown | `phase:story:breakdown` |
| Human gate | `phase:story:human` |
| Apply | `phase:story:apply` |
| Verify | `phase:story:verify` |

`prism` marks lifecycle membership. `human:approved` is the only authorization
for apply. Story assignees do not encode lifecycle phase state. Ignore phase-like
labels outside the supported Story and Epic namespaces as absent and never
migrate them. An Epic phase on a story is type-invalid. When no supported global
phase exists, initialize `phase:story:specify` without approval.

Within the story-level apply phase, child-task assignees record the inner loop:
`prism/apply/implementer` then `prism/apply/reviewer`.

Phase references:

- Specify: [references/specify.md](references/specify.md)
- Design: [references/design.md](references/design.md)
- Breakdown: [references/breakdown.md](references/breakdown.md)
- Human gate: [references/human.md](references/human.md)
- Apply: [references/apply.md](references/apply.md)
- Verify: [references/verify.md](references/verify.md)

## Prerequisites

1. **[`bd` (Beads)](https://github.com/gastownhall/beads)** is available and the target project has a Beads workspace (`bd where` / `bd prime`).
2. The repository is inspectable in the host session.
3. To run the lifecycle through specialized `prism/*` subagents, use the Prism Callee workflow instead.

## Entry

1. Resolve Beads context with `bd where`; if missing or stale, follow the **beads** skill / `bd prime`.
2. Resolve the target story:
   - if the user explicitly names a story ID, load it and require `issue_type=story`;
   - otherwise, list open Prism stories with `bd list -l prism --status=open --type=story --limit 0` and resume only when exactly one exists;
   - otherwise, derive a concise title from the user's request and create a new story:

     ```bash
     bd create "<derived title>" --type=story -l prism,phase:story:specify \
       --description="<raw user request>" --priority=2 --silent
     ```

     Start the new story in Specify; that phase normalizes acceptance criteria.
3. Load `bd show <story> --long` and `bd children <story>`.
4. Classify phase-like labels against both supported namespaces. Ignore labels
   outside both namespaces. Fail closed on an Epic phase or multiple Story
   phases. When no supported phase remains, replace labels with
   `prism,phase:story:specify`, which also clears stale authorization. Otherwise
   use the single Story phase. Do not fall back to assignee state. Reconcile the
   phase with description, acceptance, design, `human:approved`, and child state.
5. Enter the lifecycle advance loop: load exactly one matching phase reference
   and run that phase directly in the host.
6. Persist the result to Beads, then re-check the story and children. After
   successful Specify or Design persistence, immediately load the newly
   selected phase reference. After successful Breakdown persistence,
   immediately load the Human reference and present its informed approval
   request. Do not ask the human to confirm any phase transition.
7. Stop the advance loop only when the Human reference is awaiting the
   authorization or refinement decision, another reference requires missing or
   blocking human input, or lifecycle state is invalid. Merely writing
   `phase:story:human` is not a stop condition.

## Hard rules

1. Do **not** invoke `callee agent run prism/...`; that belongs only to the Prism Callee workflow.
2. Beads is the only durable lifecycle store. Phase instructions are bundled guidance, not runtime artifacts.
3. Do not implement without `human:approved`.
4. The human owns approval intent. The host may persist `human:approved` only
   after an unambiguous free-form authorization to start implementation.
5. `--set-labels` replaces all labels: retain `prism`, write exactly one target
   `phase:story:*` label, and after the gate retain `human:approved`.
6. Do not commit or push without explicit user authority.
7. Ask directly when requirements are incomplete; never invent missing requirements.
   Do not ask for confirmation merely to advance between successful
   pre-approval phases.
8. After changed code, inspect project tooling and run the relevant repository-native checks. Do not close a task if required checks fail.
9. Claim only a ready, unblocked child of the current story; never claim from global `bd ready` alone.
10. A story enters verify only when it has `human:approved` and no open child tasks.
11. Apply is story-level operational closure; verify is a close-or-bounce decision phase, never a repair loop.

## Phase → action

| Condition (priority order) | Do next |
| --- | --- |
| Missing usable description or acceptance | Specify → persist requirements |
| `phase:story:verify` or (`human:approved` and no open children) | Verify; close only on pass |
| `phase:story:apply` + `human:approved` + open children | Continue the story-level apply loop |
| Open children without `human:approved` or `phase:story:human` | Stop at the human gate |
| `phase:story:breakdown` or (design set and no children) | Breakdown → create child graph |
| `phase:story:design` or (requirements set and design empty) | Design → persist design markdown |
| `phase:story:specify` | Specify → persist description and acceptance |

## Safety

- Do not invent `human:approved` or close a story with open children.
- Callee roles are internal executors; lifecycle state is encoded only by the
  story's single supported `phase:story:*` label.
- Do not close a story after verify unless verification passes with no follow-up work.
- Prefer `bd --json` when parsing; never `bd edit`.
- Generic tracker work belongs to the **beads** skill.
