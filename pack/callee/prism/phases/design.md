---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Public Prism design phase entrypoint. Delegates to the internal design workflow
    while preserving the stable phase contract.
  children:
    - ref: prism/design/flow
      alias: design_executor
      input: |
        Prism design phase for the same story.

        {{ .Input }}
  output: |
    {{ index .State.outputs "design_executor" }}
---
{{ .Input }}
