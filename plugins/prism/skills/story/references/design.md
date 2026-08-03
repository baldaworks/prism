# Prism full design phase

Run only for `phase:story:design` or when design is absent or invalid.

## Contract projection

```json
{
  "id": "design-v1",
  "steps": ["explorer", "architect"],
  "required_outputs": ["evidence-backed-behavior-model", "req-id-traceable-design", "interfaces-and-data-flow", "tradeoffs-security-and-verification"],
  "max_iterations": 1,
  "on_exhausted": "fail"
}
```

## Inputs

- `bd show <story> --long`
- the live repository, tests, configuration, and relevant history
- the structured REQ IDs and acceptance criteria from Specify

## Role 1: explorer

Reconstruct current behavior before proposing changes:

1. Locate relevant paths, symbols, entrypoints, dependencies, tests, and configuration.
2. Trace control and data flow through indirection to observable behavior.
3. Extract entities, states/transitions, preconditions, postconditions, error
   behavior, constraints, and invariants.
4. Cite concrete repository locations for factual claims. Separate facts,
   inferences, assumptions, and unknowns.
5. Identify coverage gaps, undefined transitions, and risks if invariants are violated.

Produce an evidence-backed behavioral model for the architect. Do not propose
the solution in this pass.

## Role 2: architect

Consume the requirements and explorer model, then author design markdown:

1. Overview and requirements summary with explicit REQ-ID references.
2. Current behavior and the evidence supporting it.
3. Proposed architecture, component responsibilities, interfaces, dependencies,
   and data flow; include text diagrams when relationships or state require them.
4. API/error contracts, data model, state management, compatibility, and migration
   behavior where relevant.
5. For every significant choice: alternatives, decision, rationale, tradeoffs,
   reversibility, and affected REQ IDs.
6. Security/trust boundaries, operational behavior, failure recovery, verification,
   risks, unknowns, and open questions.

Every design element must trace to one or more REQ IDs or be marked
`[DESIGN-ONLY]` with justification. Never fabricate missing facts.

## Quality gate and persistence

Before advancing, verify:

- every REQ ID is addressed;
- repository touch points are concrete;
- interfaces include material error behavior;
- non-trivial choices include tradeoffs;
- security, invariants, risks, compatibility, and verification are covered;
- open questions do not block safe decomposition.

Persist only the architect document:

```bash
bd update <story> --design-file - --set-labels prism,phase:story:breakdown
```

## Stop when

- explorer evidence is incomplete;
- a product decision is missing;
- REQ-to-design traceability has gaps;
- the design cannot be decomposed safely.

## Never

- skip the explorer pass;
- base factual claims on generic advice;
- silently resolve unknowns;
- decompose tasks or implement code;
- modify `pack/callee/**`.
