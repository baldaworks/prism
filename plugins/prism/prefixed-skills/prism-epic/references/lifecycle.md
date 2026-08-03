# Prism Epic lifecycle graph

```mermaid
flowchart TB
  I["Intent / resume Epic"]
  F["Frame<br/>outcomes + acceptance"]
  A["Architecture<br/>explorer + architect"]
  R["Roadmap<br/>Story graph"]
  G["Approval<br/>Epic-only authorization"]
  D["Delivery<br/>sequential Story lifecycle"]
  H{"Child Human gate or blocker?"}
  S["Stop durably<br/>report child next action"]
  V["Validation<br/>integration close-or-bounce"]
  C["Close Epic"]

  I --> F --> A --> R --> G
  G -->|"approve Epic roadmap"| D
  G -->|"refine"| A
  D --> H
  H -->|"yes"| S
  H -->|"no; more ready Stories"| D
  D -->|"all Stories closed"| V
  V -->|"acceptance met"| C
  V -->|"delivery gap"| D
  V -->|"roadmap gap"| R
  V -->|"architecture gap"| A
  V -->|"requirements gap"| F
```

## Invariants

- Exactly one supported `phase:epic:*` label represents active Epic state.
- Unsupported phase labels are absent and never migrated.
- Direct children are Stories; Story children own implementation Tasks.
- Epic approval covers architecture and roadmap only and never cascades.
- Delivery advances one ready Story at a time and stops at child Human input or
  blocking state.
- Validation closes or bounces and performs no repairs.
