---
name: apply
description: >
  Run the Prism apply phase: claim one ready child task and execute
  prism/workflows/apply. Use when the user runs $prism:apply or asks to apply
  the next task for a Prism story.
metadata:
  short-description: "Prism apply phase"
---

# Prism apply

Use this skill to run exactly one apply iteration.

## Goal

- Claim one ready child task of the current story.
- Run the apply workflow.
- Execute project checks and close the task only if they pass.

## Preconditions

- The story is in `phase:apply`.
- The story has the `human:approved` tag.
- At least one child task is ready and unblocked.

## Commands

```bash
bd children <story>
bd ready
bd update <task> --claim

callee agent run prism/workflows/apply \
  --message "$(bd show <story>; echo; bd show <task>)"

task test 2>/dev/null || go test ./...
bd close <task> --reason="Implemented, reviewed, checks passed"
```

## Rules

- Only claim a ready child task of the current story.
- If checks fail, do not close the task.
- Preserve `human:approved` while the story remains in apply/verify.
