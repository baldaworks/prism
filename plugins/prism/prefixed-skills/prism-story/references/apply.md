# Prism full apply phase

Run only for `phase:story:apply` with `human:approved`.

## Contract projection

```json
{
  "id": "apply-v1",
  "steps": ["implementer", "independent-reviewer"],
  "required_outputs": ["req-and-change-traceable-patch", "invariant-impact", "repository-native-checks", "severity-ranked-review"],
  "max_iterations": 5,
  "on_exhausted": "fail"
}
```

## Inputs

- `bd show <story> --long`
- `bd children <story>` and `bd ready`
- one ready/unblocked child belonging to this story
- live implementation, tests, repository instructions, and saved design

Claim exactly one child for the logical implementer:

```bash
bd update <task> -a prism/apply/implementer
```

## Role 1: implementer

1. Map the task to its REQ IDs, design elements, invariants, and verification.
2. Inspect current implementation and tests before editing.
3. Make the smallest coherent code and verification changes for this task only.
4. Maintain an internal `CHG-<NNN>` ledger mapping every implementation and
   verification change to the upstream requirement/task.
5. Identify affected invariants and constraints. Stop rather than knowingly
   violate one; state explicitly when none are affected.
6. Follow repository conventions and run the relevant native checks.
7. Present changed artifacts, traceability, invariant impact, checks, and known gaps.

## Role 2: independent reviewer

Switch to a review pass. Re-read the task, requirements, design, actual diff,
affected files, and test results independently of the implementer narrative.
Review correctness, acceptance coverage, regressions, security, data integrity,
maintainability, scope, missing tests, and invariant preservation.

Report findings by severity with specific locations, evidence, impact, and an
actionable repair. State acceptance only when no material finding remains.

## Repair loop

If review finds a material defect:

1. keep the task open and assign `prism/apply/implementer`;
2. feed every finding into the next implementer pass;
3. rerun relevant checks;
4. repeat the independent reviewer pass.

Allow at most five implementer/reviewer iterations. On exhaustion, fail closed
with the story still in Apply.

When accepted:

```bash
bd update <task> -a prism/apply/reviewer
bd close <task> --reason="Implemented, independently reviewed, checks passed"
```

Then re-read story children. Continue with another ready child, stop if blocked,
or transition when none remain:

```bash
bd update <story> --set-labels prism,phase:story:verify,human:approved
```

## Stop when

- no child of the story is ready;
- checks fail;
- review findings remain after the current pass;
- five iterations are exhausted;
- implementation exposes a requirement/design/breakdown defect.

## Never

- select from global `bd ready` without verifying parentage;
- implement sibling scope;
- let the implementer self-declare review acceptance;
- close with failing checks or unresolved findings;
- modify `pack/callee/**`.
