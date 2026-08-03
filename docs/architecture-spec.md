# Prism Architecture Boundary

Prism exposes distinct interfaces over shared durable work:

| Interface | Scope | Runtime |
| --- | --- | --- |
| `prism:lifecycle` | Story/Epic routing and explicit open-Epic batches | Host + Beads |
| `prism:story` | Full single-Story lifecycle | Host + Beads |
| `prism:epic` | Multi-Story Epic lifecycle | Host + Beads |
| `prism:light` | Concise single-Story lifecycle | Host + Beads |
| `prism-callee:lifecycle` | Callee-backed single-Story lifecycle | Host + Beads + Callee |
| `prism/lifecycle` | Direct Story workflow graph | Callee |

## Durable model

The supported hierarchy is Epic → Story → Task. Story interfaces use exactly
one `phase:story:*` label; Epic uses exactly one `phase:epic:*` label.
Unsupported lifecycle labels are treated as absent, never migrated. A label
from the other supported namespace fails closed because it indicates an item
type or routing conflict.

Story and Epic child graphs are evaluated qualitatively. Coverage, cohesion,
reviewability, verifiability, and dependency correctness matter; fixed child
count limits do not.

Approval is layered. Epic approval covers architecture and roadmap only. Every
Story still requires its own explicit implementation approval. Approval
presentations begin with the item's complete, untruncated acceptance criteria.

## Ownership

- `plugins/prism/skills/lifecycle/` owns routing and batch coordination.
- `plugins/prism/skills/story/` owns the full host Story contract.
- `plugins/prism/skills/epic/` owns the host Epic contract.
- `plugins/prism/skills/light/` owns the concise Story contract.
- `plugins/prism-callee/skills/lifecycle/` owns host-to-Callee Story mapping.
- `pack/callee/prism/` owns direct Callee agent behavior.

Namespaced and flat skill trees are behavioral mirrors. The ownership manifest
records each managed host source and every Callee pack Markdown source with
per-file and aggregate SHA-256 digests. Intentional source changes update those
digests; unsynchronized drift fails validation.

## Validation

Run:

```sh
./scripts/validate-plugin-packaging.sh
./scripts/validate-lifecycle-ownership.sh
./scripts/test-lifecycle-drift-detection.sh
./scripts/test-lifecycle-forward-contracts.sh
```

Also validate canonical skills with the skill-creator validator and Callee pack
agents with `callee agent validate`.
