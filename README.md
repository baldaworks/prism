# Prism

Prism is a story lifecycle for software changes:

- **Beads** stores the story, design, tasks, dependencies, and progress.
- **Prism plugin skills** let a host advance the lifecycle directly in chat.
- **Prism Callee** is the optional automation surface that runs `prism/*` agents for users who want Callee-driven execution.

Tagline: *Intent through a prism: story -> design -> tasks -> apply -> verify.*

## What You Get

Prism helps you move a change through a small, explicit workflow:

1. Capture a story with description and acceptance criteria.
2. Generate a design.
3. Break the design into child tasks.
4. Collect human approval at the human gate.
5. Apply until the remaining story work is operationally closed.
6. Verify the story as a close-or-bounce decision before closing it.

The normal user-facing entrypoint is the Prism skill:

- Codex: `$prism:lifecycle`
- Claude Code: `/prism:lifecycle`
- Flat-slash hosts: `/prism-lifecycle`

The automated entrypoint follows the same split:

- Codex: `$prism-callee:lifecycle`
- Claude Code: `/prism-callee:lifecycle`
- Flat-slash hosts with the `prism-callee` plugin installed: `/prism-callee-lifecycle`

## Before You Start

For the manual host lifecycle, you need:

- [`bd` (Beads)](https://github.com/gastownhall/beads)
- a supported host with the Prism plugin installed

For the automated lifecycle, you also need:

- `callee` `0.18.0+`
- the Prism Callee agent pack installed so `prism/*` appears on `callee agent list`

Prism therefore ships two host-facing lifecycle surfaces:

1. The **`prism` plugin**, which performs lifecycle work directly in the host.
2. The **`prism-callee` plugin**, which automates lifecycle work through `prism/*`.

## Install the Host Plugin

### Codex

```sh
codex plugin marketplace add baldaworks/prism
codex plugin add prism@prism
# optional: only needed for automated Callee execution
codex plugin add prism-callee@prism
```

Invoke with:

- `$prism:lifecycle` for the main lifecycle
- `$prism-callee:lifecycle` for the automated Callee lifecycle plugin

### Claude Code

```sh
claude plugin marketplace add baldaworks/prism
claude plugin install prism@prism --scope user
# optional: only needed for automated Callee execution
claude plugin install prism-callee@prism --scope user
```

Invoke with:

- `/prism:lifecycle` for the main host-native lifecycle
- `/prism-callee:lifecycle` for the automated Callee lifecycle plugin after installing the Callee pack described below

### Grok Build

```sh
grok plugin install 'baldaworks/prism#plugins/prism' --trust
# optional: only needed for automated Callee execution
grok plugin install 'baldaworks/prism#plugins/prism-callee' --trust
```

Invoke with:

- `/prism-lifecycle` for the main lifecycle
- `/prism-callee-lifecycle` for the automated Callee lifecycle plugin

### GitHub Copilot CLI

```sh
copilot plugin marketplace add baldaworks/prism
copilot plugin install prism@prism
# optional: only needed for automated Callee execution
copilot plugin install prism-callee@prism
```

### Cursor

```sh
agent plugin marketplace add https://github.com/baldaworks/prism.git
```

Then install **prism** and, if you want automation, **prism-callee** from the
marketplace UI. Invoke `prism-lifecycle` or `prism-callee-lifecycle`.

### OpenCode

OpenCode can load these skills directly from `.opencode/skills/`. If your setup
does not install them through another compatibility path, copy the shipped flat
skills:

```sh
mkdir -p .opencode/skills
cp -a plugins/prism/prefixed-skills/prism-lifecycle .opencode/skills/
# optional: only needed for automated Callee execution
cp -a plugins/prism-callee/prefixed-skills/prism-callee-lifecycle .opencode/skills/
```

Invoke `prism-lifecycle` for the manual lifecycle or `prism-callee-lifecycle`
for the automated lifecycle.

## Install the Callee Agents

Only required for the automated lifecycle entrypoints:
`$prism-callee:lifecycle`, `/prism-callee:lifecycle`, or
`/prism-callee-lifecycle`, regardless of which supported host invokes them.

For most users, the right install path is:

```sh
callee agent import baldaworks/prism \
  --path pack/callee/prism \
  --prefix prism
```

Validate the install:

```sh
callee agent list | grep '^prism/'
callee agent view prism/lifecycle --json
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
  -a prism/interviewer \
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
/prism:lifecycle
```

or:

```text
/prism-lifecycle
```

Ask Prism to advance the current story through the next phase. Prism will inspect Beads, determine the current lifecycle state, and perform the next phase directly in the host.

If you want automation through `prism/*`, install the Callee pack and run:

```text
$prism-callee:lifecycle
```

or:

```text
/prism-callee:lifecycle
```

## Lifecycle Summary

Prism advances one phase at a time:

1. `phase:specify`
2. `phase:design`
3. `phase:plan`
4. `phase:human`
5. `phase:apply`
6. `phase:verify`

Rules that matter to users:

- `human:approved` must be set by a human before apply.
- In the automated `prism-callee` surface, the `phase:human` gate is collected through a Callee Human agent before `human:approved` is persisted.
- Beads assignee is the current phase owner.
- Host Prism derives the current phase from Beads story state; it does not expose separate host phase subskills.
- Apply closes remaining story work one ready child task at a time.
- Verify is a close-or-bounce story decision.
- `$prism:lifecycle`, `/prism:lifecycle`, and `/prism-lifecycle` perform the work directly in the host.
- `$prism-callee:lifecycle`, `/prism-callee:lifecycle`, and `/prism-callee-lifecycle` are the only Prism entrypoints that run `prism/*` Callee assets.

For the formal split between manual host behavior and automated Callee behavior,
start with:

- `docs/architecture-spec.md`
- `docs/architecture-host-lifecycle.md`
- `docs/architecture-callee-lifecycle.md`

## When to Use Direct Callee Commands

Most users should use the normal host entrypoints, not raw workflow IDs:
`$prism:lifecycle`, `/prism:lifecycle`, `/prism-lifecycle`,
`$prism-callee:lifecycle`, `/prism-callee:lifecycle`, or
`/prism-callee-lifecycle`.

Direct `callee agent run prism/...` commands are mainly for:

- debugging the lifecycle
- validating a local Prism install
- advanced operator workflows

For ordinary automated execution, prefer the host's native automated entrypoint:
`$prism-callee:lifecycle`, `/prism-callee:lifecycle`, or
`/prism-callee-lifecycle`.

If you want the full operational behavior, see:

- `docs/architecture-host-lifecycle.md` for the manual host lifecycle
- `docs/architecture-callee-lifecycle.md` for the automated `prism-callee` lifecycle

For repeatable PTY-backed smoke tests of the Callee Human path, use:

```sh
./scripts/smoke-test-callee-human.sh questions
./scripts/smoke-test-callee-human.sh specify
```

Use `--keep-temp` if you want the captured diagnostics and artifacts left under
`/tmp` for inspection.
- `plugins/prism/skills/lifecycle/SKILL.md`
- `plugins/prism-callee/skills/lifecycle/SKILL.md`
- `pack/callee/prism/lifecycle.md`

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
- `plugins/prism-callee/` contains the automated Callee lifecycle skill.
- `pack/callee/prism/` is the source of truth for the Prism Callee pack.
- `pack/callee/documentation/` is the source of truth for the optional documentation pack.
- `.callee/*` may exist as a local discovery mirror in this repo, but `pack/callee/*` remains authoritative.

The repository also publishes marketplace metadata for multiple hosts from the repo root.
The Codex and Claude plugin manifests for `prism` and `prism-callee`
should stay aligned except for host-native invocation syntax in prompts.

To validate host-plugin packaging parity after changing manifests or marketplace files, run:

```sh
./scripts/validate-plugin-packaging.sh
```

To validate the lifecycle ownership contract after changing phase, assignee, or
execution semantics, run:

```sh
./scripts/validate-lifecycle-ownership.sh
```

## Maintainer Docs

Start with the boundary docs:

- `docs/architecture-spec.md` for the repository-level boundary map
- `docs/architecture-host-lifecycle.md` for the manual host lifecycle
- `docs/architecture-callee-lifecycle.md` for the automated `prism-callee` lifecycle

Then use the surface-local sources of truth only for the surface you are editing:

- `plugins/prism/skills/lifecycle/SKILL.md`
- `plugins/prism/prefixed-skills/prism-lifecycle/SKILL.md`
- `plugins/prism/skills/lifecycle/references/lifecycle.md`
- `plugins/prism-callee/skills/lifecycle/SKILL.md`
- `plugins/prism-callee/prefixed-skills/prism-callee-lifecycle/SKILL.md`
- `plugins/prism-callee/skills/lifecycle/references/promptkit.md`

## Authority

- Only a human sets `human:approved` before apply.
- Prism should not invent approval.
- Commit and push require explicit human authority.

## License

MIT — see [LICENSE](LICENSE).
