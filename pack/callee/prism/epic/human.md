---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Epic-scoped fail-closed approval gate. It classifies one operator decision
    for the current Epic and never authorizes or mutates a child Story.
  children:
    - ref: prism/epic/human/prompt
      alias: epic_approval_prompt
      input: |
        {{ .Input }}
    - ref: prism/epic/human/intent
      alias: epic_approval_intent
      input: |
        Prepared Epic summary and request:
        {{ .Input }}

        Operator response:
        {{ index .State.outputs "epic_approval_prompt" }}
    - ref: prism/epic/human/check
      alias: epic_approval_gate
  output: |
    {{ index .State.outputs "epic_approval_gate" }}
---
{{ .Input }}
