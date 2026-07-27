---
name: prism-lifecycle
description: >
  Run the Prism story lifecycle: Beads stores story, design, tasks, and progress;
  Callee agents under prism/* run intake, design, breakdown, apply, and verify.
  Use when the user runs /prism-lifecycle, $prism:lifecycle, /prism, asks to run or
  advance Prism, uses labels prism or phase:specify|design|breakdown|apply|verify,
  or says story → design → tasks → apply.
metadata:
  short-description: "Prism story lifecycle (beads + prism/* Callee)"
---

# Prism lifecycle

Minimal story lifecycle:

| Layer | Owns |
| --- | --- |
| **Beads** | Story description, acceptance, design, task children, status, comments, human `approved` |
| **Callee `prism/*`** | Provider runs (PromptKit Roles + Sequential/Loop) |
| **This skill** | Phase machine, `bd` writes, only `callee agent run prism/…` |

Tagline: *Intent through a prism: story → design → tasks → apply → verify.*

**Invoke:** `$prism:lifecycle` (namespaced hosts) or `/prism-lifecycle` (flat slash).

Lifecycle diagram: [references/lifecycle.md](references/lifecycle.md).
When documenting the lifecycle, preserve the **vertical** top-to-bottom phase flow; Mermaid diagrams use `flowchart TB`.

## Prerequisites (target project)

1. **`bd`** available; beads workspace in the project (`bd where` / `bd prime`). Prefer the project **beads** skill for tracker basics.
2. **`callee` 0.17.0+** on `PATH` with Codex CLI installed/authenticated (`prism/*` Roles use `codex` / `gpt-5.4`; reviewer Roles pin `xhigh`, documentation writer pins `high`).
3. **Prism agents** discoverable by Callee so `callee agent list` shows `prism/*`. If absent, install them either by importing the pack or by placing it at the local discovery path `.callee/prism`.

### Install Prism agents when absent

If `callee agent list | grep '^prism/'` returns nothing, either import the Prism pack:

```bash
callee agent import baldaworks/prism \
  --path pack/callee/prism \
  --prefix prism
```

Or install it at the local discovery path `.callee/prism`:

```bash
mkdir -p .callee
ln -sfn "<path-to-prism-root>/pack/callee/prism" .callee/prism
```

Use `callee agent import` when installing from an external Prism source. Use `.callee/prism` when the pack is already available locally via this repo, a vendored copy, a submodule, or a symlinked checkout.

Validate: `callee agent list | grep '^prism/'` and `callee agent view prism/workflows/design --json`.

## Entry

1. **Beads context:** `bd where`. If missing/stale, follow **beads** skill / `bd prime`.
2. Confirm pack: `callee agent list | grep '^prism/'`. If missing, either run `callee agent import baldaworks/prism --path pack/callee/prism --prefix prism` or install the pack at `.callee/prism`, then re-check.
3. Find work: `bd list -l prism --status=open` or `bd ready` (confirm story parent).
4. Load: `bd show <id> --long` and `bd children <id>`.
5. Infer phase from **current** labels (table below). Prefer the highest `phase:*`.
6. Run **one** phase end-to-end, then re-check labels/children.
7. Lifecycle graph: [references/lifecycle.md](references/lifecycle.md).
8. PromptKit map / regenerate: [references/promptkit.md](references/promptkit.md).
9. Breakdown → beads: [references/breakdown.md](references/breakdown.md).

## Hard rules

1. **Only** `prism/roles/*` and `prism/workflows/*` — never bare `roles/*` or `workflows/*` for Prism.
2. Keep Prism agents discoverable under `prism/*`; `callee agent import` should preserve the `prism` prefix, while repo-local copy/symlink/vendor installs should expose the pack at `.callee/prism`.
3. **Beads** is the durable store for requirements, design, tasks, progress.
4. **Human gate:** do not run `prism/workflows/apply` without story label `approved` (human-only).
5. **One claimed task per apply** run.
6. After every `callee agent run`: persist with `bd`, then `bd show`, `bd children`, `bd ready`.
7. **`--set-labels` replaces all labels** — always re-include `prism` and, after gate, `approved`.
8. **No commit/push** without explicit user authority.
9. Before direct Role runs: `callee agent view <id> --json` and pass every required `--param`.
10. After apply that changed code: run project checks (`task test` or `go test ./...`). Do not close the task if checks fail.
11. `prism/workflows/design` returns design markdown on stdout; persist it directly with `bd update --design-file -` and do not create temp files.
12. A story is ready for verify when it is `approved` and has **no open child tasks**; there is no separate `apply done` marker.
13. During apply, choose a task from `bd children <story>` and confirm it is ready/unblocked before claiming it; never claim from global `bd ready` alone.

## Phase → action

| Condition (priority order) | Do next |
| --- | --- |
| `phase:verify` or (`approved` and no open children) | Verify; close only if verification passes |
| `phase:apply` + `approved` + open child tasks | Claim one ready child → apply |
| Open child tasks exist and **no** `approved` | **Stop** — ask human for `approved` |
| `phase:awaiting-human` | **Stop** — ask human for `approved` |
| `phase:breakdown` or (design set and no children) | Breakdown → create children |
| `phase:design` or (description/acceptance set and design empty) | Design → `--design` |
| `phase:specify` or missing description/acceptance | Intake / specify |

## Labels

| Label | Meaning |
| --- | --- |
| `prism` | In this lifecycle |
| `phase:specify` … `phase:verify` | Phase cache |
| `approved` | Human allowed implement |

## Agents

| Phase | Invoke |
| --- | --- |
| Intake assist | `prism/roles/interviewer` (+ params) |
| Design | `prism/workflows/design` |
| Breakdown | `prism/roles/breakdown` (+ params) |
| Apply | `prism/workflows/apply` |
| Verify | `prism/workflows/verify` |

## Lifecycle commands

### 1. Intake / specify

```bash
bd create "<title>" --type=story -l prism,phase:specify \
  --description="…" --acceptance="…" --priority=2

callee agent run prism/roles/interviewer \
  --message "<intent>" \
  --param prism/roles/interviewer.context="<constraints or none>" \
  --param prism/roles/interviewer.existing_artifacts="<or none yet>" \
  --param prism/roles/interviewer.project_name="<project>"

bd update <story> --set-labels prism,phase:design
```

### 2. Design

```bash
callee agent run prism/workflows/design --message "$(bd show <story>)" \
  | bd update <story> --design-file - --set-labels prism,phase:breakdown
```

### 3. Breakdown

```bash
callee agent run prism/roles/breakdown \
  --message "Decompose into 3-12 beads tasks with dependencies. Emit a JSON tasks array with key, title, description, depends_on." \
  --param prism/roles/breakdown.project_name="<project>" \
  --param prism/roles/breakdown.constraints="3-12 small reviewable tasks; serializable deps; no scope beyond acceptance; include JSON tasks block" \
  --param prism/roles/breakdown.requirements_doc="$(bd show <story>)" \
  --param prism/roles/breakdown.design_doc="$(bd show <story>)"
```

Follow [references/breakdown.md](references/breakdown.md), then:

```bash
bd update <story> --set-labels prism,phase:awaiting-human
```

### 4. Human gate (human only)

```bash
bd update <story> --set-labels prism,phase:apply,approved
```

### 5. Apply

```bash
bd children <story>
bd ready
# choose one task that is both a child of <story> and ready/unblocked
bd update <task> --claim
callee agent run prism/workflows/apply \
  --message "$(bd show <story>; echo; bd show <task>)"
task test 2>/dev/null || go test ./...
bd close <task> --reason="Implemented, reviewed, checks passed"
```

If no child of `<story>` is currently ready, stop and leave the story open.

### 6. Verify + close

```bash
bd update <story> --set-labels prism,phase:verify,approved
callee agent run prism/workflows/verify --message "$(bd show <story>)"
# close only if acceptance is met and verify did not require follow-up work
bd close <story> --reason="Acceptance met"
```

If verify finds gaps, keep the story open. Reopen or create child tasks as needed and return the story to `phase:apply,approved`; if verification invalidates the plan or design, move the story back to the appropriate earlier phase instead of closing it.

## Discover

```bash
bd list -l prism --status=open
bd ready
bd show <id> --long
bd children <id>
callee agent view <prism-id> --json
```

## Safety

- Do not invent `approved` or close a story with open children.
- Do not close a story after verify unless the verify result is a pass with no follow-up work.
- Prefer `bd --json` when parsing; never `bd edit`.
- Do not hand-edit PromptKit Role bodies; regenerate per [references/promptkit.md](references/promptkit.md).
- Generic beads work: **beads** skill. Prism owns story lifecycle labels and `prism/*` agents.
