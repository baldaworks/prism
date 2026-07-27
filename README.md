# Prism

**Host plugin + Callee pack repository** for a minimal **story lifecycle**:

- **[Beads](https://github.com/steveyegge/beads)** (`bd`) stores durable story, design, task, dependency, and progress state.
- **[Callee](https://github.com/baldaworks/callee)** runs the provider agents under `prism/*` and `documentation/*`.
- **Skill** `$prism:lifecycle` / `/prism-lifecycle` advances the Prism story lifecycle over `bd` + `callee`.

Tagline: *Intent through a prism: story → design → tasks → apply → verify.*

This repository is a **standalone marketplace** at the repo root. Root-level marketplace manifests live under `.grok-plugin/`, `.claude-plugin/`, `.agents/plugins/`, `.cursor-plugin/`, and `.github/plugin/`. For Codex, the repo-level marketplace entry is `.agents/plugins/marketplace.json`, while the shipped plugin payload keeps its host manifest at `plugins/prism/.codex-plugin/plugin.json`. The shipped host plugin lives at `plugins/prism/` and currently exposes one lifecycle skill in two host-facing layouts:

- `plugins/prism/skills/lifecycle/` for namespaced hosts such as Codex and Claude
- `plugins/prism/prefixed-skills/prism-lifecycle/` for flat-slash hosts such as Grok and Cursor

The story-lifecycle Callee pack lives at `pack/callee/prism/` and is installed into consumer projects as `.callee/prism/`. A separate repository-documentation pack lives at `pack/callee/documentation/` and installs as `.callee/documentation/`.

## Layout

```text
.
├── plugins/prism/                       # host plugin payload
│   ├── skills/lifecycle/                # canonical namespaced skill → $prism:lifecycle
│   ├── prefixed-skills/prism-lifecycle/ # flat slash skill → /prism-lifecycle
│   ├── .codex-plugin/plugin.json
│   ├── .claude-plugin/plugin.json
│   ├── .cursor-plugin/plugin.json
│   ├── .grok-plugin/plugin.json
│   └── .plugin/plugin.json
├── pack/callee/prism/                   # story-lifecycle Callee pack for consumer repos
│   ├── roles/                           # interviewer, explorer, architect, breakdown,
│   │                                    # implementer, reviewer
│   └── workflows/                       # design, apply, verify
├── pack/callee/documentation/           # documentation-maintenance Callee pack
│   ├── roles/                           # writer, reviewer
│   └── workflows/                       # maintain
├── .callee/                             # checked-in local Callee discovery mirror
│   ├── prism/                           # mirrors pack/callee/prism/ for local discovery
│   └── documentation/                   # mirrors pack/callee/documentation/ for local discovery
├── .agents/plugins/marketplace.json     # Codex marketplace entry
├── .claude-plugin/marketplace.json
├── .cursor-plugin/marketplace.json
├── .github/plugin/marketplace.json      # GitHub Copilot CLI marketplace entry
├── .grok-plugin/marketplace.json
└── docs/architecture-spec.md            # operator-facing repository architecture spec
```

This working tree also includes `.callee/prism/` and `.callee/documentation/` as a local discovery mirror of `pack/callee/*`. Treat `pack/callee/*` as the source of truth, maintain those paths first, and then resync the `.callee/*` mirror if needed.

## Documentation

- Repository overview and install notes: `README.md`
- Operator-facing architecture and workflow boundaries: `docs/architecture-spec.md`
- Story lifecycle reference: `plugins/prism/skills/lifecycle/references/lifecycle.md`
- PromptKit role and workflow map: `plugins/prism/skills/lifecycle/references/promptkit.md`

When repository documentation describes lifecycle behavior or workflow flow, the lifecycle must be shown as a **vertical top-to-bottom sequence**. Mermaid diagrams in this repository use `flowchart TB` for that requirement.

## Install the host plugin

### Grok Build

```sh
grok plugin install 'baldaworks/prism#plugins/prism' --trust
```

Invoke: `/prism-lifecycle`

### Codex

```sh
codex plugin marketplace add baldaworks/prism
codex plugin add prism@prism
```

Invoke: `$prism:lifecycle`

### Claude Code

```sh
claude plugin marketplace add baldaworks/prism
claude plugin install prism@prism --scope user
```

Invoke: namespaced skill under the prism plugin (see host help).

### GitHub Copilot CLI

```sh
copilot plugin marketplace add baldaworks/prism
copilot plugin install prism@prism
```

### Cursor

```sh
agent plugin marketplace add https://github.com/baldaworks/prism.git
```

Install **prism** from the marketplace UI; invoke the `prism-lifecycle` skill.

### OpenCode

Copy skills from the plugin into OpenCode skill paths (marketplace load may vary by version):

```sh
# example: project-local
mkdir -p .opencode/skills
cp -a plugins/prism/prefixed-skills/prism-lifecycle .opencode/skills/
```

Or install via any OpenCode plugin mechanism your version documents for GitHub marketplaces.

## Install the Callee pack into a *project*

The host plugin does **not** put agents on `callee agent list` by itself. Consumer repos need `.callee/prism/` for the Prism lifecycle and can optionally install `.callee/documentation/` for the repository-documentation maintenance workflow.

Within this repository, `pack/callee/prism/` and `pack/callee/documentation/` are authoritative. A repo-local `.callee/*` tree may exist for local Callee discovery, but contributors should not treat that mirror as the primary definition.

Set `PRISM_ROOT` to a clone of this repo (or use a submodule path).

### Variant A — copy

```sh
mkdir -p .callee
cp -a "$PRISM_ROOT/pack/callee/prism" .callee/prism
```

Optional documentation workflow:

```sh
cp -a "$PRISM_ROOT/pack/callee/documentation" .callee/documentation
```

### Variant B — symlink (track pack updates)

```sh
mkdir -p .callee
ln -sfn "$PRISM_ROOT/pack/callee/prism" .callee/prism
```

Optional documentation workflow:

```sh
ln -sfn "$PRISM_ROOT/pack/callee/documentation" .callee/documentation
```

### Variant C — git submodule + symlink

```sh
git submodule add https://github.com/baldaworks/prism.git vendor/prism
mkdir -p .callee
ln -sfn "$(pwd)/vendor/prism/pack/callee/prism" .callee/prism
```

Optional documentation workflow:

```sh
ln -sfn "$(pwd)/vendor/prism/pack/callee/documentation" .callee/documentation
```

### Variant D — sparse checkout (pack only)

```sh
git clone --filter=blob:none --sparse https://github.com/baldaworks/prism.git vendor/prism
git -C vendor/prism sparse-checkout set pack/callee/prism
mkdir -p .callee
ln -sfn "$(pwd)/vendor/prism/pack/callee/prism" .callee/prism
```

Optional documentation workflow:

```sh
# if you want both packs in the sparse checkout, include both paths
git -C vendor/prism sparse-checkout set pack/callee/prism pack/callee/documentation
ln -sfn "$(pwd)/vendor/prism/pack/callee/documentation" .callee/documentation
```

Validate:

```sh
callee agent list | grep prism/
callee agent validate .callee/prism/roles/interviewer.md
bd where
```

If you also installed the documentation pack:

```sh
callee agent list | grep documentation/
callee agent validate .callee/documentation/workflows/maintain.md
```

## Prerequisites

- `bd` (Beads) in the target project  
- `callee` 0.16.x on `PATH` with Codex CLI installed/authenticated (`prism/*` and `documentation/*` use `codex` / `gpt-5.4`; reviewer Roles pin `xhigh`, documentation writer pins `high`)  
- Human sets story label `approved` before apply  

## Quick start

```sh
bd create "User can export report as CSV" \
  --type=story -l prism,phase:specify \
  --description="…" --acceptance="…" --priority=2

callee agent run prism/workflows/design --message "$(bd show <story>)" \
  | bd update <story> --design-file - --set-labels prism,phase:breakdown
# … breakdown → human approved → apply → verify
```

Full procedure: skill body under `plugins/prism/skills/lifecycle/SKILL.md`.  
Lifecycle graph: `plugins/prism/skills/lifecycle/references/lifecycle.md`.  
PromptKit role/workflow map: `plugins/prism/skills/lifecycle/references/promptkit.md`.

## Story lifecycle workflows (Callee)

The Prism lifecycle is a **vertical** workflow: intake/specify → design → breakdown → human approval gate → apply → verify. Keep lifecycle diagrams top-to-bottom when updating documentation.

| Agent ID | Kind | Role |
| --- | --- | --- |
| `prism/workflows/design` | Sequential | explorer → architect |
| `prism/workflows/apply` | Loop | implementer ↔ reviewer |
| `prism/workflows/verify` | Sequential | reviewer (story-level) |

Direct Roles used by the lifecycle skill (outside those workflows): `prism/roles/interviewer`, `prism/roles/breakdown`.

## Documentation Maintenance Pack

Outside the story phase machine, the repository also ships a separate writer/reviewer loop for keeping docs aligned with the live tree:

```sh
callee agent run documentation/workflows/maintain \
  --message "Maintain documentation so README and operator docs match the live repository layout."
```

| Agent ID | Kind | Role |
| --- | --- | --- |
| `documentation/workflows/maintain` | Loop | `writer` ↔ `reviewer` |

This workflow is **not** part of the Prism story lifecycle and is not driven by beads phase labels; it is an optional separate pack for operators and maintainers. When this workflow updates lifecycle documentation, it must preserve the vertical top-to-bottom lifecycle requirement.

## Authority

- Only a **human** sets `approved` before apply  
- Skill does not invent approval; commit/push only with explicit authority  
- Durable state is beads only (not ad hoc markdown TODOs)  

## License

MIT — see [LICENSE](LICENSE).
