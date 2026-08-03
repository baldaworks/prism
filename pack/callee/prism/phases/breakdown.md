---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Public Prism breakdown phase entrypoint. Delegates task graph generation to the
    internal breakdown role while preserving the stable phase contract.
  children:
    - ref: prism/roles/breakdown
      alias: breakdown_executor
      input: |
        Prism breakdown phase for the same story.

        Requirements and acceptance:
        {{ .Input }}
      params:
        constraints: |
          Story phase label: phase:breakdown.
          Require a concrete design and produce a complete, reviewable Beads
          task graph with explicit dependencies. There is no numeric minimum or
          maximum: one task is valid when it fully and cohesively represents the
          work, and more than twelve are valid when every task remains necessary
          and reviewable. Reject incomplete graphs and separable mega-tasks
          regardless of count. If existing
          children are supplied, reconcile them: preserve open and closed tasks
          and dependencies, reuse coverage, create only missing work, and never
          auto-delete, close, or reopen. Cover actionable risks, constraints,
          and verification from the design. Stop if completed work conflicts
          with the repaired design.
        design_doc: |
          {{ .Input }}
        project_name: prism-story
        requirements_doc: |
          {{ .Input }}
  output: |
    {{ index .State.outputs "breakdown_executor" }}
---
{{ .Input }}
