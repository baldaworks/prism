# Prism full breakdown phase

Run only for `phase:story:breakdown` or when a concrete design lacks adequate children.

## Contract projection

```json
{
  "id": "breakdown-v1",
  "steps": ["implementation-planner", "beads-normalizer"],
  "required_outputs": ["task-ids-and-req-traceability", "acceptance-complexity-risks-and-verification", "dependencies-and-critical-path", "complete-reviewable-child-graph"],
  "max_iterations": 1,
  "on_exhausted": "fail"
}
```

## Inputs

- `bd show <story> --long`
- `bd children <story>`
- the structured requirements and saved design
- current repository/tooling constraints

## Role 1: implementation planner

Produce an ordered implementation plan with stable `TASK-<NNN>` identifiers.
Every task must contain:

- scope and done-when acceptance;
- addressed REQ IDs and relevant design sections;
- dependencies;
- Small/Medium/Large complexity;
- risks and mitigations;
- verification and rollback.

Include a dependency graph, identify the critical path, cover material plan
risks, and include integration/final verification. There is no numeric minimum
or maximum. Accept a graph only when it completely covers requirements and
design, each task is cohesive and objectively verifiable, separable concerns
are separate, and dependencies are necessary and acyclic. One task is valid
when it fully and cohesively represents the work; more than twelve are valid
when every task remains necessary and reviewable. Reject incomplete graphs and
separable mega-tasks regardless of count. Do not invent work outside scope.

## Role 2: Beads normalizer

Normalize the plan before writes:

```json
{
  "tasks": [
    {
      "key": "TASK-001",
      "title": "Action-oriented title",
      "description": "REQ traceability; scope; done-when; complexity; risks; verification; rollback.",
      "depends_on": []
    }
  ]
}
```

Create children with the detailed task description:

```bash
bd create "<title>" --type=task --parent=<story> -l prism \
  -a prism/apply/implementer --description="<full task contract>" --silent
bd update <new-task> --set-labels prism
bd dep add <later-id> <earlier-id>
```

The explicit task-label replacement removes any phase label inherited from the
Story parent.

For an existing graph, preserve every open/closed child and dependency, reuse
sufficient coverage, and create only missing work. Stop on conflict with
completed work. Never auto-delete, close, or reopen children.

## Quality gate and persistence

Verify with `bd children <story>` and `bd blocked` that:

- every REQ/design element has task coverage;
- every task is independently reviewable and testable;
- dependencies are acyclic and the critical path is represented;
- risks, migrations, documentation, and verification have actionable coverage.

Then enter Human:

```bash
bd update <story> --set-labels prism,phase:story:human
```

## Stop when

- design or requirements are incomplete;
- task scope, dependencies, or traceability remain unclear;
- a safe reconciliation is impossible.

## Never

- create a mega-task or runtime plan file;
- omit task acceptance, complexity, risk, verification, or rollback;
- bypass Human or move directly to Apply;
- modify `pack/callee/**`.
