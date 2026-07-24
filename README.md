# Prism

Minimal **story lifecycle** for AI-assisted software work:

- **[Beads](https://github.com/steveyegge/beads)** (`bd`) — durable story, design, tasks, progress, human `approved` gate
- **[Callee](https://github.com/baldaworks/callee)** — provider agents under `prism/*` (PromptKit Roles + Sequential/Loop workflows)
- **Skill** — phase machine that orchestrates `bd` + `callee agent run prism/…`

Tagline: *Intent through a prism: story → design → tasks → apply → verify.*

## Layout

```text
.agents/skills/prism/          # host skill (Grok / agents)
  SKILL.md
  references/
    lifecycle.md               # mermaid lifecycle graph
    promptkit.md               # frozen PromptKit map + regenerate commands
    breakdown.md               # task graph → beads children
.callee/prism/
  roles/                       # PromptKit-generated Roles
  workflows/                   # design, apply, verify
```

## Prerequisites

- `bd` (Beads) initialized in the target project
- `callee` 0.16.x on `PATH` with a configured provider (Roles use `grok` by default)
- A coding host that loads project skills from `.agents/skills/` (or copy the skill into your host’s skills path)

## Install into a project

From the project root:

```bash
# skill
mkdir -p .agents/skills
cp -a /path/to/prism/.agents/skills/prism .agents/skills/

# Callee agents (required for prism/* IDs)
mkdir -p .callee
cp -a /path/to/prism/.callee/prism .callee/
```

Or as a git subtree / submodule under a vendor path, then symlink or copy into `.agents/skills/prism` and `.callee/prism`.

Validate:

```bash
callee agent list | grep prism/
callee agent validate .callee/prism/roles/interviewer.md
bd where
```

## Quick start

```bash
bd create "User can export report as CSV" \
  --type=story -l prism,phase:specify \
  --description="…" --acceptance="…" --priority=2

# design (no extra root params)
callee agent run prism/workflows/design --message "$(bd show <story>)" \
  | tee /tmp/prism-design.md
bd update <story> --design-file /tmp/prism-design.md --set-labels prism,phase:breakdown

# … breakdown → human approved → apply → verify
```

Full operator procedure: open the skill (`/prism` or load `.agents/skills/prism/SKILL.md`).

Lifecycle diagram: [references/lifecycle.md](.agents/skills/prism/references/lifecycle.md).

## Authority

- Only a **human** sets story label `approved` before apply
- Skill never invents approval or commits/pushes without explicit authority
- Durable state is **only** in beads fields / task children, not ad hoc markdown TODOs

## License

MIT — see [LICENSE](LICENSE).
