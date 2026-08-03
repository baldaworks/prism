# Prism full story lifecycle graph

The host executes the same logical phase and role order as the digest-locked Prism
Callee workflow without invoking `callee`. Beads is the durable state store.

```mermaid
flowchart TB
  I["Intent / resume story"]
  S["Specify<br/>interviewer"]
  G{"Readiness gate"}
  Q["Human clarification"]
  X["Requirements extract"]
  E["Design explorer"]
  D["Design architect"]
  B["Breakdown planner"]
  N["Beads normalization"]
  H["Human approval prompt"]
  C{"Intent classifier + check"}
  W["Apply implementer"]
  R{"Independent reviewer"}
  V["Verify story reviewer"]
  Z["Close story"]

  I --> S
  S --> G
  G -->|"needs clarification"| Q
  Q --> S
  G -->|"ready"| X
  X --> E
  E --> D
  D --> B
  B --> N
  N --> H
  H --> C
  C -->|"approve"| W
  C -->|"refine design"| E
  C -->|"withhold"| H
  W --> R
  R -->|"repair, max 5"| W
  R -->|"task accepted; more tasks"| W
  R -->|"all tasks closed"| V
  V -->|"acceptance met"| Z
  V -->|"implementation gap"| W
  V -->|"breakdown gap"| B
  V -->|"design gap"| E
  V -->|"requirements gap"| S
```

## State invariants

- Exactly one supported `phase:story:*` label exists on every active story.
- Unsupported phase labels are treated as absent and never migrated.
- A story with no supported phase starts at `phase:story:specify` without approval.
- Specify and Apply loops fail closed after five unsuccessful iterations.
- Human approval is distinct from Specify clarification.
- Design is explorer evidence followed by architect decisions.
- Apply review is based on the actual working tree and tests, not only worker output.
- Verify makes a close-or-bounce decision and performs no repairs.
- `pack/callee/**` is never modified by host execution.
