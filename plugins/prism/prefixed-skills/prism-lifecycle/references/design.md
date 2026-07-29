# Prism design phase

Run this reference only when the story assignee is `prism/design` or the
story already has requirements but does not yet have durable design markdown.

## Goal

Inspect the repository and produce host-authored design markdown that explains
how the requested change should be implemented.

## Required inputs

- `bd show <story> --long`
- the relevant repository files and current behavior
- any constraints discovered during specify

## Host procedure

1. Load the story with `bd show <story> --long`.
2. Inspect the relevant repository areas, current behavior, dependencies, and constraints.
3. Write concise design markdown directly in the host. Prefer sections such as:
   - Summary
   - Current state
   - Proposed changes
   - Risks / open questions
   - Verification
4. Append this exact durable section and table:

```markdown
## Prism Impact Lens

| Dimension | Rating | Rationale / evidence | Mitigation / verification |
| --- | --- | --- | --- |
| Product | positive | ... | ... |
| Process | not-material | ... | ... |
| People | mixed | ... | ... |
| Planet | not-material | ... | ... |
| Prosperity | not-material | ... | ... |
```

   Use exactly one row each for Product, Process, People, Planet, and
   Prosperity. Allowed ratings are `positive`, `negative`, `mixed`,
   `not-material`, and `unknown`; do not calculate a numeric score. Every row
   needs concrete rationale or evidence. Every `negative` or `mixed` row needs
   an actionable mitigation or an explicit disposition accepting the residual
   impact.
5. Ensure the design answers three questions clearly:
   - what changes
   - where those changes land in the repository
   - how verification should prove the change worked

## Persist and advance

6. Re-read the lens. Do not advance while any rating is `unknown`, a required
   row or rationale is missing, or a material impact lacks mitigation or an
   explicit residual-impact disposition.

When the design and Impact Lens are concrete enough to decompose into small tasks:

```bash
bd update <story> --design-file - -a prism/breakdown --set-labels prism
```

Advance only to `prism/breakdown`.

## Stop when

- repository inspection is still incomplete
- the design has open questions that materially affect task breakdown
- the Impact Lens is missing, invalid, or contains `unknown`
- the proposed approach is too vague to decompose into reviewable tasks

If you stop, keep the story in design and ask the human or revise the design.

## Never

- base the design on generic architecture advice instead of the actual repository
- do task decomposition here
- hide important risks or open questions
- move to plan with design text that does not identify concrete repository touch points
