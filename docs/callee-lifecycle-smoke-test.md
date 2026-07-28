# Prism Callee Human-Step Smoke Tests

This page is for repository maintainers who validate Prism Callee locally. It
documents the existing smoke-test harness for Human-step behavior without
changing Prism entrypoints or lifecycle semantics.

## Scope

Use this page when you need a repeatable local check for the automated Human
path in the Prism Callee lifecycle.

The public automation surfaces remain:

- `prism/lifecycle`
- `prism/phases/*`

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
  diagnostics and artifacts under `/tmp` for inspection.

## Why the smoke tests need a real PTY-backed launch

The smoke-test harness requires `script(1)`, `mkfifo`, and `rg`, and it launches
the interactive Callee command through `script -qefc`. That PTY-backed path is
part of the test contract: it is how the harness reproduces the Human-step
interaction that Prism maintainers need to validate.

If you bypass the harness's PTY-backed launch, you may not reproduce the same
interactive behavior that the smoke test is designed to exercise.

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
