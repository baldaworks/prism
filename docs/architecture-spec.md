# Prism Three-Plugin Architecture

Prism exposes three independent plugins over shared durable Beads state. Their
catalog and documentation order is part of the product boundary:

| Priority | Plugin | Canonical skills | Runtime |
| --- | --- | --- | --- |
| 1 | `prism` | `lifecycle`, `story`, `epic` | Host + Beads |
| 2 | `prism-callee` | `lifecycle` | Host + Beads + Callee |
| 3 | `prism-light` | `lifecycle` | Host + Beads |

## Public interfaces

| Plugin | Codex | Claude Code | Flat surface |
| --- | --- | --- | --- |
| `prism` | `$prism:lifecycle`, `$prism:story`, `$prism:epic` | `/prism:lifecycle`, `/prism:story`, `/prism:epic` | `/prism-lifecycle`, `/prism-story`, `/prism-epic` |
| `prism-callee` | `$prism-callee:lifecycle` | `/prism-callee:lifecycle` | `/prism-callee-lifecycle` |
| `prism-light` | `$prism-light:lifecycle` | `/prism-light:lifecycle` | `/prism-light` |

Direct `callee agent run prism/lifecycle` remains the binary entrypoint to the
canonical Callee Router and its Story and Epic graphs.

## Durable model

The supported hierarchy is Epic → Story → Task. Story interfaces use exactly
one `phase:story:*` label; Epic uses exactly one `phase:epic:*` label.
Unsupported lifecycle labels are treated as absent and never migrated. A label
from the other supported namespace fails closed because it indicates an item
type or routing conflict.

Story and Epic child graphs are evaluated by coverage, cohesion, reviewability,
verifiability, and dependency correctness. They have no fixed child-count
limits.

Approval is layered. Epic approval covers architecture and roadmap only, and
every Story still requires explicit implementation approval. The full host
Story and Epic plugins keep acceptance as an internal readiness input and show
it only on explicit request. Prism Light preserves its concise approval
presentation. Normal Prism Callee output suppresses acceptance; its current-item
approval gates retain the complete acceptance context.

## Ownership

- `plugins/prism/skills/lifecycle/` owns routing and Epic batch coordination.
- `plugins/prism/skills/story/` owns the full host Story contract.
- `plugins/prism/skills/epic/` owns the host Epic contract.
- `plugins/prism-callee/skills/lifecycle/` owns host-to-Callee Story/Epic mapping
  and approval authority.
- `plugins/prism-light/skills/lifecycle/` owns the concise Story contract.
- `pack/callee/prism/` owns direct Callee Router, Story, and Epic behavior.

Each plugin owns its own manifests and marketplace entry. Namespaced and flat
skill trees remain behavioral mirrors even where their directory names differ,
as with `prism-light/skills/lifecycle` and the `/prism-light` flat alias.

The ownership manifest records every managed host Markdown source and every
Callee pack Markdown source with per-file and aggregate SHA-256 digests.
Intentional source changes update those digests; unsynchronized drift fails
validation.

## Validation

```sh
./scripts/validate-plugin-packaging.sh
./scripts/validate-lifecycle-ownership.sh
./scripts/test-lifecycle-drift-detection.sh
./scripts/test-lifecycle-forward-contracts.sh
./scripts/test-callee-lifecycle-forward-contracts.sh
```

Also validate each plugin with `plugin-creator` and each canonical skill with
the skill validator. Validate Callee pack agents with `callee agent validate`.
