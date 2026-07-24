---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Prism design — reconstruct repository behavior, then author a design document for a beads story.
  children:
    - ref: prism/roles/explorer
      alias: explorer
      params:
        audience: Prism architect and implementers
        context: |
          Prism design phase. Reconstruct behavior needed for the story in the root prompt.
          {{ .Prompt }}
        focus_areas: paths, symbols, control flow, and state relevant to the story requirements and acceptance
        system_name: repository-under-analysis
    - ref: prism/roles/architect
      alias: architect
      input: |
        Requirements and acceptance for this Prism story (from beads):

        {{ .Prompt }}

        Behavioral model from explorer:

        {{ index .State.outputs "explorer" }}
      params:
        audience: implementing engineers and reviewers
        project_name: prism-story
        technical_context: |
          Prefer the smallest design that satisfies acceptance.
          Explorer behavioral model:

          {{ index .State.outputs "explorer" }}
  output: |
    {{ index .State.outputs "architect" }}
---
{{ .Input }}
