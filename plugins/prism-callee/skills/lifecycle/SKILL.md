---
name: lifecycle
description: >
  Run the automated Prism lifecycle: Beads stores durable story state while this
  skill uses Callee `prism/*` roles and workflows to advance as far as possible
  in one pass. Collect approval through a Callee Human agent at the human gate,
  then continue or stop based on that response. Use when the user runs
  $prism-callee:lifecycle, /prism-callee:lifecycle, or asks for automated Prism
  progression through Callee.
metadata:
  short-description: "Automated Prism lifecycle via Callee prism/*"
---

# Prism Callee lifecycle

This skill is the automated Prism lifecycle entrypoint. It is the only Prism
surface that may execute `callee agent run prism/...`.

PromptKit role/workflow contract: [references/promptkit.md](references/promptkit.md).

## Goal

**Invoke:** Codex `$prism-callee:lifecycle`, Claude Code `/prism-callee:lifecycle`, or flat slash `/prism-callee-lifecycle`.

- Advance the story through as many lifecycle phases as possible using the existing `prism/*` Callee roles and workflows.
- Persist durable state in Beads after every Callee return.
- Collect human approval through a Callee Human agent at the human gate, then either continue to apply or stop cleanly.
- Resume from current state when run again later.

## Shared lifecycle state

Public phases:

- `phase:specify`
- `phase:design`
- `phase:plan`
- `phase:human`
- `phase:apply`
- `phase:verify`

Permission tag:

- `human:approved`

## Prerequisites

1. **[`bd` (Beads)](https://github.com/gastownhall/beads)** available; beads workspace in the project (`bd where` / `bd prime`).
2. **`callee` 0.18.0+** on `PATH` with the required provider/auth setup.
3. Prism agents discoverable under `prism/*`. Validate with `callee agent list | grep '^prism/'`.

If `prism/*` is absent, install the pack:

```bash
callee agent import baldaworks/prism \
  --path pack/callee/prism \
  --prefix prism
```

Or expose a local mirror:

```bash
mkdir -p .callee
ln -sfn "<path-to-prism-root>/pack/callee/prism" .callee/prism
```

Validate:

```bash
callee agent list | grep '^prism/'
callee agent view prism/lifecycle --json
bd where
```

## Entry

1. Resolve Beads context with `bd where`. If missing/stale, follow `bd prime`.
2. Confirm the Prism Callee pack is discoverable with `callee agent list | grep '^prism/'`.
3. Find work with `bd list -l prism --status=open` or `bd ready`, then confirm the parent story.
4. Load state with `bd show <story> --long` and `bd children <story>`.
5. Infer the highest current `phase:*` label, but trust artifacts when labels disagree.
6. Continue advancing phases until a stop condition is reached.
7. After every `callee agent run`, persist to Beads and re-check with `bd show`, `bd children`, and `bd ready`.
8. Before direct Role or workflow execution details, load [references/promptkit.md](references/promptkit.md).

## Stop conditions

Stop the run when any of these becomes true:

- the human approval phase returns a non-approval response
- there is no story-level description/acceptance and the intake role cannot produce usable output
- there is no ready work
- the planning output cannot be normalized into the required task JSON shape
- verification completes
- apply or checks fail

## Implementation mapping

- lifecycle root -> `prism/lifecycle`
- specify -> `prism/phases/specify`
- design -> `prism/phases/design`
- breakdown -> `prism/phases/breakdown`
- human -> `prism/phases/human`
- apply -> `prism/phases/apply`
- verify -> `prism/phases/verify`
- internal executors stay under `prism/roles/*` and `prism/<phase>/*`

## Rules

- Reuse the same Beads labels and state model as `$prism:lifecycle`.
- `$prism:*` manual skills must not invoke `callee`; this skill owns all `prism/*` execution.
- Use `prism/lifecycle` and `prism/phases/*` as the public Prism automation surface.
- Keep `prism/roles/*` and `prism/<phase>/*` as internal execution structure behind that public surface.
- `prism/lifecycle` is the canonical Sequential phase graph for automated Prism execution.
- Before direct Role runs, inspect the contract with `callee agent view <id> --json` and pass every required `--param`.
- Do not bypass the human gate; collect approval through `prism/phases/human` and persist `human:approved` only after explicit approval.
- `prism/phases/apply` is the public apply entrypoint, while `prism/apply/loop` is the one-task implementer/reviewer loop behind it.
- Public apply is the outer story loop that continues claim → apply → check → close while `human:approved` remains present and another child becomes ready.
- Verify is a close-or-bounce decision phase, not an implementation repair loop.
- Persist `prism/design/flow` stdout directly with `bd update --design-file -`.
- Run project checks after every apply iteration (`task test` or `go test ./...`). Do not close the task if checks fail.
- During apply, choose only ready/unblocked children of the current story; never claim from global `bd ready` alone.
- A story is ready for verify when it is `human:approved` and has no open child tasks.
- `--set-labels` replaces all labels, so always re-include `prism` and, after the gate, `human:approved`.
- Do not commit or push without explicit user authority.
- Resume from current story state rather than restarting the lifecycle.

## Phase → action

| Condition (priority order) | Do next |
| --- | --- |
| `phase:verify` or (`human:approved` and no open children) | Verify; close only if verification passes |
| `phase:apply` + `human:approved` + open child tasks | Continue the outer story loop: choose one ready child, run apply, run checks, close it on pass, then re-check for another ready child |
| Open child tasks exist and **no** `human:approved` | Run `prism/phases/human`; on approval persist `human:approved`, otherwise stop |
| `phase:human` | Run `prism/phases/human`; on approval persist `human:approved`, otherwise stop |
| `phase:plan` or (design set and no children) | Run plan, normalize task JSON, create children, then advance to `phase:human` for Human-agent approval |
| `phase:design` or (description/acceptance set and design empty) | Run design and persist markdown, then advance to `phase:plan` |
| `phase:specify` or missing description/acceptance | Run intake/specify and persist the resulting description and acceptance |

## Lifecycle commands

### 1. Intake / specify

```bash
bd create "<title>" --type=story -a prism/interviewer -l prism,phase:specify \
  --description="…" --acceptance="…" --priority=2

callee agent run prism/phases/specify --message "$(bd show <story>)"

bd update <story> \
  --description="persist the normalized summary from the returned requirements doc" \
  --acceptance="persist the returned acceptance criteria from the requirements doc" \
  -a prism/designer \
  --set-labels prism,phase:design
```

`prism/phases/specify` now owns the clarification loop. It runs a PromptKit
normalizer, checks design-readiness, and if needed asks the operator follow-up
questions through a Callee Human step before retrying. It returns only after the
story is sufficiently specified for design or the loop exhausts.

### 2. Design

```bash
callee agent run prism/design/flow --message "$(bd show <story>)" \
  | bd update <story> --design-file - -a prism/planner --set-labels prism,phase:plan
```

### 3. Plan

```bash
callee agent view prism/roles/breakdown --json
callee agent run prism/roles/breakdown \
  --message "Decompose into 3-12 beads tasks with dependencies. Emit a JSON tasks array with key, title, description, depends_on." \
  --param prism/roles/breakdown.project_name="<project>" \
  --param prism/roles/breakdown.constraints="3-12 small reviewable tasks; serializable deps; no scope beyond acceptance; include JSON tasks block" \
  --param prism/roles/breakdown.requirements_doc="$(bd show <story>)" \
  --param prism/roles/breakdown.design_doc="$(bd show <story>)"
```

Follow `plugins/prism/skills/lifecycle/references/breakdown.md` to create child tasks and dependencies, then:

```bash
bd update <story> -a human --set-labels prism,phase:human
```

### 4. Human gate

```bash
callee agent run prism/phases/human --message "$(bd show <story>)"
bd update <story> -a prism/implementer --set-labels prism,phase:apply,human:approved
```

If the operator withholds approval or responds with anything other than `APPROVE`,
the Human phase fails closed. Stop the run and leave the story open in
`phase:human` without `human:approved`.

### 5. Apply

```bash
bd children <story>
bd ready
# choose one task that is both a child of <story> and ready/unblocked
bd update <task> -a prism/implementer
callee agent run prism/apply/loop \
  --message "$(bd show <story>; echo; bd show <task>)"
task test 2>/dev/null || go test ./...
bd update <task> -a prism/reviewer
bd close <task> --reason="Implemented, reviewed, checks passed"
```

If another child of the same story becomes ready after closing the task, repeat this apply block in the same lifecycle run. This is the outer story loop. If open children remain but no child is ready, stop and leave the story open in apply.

### 6. Verify + close

```bash
bd update <story> -a prism/reviewer --set-labels prism,phase:verify,human:approved
callee agent run prism/verify/review --message "$(bd show <story>)"
bd close <story> --reason="Acceptance met"
```

If verify finds gaps, keep the story open. Reopen or create child tasks as needed and return the story to `phase:apply,human:approved`; if verification invalidates the plan or design, move the story back to the appropriate earlier phase and clear `human:approved`.
