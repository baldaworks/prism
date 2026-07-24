---
name: prism
description: >
  Run the Prism story lifecycle: Beads stores story, design, tasks, and progress;
  Callee agents under prism/* run intake, design, breakdown, apply, and verify.
  Use when the user runs /prism, asks to run or advance Prism, uses labels prism
  or phase:specify|design|breakdown|apply|verify, or says story → design → tasks → apply.
metadata:
  short-description: "Prism story lifecycle (beads + prism/* Callee)"
---

# Prism

Minimal story lifecycle:

| Layer | Owns |
| --- | --- |
| **Beads** | Story description, acceptance, design, task children, status, comments, human `approved` |
| **Callee `prism/*`** | Provider runs (PromptKit Roles + Sequential/Loop) |
| **This skill** | Phase machine, `bd` writes, only `callee agent run prism/…` |

Tagline: *Intent through a prism: story → design → tasks → apply → verify.*

Lifecycle diagram and phase/label map: [references/lifecycle.md](references/lifecycle.md).

## Entry

1. **Beads context:** run `bd where`. If it fails or beads context is missing/stale, follow the project **`beads`** skill (run `bd prime`, use `bd` only for durable work). Do not invent markdown TODOs.
2. Confirm Callee pack: `callee agent list | grep prism/` (expect `prism/roles/*` and `prism/workflows/*`).
3. Find work: `bd list -l prism --status=open` or `bd ready` (confirm parent is the Prism story).
4. Load: `bd show <id> --long` and `bd children <id>`.
5. Infer phase from **current** labels (table below). Prefer the most advanced `phase:*` present; ignore stale earlier phases when a later one is set.
6. Run **one** phase end-to-end, then re-check labels/children.
7. Lifecycle graph (mermaid): [references/lifecycle.md](references/lifecycle.md).
8. PromptKit regenerate / full param tables / template alternatives: [references/promptkit.md](references/promptkit.md).
9. Breakdown → beads graph rules: [references/breakdown.md](references/breakdown.md).

## Hard rules

1. **Only** `prism/roles/*` and `prism/workflows/*` — never bare `roles/*` or `workflows/*` for Prism.
2. **Beads** is the durable store for requirements, design, tasks, progress.
3. **Human gate:** do not run `prism/workflows/apply` without story label `approved` (human-only). No `bd gate` in v0.
4. **One claimed task per apply** run.
5. After every `callee agent run`: persist with `bd`, then `bd show <story>`, `bd children <story>`, `bd ready`.
6. **`--set-labels` replaces all labels** — always re-include `prism` and, after gate, `approved`.
7. **No commit/push** without explicit user authority.
8. Before direct Role runs: `callee agent view <id> --json` and pass every required `--param`.
9. After apply that changed code: run the project's usual checks when available (`task test`, else `go test ./...`, plus any checks the implementer already ran). Do not close the task if required checks fail.

## Phase → action

Use the **highest** matching phase label on the story. If labels conflict, trust artifacts (design field, children, `approved`) over stale `phase:*`.

| Condition (priority order) | Do next |
| --- | --- |
| `phase:verify` or (`approved` and no open children and apply done) | Verify → close story |
| `phase:apply` + `approved` + open child tasks | Claim one ready child → apply |
| Open child tasks exist and **no** `approved` | **Stop** — ask human for `approved` |
| `phase:awaiting-human` | **Stop** — ask human for `approved` |
| `phase:breakdown` or (design set and no children) | Breakdown → create children ([references/breakdown.md](references/breakdown.md)) |
| `phase:design` or (description/acceptance set and design empty) | Design workflow → `--design` |
| `phase:specify` or missing description/acceptance | Intake / specify |

## Labels

| Label | Meaning |
| --- | --- |
| `prism` | In this lifecycle |
| `phase:specify` | Description + acceptance |
| `phase:design` | Filling design |
| `phase:breakdown` | Creating task children |
| `phase:awaiting-human` | Waiting for human before implement |
| `phase:apply` | Implementing tasks |
| `phase:verify` | Story-level review |
| `approved` | Human allowed implement |

## Agents (summary)

Full PromptKit map, regenerate CLI, param keys: [references/promptkit.md](references/promptkit.md).

| Phase | Invoke |
| --- | --- |
| Intake assist | `prism/roles/interviewer` (+ required params) |
| Design | `prism/workflows/design` (no root params) |
| Breakdown | `prism/roles/breakdown` (+ required params) |
| Apply | `prism/workflows/apply` (no root params) |
| Verify | `prism/workflows/verify` (no root params) |

## Lifecycle commands

### 1. Intake / specify

```bash
bd create "<title>" --type=story -l prism,phase:specify \
  --description="…" --acceptance="…" --priority=2

# optional interactive interview (TTY; required params):
callee agent run prism/roles/interviewer \
  --message "<intent>" \
  --param prism/roles/interviewer.context="<constraints or none>" \
  --param prism/roles/interviewer.existing_artifacts="<or none yet>" \
  --param prism/roles/interviewer.project_name="<project>"
# paste draft → bd update --description / --acceptance

bd update <story> --set-labels prism,phase:design
```

### 2. Design

```bash
callee agent run prism/workflows/design --message "$(bd show <story>)" \
  | tee /tmp/prism-design.md
bd update <story> --design-file /tmp/prism-design.md --set-labels prism,phase:breakdown
```

Trim agent chatter from the design file if needed so `--design` holds design content only.

### 3. Breakdown

```bash
callee agent run prism/roles/breakdown \
  --message "Decompose into 3-12 beads tasks with dependencies. Emit a JSON tasks array with key, title, description, depends_on." \
  --param prism/roles/breakdown.project_name="<project>" \
  --param prism/roles/breakdown.constraints="3-12 small reviewable tasks; serializable deps; no scope beyond acceptance; include JSON tasks block" \
  --param prism/roles/breakdown.requirements_doc="$(bd show <story>)" \
  --param prism/roles/breakdown.design_doc="$(bd show <story>)"
```

**Then follow [references/breakdown.md](references/breakdown.md)** — extract JSON (or normalize), `bd create --parent`, `bd dep add`, verify children, then:

```bash
bd update <story> --set-labels prism,phase:awaiting-human
```

Do not create tasks from free-form prose alone.

### 4. Human gate (human only)

```bash
bd update <story> --set-labels prism,phase:apply,approved
```

If `approved` is missing: **stop and ask the human**. Do not apply.

### 5. Apply (repeat per task)

```bash
bd ready                    # confirm parent is this story
bd update <task> --claim
callee agent run prism/workflows/apply \
  --message "$(bd show <story>; echo; bd show <task>)"
# quality gates (when code changed):
task test 2>/dev/null || go test ./...
bd close <task> --reason="Implemented, reviewed, checks passed"
```

If checks fail: do not close the task; fix or leave notes and keep open.

### 6. Verify + close

When no open children remain:

```bash
bd update <story> --set-labels prism,phase:verify,approved
callee agent run prism/workflows/verify --message "$(bd show <story>)"
bd close <story> --reason="Acceptance met"
```

On verify failure: reopen/create tasks, return to apply (keep `approved` unless human revokes).

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
- Prefer `bd --json` when parsing.
- Do not use `bd edit` (interactive editor).
- Do not hand-edit PromptKit Role bodies; regenerate per [references/promptkit.md](references/promptkit.md).
- Generic beads workflow questions: use the **`beads`** skill; Prism only owns the story lifecycle labels and `prism/*` agents.
