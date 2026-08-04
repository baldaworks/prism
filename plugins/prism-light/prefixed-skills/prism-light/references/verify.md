# Prism Light verify phase

Run this reference only when the story label is `phase:story:verify` or the story
is `human:approved` and has no open child tasks.

## Goal

Make the close-or-bounce story decision against the story description,
acceptance criteria, design, and implemented result.

## Required inputs

- `bd show <story> --long`
- `bd children <story>`
- the final repository state after apply

## Host procedure

1. Load the full story context:

```bash
bd show <story> --long
bd children <story>
```

2. Review whether:
   - the description was implemented
   - the acceptance criteria are satisfied
   - the design intent still matches the final result
   - relevant risks, security concerns, regressions, and tests were addressed
   - no follow-up work is required for correctness
3. Decide whether the story should close or bounce back for more work.

## Persist and advance

If verification passes, close the story:

```bash
bd close <story> --reason="Acceptance met"
```

If verification fails:

- keep the story open
- reopen or create child tasks as needed
- for implementation gaps, preserve approval with
  `bd update <story> --set-labels prism,phase:story:apply,human:approved`
- for defective task coverage, clear approval with
  `bd update <story> --set-labels prism,phase:story:breakdown`
- for an invalid or incomplete design, clear approval with
  `bd update <story> --set-labels prism,phase:story:design`
- for incomplete requirements, clear approval with
  `bd update <story> --set-labels prism,phase:story:specify`

## Stop when

- follow-up work is required
- acceptance gaps still exist
- verification discovered that plan or design must be revisited

Stopping here means bouncing the story, not repairing it inside verify.

## Never

- use verify as an implementation repair loop
- close the story if follow-up work is required
- leave the story closed while acceptance gaps still exist
