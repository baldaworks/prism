# Story Lifecycle

`prism:story` is the full host-native lifecycle for one Beads Story. It keeps
durable state in Beads and preserves the role and gate contracts of the Prism
Callee Story workflow without requiring the Callee runtime.

## State machine

An active Story has exactly one supported phase label:

1. `phase:story:specify`
2. `phase:story:design`
3. `phase:story:breakdown`
4. `phase:story:human`
5. `phase:story:apply`
6. `phase:story:verify`

Unsupported phase labels are treated as absent. They are not migrated. A Story
with no supported Story phase starts at Specify and any stale approval is
cleared. Labels from another supported item namespace fail closed.

## Gates and children

Specify produces complete acceptance criteria before Design. Breakdown creates
or reconciles Task children using qualitative readiness: coverage, cohesion,
reviewability, verifiability, and correct dependencies. There is no numeric
minimum or maximum; one Task or more than twelve Tasks can be valid.

Before requesting approval, the host shows this exact order:

1. complete, untruncated Acceptance criteria;
2. Design summary;
3. Task summary;
4. Approval request.

Only unambiguous human approval writes `human:approved` and advances to Apply.
Design refinement clears approval and returns to Design. Ambiguity keeps the
gate closed. Apply advances ready Tasks sequentially; Verify closes a complete
Story or bounces a discovered gap to the appropriate phase.

## Sources

| Surface | Source |
| --- | --- |
| Namespaced | `plugins/prism/skills/story/` |
| Flat | `plugins/prism/prefixed-skills/prism-story/` |

These two trees are behavioral mirrors and are covered by the ownership
validator.
