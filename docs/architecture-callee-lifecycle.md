# Prism Callee Lifecycle Architecture

This document defines the Prism Callee workflow: `$prism-callee:lifecycle`,
`/prism-callee:lifecycle`, and `/prism-callee-lifecycle`. It advances the same
Beads-backed story state as the manual host lifecycle through public
`prism/lifecycle` and `prism/phases/*` Callee workflows. The public graph can
also be invoked directly through the `callee` binary.

The checked-in files under `pack/callee/**` are the immutable behavioral source
for both this runner and the full host `$prism:lifecycle` projection. This
surface executes those agents; the full host reproduces their contract without
invoking Callee. Prism Light intentionally uses a smaller contract.

## Direct binary invocation

After importing the Prism agent pack, run the full public workflow directly:

```sh
callee agent run prism/lifecycle \
  --message "Add CSV export to the report page."
```

Direct binary execution runs the public Callee graph only. It does not persist
or resume Beads state; use a `prism-callee` host entrypoint when the durable
lifecycle wrapper is required.

## Public surface

| Host or binary entrypoint | Callee surface |
| --- | --- |
| `callee agent run prism/lifecycle --message "..."` | Direct binary execution |
| `$prism-callee:lifecycle` | Codex automation entrypoint |
| `/prism-callee:lifecycle` | Claude Code automation entrypoint |
| `/prism-callee-lifecycle` | Flat-name automation entrypoint |
| `prism/lifecycle` | Canonical Sequential graph |
| `prism/phases/*` | Public phase entrypoints |

Internal roles and workflows remain under `prism/roles/*` and
`prism/<phase>/*`.

## Durable state

Exactly one story label is the lifecycle phase. The automation must use:

| Story label | Public workflow |
| --- | --- |
| `phase:specify` | `prism/phases/specify` |
| `phase:design` | `prism/phases/design` |
| `phase:breakdown` | `prism/phases/breakdown` |
| `phase:human` | `prism/phases/human` |
| `phase:apply` | `prism/phases/apply` |
| `phase:verify` | `prism/phases/verify` |

`prism` is membership and `human:approved` permits apply. Story assignees do
not encode lifecycle phases. Existing assignee-driven stories are intentionally
not migrated or supported. Child tasks use `prism/apply/implementer` and
`prism/apply/reviewer` inside story-level apply.

## Story resolution

Automation accepts user intent, not a pre-created story. It uses an explicitly
named story ID when present, otherwise resumes exactly one open Prism story. If
neither applies, it creates a new story labeled `prism,phase:specify` from the
raw request; Specify then normalizes the acceptance criteria.

## Specify clarification loop

`prism/phases/specify` is a public Sequential workflow containing the internal
`prism/specify/loop`. Each iteration normalizes the current requirements and
runs the Specify gate. A ready gate escalates out of the loop and allows the
phase result to advance to Design. A gate that needs clarification invokes the
`prism/specify/questions` Human agent, feeds its answer into the next normalizer
iteration, and checks readiness again.

This clarification interaction is distinct from the informed Human approval
gate after Breakdown. It does not authorize Apply or require confirmation of a
phase transition. The Callee loop allows five iterations and fails on
exhaustion rather than inventing missing product intent.

## Design and approval

The Callee workflow uses the same free-form design contract as the host
lifecycle. Design records the solution, relevant risks, constraints, tradeoffs,
and verification without requiring an assessment matrix or rating system.
Breakdown covers actionable implementation and verification work while
preserving existing child state and dependencies.

At `prism/phases/human`, the host prepares Design summary → Task summary →
Approval request from current Beads state. The Human agent accepts ordinary
language; `prism/human/intent` classifies it without tools and fails closed,
and emits exactly `APPROVE`, `REFINE_DESIGN`, or `WITHHOLD`. The deterministic
check accepts only `APPROVE`. `REFINE_DESIGN` stops the Sequential workflow with
`PRISM_HUMAN_DECISION=REFINE_DESIGN`, allowing the host wrapper to clear
approval, return durable state to `phase:design`, and preserve child state for
Breakdown reconciliation. `WITHHOLD` remains at `phase:human`.

## Rules

- Only this automated surface may execute `callee agent run prism/...`.
- Persist every Callee result to Beads, then re-read story and child state.
- After successful Specify, Design, or Breakdown persistence, invoke the newly
  selected phase immediately in the same lifecycle run. Do not request human
  confirmation between pre-approval phases.
- Collect clarification in Specify through the Callee Human step and repeat the
  Specify normalizer and gate when needed.
- Collect free-form human approval or an explicit design-refinement decision
  through `prism/phases/human`; fail closed until intent is unambiguous.
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

Do not edit or regenerate any `pack/callee/**` file while adapting host skills.
Update only the host projection and its validation metadata.

## Validation

```sh
./scripts/validate-lifecycle-ownership.sh
```
