---
name: design
description: >
  Run the Prism design phase: generate design markdown for a Prism story using
  prism/workflows/design and persist it to Beads. Use when the user runs
  $prism:design or asks to design a Prism story.
metadata:
  short-description: "Prism design phase"
---

# Prism design

Use this skill to run only the design phase.

## Goal

- Produce design markdown from the current story state.
- Persist design output to the Beads `--design` field.
- End with story labels `prism,phase:plan`.

## Preconditions

- The story already has usable description and acceptance criteria.
- Prism agents are available as `prism/*`.

## Commands

```bash
bd show <story> --long

callee agent run prism/workflows/design --message "$(bd show <story>)" \
  | bd update <story> --design-file - --set-labels prism,phase:plan
```

## Rules

- Persist design markdown directly from stdout.
- Do not create temporary design files.
- Do not advance to apply from this skill.
