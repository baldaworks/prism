# Host Lifecycle Router

`prism:lifecycle` is the host-native entrypoint that routes work to the full
Story or Epic lifecycle. It is a coordinator, not a third item lifecycle, and
it never selects Prism Light implicitly.

## Routing

The router resolves an explicitly named Beads item first:

- Epic → `prism:epic`;
- Story → `prism:story`;
- Task → its parent Story, then `prism:story`;
- unsupported item type or invalid parentage → fail closed with diagnostics.

Without an explicit item, clear multi-Story intent creates an Epic, ordinary
change intent creates a Story, and ambiguous resume candidates require the
user to choose. Unsupported lifecycle labels are treated as absent by the
selected lifecycle; they are never migrated.

## Open-Epic batch

Batch mode runs only on an explicit request to process all open Prism Epics.
At batch start the router:

1. snapshots open items labeled `prism` whose Beads type is Epic;
2. sorts the snapshot by priority, creation time, then ID;
3. visits every snapshotted Epic exactly once and sequentially through
   `prism:epic`;
4. continues after an item-local approval gate, clarification, or blocker;
5. does not rescan for newly opened Epics; and
6. reports one outcome for every snapshotted Epic.

Approval never transfers between Epics or from an Epic to any child Story.
An empty snapshot is a successful no-work result.

## Sources

| Surface | Source |
| --- | --- |
| Namespaced router | `plugins/prism/skills/lifecycle/` |
| Flat router | `plugins/prism/prefixed-skills/prism-lifecycle/` |
| Story lifecycle | `plugins/prism/skills/story/` |
| Epic lifecycle | `plugins/prism/skills/epic/` |

The flat and namespaced router skills must remain behavioral mirrors. Lifecycle
ownership and source digests are enforced by
`scripts/validate-lifecycle-ownership.sh`.
