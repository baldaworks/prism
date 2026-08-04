# Prism full human gate

Run for `phase:story:human` or open children without `human:approved`.

## Contract projection

```json
{
  "id": "human-v1",
  "steps": ["approval-prompt", "intent-classifier", "decision-check"],
  "required_outputs": ["design-task-approval-summary", "approve-refine-withhold", "fail-closed-authorization"],
  "max_iterations": 1,
  "on_exhausted": "withhold"
}
```

## Inputs

- `bd show <story> --long`
- `bd children <story>`
- `bd blocked`

## Role 1: approval prompt

Require complete, usable current-Story acceptance plus valid design and task
coverage. If acceptance is missing or unusable, clear approval, write
`prism,phase:story:specify`, and stop without presenting an approval request.

Otherwise present exactly:

1. `### Design summary` — objective, approach, affected areas, material risks,
   tradeoffs, and open questions.
2. `### Task summary` — every child ID/title/state plus dependencies, blockers,
   critical path, and execution order.
3. `### Approval request` — explain that one decision covers the design and
   task graph and that ordinary free-form language is accepted.

Derive every statement from current Beads state.

## Role 2: intent classifier

Classify the latest human response into exactly one internal decision:

- `APPROVE` only for unambiguous authorization to begin implementation;
- `REFINE_DESIGN` only for an explicit request to revise the design;
- `WITHHOLD` for questions, conditional language, ambiguity, discussion, or denial.

Classification uses no tools and grants no authority by itself.

## Role 3: decision check

Persist only after the classifier decision:

```bash
# APPROVE
bd update <story> --set-labels prism,phase:story:apply,human:approved

# REFINE_DESIGN
bd update <story> --set-labels prism,phase:story:design
```

For `APPROVE`, re-read and confirm both labels, then continue Apply.
For `REFINE_DESIGN`, clear approval, preserve all children/dependencies, and
stop without implementation. For `WITHHOLD`, keep `phase:story:human` and stop.

## Stop when

- approval is withheld or ambiguous;
- design refinement is requested;
- design/task coverage is not ready for informed approval.

## Never

- infer approval from discussion, silence, or a question;
- emit current-Story acceptance as part of the approval prompt without an
  explicit operator request;
- skip or weaken the internal acceptance-readiness check;
- omit a child from the summary;
- alter child scope at the gate;
- implement before persisted and re-read approval;
- modify `pack/callee/**`.
