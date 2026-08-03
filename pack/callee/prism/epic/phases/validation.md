---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Public Prism Epic Validation phase. Reviews closed Story evidence,
    cross-Story integration, and Epic acceptance, then closes or identifies
    the earliest defective Epic phase without repairing implementation.
  children:
    - ref: prism/epic/roles/validation
      alias: validation_executor
      input: |
        Validate the complete Epic context below without modifying the repository.

        {{ .Input }}
  output: |
    {{ index .State.outputs "validation_executor" }}
---
{{ .Input }}
