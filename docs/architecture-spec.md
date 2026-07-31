# Prism Architecture Index

Prism exposes three execution surfaces over one Beads state machine:

- full host lifecycle: `$prism:lifecycle`, `/prism:lifecycle`, `/prism-lifecycle`;
- concise host lifecycle: `$prism:light`, `/prism:light`, `/prism-light`;
- Callee lifecycle: `$prism-callee:lifecycle`, `/prism-callee:lifecycle`,
  `/prism-callee-lifecycle`, or direct
  `callee agent run prism/lifecycle --message "..."`.

## Repository surfaces

| Surface | Execution | Behavioral contract |
| --- | --- | --- |
| Full host lifecycle | Current host performs all work; never invokes Callee | Read-only projection of `pack/callee/prism` phases, workflows, and roles |
| Prism Light | Current host performs a concise workflow | Intentionally simplified Light references |
| Prism Callee | Host wrapper invokes `prism/*` agents | Original `pack/callee/prism` files |
| Direct Callee binary | Runs public Callee graph without Beads wrapper | Original `pack/callee/prism` files |

The original files under `pack/callee/**` are immutable. Full host parity is
implemented only through Prism skill references, ownership metadata, validators,
manifests, and documentation.

## Shared durable state

All host entrypoints use the same Beads model:

- `prism` lifecycle membership;
- `human:approved` Apply authorization;
- exactly one label from `phase:specify`, `phase:design`, `phase:breakdown`,
  `phase:human`, `phase:apply`, and `phase:verify`;
- description, acceptance, design, child tasks, dependencies, and status;
- Apply child assignees `prism/apply/implementer` and `prism/apply/reviewer`.

Entrypoints accept either an explicit story ID or user intent. They otherwise
resume exactly one open Prism story or create a new `phase:specify` story.
No Beads migration is required when choosing another execution surface.

## Full contract vs Light

The full host and Callee surfaces share role order, outputs, gates, iteration
limits, and failure behavior:

1. interviewer → readiness gate → Human clarification → extract;
2. explorer → architect;
3. implementation planner → Beads normalization;
4. approval prompt → intent classifier → decision check;
5. implementer → independent reviewer repair loop;
6. story reviewer → close or phase-specific bounce.

Prism Light preserves the previous concise phase instructions and does not claim
this role-level parity.

## Source of truth

| Topic | Source |
| --- | --- |
| Immutable full behavior | `pack/callee/prism/` |
| Machine-checkable projection and source digests | `docs/lifecycle-ownership.json` |
| Full host execution | `plugins/prism/skills/lifecycle/` |
| Light host execution | `plugins/prism/skills/light/` |
| Callee host execution | `plugins/prism-callee/skills/lifecycle/` |
| Shared labels and transitions | `docs/lifecycle-ownership.json` and lifecycle references |
| Packaging | plugin manifests, marketplace manifests, and `README.md` |

## Documentation map

- Full host behavior: [architecture-host-lifecycle.md](architecture-host-lifecycle.md)
- Light behavior: [architecture-light-lifecycle.md](architecture-light-lifecycle.md)
- Callee execution: [architecture-callee-lifecycle.md](architecture-callee-lifecycle.md)

## Validation

`scripts/validate-lifecycle-ownership.sh` checks the immutable source digests,
contract projections, mirrors, and lifecycle state. `scripts/validate-plugin-packaging.sh`
checks both Prism skills and the preserved Prism Callee plugin across supported hosts.
