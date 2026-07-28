# Prism plan phase

Run this reference only when the inferred story phase is `phase:plan` or the
story already has design markdown but does not yet have child tasks.

## Goal

Turn the story design into a small Beads task graph that is ready for the human
approval gate.

## Required inputs

- `bd show <story> --long`
- durable design markdown already stored on the story
- the task-graph contract in [breakdown.md](breakdown.md)

## Host procedure

1. Load the story with `bd show <story> --long`.
2. Produce a 3-12 task plan that covers the story acceptance without adding scope.
3. Normalize that plan using the exact JSON contract in [breakdown.md](breakdown.md).
4. Create Beads child tasks and dependencies from that normalized task graph.
5. Verify the resulting graph with:

```bash
bd children <story>
bd blocked
```

6. Confirm the graph is reviewable:
   - no single mega-task for the whole story
   - dependencies are serializable
   - every task has done-when language

## Persist and advance

When children and dependencies are valid:

```bash
bd update <story> -a human --set-labels prism,phase:human
```

Advance only to `phase:human`.

## Stop when

- the design cannot be decomposed cleanly into small reviewable tasks
- the plan would add scope beyond acceptance or design
- dependency structure is still unclear

If you stop, keep the story in plan and revise the breakdown or ask the human.

## Never

- violate the exact task-graph contract from `breakdown.md`
- create one mega-task for the whole story
- put human approval into child tasks
- advance to the human gate before verifying the created child graph
