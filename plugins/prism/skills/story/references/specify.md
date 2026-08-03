# Prism full specify phase

Run only for `phase:story:specify` or when description/acceptance is not design-ready.

## Contract projection

```json
{
  "id": "specify-v1",
  "steps": ["interviewer", "readiness-gate", "human-clarification", "requirements-extract"],
  "required_inputs": ["story-record", "raw-user-intent", "human-clarifications", "system-context"],
  "required_outputs": ["normalizer-envelope", "gate-report-envelope", "structured-requirements-document", "atomic-req-ids", "rfc2119-requirements", "per-requirement-acceptance", "constraints-and-non-goals", "epistemic-and-self-verification", "fail-closed-requirements-extract"],
  "quality_gates": ["readiness-invariants", "minimum-blocking-questions", "self-verification", "non-empty-requirements-extract"],
  "protocol": {
    "normalizer_sections": ["SPECIFY_DECISION", "MISSING_DIMENSIONS", "FOLLOW_UP_QUESTIONS", "REQUIREMENTS_DOCUMENT"],
    "gate_sections": ["SPECIFY_GATE_DECISION", "GATE_SUMMARY", "MISSING_DIMENSIONS", "FOLLOW_UP_QUESTIONS", "REQUIREMENTS_RISKS"],
    "requirements_sections": ["Pre-Authoring Analysis", "Overview", "Scope", "Definitions and Glossary", "Requirements", "Dependencies", "Assumptions", "Risks", "Revision History"],
    "epistemic_labels": ["KNOWN", "INFERRED", "ASSUMED", "UNKNOWN"],
    "human_response": "numbered-follow-ups-or-UNKNOWN",
    "extract": "non-empty-REQUIREMENTS_DOCUMENT"
  },
  "max_iterations": 5,
  "on_exhausted": "fail"
}
```

## Inputs

- `bd show <story> --long`
- raw user intent and subsequent clarification answers
- known system context, stakeholders, constraints, artifacts, and terminology

## Workflow output protocol

The interviewer/normalizer MUST return these top-level sections in this exact
order so the readiness gate and extractor can consume the result:

1. `SPECIFY_DECISION`: `READY_FOR_DESIGN` or `NEEDS_CLARIFICATION`;
2. `MISSING_DIMENSIONS`: bullets, or `- none` only when ready;
3. `FOLLOW_UP_QUESTIONS`: the minimum numbered questions, or `1. none` only
   when ready;
4. `REQUIREMENTS_DOCUMENT`: the complete structured document.

The readiness gate MUST return these top-level sections in this exact order:

1. `SPECIFY_GATE_DECISION`: `READY_FOR_DESIGN` or `NEEDS_CLARIFICATION`;
2. `GATE_SUMMARY`;
3. `MISSING_DIMENSIONS`;
4. `FOLLOW_UP_QUESTIONS`;
5. `REQUIREMENTS_RISKS`.

Each list uses its documented `none` sentinel only when the candidate is ready.
The gate may exit the loop only for `READY_FOR_DESIGN`; otherwise its report is
fed into Human clarification and then the next interviewer pass.

## Role 1: interviewer

Normalize the request into a requirements document:

1. Start with `Pre-Authoring Analysis`: identify ambiguities, implicit
   requirements, and potential conflicts without silently resolving them.
2. Identify objective, actors, scope, explicit constraints, implicit assumptions,
   dependencies, conflicts, negative requirements, and non-goals.
3. Label grounded factual claims `KNOWN`, reasoned conclusions `INFERRED`, and
   unsupported assumptions `ASSUMED` with `[ASSUMPTION]` and justification.
   Represent a required missing detail as `[UNKNOWN: <what is missing>]`. If
   assumptions exceed roughly 30% of grounded content, stop for clarification.
4. Split behavior into atomic requirements with stable
   `REQ-<CATEGORY>-<NNN>` identifiers.
5. Use RFC 2119 terms precisely: MUST, MUST NOT, SHOULD, SHOULD NOT, MAY.
6. Give every requirement at least one objective acceptance criterion with
   concrete inputs/actions and expected outcomes.
7. Do not introduce design. Before returning, re-check 3–5 claims against the
   supplied sources and confirm scope, citations, internal consistency, and
   coverage.

The content of `REQUIREMENTS_DOCUMENT` MUST begin with `Pre-Authoring Analysis`,
followed by `# <Project/Feature Name> — Requirements Document` and these numbered
sections in this exact order. Do not omit an empty section—write
`None identified` with a brief justification:

1. Overview;
2. Scope, with In Scope and Out of Scope;
3. Definitions and Glossary;
4. Requirements, split into Functional Requirements, Non-Functional
   Requirements, and Constraints identified as `CON-<NNN>`;
5. Dependencies identified as `DEP-<NNN>`;
6. Assumptions identified as `ASM-<NNN>`;
7. Risks as a table with stable risk IDs, likelihood, impact, and mitigation;
8. Revision History as a version/date/author/changes table.

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

Ask only the numbered `FOLLOW_UP_QUESTIONS`. The Human response must answer only
those items and use `UNKNOWN` for an answer it does not know. Feed the answers
and the gate findings into the next interviewer pass, merge them into the current
candidate, then repeat interviewer → readiness gate. Clarification never
authorizes Apply and never asks for phase-transition confirmation.

Allow at most five unsuccessful gate iterations in one lifecycle attempt. On
exhaustion, leave `phase:story:specify`, report the unresolved dimensions, and fail
closed instead of inventing intent.

## Requirements extract and persistence

Fail closed unless the final normalizer output contains a non-empty
`REQUIREMENTS_DOCUMENT` section. Extract only that document; do not persist the
workflow envelopes.

Persist the final structured requirements across the Beads fields:

- `description`: pre-authoring analysis, overview, actors, scope, glossary,
  functional and non-functional requirements with REQ IDs, constraints,
  dependencies, assumptions, risks, non-goals, and revision history;
- `acceptance`: acceptance criteria grouped by their REQ IDs.

Then re-read both fields. If extraction lost traceability or material context,
repair it before advancing.

```bash
bd update <story> \
  --description="..." \
  --acceptance="..." \
  --set-labels prism,phase:story:design
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
