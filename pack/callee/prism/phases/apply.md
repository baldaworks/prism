---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Public Prism apply phase entrypoint. Delegates one task execution to the internal
    implementer/reviewer loop while preserving apply as the story execution phase.
  children:
    - ref: prism/apply/loop
      alias: apply_executor
      input: |
        Prism apply phase for the same story.

        Human approval must already be present before execution. Treat apply as
        story-level operational closure. Use the inner one-task implementer/reviewer
        loop to close ready child work without expanding beyond this story.
        Honor the story requirements, design, task scope, and verification
        criteria.

        {{ .Input }}
  output: |
    {{ index .State.outputs "apply_executor" }}
---
{{ .Input }}
