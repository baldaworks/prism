# Prism Light Lifecycle

Prism Light is the standalone `prism-light` plugin. It provides one concise,
host-native Story workflow and is selected only by an explicit Light
invocation.

| Host surface | Invocation | Source |
| --- | --- | --- |
| Codex | `$prism-light:lifecycle` | `plugins/prism-light/skills/lifecycle/` |
| Claude Code | `/prism-light:lifecycle` | `plugins/prism-light/skills/lifecycle/` |
| Flat hosts | `/prism-light` | `plugins/prism-light/prefixed-skills/prism-light/` |

The canonical skill is named `lifecycle`; the flat mirror is intentionally
named `prism-light`.

## State machine

```mermaid
flowchart TB
    I["Change intent"] --> S["Specify"]
    S --> D["Design"]
    D --> B["Breakdown"]
    B --> H{"Concise Human approval"}
    H -->|approved| A["Apply"]
    H -->|refine design| D
    A --> V{"Verify"]
    V -->|pass| C["Close Story"]
    V -->|gap| S
```

Light uses the same durable Story phase labels and the same Epic → Story → Task
hierarchy as the full host workflow. Unsupported labels are not migrated, a
wrong-type phase fails closed, Task graphs are qualitative, and every Apply
transition requires explicit approval.

## Deliberate differences

- phase instructions are shorter than the role-aligned `prism:story` contract;
- the approval display remains Acceptance criteria → Design summary → Task
  summary → Approval request;
- the primary Prism router never selects Light implicitly;
- Light does not run Epics, open-Epic batches, or Callee agents.

Namespaced and flat trees are behavioral mirrors enforced by the ownership
validator.
