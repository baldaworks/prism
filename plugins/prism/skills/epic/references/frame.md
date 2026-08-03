# Prism Epic Frame phase

Run for `phase:epic:frame` or when the Epic lacks usable outcomes or acceptance.

## Inputs

- `bd show <epic> --long`
- the user's initiative intent and answers
- current child Stories, if any

## Contract

Act as interviewer, readiness gate, then requirements extractor:

1. Separate known facts, inferences, assumptions, and unknowns.
2. Normalize the initiative into outcomes, actors, boundaries, non-goals,
   constraints, dependencies, rollout expectations, and integration success.
3. Author stable REQ IDs and observable current-Epic acceptance criteria.
4. Ask only the minimum questions whose answers materially change architecture,
   Story boundaries, safety, or acceptance.
5. Reject acceptance that merely lists implementation activities or delegates
   acceptance to unspecified child Stories.

## Persist

When the Epic is design-ready, persist normalized description and complete
acceptance, clear stale authorization, and advance:

```bash
bd update <epic> --description="..." --acceptance="..." \
  --set-labels prism,phase:epic:architecture
```

Remain in Frame when a blocking product decision or usable acceptance is missing.
Do not design, create Stories, or modify repository files in this phase.
