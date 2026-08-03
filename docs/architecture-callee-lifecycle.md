# Prism Callee Story Lifecycle

`prism-callee:lifecycle` is the Story-only host integration for the specialized
`prism/*` Callee agent pack. The host wrapper owns Beads persistence and maps
the pack's logical Story phases to namespaced labels.

## Host-managed state

The wrapper uses:

1. `phase:story:specify`
2. `phase:story:design`
3. `phase:story:breakdown`
4. `phase:story:human`
5. `phase:story:apply`
6. `phase:story:verify`

Unsupported phase labels are absent, never migrated. Another supported item
namespace fails closed. The wrapper is not an Epic workflow and is not selected
by the host-native `prism:lifecycle` router.

Before approval, the wrapper shows complete Acceptance criteria → Design
summary → Task summary → Approval request. A no-tools classifier interprets the
human response, and a deterministic gate permits Apply only for unambiguous
approval. Refinement clears approval and returns to Design; ambiguity withholds
approval.

Breakdown creates a qualitatively complete Task graph without a numeric child
limit. Apply and Verify remain Story-scoped.

## Direct Callee execution

`callee agent run prism/lifecycle` executes the pack's deterministic Story
graph without host-managed Beads state. The pack uses internal logical phase
names; namespaced Beads labels belong to the host wrapper. Pack Markdown is
digest-locked, and intentional changes require synchronized ownership digest
updates.

| Surface | Source |
| --- | --- |
| Host wrapper | `plugins/prism-callee/skills/lifecycle/` |
| Flat host wrapper | `plugins/prism-callee/prefixed-skills/prism-callee-lifecycle/` |
| Callee pack | `pack/callee/prism/` |

Validate the pack with `callee agent validate` and the repository ownership
scripts.
