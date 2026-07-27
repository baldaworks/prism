---
name: specify
description: >
  Run the Prism specify phase: create or refine a Beads story's description and
  acceptance criteria, optionally using prism/roles/interviewer. Use when the
  user runs $prism:specify or asks to specify a Prism story.
metadata:
  short-description: "Prism specify phase"
---

# Prism specify

Use this skill to move a Prism story through the specify phase only.

## Goal

- Ensure the story has a clear description and acceptance criteria.
- End with story labels `prism,phase:design`.

## Preconditions

- `bd` is available and points at the target project.
- Prism Callee agents are discoverable as `prism/*`.
- The target bead is a story in the Prism lifecycle.

## Commands

```bash
bd show <story> --long

callee agent run prism/roles/interviewer \
  --message "<intent>" \
  --param prism/roles/interviewer.context="<constraints or none>" \
  --param prism/roles/interviewer.existing_artifacts="<or none yet>" \
  --param prism/roles/interviewer.project_name="<project>"

bd update <story> --set-labels prism,phase:design
```

## Rules

- Use `prism/roles/interviewer` if requirements are incomplete or ambiguous.
- Keep durable state in Beads, not in ad hoc notes.
- Do not skip directly to apply or verify from this skill.
