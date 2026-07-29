---
name: prism-lifecycle
description: >
  Run the Prism story lifecycle directly in the host. Beads stores story state,
  and the story assignee is the current lifecycle phase. Use when the user runs
  /prism-lifecycle, /prism:lifecycle, $prism:lifecycle, /prism, asks to run or
  advance Prism, uses the prism label, or asks to continue a Prism story.
metadata:
  short-description: "Host-native Prism story lifecycle"
---

# Prism lifecycle

| Layer | Owns |
| --- | --- |
| **Beads** | Story description, acceptance, design, child tasks, status, assignee, labels, comments |
| **This skill** | Assignee-driven phase machine, repository work, and `bd` writes |
| **`/prism-callee-lifecycle`** | Separate automation surface that owns all `callee agent run prism/...` execution |

**Invoke:** `/prism-lifecycle` or `/prism:lifecycle`.

Lifecycle diagram: [references/lifecycle.md](references/lifecycle.md). Keep lifecycle diagrams vertical with Mermaid `flowchart TB`.

## Durable lifecycle state

The story assignee is the only source of its active lifecycle phase:

| Phase | Story assignee |
| --- | --- |
| Specify | `prism/specify` |
| Design | `prism/design` |
| Breakdown | `prism/breakdown` |
| Human gate | `prism/human` |
| Apply | `prism/apply` |
| Verify | `prism/verify` |

`prism` marks lifecycle membership. `human:approved` is the only authorization
for apply. Do not add `phase:*` labels.

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
3. For automated `prism/*` execution, use `/prism-callee-lifecycle` instead.

## Entry

1. Resolve Beads context with `bd where`; if missing or stale, follow the **beads** skill / `bd prime`.
2. Resolve the target story:
   - if the user explicitly names a story ID, load that story;
   - otherwise, list open Prism stories with `bd list -l prism --status=open` and resume it only when exactly one open Prism story exists;
   - otherwise, derive a concise title from the user's request and create a new story:

     ```bash
     bd create "<derived title>" --type=story -a prism/specify -l prism \
       --description="<raw user request>" --priority=2 --silent
     ```

     Start the new story in Specify; that phase normalizes acceptance criteria.
3. Load `bd show <story> --long` and `bd children <story>`.
4. Derive the current phase from the story assignee; reconcile it with description, acceptance, design, `human:approved`, and child task state.
5. Load exactly one matching phase reference and run that phase directly in the host.
6. Persist the result to Beads, then re-check the story and children before deciding whether another lifecycle run is needed.

## Hard rules

1. Do **not** invoke `callee agent run prism/...`; that belongs only to `/prism-callee-lifecycle`.
2. Beads is the only durable lifecycle store. Phase instructions are bundled guidance, not runtime artifacts.
3. Do not implement without `human:approved`.
4. The human owns approval intent. The host may persist `human:approved` only
   after an unambiguous free-form authorization to start implementation.
5. `--set-labels` replaces all labels: retain `prism`, and after the gate retain `human:approved`; never write `phase:*` labels.
6. Do not commit or push without explicit user authority.
7. Ask directly when requirements are incomplete; never invent missing requirements.
8. After changed code, run project checks (`task test` or `go test ./...`). Do not close a task if checks fail.
9. Claim only a ready, unblocked child of the current story; never claim from global `bd ready` alone.
10. A story enters verify only when it has `human:approved` and no open child tasks.
11. Apply is story-level operational closure; verify is a close-or-bounce decision phase, never a repair loop.

## Phase → action

| Condition (priority order) | Do next |
| --- | --- |
| `prism/verify` or (`human:approved` and no open children) | Verify; close only on pass |
| `prism/apply` + `human:approved` + open children | Continue the story-level apply loop |
| Open children without `human:approved` or `prism/human` | Stop at the human gate |
| `prism/breakdown` or (design set and no children) | Breakdown → create child graph |
| `prism/design` or (requirements set and design empty) | Design → persist design markdown |
| `prism/specify` or missing requirements | Specify → persist description and acceptance |

## Phase execution contract

The phase references own phase-local procedure. For every lifecycle run:

1. infer the phase from the story assignee
2. load exactly one matching reference
3. follow its inputs, procedure, persistence, and stop conditions
4. re-check Beads state before the next run

| Phase | Load | Successful outcome |
| --- | --- | --- |
| Specify | [references/specify.md](references/specify.md) | story assignee is `prism/design` |
| Design | [references/design.md](references/design.md) | story assignee is `prism/breakdown` |
| Breakdown | [references/breakdown.md](references/breakdown.md) | child graph exists; story assignee is `prism/human` |
| Human | [references/human.md](references/human.md) | stop until explicit approval moves the story to `prism/apply` |
| Apply | [references/apply.md](references/apply.md) | one ready child closes, story enters verify, or apply stops blocked |
| Verify | [references/verify.md](references/verify.md) | story closes on pass; otherwise it bounces to an earlier assignee |

## Safety

- Do not invent `human:approved` or close a story with open children.
- Callee roles are internal executors; lifecycle state is encoded only by story assignee.
- Do not close a story after verify unless verification passes with no follow-up work.
- Prefer `bd --json` when parsing; never `bd edit`.
- Generic tracker work belongs to the **beads** skill.
