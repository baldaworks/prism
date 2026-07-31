# Prism full human gate

Run for `phase:human` or open children without `human:approved`.

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

Confirm design and task coverage are valid, then present exactly:

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
bd update <story> --set-labels prism,phase:apply,human:approved

# REFINE_DESIGN
bd update <story> --set-labels prism,phase:design
```

For `APPROVE`, re-read and confirm both labels, then continue Apply.
For `REFINE_DESIGN`, clear approval, preserve all children/dependencies, and
stop without implementation. For `WITHHOLD`, keep `phase:human` and stop.

## Stop when

- approval is withheld or ambiguous;
- design refinement is requested;
- design/task coverage is not ready for informed approval.

## Never

- infer approval from discussion, silence, or a question;
- omit a child from the summary;
- alter child scope at the gate;
- implement before persisted and re-read approval;
- modify `pack/callee/**`.
