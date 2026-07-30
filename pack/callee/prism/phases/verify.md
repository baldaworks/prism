---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Public Prism verify phase entrypoint. Delegates the close-or-bounce decision to
    the internal verify workflow while preserving verify as a non-repair phase.
  children:
    - ref: prism/verify/review
      alias: verify_executor
      input: |
        Prism verify phase for the same story.

        Treat verify as a close-or-bounce decision phase. Do not perform
        implementation work here. Bounce implementation gaps to phase:apply;
        bounce missing task coverage to phase:breakdown and clear approval;
        bounce an invalid or incomplete design to phase:design and clear
        approval. Bounce incomplete requirements to phase:specify.

        {{ .Input }}
  output: |
    {{ index .State.outputs "verify_executor" }}
---
{{ .Input }}
