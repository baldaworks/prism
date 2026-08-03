# Prism Epic Roadmap phase

Run for `phase:epic:roadmap` or when a concrete architecture lacks an adequate
Story graph.

## Story graph contract

Produce or reconcile a complete, reviewable graph of direct Story children.
There is no numeric minimum or maximum. Count alone never passes or fails a graph.

The graph passes only when:

- every Epic requirement, architecture element, material risk, rollout need,
  documentation need, and integration verification has clear ownership;
- each Story is cohesive, independently approvable, and objectively verifiable;
- separable concerns are separate rather than hidden in a mega-Story;
- dependencies are necessary, explicit, and acyclic;
- existing open and closed child state is preserved during reconciliation.

One Story is valid when it fully and cohesively delivers the Epic. More than
twelve Stories are valid when each remains necessary and reviewable. An empty
graph is valid only when no actionable delivery remains and Validation is the
correct next phase.

## Normalize in Beads

Each Story description must include REQ traceability, scope, done-when,
complexity, risks and mitigations, verification, and rollback.

```bash
bd create "<story title>" --type=story --parent=<epic> \
  -l prism,phase:story:specify --description="<story contract>" --silent
bd update <new-story> --set-labels prism,phase:story:specify
bd dep add <later-story> <earlier-story>
```

The explicit label replacement is required because Beads configurations may
inherit parent labels. Never leave `phase:epic:*` on a Story child.

Reject direct Tasks and nested Epics. During reconciliation, never delete,
close, reopen, or reparent existing children automatically. Stop on conflicts
with completed work or unsafe dependency changes.

After verifying coverage, cohesion, reviewability, verifiability, and an acyclic
critical path, clear stale authorization and enter Approval:

```bash
bd update <epic> --set-labels prism,phase:epic:approval
```
