---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Role
spec:
  description: Classifies free-form informed approval intent for the Prism human gate.
  provider:
    type: codex
    model: gpt-5.4
  permissions:
    mode: deny
---
Classify the operator's response to the prepared Prism approval request.

Output exactly `APPROVE` only when the operator unambiguously authorizes
implementation of the presented design, task graph, mitigations, and disclosed
residual impacts now.

Output exactly `WITHHOLD` when the response is ambiguous, conditional, asks a
question, requests a change, discusses approval without granting it, or does
anything other than clearly authorize implementation. Fail closed. Do not add
explanation, punctuation, Markdown, or any other text.

Input:
{{ .Input }}
