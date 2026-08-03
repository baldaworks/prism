# Prism Epic Architecture phase

Run for `phase:epic:architecture` or when framed requirements lack a usable
cross-story architecture.

## Inputs

- current Epic description and acceptance
- existing child Stories
- live repository, tests, configuration, and relevant history

## Contract

Perform two ordered passes:

1. **Explorer:** reconstruct affected systems, interfaces, ownership, state,
   transitions, constraints, current tests, and repository evidence. Separate
   facts from assumptions and cite concrete paths or symbols.
2. **Architect:** define cross-Story boundaries, interfaces, dependency order,
   data/state flow, compatibility, rollout and recovery, operational behavior,
   security boundaries, integration verification, tradeoffs, and risks.

Trace every design element to Epic REQ IDs or mark it `[DESIGN-ONLY]` with a
reason. Architecture must be concrete enough to partition into independently
approvable Stories without duplicating implementation Tasks at Epic level.

## Persist

```bash
bd update <epic> --design-file - --set-labels prism,phase:epic:roadmap
```

Stop in Architecture when evidence is incomplete, an architectural decision is
missing, or safe Story boundaries cannot be derived. Do not create children or
implement code.
