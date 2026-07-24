# Prism PromptKit references

Authoritative map of PromptKit templates, personas, binds, and runtime parameters
for Prism Callee agents under `pack/callee/prism/`.

Regenerate Roles with `callee promptkit role create` (do not hand-rewrite PromptKit
bodies). Workflows under `pack/callee/prism/workflows/` are authored Sequential/Loop
graphs that reference these Roles. After regeneration, preserve the checked-in
`spec.provider.model` / `spec.provider.reasoning` values. Repository-documentation
agents now live in the separate `pack/callee/documentation/` pack and are intentionally
excluded from this Prism lifecycle reference.

Lifecycle diagram: [lifecycle.md](lifecycle.md).

After `prism/roles/breakdown` runs, turn the plan into beads children using
[breakdown.md](breakdown.md) (JSON task graph contract).

Provider for all Roles: **`codex`** with **`model: gpt-5.4`**. The Prism reviewer pins
**`reasoning: xhigh`**.
Permissions: default / **`ask`**.

---

## Frozen Role map

| Agent ID | Kind | PromptKit template | Persona | `--prompt-param` | Author-time `--bind` | `repl` |
| --- | --- | --- | --- | --- | --- | --- |
| `prism/roles/interviewer` | Role | `collaborate-requirements-change` | `software-architect` | `change_description` | — | **true** (template `metadata.mode: interactive`) |
| `prism/roles/explorer` | Role | `reconstruct-behavior` | `reverse-engineer` | `artifact_content` | `artifact_type=code` | false |
| `prism/roles/architect` | Role | `author-design-doc` | `software-architect` | `requirements_doc` | — | false |
| `prism/roles/breakdown` | Role | `plan-implementation` | `software-architect` | `description` | — | false |
| `prism/roles/implementer` | Role | `generate-implementation-changes` | `implementation-engineer` | `spec_patch` | — | false |
| `prism/roles/reviewer` | Role | `review-code` | `systems-engineer` | `code` | — | false |

Paths on disk:

```text
pack/callee/prism/roles/interviewer.md
pack/callee/prism/roles/explorer.md
pack/callee/prism/roles/architect.md
pack/callee/prism/roles/breakdown.md
pack/callee/prism/roles/implementer.md
pack/callee/prism/roles/reviewer.md
```

### Regenerate one Role

```bash
# interviewer
callee promptkit role create prism/roles/interviewer \
  --template collaborate-requirements-change \
  --description "Prism intake: interactive requirements discovery for a beads story (description + acceptance)." \
  --provider codex \
  --prompt-param change_description \
  --persona software-architect \
  --output pack/callee/prism/roles/interviewer.md \
  --force

# explorer
callee promptkit role create prism/roles/explorer \
  --template reconstruct-behavior \
  --description "Prism design explorer: reconstruct repository behavior for a beads story design phase." \
  --provider codex \
  --prompt-param artifact_content \
  --persona reverse-engineer \
  --bind artifact_type=code \
  --output pack/callee/prism/roles/explorer.md \
  --force

# architect
callee promptkit role create prism/roles/architect \
  --template author-design-doc \
  --description "Prism design architect: author design notes stored on a beads story --design field." \
  --provider codex \
  --prompt-param requirements_doc \
  --persona software-architect \
  --output pack/callee/prism/roles/architect.md \
  --force

# breakdown
callee promptkit role create prism/roles/breakdown \
  --template plan-implementation \
  --description "Prism breakdown: implementation plan and task graph for beads story children." \
  --provider codex \
  --prompt-param description \
  --persona software-architect \
  --output pack/callee/prism/roles/breakdown.md \
  --force

# implementer
callee promptkit role create prism/roles/implementer \
  --template generate-implementation-changes \
  --description "Prism implementer: apply one claimed beads task as implementation and verification changes." \
  --provider codex \
  --prompt-param spec_patch \
  --persona implementation-engineer \
  --output pack/callee/prism/roles/implementer.md \
  --force

# reviewer
callee promptkit role create prism/roles/reviewer \
  --template review-code \
  --description "Prism reviewer: independent code review for one-task apply validation or story-level verify." \
  --provider codex \
  --prompt-param code \
  --persona systems-engineer \
  --output pack/callee/prism/roles/reviewer.md \
  --force
```

After regenerate:

```bash
callee agent validate pack/callee/prism/roles/<id>.md
callee agent view prism/roles/<id> --json
```

---

## Required runtime parameters (direct Role runs)

`{{ .Input }}` / `--message` supplies the PromptKit **prompt-param**. Other unbound
PromptKit fields become `spec.params` and must be passed as:

```bash
--param <qualified-key>=<value>
```

Inspect live keys with `callee agent view <id> --json` (authoritative if drift).

### `prism/roles/interviewer`

| Key | Description |
| --- | --- |
| `prism/roles/interviewer.context` | Additional context — system architecture, constraints, domain conventions |
| `prism/roles/interviewer.existing_artifacts` | Existing requirements, design docs, specs — paste or reference |
| `prism/roles/interviewer.project_name` | Name of the project, product, or system being changed |

### `prism/roles/explorer`

| Key | Description |
| --- | --- |
| `prism/roles/explorer.audience` | Who will read the output |
| `prism/roles/explorer.context` | Additional context about the system |
| `prism/roles/explorer.focus_areas` | Optional narrowing of analysis |
| `prism/roles/explorer.system_name` | Name of the system or component being analyzed |

`artifact_type` is author-bound to `code` (not required at runtime).

### `prism/roles/architect`

| Key | Description |
| --- | --- |
| `prism/roles/architect.audience` | Who will read the design |
| `prism/roles/architect.project_name` | Name of the project or feature |
| `prism/roles/architect.technical_context` | Existing architecture, tech stack, constraints, conventions |

### `prism/roles/breakdown`

| Key | Description |
| --- | --- |
| `prism/roles/breakdown.constraints` | Timeline, team size, technology constraints (use beads-oriented constraints) |
| `prism/roles/breakdown.design_doc` | Design document (if available) |
| `prism/roles/breakdown.project_name` | Name of the project or feature |
| `prism/roles/breakdown.requirements_doc` | Requirements document (if available) |

### `prism/roles/implementer`

| Key | Description |
| --- | --- |
| `prism/roles/implementer.context` | Build system, toolchain, domain conventions, coding standards |
| `prism/roles/implementer.implementation_artifacts` | Existing implementation context |
| `prism/roles/implementer.project_name` | Name of the project, product, or system |
| `prism/roles/implementer.verification_artifacts` | Existing tests / verification artifacts |

### `prism/roles/reviewer`

| Key | Description |
| --- | --- |
| `prism/roles/reviewer.additional_protocols` | Optional analysis protocols (or `none`) |
| `prism/roles/reviewer.context` | What the code does / known concerns |
| `prism/roles/reviewer.language` | Programming language |
| `prism/roles/reviewer.review_focus` | Focus areas (e.g. correctness, security) |

## Workflow map

| Agent ID | Kind | Children | Root required params |
| --- | --- | --- | --- |
| `prism/workflows/design` | Sequential | `explorer` → `architect` | **none** (child params bound in workflow) |
| `prism/workflows/apply` | Loop | `worker`=`implementer` ↔ `validator`=`reviewer` (`canEscalate`) | **none** |
| `prism/workflows/verify` | Sequential | `reviewer` | **none** |

Paths:

```text
pack/callee/prism/workflows/design.md
pack/callee/prism/workflows/apply.md
pack/callee/prism/workflows/verify.md
```

Root message conventions:

| Workflow | `--message` content |
| --- | --- |
| `prism/workflows/design` | `bd show <story>` dump (requirements + acceptance) |
| `prism/workflows/apply` | story dump + claimed task dump |
| `prism/workflows/verify` | story dump (acceptance + design context) |

Child `params` bindings live in the workflow Markdown frontmatter (not PromptKit).
If you change Role param names via regenerate, update workflow `params:` keys to match.

Validate trees:

```bash
callee agent validate pack/callee/prism/workflows/design.md
callee agent validate pack/callee/prism/workflows/apply.md
callee agent validate pack/callee/prism/workflows/verify.md
callee agent view prism/workflows/design --json
callee agent view prism/workflows/apply --json
callee agent view prism/workflows/verify --json
```

---

## Alternatives considered (not frozen)

Documented so future changes do not re-litigate without reason.

| Role | Chosen | Strong alternatives |
| --- | --- | --- |
| interviewer | `collaborate-requirements-change` | `author-requirements-doc` (one-shot, no REPL) |
| explorer | `reconstruct-behavior` | `reverse-engineer-requirements`, `investigate-bug` |
| architect | `author-design-doc` | `interactive-design` (REPL; format is requirements-doc) |
| breakdown | `plan-implementation` | `plan-refactoring` (refactor-only stories) |
| implementer | `generate-implementation-changes` | `author-implementation-prompt` (prompt only, not code) |
| reviewer | `review-code` + `systems-engineer` | `audit-code-compliance` + `specification-analyst` (stronger story verify); `review-code` + `security-auditor` |

---

## Catalog inspection commands

```bash
callee promptkit list --type template
callee promptkit list --type persona
callee promptkit search "<intent>" --type template
callee promptkit show <template>
callee promptkit show <template> --json
callee agent list | grep '^prism/'
```
