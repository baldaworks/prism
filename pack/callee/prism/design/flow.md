---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Prism design — reconstruct repository behavior, then author a design document for a beads story and return that markdown as the root stdout artifact.
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
          The returned design MUST end with a complete `## Prism Impact Lens`
          table covering Product, Process, People, Planet, and Prosperity.
          Allowed qualitative ratings: positive, negative, mixed,
          not-material, unknown. Every row needs rationale/evidence; negative
          and mixed require mitigation or an explicit residual-impact
          disposition. Do not advance with unknown.
          Explorer behavioral model:

          {{ index .State.outputs "explorer" }}
  output: |
    {{ index .State.outputs "architect" }}
---
{{ .Input }}
