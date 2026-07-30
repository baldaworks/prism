# Prism PromptKit references

Authoritative map of PromptKit templates, personas, binds, and runtime parameters
for Prism Callee agents under `pack/callee/prism/`.

Regenerate Roles with `callee promptkit role create` (do not hand-rewrite PromptKit
bodies). Public lifecycle entrypoints now live at `pack/callee/prism/lifecycle.md`
and `pack/callee/prism/phases/*`. Internal phase-local agents under
`pack/callee/prism/<phase>/` remain authored Sequential/Loop/Human/Script graphs
that reference these Roles. After regeneration, preserve the checked-in
`spec.provider.model` / `spec.provider.reasoning` values. Repository-documentation agents now live in the
separate `pack/callee/documentation/` pack and are intentionally excluded from this
Prism lifecycle reference.

After `prism/roles/breakdown` runs, turn the plan into beads children using
the local [breakdown contract](breakdown.md).

Provider for all Roles: **`codex`**. Default role model is **`gpt-5.4`**.
Validator-style roles use **`gpt-5.3-codex-spark`**:

- `prism/specify/gate`
- `prism/roles/reviewer`
Permissions: default / **`ask`**.
The directly authored `prism/human/intent` classifier is the sole exception:
it uses `spec.permissions.mode: deny` because approval classification requires
no tools and must fail closed.

## Contents

- [Frozen Role map](#frozen-role-map)
- [Required runtime parameters](#required-runtime-parameters-direct-role-runs)
- [Workflow map](#workflow-map)
- [Alternatives considered](#alternatives-considered-not-frozen)
- [Catalog inspection commands](#catalog-inspection-commands)

## Frozen Role map

| Agent ID | Kind | PromptKit template | Persona | `--prompt-param` | Author-time `--bind` | `repl` |
| --- | --- | --- | --- | --- | --- | --- |
| `prism/roles/interviewer` | Role | `author-requirements-doc` | `software-architect` | `description` | — | false |
| `prism/specify/gate` | Role | `audit-spec-invariants` | `specification-analyst` | `spec_content` | — | false |
| `prism/roles/explorer` | Role | `reconstruct-behavior` | `reverse-engineer` | `artifact_content` | `artifact_type=code` | false |
| `prism/roles/architect` | Role | `author-design-doc` | `software-architect` | `requirements_doc` | — | false |
| `prism/roles/breakdown` | Role | `plan-implementation` | `software-architect` | `description` | — | false |
| `prism/roles/implementer` | Role | `generate-implementation-changes` | `implementation-engineer` | `spec_patch` | — | false |
| `prism/roles/reviewer` | Role | `review-code` | `systems-engineer` | `code` | — | false |

Paths on disk:

```text
pack/callee/prism/roles/interviewer.md
pack/callee/prism/specify/gate.md
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
  --template author-requirements-doc \
  --description "Prism specify normalizer: produce a design-ready requirements document when the current story context is sufficient, otherwise identify only the missing requirement dimensions needed for follow-up." \
  --provider codex \
  --model gpt-5.4 \
  --prompt-param description \
  --persona software-architect \
  --output pack/callee/prism/roles/interviewer.md \
  --force

# specify_gate
callee promptkit role create prism/specify/gate \
  --template audit-spec-invariants \
  --description "Prism specify gate: audit a candidate requirements document against design-readiness invariants, escalate when the story is sufficiently specified for design, otherwise return only the missing requirement dimensions and follow-up questions." \
  --provider codex \
  --model gpt-5.3-codex-spark \
  --prompt-param spec_content \
  --persona specification-analyst \
  --output pack/callee/prism/specify/gate.md \
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
  --description "Prism design architect: author design markdown for later persistence to a beads story --design field." \
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
  --model gpt-5.3-codex-spark \
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
| `prism/roles/interviewer.audience` | Who will read the output |
| `prism/roles/interviewer.context` | Additional context — existing system, constraints, stakeholders |
| `prism/roles/interviewer.project_name` | Name of the project or feature |

### `prism/specify/gate`

| Key | Description |
| --- | --- |
| `prism/specify/gate.audience` | Who will read the audit output |
| `prism/specify/gate.context` | Additional context about the system and gate policy |
| `prism/specify/gate.invariants` | Design-readiness invariants the candidate requirements doc must satisfy |
| `prism/specify/gate.project_name` | Name of the project or feature |

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

### Public Callee surface

| Agent ID | Kind | Semantic role |
| --- | --- | --- |
| `prism/lifecycle` | Sequential | Root lifecycle graph for specify → design → breakdown → human → apply → verify |
| `prism/phases/specify` | Sequential | Public specify phase entrypoint |
| `prism/phases/design` | Sequential | Public design phase entrypoint |
| `prism/phases/breakdown` | Sequential | Public breakdown phase entrypoint for stories assigned to `prism/breakdown` |
| `prism/phases/human` | Sequential | Public human approval gate that collects approval through a Human agent |
| `prism/phases/apply` | Sequential | Public apply phase entrypoint delegating to the one-task loop |
| `prism/phases/verify` | Sequential | Public verify phase entrypoint delegating to the close-or-bounce review |

### Internal execution layer

| Agent ID | Kind | Children | Root required params |
| --- | --- | --- | --- |
| `prism/specify/loop` | Loop | `normalizer`=`interviewer` → `gate`=`specify/gate` (`canEscalate`) → `clarifications`=`specify/questions` | **none** (child params bound in workflow) |
| `prism/specify/questions` | Human | operator answers to the gate's follow-up questions | **none** |
| `prism/specify/extract` | Script | final requirements document extractor | **none** |
| `prism/design/flow` | Sequential | `explorer` → `architect` | **none** (child params bound in workflow) |
| `prism/human/prompt` | Human | operator approval prompt | **none** |
| `prism/human/intent` | Role | fail-closed free-form approval intent classifier | **none** |
| `prism/human/check` | Script | exact classifier decision validator | **none** |
| `prism/apply/loop` | Loop | `worker`=`implementer` ↔ `validator`=`reviewer` (`canEscalate`) | **none** |
| `prism/verify/review` | Sequential | `reviewer` | **none** |

Paths:

```text
pack/callee/prism/specify/loop.md
pack/callee/prism/specify/questions.md
pack/callee/prism/specify/extract.md
pack/callee/prism/design/flow.md
pack/callee/prism/human/prompt.md
pack/callee/prism/human/intent.md
pack/callee/prism/human/check.md
pack/callee/prism/apply/loop.md
pack/callee/prism/verify/review.md
```

Root message conventions:

| Workflow | `--message` content |
| --- | --- |
| `prism/specify/loop` | `bd show <story>` dump plus any current intent / constraints |
| `prism/design/flow` | `bd show <story>` dump (requirements + acceptance) |
| `prism/phases/human` | prepared Design summary → Task summary → Approval request from `bd show`, `bd children`, and `bd blocked` |
| `prism/apply/loop` | story dump + claimed task dump |
| `prism/verify/review` | story dump (acceptance + design context) |

Child `params` bindings live in the workflow Markdown frontmatter (not PromptKit).
If you change Role param names via regenerate, update workflow `params:` keys to match.

Validate trees:

```bash
callee agent validate pack/callee/prism/design/flow.md
callee agent validate pack/callee/prism/lifecycle.md
callee agent validate pack/callee/prism/phases/specify.md
callee agent validate pack/callee/prism/phases/design.md
callee agent validate pack/callee/prism/phases/breakdown.md
callee agent validate pack/callee/prism/phases/human.md
callee agent validate pack/callee/prism/phases/apply.md
callee agent validate pack/callee/prism/phases/verify.md
callee agent validate pack/callee/prism/human/prompt.md
callee agent validate pack/callee/prism/human/intent.md
callee agent validate pack/callee/prism/human/check.md
callee agent validate pack/callee/prism/apply/loop.md
callee agent validate pack/callee/prism/verify/review.md
callee agent view prism/lifecycle --json
callee agent view prism/phases/specify --json
callee agent view prism/phases/design --json
callee agent view prism/phases/breakdown --json
callee agent view prism/phases/human --json
callee agent view prism/phases/apply --json
callee agent view prism/phases/verify --json
callee agent view prism/human/prompt --json
callee agent view prism/human/intent --json
callee agent view prism/human/check --json
callee agent view prism/design/flow --json
callee agent view prism/apply/loop --json
callee agent view prism/verify/review --json
```

---

## Alternatives considered (not frozen)

Documented so future changes do not re-litigate without reason.

| Role | Chosen | Strong alternatives |
| --- | --- | --- |
| interviewer | `author-requirements-doc` | `collaborate-requirements-change` (interactive workshop / patch workflow) |
| specify_gate | `audit-spec-invariants` | `audit-spec-alignment`, `audit-traceability` |
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
