---
name: prism-lifecycle
description: >
  Run the Prism story lifecycle directly in the host. Beads stores story state,
  and exactly one phase:* label is the current lifecycle phase. Use when the user runs
  $prism:lifecycle, /prism:lifecycle, /prism-lifecycle, /prism, asks to run or
  advance Prism, uses the prism label, or asks to continue a Prism story.
---

# Prism lifecycle

| Layer | Owns |
| --- | --- |
| **Beads** | Story description, acceptance, design, child tasks, status, assignee, labels, comments |
| **This skill** | Label-driven phase machine, repository work, and `bd` writes |
| **Prism Callee workflow** | Specialized `prism/*` subagents with phase-specific roles and settings; owns all `callee agent run prism/...` execution |

**Invoke:** Codex `$prism:lifecycle`, Claude Code `/prism:lifecycle`, or flat slash `/prism-lifecycle`.

Lifecycle diagram: [references/lifecycle.md](references/lifecycle.md). Keep lifecycle diagrams vertical with Mermaid `flowchart TB`.

## Durable lifecycle state

Exactly one story label is the only source of its active lifecycle phase:

| Phase | Story label |
| --- | --- |
| Specify | `phase:specify` |
| Design | `phase:design` |
| Breakdown | `phase:breakdown` |
| Human gate | `phase:human` |
| Apply | `phase:apply` |
| Verify | `phase:verify` |

`prism` marks lifecycle membership. `human:approved` is the only authorization
for apply. Every open lifecycle story must have exactly one supported `phase:*`
label. Story assignees do not encode lifecycle phase state.

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
   - if the user explicitly names a story ID, load that story;
   - otherwise, list open Prism stories with `bd list -l prism --status=open` and resume it only when exactly one open Prism story exists;
   - otherwise, derive a concise title from the user's request and create a new story:

     ```bash
     bd create "<derived title>" --type=story -l prism,phase:specify \
       --description="<raw user request>" --priority=2 --silent
     ```

     Start the new story in Specify; that phase normalizes acceptance criteria.
3. Load `bd show <story> --long` and `bd children <story>`.
4. Derive the current phase from exactly one supported `phase:*` story label;
   stop on a missing or conflicting phase label. Do not fall back to assignee
   state: existing assignee-driven stories are intentionally unsupported.
   Reconcile the phase with description, acceptance, design,
   `human:approved`, and child task state.
5. Enter the lifecycle advance loop: load exactly one matching phase reference
   and run that phase directly in the host.
6. Persist the result to Beads, then re-check the story and children. After a
   successful Specify, Design, or Breakdown transition, immediately load the
   newly selected phase reference and continue in the same invocation. Do not
   ask the human to confirm those phase transitions.
7. Stop the advance loop only when the current reference requires missing or
   blocking human input, lifecycle state is invalid, or the story reaches the
   Human gate.

## Hard rules

1. Do **not** invoke `callee agent run prism/...`; that belongs only to the Prism Callee workflow.
2. Beads is the only durable lifecycle store. Phase instructions are bundled guidance, not runtime artifacts.
3. Do not implement without `human:approved`.
4. The human owns approval intent. The host may persist `human:approved` only
   after an unambiguous free-form authorization to start implementation.
5. `--set-labels` replaces all labels: retain `prism`, write exactly one target
   `phase:*` label, and after the gate retain `human:approved`.
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
| `phase:verify` or (`human:approved` and no open children) | Verify; close only on pass |
| `phase:apply` + `human:approved` + open children | Continue the story-level apply loop |
| Open children without `human:approved` or `phase:human` | Stop at the human gate |
| `phase:breakdown` or (design set and no children) | Breakdown → create child graph |
| `phase:design` or (requirements set and design empty) | Design → persist design markdown |
| `phase:specify` | Specify → persist description and acceptance |

## Phase execution contract

The phase references own phase-local procedure. Within one lifecycle
invocation, repeat:

1. infer the phase from exactly one supported `phase:*` story label
2. load exactly one matching reference
3. follow its inputs, procedure, persistence, and stop conditions
4. re-check Beads state
5. continue immediately after successful Specify, Design, or Breakdown
   persistence; never pause for phase-transition confirmation
6. stop at the Human gate or another explicit stop condition

| Phase | Load | Successful outcome |
| --- | --- | --- |
| Specify | [references/specify.md](references/specify.md) | story label is `phase:design` |
| Design | [references/design.md](references/design.md) | concrete design exists; story label is `phase:breakdown` |
| Breakdown | [references/breakdown.md](references/breakdown.md) | child graph covers the design; story label is `phase:human` |
| Human | [references/human.md](references/human.md) | approval moves to `phase:apply`; explicit design refinement moves to `phase:design`; otherwise stop |
| Apply | [references/apply.md](references/apply.md) | one ready child closes, story enters verify, or apply stops blocked |
| Verify | [references/verify.md](references/verify.md) | story closes on pass; otherwise it bounces to an earlier phase label |

## Safety

- Do not invent `human:approved` or close a story with open children.
- Callee roles are internal executors; lifecycle state is encoded only by the
  story's single `phase:*` label.
- Do not close a story after verify unless verification passes with no follow-up work.
- Prefer `bd --json` when parsing; never `bd edit`.
- Generic tracker work belongs to the **beads** skill.
