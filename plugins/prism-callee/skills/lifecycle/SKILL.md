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
- Run successful pre-approval phases continuously, then enter the Human phase
  and present its informed approval request in the same invocation.
- Persist state after every Callee return.
- Collect approval or an explicit design-refinement decision through the Callee
  Human phase, then continue to Apply only after explicit approval.
- Resume from the story's single supported `phase:story:*` label.

## Durable lifecycle state

| Phase | Story label | Public Callee entrypoint |
| --- | --- | --- |
| Specify | `phase:story:specify` | `prism/phases/specify` |
| Design | `phase:story:design` | `prism/phases/design` |
| Breakdown | `phase:story:breakdown` | `prism/phases/breakdown` |
| Human | `phase:story:human` | `prism/phases/human` |
| Apply | `phase:story:apply` | `prism/phases/apply` |
| Verify | `phase:story:verify` | `prism/phases/verify` |

`prism` is the lifecycle membership label. `human:approved` authorizes apply.
Persist exactly one supported `phase:story:*` label on every active story.
Ignore phase-like labels outside the supported Story and Epic namespaces as
absent and never migrate them. An Epic phase on a Story fails closed. Story
assignees do not encode lifecycle phase state. Child tasks continue to use
`prism/apply/implementer` and `prism/apply/reviewer` inside the outer
`phase:story:apply` story phase.

## Prerequisites

1. **[`bd` (Beads)](https://github.com/gastownhall/beads)** and a project workspace (`bd where` / `bd prime`).
2. **`callee` 0.18.0+** on `PATH` with provider authentication.
3. Discoverable Prism agents: `callee agent list | grep '^prism/'`.

If needed, import `pack/callee/prism` under the `prism` prefix or expose it as
`.callee/prism`, then validate with `callee agent view prism/lifecycle --json`.

## Entry

1. Resolve Beads with `bd where`; follow `bd prime` when needed.
2. Confirm `prism/*` is discoverable.
3. Resolve the target story: require `issue_type=story` for an explicit ID;
   otherwise resume exactly one open Prism Story; otherwise derive a concise
   title and create a Story from the user's raw request:

   ```bash
   bd create "<derived title>" --type=story -l prism,phase:story:specify \
     --description="<raw user request>" --priority=2 --silent
   ```

   The new story starts in Specify, which normalizes acceptance criteria.
4. Load `bd show <story> --long` plus `bd children <story>`.
5. Classify phase-like labels against both supported namespaces. Ignore labels
   outside both namespaces, fail closed on an Epic phase or multiple Story
   phases, and do not fall back to assignee state. When no supported phase
   remains, replace labels with `prism,phase:story:specify`, clearing stale
   authorization. Reconcile the resulting phase with requirements, design,
   approval, and children.
6. Before direct role or workflow execution details, load [references/promptkit.md](references/promptkit.md).
7. Enter the lifecycle advance loop, persisting and re-checking after every
   Callee return. After successful Specify or Design persistence, immediately
   invoke the newly selected phase. After successful Breakdown persistence,
   immediately invoke `prism/phases/human` with the informed approval request.
   Do not ask the human to confirm any phase transition.
8. Stop the advance loop only while the Human phase awaits or returns an
   authorization or refinement decision, for another missing or blocking
   input, invalid lifecycle state, or an unresolved Callee failure. Merely
   writing `phase:story:human` is not a stop condition.

## Rules

- `$prism:*` manual skills must not invoke `callee`; this skill owns `prism/*` execution.
- `prism/lifecycle` and `prism/phases/*` are public workflow entrypoints; `prism/roles/*` and `prism/<phase>/*` are internal.
- Inspect direct role contracts with `callee agent view <id> --json` and supply every required parameter.
- Do not bypass the human gate. Persist `human:approved` only after explicit approval.
- Treat unambiguous free-form approval as explicit. The Callee human phase
  classifies intent fail-closed; only its exact `APPROVE` decision authorizes
  the host to persist the label.
- Treat an explicit request to refine the design as a durable transition back
  to `phase:story:design`, not as approval. The Callee human phase reports this as
  `REFINE_DESIGN`, and its deterministic gate stops with
  `PRISM_HUMAN_DECISION=REFINE_DESIGN`. Clear `human:approved`, preserve every
  child and dependency for Breakdown reconciliation, start no implementation,
  and stop the current invocation.
- Keep ambiguous, conditional, inquisitive, or otherwise unclear non-approval
  at `phase:story:human`.
- Ask for human input before the gate only when requirements or another
  blocking input are genuinely missing; never ask merely to confirm a
  successful pre-approval phase transition.
- Apply is the outer story loop over ready children. `prism/apply/loop` is the inner one-task implementation/review loop.
- Verify is close-or-bounce, never an implementation repair loop.
- Persist design output directly through `bd update --design-file -`.
- Run project checks after every apply iteration. Do not close a task when checks fail.
- Select only ready, unblocked children of the current story.
- Always preserve `prism` and exactly one target `phase:story:*` label in
  `--set-labels`, and preserve `human:approved` after the gate.
- Do not commit or push without explicit authority.

## Phase → action

| Condition (priority order) | Do next |
| --- | --- |
| Missing usable description or acceptance | Run specify and persist requirements |
| `phase:story:verify` or (`human:approved` and no open children) | Verify; close only on pass |
| `phase:story:apply` + `human:approved` + open children | Continue the outer apply loop |
| Open children without approval or `phase:story:human` | Run human phase; stop on non-approval |
| `phase:story:breakdown` or (design set and no children) | Run breakdown, create child graph, move to `phase:story:human` |
| `phase:story:design` or (requirements set and design empty) | Run design, persist it, move to `phase:story:breakdown` |
| `phase:story:specify` | Run specify, persist requirements, move to `phase:story:design` |

## Lifecycle commands

### Specify

```bash
bd create "<title>" --type=story -l prism,phase:story:specify \
  --description="…" --acceptance="…" --priority=2
callee agent run prism/phases/specify --message "$(bd show <story>)"
bd update <story> --description="…" --acceptance="…" \
  --set-labels prism,phase:story:design
```

### Design

```bash
callee agent run prism/phases/design --message "$(bd show <story>)" \
  | bd update <story> --design-file - --set-labels prism,phase:story:breakdown
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
bd update <story> --set-labels prism,phase:story:human
```

### Human gate

```bash
bd show <story> --long
bd children <story>
bd blocked
callee agent run prism/phases/human --message "<prepared informed-approval summary>"
```

The prepared message must be derived from those three Beads reads and use this
exact order: `### Acceptance criteria`, `### Design summary`,
`### Task summary`, `### Approval request`. The acceptance section must reproduce
the current Story's complete, untruncated acceptance field only. If acceptance
is missing or unusable, clear approval, return to `phase:story:specify`, and do
not invoke the Human phase. Cover every child and explain that one approval
covers the design and task graph. Persist approval only when the phase succeeds
with the exact `APPROVE` classifier decision.

On successful output `APPROVE`, persist authorization:

```bash
bd update <story> --set-labels prism,phase:story:apply,human:approved
```

If the command stops with
`PRISM_HUMAN_DECISION=REFINE_DESIGN`, clear approval and persist the refinement
decision instead:

```bash
bd update <story> --set-labels prism,phase:story:design
```

Preserve every existing child task, status, and dependency, then stop. The next
lifecycle invocation automatically runs Design and Breakdown, re-enters the
Human phase, and presents the refreshed approval request. On any other nonzero
outcome, stop with the story open and labeled `phase:story:human`.

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
bd update <story> --set-labels prism,phase:story:verify,human:approved
```

### Verify

```bash
callee agent run prism/phases/verify --message "$(bd show <story>)"
bd close <story> --reason="Acceptance met"
```

If verification fails, keep the story open and write the appropriate phase
label. For implementation gaps, use
`--set-labels prism,phase:story:apply,human:approved`; for task coverage gaps use
`--set-labels prism,phase:story:breakdown`; for design gaps use
`--set-labels prism,phase:story:design`; and for requirements gaps use
`--set-labels prism,phase:story:specify`.
