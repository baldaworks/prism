# Prism apply phase

Run this reference only when the story label is `phase:apply` and the
story already has `human:approved`.

## Goal

Drive story-level operational closure by implementing one ready child task at a
time, reviewing it, and repeating while ready work remains.

## Required inputs

- `bd show <story> --long`
- `bd children <story>`
- `bd ready`
- the story description, acceptance, and design

## Host procedure

1. Load story and task state:

```bash
bd show <story> --long
bd children <story>
bd ready
```

2. Choose exactly one task that is both:
   - a child of the current story
   - ready / unblocked
3. Claim it with `bd update <task> -a prism/apply/implementer`.
4. Inspect the task, story, acceptance, and design before editing code.
5. Implement only the claimed task's scope and verification criteria.
6. Run the most relevant project checks after code changes.
7. Review the result for correctness, scope fit, regressions, missing
   verification, security concerns, and adherence to the saved design.

## Persist and advance

If checks pass and review is clean:

```bash
bd update <task> -a prism/apply/reviewer
bd close <task> --reason="Implemented, reviewed, checks passed"
```

Then re-check the story:

- if another child is ready, continue apply in the same run
- if open children remain but none are ready, stop in apply
- if no open children remain, advance the story to verify

When no open children remain:

```bash
bd update <story> --set-labels prism,phase:verify,human:approved
```

## Stop when

- no child of the current story is ready
- checks fail
- review finds correctness or scope gaps
- implementation reveals a design or plan defect that must be fixed before continuing

If you stop because of a defect, keep the story open and move it back only as
far as the defect requires.

## Never

- claim from global `bd ready` alone without confirming the task belongs to the story
- implement more than the currently claimed child task
- close the task if checks fail or review finds gaps
- treat apply as a synonym for one child task; it is the outer story loop
