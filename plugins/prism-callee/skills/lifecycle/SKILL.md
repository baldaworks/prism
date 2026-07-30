---
name: lifecycle
description: >
  Run the Prism lifecycle as a Callee workflow composed of specialized `prism/*`
  subagents with phase-specific roles and settings. Beads stores durable state.
  Use when the user runs $prism-callee:lifecycle, /prism-callee:lifecycle,
  /prism-callee-lifecycle, or asks to run Prism through Callee subagents.
---

# Prism Callee lifecycle

This is the only Prism surface that may execute `callee agent run prism/...`.
PromptKit role/workflow contract: [references/promptkit.md](references/promptkit.md).

## Goal

- Advance a story through `specify → design → breakdown → human → apply → verify`.
- Persist state after every Callee return.
- Collect approval through the Callee Human phase, then continue only after explicit approval.
- Resume from the story's single `phase:*` label.

## Durable lifecycle state

| Phase | Story label | Public Callee entrypoint |
| --- | --- | --- |
| Specify | `phase:specify` | `prism/phases/specify` |
| Design | `phase:design` | `prism/phases/design` |
| Breakdown | `phase:breakdown` | `prism/phases/breakdown` |
| Human | `phase:human` | `prism/phases/human` |
| Apply | `phase:apply` | `prism/phases/apply` |
| Verify | `phase:verify` | `prism/phases/verify` |

`prism` is the lifecycle membership label. `human:approved` authorizes apply.
Persist exactly one supported `phase:*` label on every open story. Story
assignees do not encode lifecycle phase state. Child tasks continue to use
`prism/apply/implementer` and `prism/apply/reviewer` inside the outer
`phase:apply` story phase.

## Prerequisites

1. **[`bd` (Beads)](https://github.com/gastownhall/beads)** and a project workspace (`bd where` / `bd prime`).
2. **`callee` 0.18.0+** on `PATH` with provider authentication.
3. Discoverable Prism agents: `callee agent list | grep '^prism/'`.

If needed, import `pack/callee/prism` under the `prism` prefix or expose it as
`.callee/prism`, then validate with `callee agent view prism/lifecycle --json`.

## Entry

1. Resolve Beads with `bd where`; follow `bd prime` when needed.
2. Confirm `prism/*` is discoverable.
3. Resolve the target story: use an explicitly named story ID, otherwise resume exactly one open Prism story, otherwise derive a concise title and create a story from the user's raw request:

   ```bash
   bd create "<derived title>" --type=story -l prism,phase:specify \
     --description="<raw user request>" --priority=2 --silent
   ```

   The new story starts in Specify, which normalizes acceptance criteria.
4. Load `bd show <story> --long` plus `bd children <story>`.
5. Derive the phase from exactly one supported `phase:*` story label. Stop on a
   missing or conflicting phase label, and do not fall back to assignee state;
   existing assignee-driven stories are intentionally unsupported. Reconcile
   with requirements, design, approval, and children.
6. Before direct role or workflow execution details, load [references/promptkit.md](references/promptkit.md).
7. Advance until a stop condition, persisting and re-checking after every Callee return.

## Rules

- `$prism:*` manual skills must not invoke `callee`; this skill owns `prism/*` execution.
- `prism/lifecycle` and `prism/phases/*` are public workflow entrypoints; `prism/roles/*` and `prism/<phase>/*` are internal.
- Inspect direct role contracts with `callee agent view <id> --json` and supply every required parameter.
- Do not bypass the human gate. Persist `human:approved` only after explicit approval.
- Treat unambiguous free-form approval as explicit. The Callee human phase
  classifies intent fail-closed; only its exact `APPROVE` decision authorizes
  the host to persist the label.
- Apply is the outer story loop over ready children. `prism/apply/loop` is the inner one-task implementation/review loop.
- Verify is close-or-bounce, never an implementation repair loop.
- Persist design output directly through `bd update --design-file -`.
- Run project checks after every apply iteration. Do not close a task when checks fail.
- Select only ready, unblocked children of the current story.
- Always preserve `prism` and exactly one target `phase:*` label in
  `--set-labels`, and preserve `human:approved` after the gate.
- Do not commit or push without explicit authority.

## Phase → action

| Condition (priority order) | Do next |
| --- | --- |
| Missing usable description or acceptance | Run specify and persist requirements |
| `phase:verify` or (`human:approved` and no open children) | Verify; close only on pass |
| `phase:apply` + `human:approved` + open children | Continue the outer apply loop |
| Open children without approval or `phase:human` | Run human phase; stop on non-approval |
| `phase:breakdown` or (design set and no children) | Run breakdown, create child graph, move to `phase:human` |
| `phase:design` or (requirements set and design empty) | Run design, persist it, move to `phase:breakdown` |
| `phase:specify` | Run specify, persist requirements, move to `phase:design` |

## Lifecycle commands

### Specify

```bash
bd create "<title>" --type=story -l prism,phase:specify \
  --description="…" --acceptance="…" --priority=2
callee agent run prism/phases/specify --message "$(bd show <story>)"
bd update <story> --description="…" --acceptance="…" \
  --set-labels prism,phase:design
```

### Design

```bash
callee agent run prism/phases/design --message "$(bd show <story>)" \
  | bd update <story> --design-file - --set-labels prism,phase:breakdown
```

Advance only when the saved design is concrete, addresses the requirements,
identifies relevant risks and verification, and is ready to decompose.

### Breakdown

Run `prism/phases/breakdown`, normalize its JSON task graph using
the local [breakdown contract](references/breakdown.md), create child tasks and
dependencies, then move the story to the human gate:

For an existing graph, reconcile instead: reuse sufficient open or closed
children, create only missing work needed by the repaired design, preserve
dependencies and statuses, and stop for human direction on conflicts. Never automatically delete, close, or reopen children.

```bash
bd update <story> --set-labels prism,phase:human
```

### Human gate

```bash
bd show <story> --long
bd children <story>
bd blocked
callee agent run prism/phases/human --message "<prepared informed-approval summary>"
bd update <story> --set-labels prism,phase:apply,human:approved
```

The prepared message must be derived from those three Beads reads and use this
exact order: `### Design summary`, `### Task summary`, `### Approval request`.
Cover every child and explain that one approval covers the design and task
graph. Persist approval only when the phase succeeds with the exact `APPROVE` classifier decision.
On non-approval or classifier failure, stop with the story open and labeled
`phase:human`.

### Apply

```bash
bd update <task> -a prism/apply/implementer
callee agent run prism/apply/loop --message "$(bd show <story>; echo; bd show <task>)"
bd update <task> -a prism/apply/reviewer
bd close <task> --reason="Implemented, reviewed, checks passed"
```

Discover and run the relevant repository-native checks before assigning review
or closing the task.

Repeat for ready children of the same story. With no open children, transition:

```bash
bd update <story> --set-labels prism,phase:verify,human:approved
```

### Verify

```bash
callee agent run prism/phases/verify --message "$(bd show <story>)"
bd close <story> --reason="Acceptance met"
```

If verification fails, keep the story open and write the appropriate phase
label. For implementation gaps, use
`--set-labels prism,phase:apply,human:approved`; for task coverage gaps use
`--set-labels prism,phase:breakdown`; for design gaps use
`--set-labels prism,phase:design`; and for requirements gaps use
`--set-labels prism,phase:specify`.
