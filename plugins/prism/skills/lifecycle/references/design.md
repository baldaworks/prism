# Prism design phase

Run this reference only when the story label is `phase:design` or the
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
   Capture relevant risks, constraints, tradeoffs, and verification in ordinary
   prose. Do not require a fixed assessment matrix or rating system.
4. Ensure the design answers three questions clearly:
   - what changes
   - where those changes land in the repository
   - how verification should prove the change worked

## Persist and advance

When the design is concrete enough to decompose into small tasks:

```bash
bd update <story> --design-file - --set-labels prism,phase:breakdown
```

Advance only to `phase:breakdown`.

## Stop when

- repository inspection is still incomplete
- the design has open questions that materially affect task breakdown
- the proposed approach is too vague to decompose into reviewable tasks

If you stop, keep the story in design and ask the human or revise the design.

## Never

- base the design on generic architecture advice instead of the actual repository
- do task decomposition here
- hide important risks or open questions
- move to plan with design text that does not identify concrete repository touch points
