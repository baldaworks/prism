---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Public Prism Epic Frame phase. Establishes observable outcomes,
    acceptance, boundaries, constraints, non-goals, dependencies, and
    integration success without creating child work or making implementation
    changes.
  children:
    - ref: prism/epic/roles/frame
      alias: frame_executor
      input: |
        Frame one Prism Epic from the complete context below.

        {{ .Input }}
  output: |
    {{ index .State.outputs "frame_executor" }}
---
{{ .Input }}
