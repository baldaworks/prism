# Prism Host Lifecycle Architecture

This document defines only the manual host lifecycle: `$prism:lifecycle`,
`/prism:lifecycle`, and `/prism-lifecycle`. It does not define Callee
automation or allow `callee agent run prism/...`.

## Purpose

The host skill performs each phase directly and persists results in Beads:

- clarify requirements
- inspect the repository and write design markdown plus Prism Impact Lens
- break down design into Beads child tasks, including actionable mitigations
- implement and review child tasks
- verify before close

## Durable state

Beads is the only durable lifecycle store. A story's assignee is the active
phase:

| Assignee | Phase |
| --- | --- |
| `prism/specify` | Specify |
| `prism/design` | Design |
| `prism/breakdown` | Breakdown |
| `prism/human` | Human approval gate |
| `prism/apply` | Apply |
| `prism/verify` | Verify |

Use label `prism` to find lifecycle stories and `human:approved` to permit
apply. Do not create a `phase:*` label.

Child tasks remain inside the story-level apply phase: their assignee moves from
`prism/apply/implementer` to `prism/apply/reviewer`.

## Story resolution

Lifecycle accepts user intent, not a pre-created story. It resolves work in this
order: an explicitly named story ID; exactly one open Prism story; otherwise a
new `prism/specify` story. New stories retain the raw user request in their
description and let Specify normalize the acceptance criteria.

## Prism Impact Lens

Design stores an exact `## Prism Impact Lens` table with Product, Process,
People, Planet, and Prosperity rows. Ratings are `positive`, `negative`,
`mixed`, `not-material`, or `unknown`; every row needs evidence, and negative
or mixed rows need mitigation or an explicit residual-impact disposition.
`unknown` blocks Breakdown.

Any open legacy story without a complete lens returns to `prism/design`,
clears `human:approved`, and preserves every open or closed child. Breakdown
then reconciles the graph without automatic deletion or closure. Closed stories
are unchanged.

## Execution model

The host skill derives the phase from story assignee, then loads the matching
bundled instruction:

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
closed at `prism/human`.

Before asking, the host presents Design summary → Prism Impact Lens → Task
summary → Approval request. One unambiguous free-form approval covers the
design, task graph, mitigations, and disclosed residual impacts.

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
