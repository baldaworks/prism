# Prism Callee Lifecycle Architecture

This document defines the automated lifecycle only. It covers
`$prism-callee:lifecycle`, `/prism-callee:lifecycle`, the PromptKit mapping
that feeds Prism Roles and workflows, and the `pack/callee/prism/` execution
surface.

It does not define the manual host lifecycle contract.

## Purpose

The automated lifecycle advances the same Beads-backed story state as the manual
host lifecycle, but it does so by running `prism/*` Callee assets instead of
performing the work directly in the host.

## Invocation surface

| Surface | Entry point |
| --- | --- |
| Codex host skill | `$prism-callee:lifecycle` |
| Claude Code host skill | `/prism-callee:lifecycle` |
| Flat host skill | `/prism-callee-lifecycle` |
| Public Callee lifecycle graph | `prism/lifecycle` |
| Public phase entrypoints | `prism/phases/*` |

Internal implementation stays behind:

- `prism/roles/*`
- `prism/<phase>/*`

## PromptKit contract

`plugins/prism-callee/skills/lifecycle/references/promptkit.md` is a required
instruction source for this surface. It maps Prism lifecycle responsibilities to
PromptKit-backed Role and workflow generation.

That reference belongs only to the automated lifecycle. The manual host skill
must not depend on it.

## Shared Beads state

The automated lifecycle reuses the same story labels and fields as the manual
host lifecycle:

- `prism`
- `phase:specify`
- `phase:design`
- `phase:plan`
- `phase:human`
- `phase:apply`
- `phase:verify`
- `human:approved`

The Beads phase model is shared. The execution contract is not.

## Execution model

The automated Prism host entrypoints (`$prism-callee:lifecycle`,
`/prism-callee:lifecycle`, and `/prism-callee-lifecycle`) are the only user
surfaces that may execute:

- `callee agent run prism/lifecycle`
- `callee agent run prism/phases/*`
- `callee agent run prism/roles/*`
- `callee agent run prism/<phase>/*`

The automated lifecycle must:

- inspect current Beads state
- choose the next public phase
- run the matching Callee asset
- collect clarification during `phase:specify` through a Callee Human step when
  the specify loop still lacks design-ready requirements
- collect approval at `phase:human` through a Callee Human agent
- persist outputs back into Beads
- stop only when approval is withheld or another blocking condition is reached

## Public vs internal surfaces

| Layer | Contract |
| --- | --- |
| `$prism-callee:lifecycle` / `/prism-callee:lifecycle` / `/prism-callee-lifecycle` | user-facing automation entrypoint |
| `prism/lifecycle` | canonical automated lifecycle graph |
| `prism/phases/*` | public phase-level automation entrypoints |
| `prism/roles/*` | internal role building blocks |
| `prism/<phase>/*` | internal phase-local executors |

Docs should describe `prism/lifecycle` and `prism/phases/*` as public. Direct
references to `prism/roles/*` and `prism/<phase>/*` should be framed as
implementation details unless the change is specifically about maintainers.

## Hard rules

- Do not describe PromptKit as part of the manual host lifecycle.
- Do not move automated execution rules into the host phase references.
- Do not expose internal `prism/<phase>/*` as the primary user-facing surface
  when `prism/lifecycle` or `prism/phases/*` already owns that behavior.
- Do not bypass `human:approved` before apply.

## File boundaries

| Concern | Files |
| --- | --- |
| Automated host skill | `plugins/prism-callee/skills/lifecycle/` |
| Flat-name automated host skill | `plugins/prism-callee/prefixed-skills/prism-callee-lifecycle/` |
| PromptKit mapping | `plugins/prism-callee/skills/lifecycle/references/promptkit.md` |
| Reusable Callee assets | `pack/callee/prism/` |
| Optional local mirror | `.callee/prism/` when present |

`pack/callee/prism/` remains authoritative. `.callee/prism/` is only a local
discovery mirror.

## Validation

After changing automation semantics, validate:

```sh
./scripts/validate-lifecycle-ownership.sh
./scripts/validate-plugin-packaging.sh
```

Then verify the automation surface definitions still line up:

- `plugins/prism-callee/skills/lifecycle/SKILL.md`
- `plugins/prism-callee/skills/lifecycle/references/promptkit.md`
- `pack/callee/prism/`
