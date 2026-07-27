---
name: lifecycle
description: >
  Run the Prism lifecycle through Callee subagents as far as possible in one
  pass. Stop at the human gate until human:approved is present, then resume from
  the current story state on the next run. Use when the user runs
  $prism-callee:lifecycle or asks for automated Prism progression through
  subagents.
metadata:
  short-description: "Automated Prism lifecycle via Callee subagents"
---

# Prism Callee lifecycle

This skill is the automated Prism lifecycle entrypoint for Codex.

## Goal

- Advance the story through as many lifecycle phases as possible using the existing `prism/*` Callee roles and workflows.
- Stop cleanly at the human gate or any other blocking condition.
- Resume from current state when run again later.

## Lifecycle model

Public phases:

- `phase:specify`
- `phase:design`
- `phase:plan`
- `phase:human`
- `phase:apply`
- `phase:verify`

Permission tag:

- `human:approved`

## Stop conditions

Stop the run when any of these becomes true:

- the story reaches `phase:human` without `human:approved`
- there is no ready work
- verification completes
- apply or checks fail

## Implementation mapping

- specify -> `prism/roles/interviewer`
- design -> `prism/workflows/design`
- plan -> existing internal `prism/roles/breakdown`
- apply -> `prism/workflows/apply`
- verify -> `prism/workflows/verify`

## Rules

- Reuse the same Beads state model and Callee assets as `$prism:lifecycle`.
- Do not bypass the human gate.
- Resume from current story state rather than restarting the lifecycle.
