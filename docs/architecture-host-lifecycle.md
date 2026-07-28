# Prism Host Lifecycle Architecture

This document defines the manual host lifecycle only. It covers
`$prism:lifecycle`, `/prism:lifecycle`, and `/prism-lifecycle`. It does not
define `prism-callee` automation or any `callee agent run prism/...` behavior.

## Purpose

The host lifecycle advances one Prism story through the Beads phase machine by
doing the work directly in the host session:

- inspect repository state
- ask for clarification when requirements are incomplete
- author design markdown
- decompose into child tasks
- implement and review child tasks
- verify the story before close

## Invocation surface

| Host shape | Entry point |
| --- | --- |
| Codex | `$prism:lifecycle` |
| Claude Code | `/prism:lifecycle` |
| Flat slash | `/prism-lifecycle` |

The Codex, Claude Code, and flat-skill variants must stay semantically
identical. Only layout and invocation syntax may differ.

## Durable state

Beads is the only durable lifecycle store.

The host skill owns:

- inferring the current phase from Beads state
- performing one lifecycle phase directly in the host
- persisting the result back into Beads

The host skill does not own:

- generating or running `prism/*` Callee Roles/workflows
- PromptKit role mapping
- Callee pack installation

## Phase contract

The host lifecycle uses these public story phases:

- `phase:specify`
- `phase:design`
- `phase:plan`
- `phase:human`
- `phase:apply`
- `phase:verify`

The `human:approved` label is the only authorization to enter apply.

## Phase execution model

Before running a phase, the skill must load the matching phase reference from
`plugins/prism/skills/lifecycle/references/` or the prefixed mirror:

- `specify.md`
- `design.md`
- `plan.md`
- `human.md`
- `apply.md`
- `verify.md`

Those files are the phase-level operating instructions. The lifecycle skill
chooses which one to load based on current Beads state, not just on what the
user typed in chat.

## Authority boundaries

| Actor | Allowed actions |
| --- | --- |
| Human | sets `human:approved`, changes requirements, grants commit/push authority |
| Host lifecycle skill | repository inspection, host-authored phase work, Beads writes, local checks |
| Beads | durable state for stories, design, child tasks, labels, assignees |

## Hard rules

- Do not invoke `callee agent run prism/...` from the host lifecycle skill.
- Do not use PromptKit references as host-phase instructions.
- Do not skip the per-phase reference load.
- Do not implement without `human:approved`.
- Do not close a story while child tasks remain open.
- Do not treat global `bd ready` as enough to claim a task; the task must belong
  to the current story and be ready/unblocked.

## File boundaries

| Concern | Files |
| --- | --- |
| Manual host lifecycle skill | `plugins/prism/skills/lifecycle/` |
| Flat-name variant with identical behavior | `plugins/prism/prefixed-skills/prism-lifecycle/` |
| Shared host lifecycle graph | `plugins/prism/skills/lifecycle/references/lifecycle.md` |
| Phase-specific host instructions | `plugins/prism/skills/lifecycle/references/*.md` and prefixed mirror |

## Out of scope

The following belong to the automated lifecycle, not this document:

- `plugins/prism-callee/skills/lifecycle/SKILL.md`
- `plugins/prism-callee/skills/lifecycle/references/promptkit.md`
- `pack/callee/prism/`

If a change needs those files, it is not a host-only lifecycle change anymore.

## Validation

After changing host lifecycle semantics, validate with:

```sh
./scripts/validate-lifecycle-ownership.sh
```

Then re-read:

- `plugins/prism/skills/lifecycle/SKILL.md`
- `plugins/prism/prefixed-skills/prism-lifecycle/SKILL.md`
- the affected phase reference(s)

The two host variants must still describe the same behavior.
