# Prism Callee Human-Step Smoke Tests

This page is for repository maintainers who validate Prism Callee locally. It
documents the existing smoke-test harness for Human-step behavior without
changing Prism entrypoints or lifecycle semantics.

## Scope

Use this page when you need a repeatable local check for the automated Human
path in the Prism Callee lifecycle.

The pack-level test entrypoints are:

- `prism/lifecycle`
- `prism/story`
- `prism/epic`
- `prism/phases/*` for Story phases
- `prism/epic/phases/*` for Epic phases

Before running the harness, verify that the default catalog contains
`prism/lifecycle` as a Router and includes both `prism/story` and `prism/epic`:

```sh
callee agent view prism/lifecycle --json
callee agent view prism/story --json
callee agent view prism/epic --json
```

If the lifecycle is still a Story-only `Sequential` resource or either direct
root is missing, refresh the import before testing:

```sh
callee agent import baldaworks/prism \
  --path pack/callee/prism \
  --prefix prism \
  --force
```

`prism/lifecycle` requires a host-built envelope whose first line is
exactly `ROUTE=story` or `ROUTE=epic`. Direct graph runs are useful
only for maintainer inspection. They are not the public free-form plugin UX and
do not replace host-managed Beads resolution, persistence, or batch
coordination.

Internal IDs such as `prism/specify/questions` and `prism/specify/loop` appear
here only as maintainer-facing implementation detail for the smoke tests.

## Exact smoke-test commands

Run these commands from the repository root:

```sh
./scripts/smoke-test-callee-human.sh questions
./scripts/smoke-test-callee-human.sh specify --keep-temp
```

What they validate:

- `questions` runs `prism/specify/questions`, waits for operator input, and
  verifies that the returned artifact preserves the operator response exactly.
- `specify --keep-temp` runs `prism/phases/specify`, waits for the first
  clarification step, sends grounded answers, and treats resumed `normalizer`
  visit 2 as the success boundary. `--keep-temp` preserves the captured
  diagnostics and artifacts under `/tmp` for inspection. The provider-backed
  path allows up to 600 seconds to reach the first Human clarification; the
  shorter post-reply progress checks retain their 30-second deadlines.

## Why the smoke tests need a real PTY-backed launch

The smoke-test harness requires `script(1)`, `mkfifo`, and `rg`, and it launches
the interactive Callee command through `script -qefc`. That PTY-backed path is
part of the test contract: it is how the harness reproduces the Human-step
interaction that Prism maintainers need to validate.

If you bypass the harness's PTY-backed launch, you may not reproduce the same
interactive behavior that the smoke test is designed to exercise.

The harness prefers an installed `callee` binary. If `callee` is absent, it
falls back to `npx --yes @baldaworks/callee@0.19.0`, matching the repository's
documented Router-capable Callee baseline.

## Codex-backed local shell caveat

Prism's automated Role generation is codex-backed. In practice, `specify` or
full lifecycle runs that depend on the Codex provider may require a writable
`~/.codex`, so run them from an ordinary unsandboxed local shell if a restricted
environment blocks provider state writes there.

This is an operational caveat for local maintainer validation. It does not
change the lifecycle contract, the public entrypoints, or the smoke-test script
behavior.

## Troubleshooting

Common failures usually come from missing local prerequisites rather than Prism
workflow changes:

- missing `script(1)`
- missing `mkfifo`
- missing `rg`
- missing `callee`, with no `npx` fallback available

The harness already checks these prerequisites and fails explicitly when one is
missing.
