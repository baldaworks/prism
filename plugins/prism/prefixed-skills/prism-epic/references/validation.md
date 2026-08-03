# Prism Epic Validation phase

Run for `phase:epic:validation` or an approved Epic whose Story children are all
closed. Validation reviews and routes; it performs no repairs.

## Review

1. Re-read the Epic requirements, complete acceptance, architecture, roadmap,
   every Story, and the actual repository diff/history relevant to the Epic.
2. Require every direct child to be a closed Story and reject direct Tasks or
   nested Epics.
3. Verify cross-Story interfaces, integration behavior, migrations and rollout,
   operational and security invariants, documentation, and current-Epic
   acceptance with repository-native checks.
4. Report findings by severity with evidence and next action.

## Decision

- Close the Epic only when all Stories are closed, all Epic acceptance criteria
  pass, required checks pass, and no material finding remains.
- An open-child race discovered on re-read: retain approval and return to
  `phase:epic:delivery` without repairing the child in Validation.
- Missing delivery scope or another Story graph gap: clear approval and return
  to `phase:epic:roadmap`.
- Architecture gap: clear approval and return to `phase:epic:architecture`.
- Requirements or acceptance gap: clear approval and return to
  `phase:epic:frame`.

Never repair code, silently change Story state, or close with open children.
