# Prism Architecture Index

This repository ships two different Prism host skills that share the same Beads
story state but do not share the same execution contract:

- `plugins/prism/` exposes the manual host lifecycle skill.
- `plugins/prism-callee/` exposes the automated Callee lifecycle skill.

The old single architecture spec mixed those surfaces together. This file is now
only the repository-level index and boundary map. Read the surface-specific
documents for actual behavior:

- Host lifecycle: [architecture-host-lifecycle.md](architecture-host-lifecycle.md)
- Automated lifecycle: [architecture-callee-lifecycle.md](architecture-callee-lifecycle.md)

## Repository surfaces

| Surface | Entry point | Owns | Does not own |
| --- | --- | --- | --- |
| Manual host lifecycle | `$prism:lifecycle`, `/prism:lifecycle`, or `/prism-lifecycle` | Direct host execution, repository inspection, Beads writes, host-authored phase work | `callee agent run prism/...`, PromptKit role generation |
| Automated lifecycle | `$prism-callee:lifecycle`, `/prism-callee:lifecycle`, or `/prism-callee-lifecycle` | `callee agent run prism/...`, PromptKit role/workflow mapping, automated phase execution | Manual host-only phase procedure |
| Prism Callee pack | `pack/callee/prism/` | Reusable `prism/*` Roles, phases, workflows | Manual host lifecycle behavior |
| Documentation pack | `pack/callee/documentation/` | Documentation maintenance workflow | Prism story execution |

## Shared state vs separate execution

Both Prism skills operate on the same durable Beads model:

- story labels: `prism`, `human:approved`
- story assignee: the active lifecycle phase, from `prism/specify` through `prism/verify`
- story fields: description, acceptance, design (including the durable
  `## Prism Impact Lens`)
- child tasks and dependencies

Both skills accept user intent rather than requiring a pre-created story: use
an explicitly named story ID, otherwise resume exactly one open Prism story,
otherwise create a new story assigned to `prism/specify`.

The Impact Lens is a Prism-owned qualitative assessment of Product, Process,
People, Planet, and Prosperity. It adds no lifecycle label or phase. A complete
lens is required before Breakdown, and actionable mitigations must be covered
by the durable child-task graph before informed human approval.

What differs is execution:

- `prism` performs lifecycle work directly in the host.
- `prism-callee` delegates lifecycle work to `prism/*` Callee assets.

That separation is intentional and must remain explicit in docs and skills.

## Source of truth

| Topic | Source of truth |
| --- | --- |
| Manual host lifecycle contract | `plugins/prism/skills/lifecycle/SKILL.md` and its phase references |
| Automated lifecycle contract | `plugins/prism-callee/skills/lifecycle/SKILL.md`, `plugins/prism-callee/prefixed-skills/prism-callee-lifecycle/SKILL.md`, and `references/promptkit.md` |
| Shared Beads lifecycle graph | `plugins/prism/skills/lifecycle/references/lifecycle.md` |
| Automated `prism/*` agent graph | `pack/callee/prism/` |
| Repository packaging and install surface | `README.md` plus host manifests under `plugins/` and marketplace files |

## Documentation map

Read the smallest document that matches the change:

1. Editing manual host lifecycle behavior:
   `docs/architecture-host-lifecycle.md`
2. Editing automated `prism-callee` behavior or PromptKit mappings:
   `docs/architecture-callee-lifecycle.md`
3. Editing repo-level packaging, installation, or distribution boundaries:
   this file plus `README.md`

## Non-goals

This repository-level document does not define:

- per-phase host instructions
- PromptKit template choices
- exact `callee agent run` command shapes
- consumer-project test strategy

Those details belong in the surface-specific architecture docs and the skill
references they point to.
