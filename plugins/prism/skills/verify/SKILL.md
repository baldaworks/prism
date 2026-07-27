---
name: verify
description: >
  Run the Prism verify phase: execute story-level verification with
  prism/workflows/verify and close the story only on pass. Use when the user
  runs $prism:verify or asks to verify a Prism story.
metadata:
  short-description: "Prism verify phase"
---

# Prism verify

Use this skill to run only the verify phase.

## Goal

- Verify the story after child tasks are complete.
- Close the story only if verification passes with no follow-up work.

## Preconditions

- The story has no open child tasks.
- The story still carries `human:approved`.

## Commands

```bash
bd update <story> --set-labels prism,phase:verify,human:approved
callee agent run prism/workflows/verify --message "$(bd show <story>)"
bd close <story> --reason="Acceptance met"
```

## Rules

- If verification finds implementation gaps, move back to `phase:apply,human:approved`.
- If verification invalidates the plan or design, move back to the appropriate earlier phase and clear `human:approved`.
- Do not close with open child tasks.
