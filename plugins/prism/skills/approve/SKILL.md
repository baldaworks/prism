---
name: approve
description: >
  Run the Prism human gate transition: mark a planned story as authorized for
  apply by adding the human:approved tag. Use when the user runs $prism:approve
  or explicitly grants implementation authority for a Prism story.
metadata:
  short-description: "Prism human gate"
---

# Prism approve

Use this skill to perform the human authorization transition only.

## Goal

- Move the story from the human gate to the apply phase.
- Add the explicit authorization tag `human:approved`.

## Preconditions

- The story is ready for the human gate.
- A human has explicitly granted approval.

## Command

```bash
bd update <story> --set-labels prism,phase:apply,human:approved
```

## Rules

- This skill is a manual authority transition, not a PromptKit/Callee role.
- Do not use it without explicit human approval.
- Do not skip directly from planning to verify.
