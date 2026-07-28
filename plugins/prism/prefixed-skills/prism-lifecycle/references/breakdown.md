# Prism plan → beads children

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

- **3–12** tasks.
- `key` is a local id for deps only (not a beads id).
- `title` ≤ ~80 chars, action-oriented.
- `description` states **done-when** (testable).
- `depends_on` lists earlier `key`s that must complete first.
- No scope beyond story acceptance / design.
- If the plan has no extractable tasks, revise the plan or stop and ask the human — do not invent a graph.

## Host procedure (strict)

1. Produce or collect a plan in the JSON shape above.
   - The manual host lifecycle may author this plan directly in the host after it derives `phase:plan` from Beads state.
   - Automated `/prism-callee-lifecycle` may obtain it from `prism/roles/breakdown`.
2. Parse or normalize into the JSON shape above. Keep a key→bead-id map.
3. Create children **in any order**, recording ids:

```bash
bd create "<title>" --type=task --parent=<story-id> -l prism -a prism/implementer \
  --description="<done-when>" --silent
# → prints bead id; map key → id
```

4. Wire dependencies (`later` depends on `earlier`):

```bash
bd dep add <later-bead-id> <earlier-bead-id>
```

5. Verify:

```bash
bd children <story-id>
bd blocked
```

6. Advance story labels:

```bash
bd update <story-id> -a human --set-labels prism,phase:human
```

## Reject

- Free-form prose without task titles
- Single mega-task that is the whole story
- Tasks that require human approval to start code (gate stays on the story)
