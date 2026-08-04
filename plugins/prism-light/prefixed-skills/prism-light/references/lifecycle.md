# Prism Light lifecycle graph

Lifecycle starts from user intent. It uses an explicitly named story ID when
present, otherwise resumes exactly one open Prism story; if neither applies, it
creates a new story labeled `phase:story:specify`. Exactly one supported
`phase:story:*` label is the durable lifecycle state. Unsupported phase labels
are treated as absent and never migrated. `prism` marks lifecycle membership and,
after approval, `human:approved` authorizes apply. The Prism Light skill
continues through successful pre-approval phases and presents the Human request
in one invocation. The full Prism Story lifecycle and Prism Callee workflow use
the role-aligned contract instead.

## Graph

Keep workflow diagrams vertical and top-to-bottom.

```mermaid
flowchart TB
  I["1 Intake<br/>label: phase:story:specify"]
  S["2a Specify normalize<br/>description + acceptance"]
  G{"2b Specify gate<br/>ready for design?"}
  Q["2c Human clarification<br/>minimum missing answers"]
  D["3 Design<br/>label: phase:story:design"]
  B["4 Breakdown<br/>label: phase:story:breakdown<br/>Beads child graph"]
  H["5 Human gate<br/>label: phase:story:human"]
  A["6 Apply<br/>label: phase:story:apply<br/>one-task implementer/reviewer subloop"]
  V["7 Verify<br/>label: phase:story:verify<br/>close-or-bounce decision"]
  C["8 Close story"]

  I --> S --> G
  G -->|"ready"| D
  G -->|"needs clarification"| Q
  Q -->|"answer"| S
  D --> B --> H
  H -->|"approve"| A
  H -->|"request design refinement; clear approval"| D
  A -->|"open tasks remain"| A
  A -->|"all children closed"| V
  V -->|"follow-up work"| A
  V -->|"design defect; clear approval"| D
  V -->|"pass"| C
```

## Story state

| Step | Story phase label | Other labels |
| --- | --- | --- |
| Intake / specify | `phase:story:specify` | `prism` |
| Design | `phase:story:design` | `prism` |
| Breakdown | `phase:story:breakdown` | `prism` |
| Human gate | `phase:story:human` | `prism` |
| Apply | `phase:story:apply` | `prism`, `human:approved` |
| Verify | `phase:story:verify` | `prism`, `human:approved` |
| Done | closed | unchanged |

Derive phase from exactly one supported `phase:story:*` label. Treat phase-like
labels outside both supported namespaces as absent, fail closed on an Epic phase,
and initialize `phase:story:specify` without approval when no supported phase
exists. Reconcile it with requirements, design, children, and approval. Do not
fall back to story assignee state.

## Host actions per phase

| Step | Host action | Beads writes |
| --- | --- | --- |
| Specify | Normalize, check readiness, and loop through Human clarification when needed | description, acceptance, `phase:story:design` |
| Design | Inspect repository; write a concrete design with relevant risks and verification | design, `phase:story:breakdown` |
| Breakdown | Create or reconcile children that cover the design | children, dependencies, `phase:story:human` |
| Human | Show Acceptance criteria → Design summary → Task summary → Approval request | approval writes `human:approved`, `phase:story:apply`; explicit design refinement clears approval and writes `phase:story:design` |
| Apply | Close ready children through the inner loop | task `prism/apply/implementer` → `prism/apply/reviewer`; story stays `phase:story:apply` |
| Verify | Make the close-or-bounce decision | close story or return it to the needed phase label |

## Authority boundaries

```text
Human ──human:approved──► phase:story:apply / phase:story:verify consent
Manual Prism skill ──bd + host work──► durable state + repo changes
Prism Callee skill ──prism/*──► provider work
```

- Do not run apply without `human:approved`.
- Do not invoke `callee agent run prism/...` from the host-native Prism skill.
- During apply, claim only a ready child of the current story.
- Verify is a close-or-bounce story decision; do not close the story with open children or follow-up work.
