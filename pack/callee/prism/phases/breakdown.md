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
          Story phase assignee: prism/breakdown.
          Produce 3-12 small reviewable Beads tasks with explicit dependencies.
        design_doc: |
          {{ .Input }}
        project_name: prism-story
        requirements_doc: |
          {{ .Input }}
  output: |
    {{ index .State.outputs "breakdown_executor" }}
---
{{ .Input }}
