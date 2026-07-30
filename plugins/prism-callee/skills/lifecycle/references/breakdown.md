# Prism breakdown phase

Run this reference only when the story label is `phase:breakdown`, or when
the story has durable design markdown but no child tasks.

## Goal

Turn the story design into a small Beads task graph ready for the human gate.
The task graph is persisted directly in Beads; do not create a plan file.

Contract for turning a Prism implementation plan into beads task children. The
host agent **must** extract a machine-usable task list before creating issues.
Do not invent tasks that are not in the plan.

## Required output shape

Prefer a single fenced JSON block from the host-authored plan (or normalize
free-form plan text into this shape before any `bd create`):

```json
{
  "tasks": [
    {
      "key": "t1",
      "title": "Short action title",
      "description": "Done-when criteria for this task only.",
      "depends_on": []
    },
    {
      "key": "t2",
      "title": "Next action",
      "description": "Done-when criteria.",
      "depends_on": ["t1"]
    }
  ]
}
```

Rules:

- For a new story graph, create **3–12** tasks.
- `key` is a local id for deps only (not a beads id).
- `title` ≤ ~80 chars, action-oriented.
- `description` states **done-when** (testable).
- `depends_on` lists earlier `key`s that must complete first.
- No scope beyond story acceptance / design.
- Relevant design risks, constraints, and verification work must be represented
  by a child task when they require implementation.
- If the plan has no extractable tasks, revise the plan or stop and ask the human — do not invent a graph.

## Host procedure (strict)

1. Validate that the saved design is concrete enough to decompose. If it is
   missing or incomplete, clear `human:approved`, return the story to
   `phase:design` with
   `bd update <story-id> --set-labels prism,phase:design`, and stop.
2. Produce or collect a breakdown in the JSON shape above.
   - The manual host lifecycle authors it directly in the host after it derives
     `phase:breakdown` from the story labels.
   - The Prism Callee workflow may obtain it from `prism/roles/breakdown`.
3. Parse or normalize into the JSON shape above. Keep a key→bead-id map.
4. If the story already has children, enter reconciliation mode:
   - preserve every open and closed child and its dependencies
   - reuse tasks that already cover the design
   - create only missing implementation or verification tasks
   - never auto-delete, auto-close, or reopen a child
   - stop for human direction when the new design conflicts with completed
     work or cannot be reconciled safely
   The 3–12 rule applies to initial graph creation, not to the number of new
   tasks added during reconciliation.
5. Create required missing children **in any order**, recording ids:

```bash
bd create "<title>" --type=task --parent=<story-id> -l prism -a prism/apply/implementer \
  --description="<done-when>" --silent
# → prints bead id; map key → id
```

6. Wire only required missing dependencies (`later` depends on `earlier`):

```bash
bd dep add <later-bead-id> <earlier-bead-id>
```

7. Verify:

```bash
bd children <story-id>
bd blocked
```

8. Confirm the child graph covers the design, including actionable risks,
   constraints, and verification. Then advance the story to the human gate:

```bash
bd update <story-id> --set-labels prism,phase:human
```

## Reject

- Free-form prose without task titles
- Single mega-task that is the whole story
- Tasks that require human approval to start code (gate stays on the story)

## Stop when

- the design cannot be decomposed into small reviewable tasks
- the task graph would exceed story acceptance or design scope
- dependencies are still unclear
- existing or completed work conflicts with the repaired design

Keep the story labeled `phase:breakdown` when stopping.

## Never

- create a runtime plan file
- create a single task for the whole story
- delete, close, or reopen existing children merely to reconcile a migration
- bypass the human gate or move the story directly to `phase:apply`
