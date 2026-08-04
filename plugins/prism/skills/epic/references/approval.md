# Prism Epic Approval phase

Run for `phase:epic:approval` or open Story children without Epic approval.

## Gate readiness

Require usable current-Epic acceptance, concrete architecture, and a complete
Story roadmap. Missing acceptance returns to Frame; defective architecture
returns to Architecture; defective Story coverage returns to Roadmap. Clear
approval on every return.

## Approval prompt

Present exactly, in this order:

1. `### Architecture summary` — objective, approach, affected systems,
   interfaces, risks, tradeoffs, and open questions.
2. `### Story roadmap` — every Story ID/title/state, dependencies, blockers,
   critical path, and delivery order.
3. `### Approval request` — explain that approval covers this Epic architecture
   and roadmap only; every Story still requires its own implementation approval.

Do not include the Epic acceptance in this approval prompt without an explicit
operator request. The acceptance remains an internal readiness input and MUST
NOT be skipped or weakened.

Classify the latest human response as `APPROVE`, `REFINE_ARCHITECTURE`, or
`WITHHOLD`. Approval requires unambiguous authorization.

```bash
# APPROVE
bd update <epic> --set-labels prism,phase:epic:delivery,human:approved

# REFINE_ARCHITECTURE
bd update <epic> --set-labels prism,phase:epic:architecture
```

Re-read approval before Delivery. Never write `human:approved` to a child Story.
Withhold on questions, conditions, ambiguity, denial, or incomplete gate inputs.
