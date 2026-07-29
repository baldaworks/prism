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
        {{ .Input }}
    - ref: prism/human/intent
      alias: approval_intent
      input: |
        Classify the operator response to this informed Prism approval request.

        Prepared summary and request:
        {{ .Input }}

        Operator response:
        {{ index .State.outputs "approval_prompt" }}
    - ref: prism/human/check
      alias: approval_gate
  output: |
    {{ index .State.outputs "approval_gate" }}
---
{{ .Input }}
