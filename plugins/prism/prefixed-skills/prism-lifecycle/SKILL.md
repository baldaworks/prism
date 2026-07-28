---
name: prism-lifecycle
description: >
  Run the Prism story lifecycle directly in the host: Beads stores story,
  design, tasks, and progress while this skill performs specify, design, plan,
  apply, and verify in chat. Use when the user runs /prism-lifecycle,
  /prism:lifecycle, $prism:lifecycle, /prism, asks to run or advance Prism,
  uses labels prism or phase:specify|design|plan|human|apply|verify, or asks
  to continue from the current Beads phase state.
metadata:
  short-description: "Host-native Prism story lifecycle"
---

# Prism lifecycle

Minimal story lifecycle:

| Layer | Owns |
| --- | --- |
| **Beads** | Story description, acceptance, design, task children, status, comments, human approval tag `human:approved` |
| **This skill** | Phase machine, repository inspection, direct implementation/review work, `bd` writes |
| **`/prism-callee-lifecycle`** | Optional separate automation surface that owns all `callee agent run prism/...` execution |

Tagline: *Intent through a prism: story → design → tasks → apply → verify.*

**Invoke:** Codex `$prism:lifecycle`, Claude Code `/prism:lifecycle`, or flat slash `/prism-lifecycle`.

Lifecycle diagram: [references/lifecycle.md](references/lifecycle.md).
When documenting the lifecycle, preserve the **vertical** top-to-bottom phase flow; Mermaid diagrams use `flowchart TB`.

Phase references:

- Specify: [references/specify.md](references/specify.md)
- Design: [references/design.md](references/design.md)
- Plan: [references/plan.md](references/plan.md)
- Human gate: [references/human.md](references/human.md)
- Apply: [references/apply.md](references/apply.md)
- Verify: [references/verify.md](references/verify.md)

## Prerequisites (target project)

1. **[`bd` (Beads)](https://github.com/gastownhall/beads)** available; beads workspace in the project (`bd where` / `bd prime`). Prefer the project **beads** skill for tracker basics.
2. Repository context is inspectable from the current host session so the skill can reason about requirements, design, implementation, and verification directly.
3. If the user wants automated `prism/*` execution instead of host-native work, switch to `/prism-callee-lifecycle`.

## Entry

1. **Beads context:** `bd where`. If missing/stale, follow **beads** skill / `bd prime`.
2. Find work: `bd list -l prism --status=open` or `bd ready` (confirm story parent).
3. Load: `bd show <id> --long` and `bd children <id>`.
4. Infer the **current phase from Beads story state**, not from a requested subskill:
   prefer the highest `phase:*` label, but reconcile it with story artifacts,
   `human:approved`, open child tasks, and the current assignee.
5. Run **one** phase end-to-end directly in the host, then re-check labels/children.
6. Lifecycle graph: [references/lifecycle.md](references/lifecycle.md).
7. Before executing a phase, load exactly one matching phase reference from `references/`: `specify.md`, `design.md`, `plan.md`, `human.md`, `apply.md`, or `verify.md`.
8. Plan task graph contract: [references/breakdown.md](references/breakdown.md).

## Hard rules

1. Do **not** invoke `callee agent run prism/...` from this skill. Automated `prism/*` execution belongs only to `/prism-callee-lifecycle`.
2. **Beads** is the durable store for requirements, design, tasks, and progress.
3. **Human gate:** do not implement apply work without story label `human:approved` (human-only).
4. **Apply is story-level operational closure, not a single-task semantic.**
5. After every substantive phase step, persist with `bd`, then re-check with `bd show`, `bd children`, and `bd ready` as needed.
6. **`--set-labels` replaces all labels** — always re-include `prism` and, after gate, `human:approved`.
7. **No commit/push** without explicit user authority.
8. Ask clarifying questions directly in chat when requirements are incomplete; do not invent missing requirements.
9. After apply that changed code: run project checks (`task test` or `go test ./...`). Do not close the task if checks fail.
10. A story is ready for verify when it is `human:approved` and has **no open child tasks**; there is no separate `apply done` marker.
11. During apply, choose a task from `bd children <story>` and confirm it is ready/unblocked before claiming it; never claim from global `bd ready` alone.
12. Treat host Prism as **lifecycle-only**: if the user names a phase, use that as intent, but still start from the story's current Beads phase state and advance from there.

## Current phase source

Derive the active lifecycle phase from Beads state in this order:

1. `bd show <story> --long`
2. `bd children <story>`
3. current labels, preferring the highest `phase:*`
4. presence or absence of `human:approved`
5. whether child tasks are open, closed, ready, or blocked
6. current assignee as a consistency signal, not the sole source of truth

If labels and artifacts disagree, trust durable Beads state over the user's wording in chat.

## Phase → action

| Condition (priority order) | Do next |
| --- | --- |
| `phase:verify` or (`human:approved` and no open children) | Verify; close only if verification passes |
| `phase:apply` + `human:approved` + open child tasks | Advance apply as story-level operational closure |
| Open child tasks exist and **no** `human:approved` | **Stop** — ask human for `human:approved` |
| `phase:human` | **Stop** — ask human for `human:approved` |
| `phase:plan` or (design set and no children) | Plan → create children |
| `phase:design` or (description/acceptance set and design empty) | Design → `--design` |
| `phase:specify` or missing description/acceptance | Intake / specify |

## Labels

| Label | Meaning |
| --- | --- |
| `prism` | In this lifecycle |
| `phase:specify` … `phase:verify` | Phase cache |
| `human:approved` | Human allowed implement |

## Host actions

| Phase | Invoke |
| --- | --- |
| Specify | Clarify requirements directly in chat, then update the story description and acceptance |
| Design | Inspect the repository and author design markdown directly in the host |
| Plan | Decompose the story into 3–12 Beads child tasks and dependencies |
| Apply | Close remaining story work one ready child at a time through the implementer/reviewer subloop |
| Verify | Run the close-or-bounce decision phase against description, acceptance, and design |

## Phase execution contract

The phase references, not this file, own the phase-local procedure.

For every lifecycle run:

1. infer the current phase from Beads state
2. load exactly one matching phase reference
3. follow that reference's inputs, procedure, persistence, and stop conditions
4. re-check Beads state before deciding whether another lifecycle run is needed

Use this routing table:

| Phase | Load | Successful outcome |
| --- | --- | --- |
| Specify | [references/specify.md](references/specify.md) | story is ready for `phase:design` |
| Design | [references/design.md](references/design.md) | durable design exists and story is ready for `phase:plan` |
| Plan | [references/plan.md](references/plan.md) | child task graph exists and story is ready for `phase:human` |
| Human | [references/human.md](references/human.md) | stop until a human adds `human:approved` and moves the story to `phase:apply` |
| Apply | [references/apply.md](references/apply.md) | one ready child is closed, or the story advances to `phase:verify`, or apply stops blocked |
| Verify | [references/verify.md](references/verify.md) | story closes on pass, otherwise bounces back for follow-up work |

If a phase reference says to stop, stop. Do not continue into another phase from this file by improvising.

## Discover

```bash
bd list -l prism --status=open
bd ready
bd show <id> --long
bd children <id>
```

## Safety

- Do not invent `human:approved` or close a story with open children.
- Beads assignee is the current phase owner: `prism/interviewer`, `prism/designer`, `prism/planner`, `human`, `prism/implementer`, `prism/reviewer`.
- Apply is story-level operational closure through the one-task implementer/reviewer subloop.
- Verify is a close-or-bounce decision phase, not an implementation repair loop.
- Do not close a story after verify unless the verify result is a pass with no follow-up work.
- Prefer `bd --json` when parsing; never `bd edit`.
- The phase references are the only host-owned source of truth for per-phase procedure.
- Generic beads work: **beads** skill. Use `/prism-callee-lifecycle` when the user explicitly wants `prism/*` automation.
