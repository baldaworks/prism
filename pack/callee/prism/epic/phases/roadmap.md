---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Public Prism Epic Roadmap phase. Produces a complete qualitative graph of
    direct Story children and necessary acyclic dependencies. Direct Tasks,
    nested Epics, numeric child limits, and implementation are forbidden.
  children:
    - ref: prism/epic/roles/roadmap
      alias: roadmap_executor
      input: |
        Reconcile the direct Story roadmap for the complete Epic context below.

        {{ .Input }}
  output: |
    {{ index .State.outputs "roadmap_executor" }}
---
{{ .Input }}
