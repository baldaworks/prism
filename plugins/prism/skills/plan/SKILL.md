---
name: plan
description: >
  Run the Prism plan phase: decompose a designed story into child tasks and
  dependencies using the existing prism/roles/breakdown role. Use when the user
  runs $prism:plan or asks to plan a Prism story.
metadata:
  short-description: "Prism plan phase"
---

# Prism plan

Use this skill to run only the planning phase.

## Goal

- Turn the current design into a task graph of Beads child tasks.
- End with story labels `prism,phase:human`.

## Preconditions

- The story already has design markdown.
- Prism agents are available as `prism/*`.

## Commands

```bash
callee agent run prism/roles/breakdown \
  --message "Decompose into 3-12 beads tasks with dependencies. Emit a JSON tasks array with key, title, description, depends_on." \
  --param prism/roles/breakdown.project_name="<project>" \
  --param prism/roles/breakdown.constraints="3-12 small reviewable tasks; serializable deps; no scope beyond acceptance; include JSON tasks block" \
  --param prism/roles/breakdown.requirements_doc="$(bd show <story>)" \
  --param prism/roles/breakdown.design_doc="$(bd show <story>)"
```

Then follow `../lifecycle/references/breakdown.md` to create child tasks and:

```bash
bd update <story> --set-labels prism,phase:human
```

## Rules

- Public phase name is `plan`, but the internal Callee role remains `prism/roles/breakdown`.
- Do not invent tasks that are not supported by the plan output.
- Stop at the human gate after child creation.
