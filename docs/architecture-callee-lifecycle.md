# Prism Callee Lifecycle Architecture

This document defines automated Prism only: `$prism-callee:lifecycle`,
`/prism-callee:lifecycle`, and `/prism-callee-lifecycle`. It advances the
same Beads-backed story state as the manual host lifecycle through public
`prism/lifecycle` and `prism/phases/*` Callee workflows.

## Public surface

| Host entrypoint | Callee surface |
| --- | --- |
| `$prism-callee:lifecycle` | Codex automation entrypoint |
| `/prism-callee:lifecycle` | Claude Code automation entrypoint |
| `/prism-callee-lifecycle` | Flat-name automation entrypoint |
| `prism/lifecycle` | Canonical Sequential graph |
| `prism/phases/*` | Public phase entrypoints |

Internal roles and workflows remain under `prism/roles/*` and
`prism/<phase>/*`.

## Durable state

The story assignee is the lifecycle phase. The automation must use:

| Assignee | Public workflow |
| --- | --- |
| `prism/specify` | `prism/phases/specify` |
| `prism/design` | `prism/phases/design` |
| `prism/breakdown` | `prism/phases/breakdown` |
| `prism/human` | `prism/phases/human` |
| `prism/apply` | `prism/phases/apply` |
| `prism/verify` | `prism/phases/verify` |

`prism` is membership and `human:approved` permits apply. No phase labels
are written. Child tasks use `prism/apply/implementer` and
`prism/apply/reviewer` inside story-level apply.

## Story resolution

Automation accepts user intent, not a pre-created story. It uses an explicitly
named story ID when present, otherwise resumes exactly one open Prism story. If
neither applies, it creates a new `prism/specify` story from the raw request;
Specify then normalizes the acceptance criteria.

## Prism Impact Lens and approval

The automated surface enforces the same five-dimension design contract and
legacy migration as the host lifecycle: incomplete open stories return to
Design, approval is cleared, children are preserved, and Breakdown reconciles
mitigation coverage.

At `prism/phases/human`, the host prepares Design summary → Prism Impact Lens →
Task summary → Approval request from current Beads state. The Human agent
accepts ordinary language; `prism/human/intent` classifies it without tools and
fails closed, and the deterministic check accepts only exact `APPROVE`.

## Rules

- Only this automated surface may execute `callee agent run prism/...`.
- Persist every Callee result to Beads, then re-read story and child state.
- Collect clarification in specify through the Callee Human step when needed.
- Collect free-form human approval through `prism/phases/human`; fail closed until intent is unambiguous.
- Use `prism/phases/apply` for the outer story loop and
  `prism/apply/loop` for one child task.
- Verify closes or bounces; it never repairs code.
- Use `plugins/prism-callee/skills/lifecycle/references/promptkit.md` only for
  automated role/workflow mapping, never for manual host phase instructions.

## Ownership

| Concern | Location |
| --- | --- |
| Automated host skill | `plugins/prism-callee/skills/lifecycle/` |
| Flat-name automated skill | `plugins/prism-callee/prefixed-skills/prism-callee-lifecycle/` |
| PromptKit mapping | `plugins/prism-callee/skills/lifecycle/references/promptkit.md` |
| Public workflow graph | `pack/callee/prism/lifecycle.md` |

## Validation

```sh
./scripts/validate-lifecycle-ownership.sh
```
