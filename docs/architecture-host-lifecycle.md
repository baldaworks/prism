# Prism Host Lifecycle Architecture

This document defines only the manual host lifecycle: `$prism:lifecycle`,
`/prism:lifecycle`, and `/prism-lifecycle`. It does not define Callee
automation or allow `callee agent run prism/...`.

## Purpose

The host skill performs each phase directly and persists results in Beads:

- clarify requirements
- inspect the repository and write concrete design markdown
- break down design into Beads child tasks with dependencies and verification
- implement and review child tasks
- verify before close

## Durable state

Beads is the only durable lifecycle store. Exactly one story label is the
active phase:

| Label | Phase |
| --- | --- |
| `phase:specify` | Specify |
| `phase:design` | Design |
| `phase:breakdown` | Breakdown |
| `phase:human` | Human approval gate |
| `phase:apply` | Apply |
| `phase:verify` | Verify |

Use label `prism` to find lifecycle stories and `human:approved` to permit
apply. Story assignees do not encode lifecycle phases. Existing assignee-driven
stories are intentionally not migrated or supported.

Child tasks remain inside the story-level apply phase: their assignee moves from
`prism/apply/implementer` to `prism/apply/reviewer`.

## Story resolution

Lifecycle accepts user intent, not a pre-created story. It resolves work in this
order: an explicitly named story ID; exactly one open Prism story; otherwise a
new story labeled `prism,phase:specify`. New stories retain the raw user
request in their description and let Specify normalize the acceptance
criteria.

## Design and task coverage

Design records the proposed solution, relevant risks, constraints, tradeoffs,
and verification in ordinary prose. Prism does not require a fixed assessment
matrix or rating system.

Breakdown creates tasks that cover the actionable design. When a story already
has children, it preserves open and closed tasks plus dependencies, reuses
sufficient work, and creates only missing implementation or verification tasks.
It never automatically deletes, closes, or reopens existing children.

## Execution model

The host skill derives the phase from exactly one supported `phase:*` label,
then loads the matching bundled instruction:

- `specify.md`
- `design.md`
- `breakdown.md`
- `human.md`
- `apply.md`
- `verify.md`

These files are agent instructions, not runtime artifacts. Requirements,
design, task graph, status, labels, and assignees are written directly to Beads.

## Authority boundaries

| Actor | Allowed actions |
| --- | --- |
| Human | explicitly authorizes apply, changes requirements, grants commit/push authority |
| Host lifecycle skill | repository inspection, host work, Beads writes, local checks, and persisting unambiguous free-form approval as `human:approved` |
| Beads | durable story and child-task state |

The decision and persistence boundaries are distinct: the human supplies the
authorization intent, while the host records it in Beads. Questions,
conditional language, requests for changes, and other ambiguous responses fail
closed at `phase:human`.

Before asking, the host presents Design summary → Task summary → Approval
request. One unambiguous free-form approval covers the design and task graph.

## Hard rules

- Do not invoke `callee agent run prism/...` from the host lifecycle skill.
- Do not use PromptKit references as host phase instructions.
- Do not implement without `human:approved`.
- Do not persist `human:approved` without unambiguous human authorization.
- Do not close a story while child tasks remain open.
- Claim only a ready/unblocked child of the current story.
- Verify is close-or-bounce; it does not repair implementation.

## File boundaries

| Concern | Files |
| --- | --- |
| Manual host lifecycle skill | `plugins/prism/skills/lifecycle/` |
| Flat-name mirror | `plugins/prism/prefixed-skills/prism-lifecycle/` |
| Shared lifecycle graph | `plugins/prism/skills/lifecycle/references/lifecycle.md` |
| Phase instructions | `plugins/prism/skills/lifecycle/references/*.md` and prefixed mirror |

## Validation

```sh
./scripts/validate-lifecycle-ownership.sh
```
