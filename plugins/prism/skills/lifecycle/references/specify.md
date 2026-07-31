# Prism full specify phase

Run only for `phase:specify` or when description/acceptance is not design-ready.

## Contract projection

```json
{
  "id": "specify-v1",
  "steps": ["interviewer", "readiness-gate", "human-clarification", "requirements-extract"],
  "required_outputs": ["atomic-req-ids", "rfc2119-requirements", "per-requirement-acceptance", "constraints-and-non-goals"],
  "max_iterations": 5,
  "on_exhausted": "fail"
}
```

## Inputs

- `bd show <story> --long`
- raw user intent and subsequent clarification answers
- known system context, stakeholders, constraints, artifacts, and terminology

## Role 1: interviewer

Normalize the request into a requirements document:

1. Identify objective, actors, scope, explicit constraints, implicit assumptions,
   dependencies, conflicts, negative requirements, and non-goals.
2. Split behavior into atomic requirements with stable
   `REQ-<CATEGORY>-<NNN>` identifiers.
3. Use RFC 2119 terms precisely: MUST, MUST NOT, SHOULD, SHOULD NOT, MAY.
4. Give every requirement at least one objective acceptance criterion with
   concrete inputs/actions and expected outcomes.
5. Mark unknowns rather than silently resolving them. Do not introduce design.

## Role 2: readiness gate

Audit the candidate without rewriting it. It is ready only when:

- objective, actor, scope boundaries, terminology, constraints, and non-goals are clear;
- every requirement is atomic, unambiguous, testable, and uniquely identified;
- acceptance criteria cover success, material failure, and boundary behavior;
- conflicts, dependencies, assumptions, and unresolved product decisions are explicit;
- Design can inspect the repository without guessing product intent.

If ready, continue to extract. Otherwise produce only the minimum blocking
questions and enter Human clarification.

## Human clarification loop

Ask the blocking questions directly, merge the answer into the current candidate,
then repeat interviewer → readiness gate. Clarification never authorizes Apply
and never asks for phase-transition confirmation.

Allow at most five unsuccessful gate iterations in one lifecycle attempt. On
exhaustion, leave `phase:specify`, report the unresolved dimensions, and fail
closed instead of inventing intent.

## Requirements extract and persistence

Persist the final structured requirements across the Beads fields:

- `description`: objective, actors, scope, assumptions, constraints, non-goals,
  and the atomic RFC 2119 requirements with REQ IDs;
- `acceptance`: acceptance criteria grouped by their REQ IDs.

Then re-read both fields. If extraction lost traceability or material context,
repair it before advancing.

```bash
bd update <story> \
  --description="..." \
  --acceptance="..." \
  --set-labels prism,phase:design
```

## Stop when

- Human input is required;
- five iterations are exhausted;
- requirements remain contradictory or speculative;
- persistence cannot retain the required traceability.

## Never

- invent requirements, values, stakeholders, or constraints;
- omit REQ IDs or per-requirement acceptance;
- write implementation design;
- treat clarification as approval;
- modify `pack/callee/**`.
