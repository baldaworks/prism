---
name: lifecycle
description: >
  Run the automated Prism lifecycle through Callee `prism/*` workflows. Beads
  stores durable state and the story assignee is the active lifecycle phase. Use
  when the user runs $prism-callee:lifecycle, /prism-callee:lifecycle, or asks
  for automated Prism progression through Callee.
metadata:
  short-description: "Automated Prism lifecycle via Callee prism/*"
---

# Prism Callee lifecycle

This is the only Prism surface that may execute `callee agent run prism/...`.
PromptKit role/workflow contract: [references/promptkit.md](references/promptkit.md).

## Goal

- Advance a story through `specify → design → breakdown → human → apply → verify`.
- Persist state after every Callee return.
- Collect approval through the Callee Human phase, then continue only after explicit approval.
- Resume from the story's current assignee.

## Durable lifecycle state

| Phase | Story assignee | Public Callee entrypoint |
| --- | --- | --- |
| Specify | `prism/specify` | `prism/phases/specify` |
| Design | `prism/design` | `prism/phases/design` |
| Breakdown | `prism/breakdown` | `prism/phases/breakdown` |
| Human | `prism/human` | `prism/phases/human` |
| Apply | `prism/apply` | `prism/phases/apply` |
| Verify | `prism/verify` | `prism/phases/verify` |

`prism` is the lifecycle membership label. `human:approved` authorizes apply.
Never persist `phase:*` labels. Child tasks use `prism/apply/implementer` and
`prism/apply/reviewer` inside the outer `prism/apply` story phase.

Every open Prism story must have a complete `## Prism Impact Lens` in its
durable design. It covers Product, Process, People, Planet, and Prosperity with
qualitative ratings; closed stories are not migrated.

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
   bd create "<derived title>" --type=story -a prism/specify -l prism \
     --description="<raw user request>" --priority=2 --silent
   ```

   The new story starts in Specify, which normalizes acceptance criteria.
4. Load `bd show <story> --long` plus `bd children <story>`.
5. Derive the phase from story assignee; reconcile with requirements, design, approval, and children.
6. Before direct role or workflow execution details, load [references/promptkit.md](references/promptkit.md).
7. Advance until a stop condition, persisting and re-checking after every Callee return.

## Rules

- `$prism:*` manual skills must not invoke `callee`; this skill owns `prism/*` execution.
- `prism/lifecycle` and `prism/phases/*` are public automation; `prism/roles/*` and `prism/<phase>/*` are internal.
- Inspect direct role contracts with `callee agent view <id> --json` and supply every required parameter.
- Do not bypass the human gate. Persist `human:approved` only after explicit approval.
- Treat unambiguous free-form approval as explicit. The Callee human phase
  classifies intent fail-closed; only its exact `APPROVE` decision authorizes
  the host to persist the label.
- Do not advance an open story whose Impact Lens is missing, malformed, has an
  empty rationale, lacks mitigation/residual disposition for `negative` or
  `mixed`, or contains `unknown`.
- Apply is the outer story loop over ready children. `prism/apply/loop` is the inner one-task implementation/review loop.
- Verify is close-or-bounce, never an implementation repair loop.
- Persist design output directly through `bd update --design-file -`.
- Run project checks after every apply iteration. Do not close a task when checks fail.
- Select only ready, unblocked children of the current story.
- Always preserve `prism` in `--set-labels`, and preserve `human:approved` after the gate.
- Do not commit or push without explicit authority.

## Phase → action

| Condition (priority order) | Do next |
| --- | --- |
| Missing usable description or acceptance | Run specify and persist requirements |
| Open story has a missing, invalid, or `unknown` Impact Lens | Clear approval; run design, then reconcile children in breakdown |
| `prism/verify` or (`human:approved` and no open children) | Verify; close only on pass |
| `prism/apply` + `human:approved` + open children | Continue the outer apply loop |
| Open children without approval or `prism/human` | Run human phase; stop on non-approval |
| `prism/breakdown` or (design set and no children) | Run breakdown, create child graph, move to `prism/human` |
| `prism/design` or (requirements set and design empty) | Run design, persist it, move to `prism/breakdown` |
| `prism/specify` | Run specify, persist requirements, move to `prism/design` |

This migration rule precedes assignee routing. Preserve all open and closed
children and dependencies, never auto-delete or auto-close them, and clear
`human:approved`. Closed stories remain unchanged.

```bash
bd update <story> -a prism/design --set-labels prism
```

## Lifecycle commands

### Specify

```bash
bd create "<title>" --type=story -a prism/specify -l prism \
  --description="…" --acceptance="…" --priority=2
callee agent run prism/phases/specify --message "$(bd show <story>)"
bd update <story> --description="…" --acceptance="…" \
  -a prism/design --set-labels prism
```

### Design

```bash
callee agent run prism/phases/design --message "$(bd show <story>)" \
  | bd update <story> --design-file - -a prism/breakdown --set-labels prism
```

Advance only when the saved design has the exact Impact Lens heading and table,
all five dimensions, allowed ratings, rationale/evidence in each row,
mitigation or residual disposition for every `negative` or `mixed` row, and no
`unknown`.

### Breakdown

Run `prism/phases/breakdown`, normalize its JSON task graph using
`plugins/prism/skills/lifecycle/references/breakdown.md`, create child tasks and
dependencies, then move the story to the human gate:

For an existing graph, reconcile instead: reuse sufficient open or closed
children, create only missing work needed by the repaired design or actionable
Impact Lens mitigations, preserve dependencies and statuses, and stop for human
direction on conflicts. Never automatically delete, close, or reopen children.

```bash
bd update <story> -a prism/human --set-labels prism
```

### Human gate

```bash
bd show <story> --long
bd children <story>
bd blocked
callee agent run prism/phases/human --message "<prepared informed-approval summary>"
bd update <story> -a prism/apply --set-labels prism,human:approved
```

The prepared message must be derived from those three Beads reads and use this
exact order: `### Design summary`, `### Prism Impact Lens`,
`### Task summary`, `### Approval request`. Cover all five dimensions and
every child. Explain that one approval covers design, tasks, mitigations, and
disclosed residual impacts. Persist approval only when the phase succeeds with
the exact `APPROVE` classifier decision. On non-approval or classifier failure,
stop with the story open and assigned to `prism/human`.

### Apply

```bash
bd update <task> -a prism/apply/implementer
callee agent run prism/apply/loop --message "$(bd show <story>; echo; bd show <task>)"
task test 2>/dev/null || go test ./...
bd update <task> -a prism/apply/reviewer
bd close <task> --reason="Implemented, reviewed, checks passed"
```

Repeat for ready children of the same story. With no open children, transition:

```bash
bd update <story> -a prism/verify --set-labels prism,human:approved
```

### Verify

```bash
callee agent run prism/phases/verify --message "$(bd show <story>)"
bd close <story> --reason="Acceptance met"
```

If verification fails, keep the story open and return it to the appropriate
assignee. For implementation gaps, use `prism/apply` and preserve
`human:approved`; for mitigation coverage gaps use `prism/breakdown` and clear
approval; for design, Impact Lens, or requirements gaps, move to that phase and
clear approval.
