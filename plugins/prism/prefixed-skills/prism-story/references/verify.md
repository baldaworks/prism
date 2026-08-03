# Prism full verify phase

Run for `phase:story:verify` or an approved story with no open children.

## Contract projection

```json
{
  "id": "verify-v1",
  "steps": ["story-reviewer", "close-or-bounce"],
  "required_outputs": ["acceptance-and-design-review", "severity-ranked-findings", "tests-regressions-and-security", "close-or-phase-specific-bounce"],
  "max_iterations": 1,
  "on_exhausted": "bounce"
}
```

## Inputs

- `bd show <story> --long`
- `bd children <story>`
- final working tree, diff/history, tests, and repository instructions

## Role 1: story reviewer

Independently inspect the implementation against every REQ ID, acceptance
criterion, design decision, invariant, risk, and closed child:

- confirm actual behavior rather than trusting task closure or summaries;
- inspect relevant tests and run repository-native checks;
- check correctness, error paths, regressions, security, data integrity,
  compatibility, maintainability, and missing verification;
- report every finding with severity, location, evidence, impact, and repair;
- identify the three most important repairs when findings exist.

Clearly state whether the story is acceptable to close.

## Role 2: close-or-bounce

Close only when all acceptance is satisfied and no follow-up is required:

```bash
bd close <story> --reason="Acceptance met"
```

Otherwise keep it open and route to the earliest defective phase:

```bash
# implementation gap
bd update <story> --set-labels prism,phase:story:apply,human:approved

# task coverage gap
bd update <story> --set-labels prism,phase:story:breakdown

# design gap
bd update <story> --set-labels prism,phase:story:design

# requirements gap
bd update <story> --set-labels prism,phase:story:specify
```

Create or reopen child work only after selecting the appropriate earlier phase.
Clear approval for Breakdown, Design, or Specify. Verify never performs repairs.

## Stop when

- any finding requires follow-up;
- checks or acceptance evidence are incomplete;
- the story has an open child;
- the correct bounce phase has been persisted.

## Never

- implement or edit code during Verify;
- close with unresolved findings;
- preserve approval when bouncing before Apply;
- modify `pack/callee/**`.
