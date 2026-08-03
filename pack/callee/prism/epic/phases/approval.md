---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Public Prism Epic Approval phase. Presents the complete current-Epic
    acceptance, architecture summary, Story roadmap, and item-scoped approval
    request through the existing fail-closed Human gate. Approval never
    authorizes a child Story.
  children:
    - ref: prism/epic/human
      alias: approval_executor
      input: |
        {{ .Input }}
  output: |
    {{ index .State.outputs "approval_executor" }}
---
{{ .Input }}
