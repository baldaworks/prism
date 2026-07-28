---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Public Prism human phase entrypoint. Collects operator approval through a
    Callee Human agent and fails closed unless the operator explicitly approves.
  children:
    - ref: prism/human/prompt
      alias: approval_prompt
      input: |
        Prism human approval phase for the same story.

        Review the current story state below and decide whether automated apply
        may begin for this story.

        {{ .Input }}
    - ref: prism/human/check
      alias: approval_gate
  output: |
    {{ index .State.outputs "approval_prompt" }}
---
{{ .Input }}
