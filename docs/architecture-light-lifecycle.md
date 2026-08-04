# Prism Light Story Lifecycle

Prism Light is a standalone plugin, `prism-light`, containing one canonical
skill named `lifecycle`. It is selected only by an explicit Light invocation and
never by the primary `$prism:lifecycle` router.

| Host surface | Invocation | Source |
| --- | --- | --- |
| Codex | `$prism-light:lifecycle` | `plugins/prism-light/skills/lifecycle/` |
| Claude Code | `/prism-light:lifecycle` | `plugins/prism-light/skills/lifecycle/` |
| Flat hosts | `/prism-light` | `plugins/prism-light/prefixed-skills/prism-light/` |

The canonical and flat trees are behavioral mirrors despite their intentionally
different skill names.

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
and verification durable in Beads, but uses shorter phase instructions than the
full `prism:story` workflow. Breakdown is qualitative and has no numeric child
limit.

Its concise approval display remains Acceptance criteria → Design summary →
Task summary → Approval request. Unambiguous approval is required before Apply;
refinement clears approval and returns to Design; ambiguity keeps the gate
closed.
