# Host Lifecycle Router

`prism:lifecycle` is the default host-native entrypoint. It resolves a target
and delegates to `prism:story` or `prism:epic`; it is not a third item
lifecycle and never selects Prism Callee or Prism Light implicitly.

## Routing

```mermaid
flowchart TB
    I["Operator request"] --> B{"All open Prism Epics explicitly requested?"}
    B -->|yes| Batch["Freeze and process one Epic snapshot"]
    B -->|no| X{"Explicit item?"}
    X -->|Epic| E["prism:epic"]
    X -->|Story| S["prism:story"]
    X -->|Task| P["Resolve parent Story"]
    P --> S
    X -->|none| O{"One open Prism item?"}
    O -->|yes| T["Resume by item type"]
    O -->|ambiguous| Stop["Stop and request a target"]
    O -->|none, multi-Story intent| NewE["Create Epic"]
    O -->|none, ordinary intent| NewS["Create Story"]
    NewE --> E
    NewS --> S
```

Explicit item IDs win over inferred intent. Unsupported item types, invalid
Task parentage, wrong-type lifecycle phases, and ambiguous resume candidates
fail closed without inventing a target.

## Open-Epic batch

Batch mode runs only on an explicit request to process all open Prism Epics.

```mermaid
flowchart TB
    S["Snapshot open prism Epics once"] --> O["Order by priority, creation time, ID"]
    O --> N["Advance next Epic to its genuine stop"]
    N --> R["Record one outcome row"]
    R --> M{"Snapshot items remain?"}
    M -->|yes| N
    M -->|no| C["Return complete batch report"]
```

The router visits every snapshotted Epic exactly once and sequentially. It
continues after item-local approval gates, clarification, blockers, and
failures; it never rescans for newly opened Epics. Approval never transfers
between Epics or to a child Story. An empty snapshot is a successful no-work
result.

## Sources

| Surface | Source |
| --- | --- |
| Namespaced router | `plugins/prism/skills/lifecycle/` |
| Flat router | `plugins/prism/prefixed-skills/prism-lifecycle/` |
| Story lifecycle | `plugins/prism/skills/story/` |
| Epic lifecycle | `plugins/prism/skills/epic/` |

The canonical and flat router trees are behavioral mirrors enforced by
`scripts/validate-lifecycle-ownership.sh`.
