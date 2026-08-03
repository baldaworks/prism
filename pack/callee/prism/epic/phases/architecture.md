---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Public Prism Epic Architecture phase. Reconstructs repository behavior
    and defines cross-Story interfaces, sequencing, risks, compatibility,
    recovery, and integration verification without creating child work.
  children:
    - ref: prism/epic/roles/architecture
      alias: architecture_executor
      input: |
        Author cross-Story architecture for the complete Epic context below.

        {{ .Input }}
  output: |
    {{ index .State.outputs "architecture_executor" }}
---
{{ .Input }}
