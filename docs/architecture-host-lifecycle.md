# Prism Full Host Lifecycle Architecture

This document defines `$prism:lifecycle`, `/prism:lifecycle`, and
`/prism-lifecycle`. The host performs the work directly and never invokes
`callee`, while preserving the behavioral contracts of the immutable Prism
Callee pack.

## Purpose

The full host lifecycle provides Callee-role semantics without a Callee runtime:

- Specify performs interviewer normalization, readiness audit, Human
  clarification, and structured extraction.
- Design performs an evidence-backed explorer pass followed by an architect pass.
- Breakdown creates a traceable implementation plan and normalized Beads graph.
- Human prepares informed approval, classifies intent, and fails closed.
- Apply alternates implementer and independent reviewer passes for one task.
- Verify performs story-level review and a close-or-bounce decision.

Prism Light is the separate concise host workflow documented in
[architecture-light-lifecycle.md](architecture-light-lifecycle.md).

## Immutable behavioral source

`pack/callee/**` is read-only. The full host references are self-contained
projections because an installed Prism plugin cannot assume the pack is present.
`docs/lifecycle-ownership.json` records, for every phase:

- ordered Callee source files and frozen SHA-256 digests;
- ordered logical role steps;
- required outputs;
- iteration limit and exhaustion behavior;
- full and Light host reference paths.

The ownership validator compares these projections and fails on any changed
Callee source. This repository task must leave the committed `pack/callee` Git
tree and working tree byte-for-byte unchanged.

## Durable state

Beads remains the only durable lifecycle store. Exactly one story label is active:

| Label | Phase |
| --- | --- |
| `phase:specify` | Specify |
| `phase:design` | Design |
| `phase:breakdown` | Breakdown |
| `phase:human` | Human approval |
| `phase:apply` | Apply |
| `phase:verify` | Verify |

`prism` marks membership and `human:approved` authorizes Apply. Story assignees
do not encode phases. Apply child tasks use `prism/apply/implementer` and
`prism/apply/reviewer`.

## Story resolution and progression

Use an explicitly named story ID, otherwise resume exactly one open Prism story,
otherwise create a new story from raw intent with `prism,phase:specify`.
Successful Specify, Design, and Breakdown phases advance continuously into the
informed Human request. Human clarification inside Specify is not approval.

## Logical role execution

One host session executes the roles sequentially. Role separation is logical:

- every pass has its own inputs, required outputs, and gate;
- Design architect consumes the explorer evidence;
- Apply reviewer re-reads actual files, diff, tests, story, and design rather
  than trusting the implementer narrative;
- failed review feeds actionable findings into the next implementer pass;
- Specify and Apply allow at most five unsuccessful iterations and fail closed.

This preserves behavior and evidence boundaries without claiming separate
provider processes.

## Human authority

Before approval, present Design summary → Task summary → Approval request.
Classify the response as APPROVE, REFINE_DESIGN, or WITHHOLD. Only unambiguous
APPROVE persists `human:approved`. Refinement clears approval, returns to Design,
and preserves children. Ambiguity remains at Human.

## Hard rules

- Never invoke `callee agent run prism/...`.
- Never modify `pack/callee/**`.
- Never weaken or skip a mapped role output or gate.
- Never implement without persisted and re-read approval.
- Claim only one ready child of the current story.
- Verify never repairs implementation.
- Do not close tasks or stories with failing checks or unresolved findings.

## File boundaries

| Concern | Location |
| --- | --- |
| Namespaced full host skill | `plugins/prism/skills/lifecycle/` |
| Flat full host skill | `plugins/prism/prefixed-skills/prism-lifecycle/` |
| Light host skill | `plugins/prism/skills/light/` |
| Machine-checkable projection | `docs/lifecycle-ownership.json` |
| Immutable source | `pack/callee/` |

## Validation

```sh
./scripts/validate-lifecycle-ownership.sh
./scripts/test-lifecycle-drift-detection.sh
./scripts/validate-plugin-packaging.sh
```
