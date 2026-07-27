# Prism

Prism is a story lifecycle for software changes:

- **Beads** stores the story, design, tasks, dependencies, and progress.
- **Callee** runs the `prism/*` agents that move the story forward.
- **Prism plugin skills** give users a simple command to advance the lifecycle from their host tool.

Tagline: *Intent through a prism: story -> design -> tasks -> apply -> verify.*

## What You Get

Prism helps you move a change through a small, explicit workflow:

1. Capture a story with description and acceptance criteria.
2. Generate a design.
3. Break the design into child tasks.
4. Wait for human approval.
5. Apply one task at a time.
6. Verify the story before closing it.

The normal user-facing entrypoint is the Prism skill:

- Codex / Claude-style hosts: `$prism:lifecycle`
- Flat-slash hosts: `/prism-lifecycle`

## Before You Start

You need these tools in the target project:

- `bd` (Beads)
- `callee` `0.17.0+`
- a supported host with the Prism plugin installed

Prism has two install surfaces:

1. The **host plugin**, so your tool exposes the Prism skill.
2. The **Callee agent pack**, so `prism/*` agents exist on `callee agent list`.

You need both.

## Install the Host Plugin

### Codex

```sh
codex plugin marketplace add baldaworks/prism
codex plugin add prism@prism
```

Invoke with: `$prism:lifecycle`

### Claude Code

```sh
claude plugin marketplace add baldaworks/prism
claude plugin install prism@prism --scope user
```

Invoke with the Prism lifecycle skill under the `prism` plugin.

### Grok Build

```sh
grok plugin install 'baldaworks/prism#plugins/prism' --trust
```

Invoke with: `/prism-lifecycle`

### GitHub Copilot CLI

```sh
copilot plugin marketplace add baldaworks/prism
copilot plugin install prism@prism
```

### Cursor

```sh
agent plugin marketplace add https://github.com/baldaworks/prism.git
```

Then install **prism** from the marketplace UI and invoke `prism-lifecycle`.

### OpenCode

If your OpenCode setup does not load the plugin from a marketplace, copy the shipped flat skill:

```sh
mkdir -p .opencode/skills
cp -a plugins/prism/prefixed-skills/prism-lifecycle .opencode/skills/
```

## Install the Callee Agents

For most users, the right install path is:

```sh
callee agent import baldaworks/prism \
  --path pack/callee/prism \
  --prefix prism
```

Validate the install:

```sh
callee agent list | grep '^prism/'
callee agent view prism/workflows/design --json
bd where
```

If you also want the optional documentation-maintenance workflow:

```sh
callee agent import baldaworks/prism \
  --path pack/callee/documentation \
  --prefix documentation
```

Validate:

```sh
callee agent list | grep '^documentation/'
callee agent view documentation/workflows/maintain --json
```

## Quick Start

Create a story in your project:

```sh
bd create "User can export report as CSV" \
  --type=story \
  -l prism,phase:specify \
  --description="Users can export the current report as CSV." \
  --acceptance="User can download a CSV export from the report page." \
  --priority=2
```

Then run the Prism skill from your host:

```text
$prism:lifecycle
```

or:

```text
/prism-lifecycle
```

Ask Prism to advance the current story through the next phase. Prism will inspect Beads, find the current lifecycle state, and run the appropriate `prism/*` agent.

## Lifecycle Summary

Prism advances one phase at a time:

1. `phase:specify`
2. `phase:design`
3. `phase:breakdown`
4. `phase:awaiting-human`
5. `phase:apply`
6. `phase:verify`

Rules that matter to users:

- `approved` must be set by a human before apply.
- Apply works one claimed child task at a time.
- Verify only closes the story when verification passes.

## When to Use Direct Callee Commands

Most users should use the Prism skill, not raw workflow IDs.

Direct `callee agent run prism/...` commands are mainly for:

- debugging the lifecycle
- validating a local Prism install
- advanced operator workflows

If you want the full operational behavior, see:

- `plugins/prism/skills/lifecycle/SKILL.md`
- `plugins/prism/skills/lifecycle/references/lifecycle.md`
- `plugins/prism/skills/lifecycle/references/promptkit.md`

## Optional Documentation Workflow

This repository also ships a separate documentation-maintenance workflow:

```sh
callee agent run documentation/workflows/maintain \
  --message "Maintain repository documentation so it matches the live tree."
```

This is **not** part of the Prism story lifecycle. It is optional and mainly useful for maintainers.

## Repository Notes

If you are using this repository itself as a source checkout, these paths matter:

- `plugins/prism/` contains the shipped host plugin payload.
- `pack/callee/prism/` is the source of truth for the Prism Callee pack.
- `pack/callee/documentation/` is the source of truth for the optional documentation pack.
- `.callee/*` may exist as a local discovery mirror in this repo, but `pack/callee/*` remains authoritative.

The repository also publishes marketplace metadata for multiple hosts from the repo root.

For contributor- and operator-facing details, see:

- `docs/architecture-spec.md`
- `plugins/prism/skills/lifecycle/references/lifecycle.md`
- `plugins/prism/skills/lifecycle/references/promptkit.md`

## Authority

- Only a human sets `approved` before apply.
- Prism should not invent approval.
- Commit and push require explicit human authority.

## License

MIT — see [LICENSE](LICENSE).
