# Prism Light Story Lifecycle

`prism:light` is the concise, host-only Story workflow. It is selected only by
an explicit Light invocation and never by `prism:lifecycle` routing.

Light uses the same durable Story phases as the full Story lifecycle:

1. `phase:story:specify`
2. `phase:story:design`
3. `phase:story:breakdown`
4. `phase:story:human`
5. `phase:story:apply`
6. `phase:story:verify`

Unsupported phase labels are treated as absent and are not migrated. A Story
with no supported Story phase starts at Specify; a phase label from another
supported item namespace fails closed.

Light keeps requirements, design, Task dependencies, approval, implementation,
and verification durable in Beads, but uses shorter phase instructions than
`prism:story`. Breakdown is qualitative and has no numeric child limit.

The approval display is complete Acceptance criteria → Design summary → Task
summary → Approval request. Unambiguous approval is required before Apply;
refinement clears approval and returns to Design; ambiguity keeps the gate
closed.

| Surface | Source |
| --- | --- |
| Namespaced | `plugins/prism/skills/light/` |
| Flat | `plugins/prism/prefixed-skills/prism-light/` |

The two source trees are behavioral mirrors.
