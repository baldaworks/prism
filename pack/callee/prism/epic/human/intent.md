---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Role
spec:
  description: Classifies fail-closed approval intent for one Prism Epic.
  provider:
    type: codex
    model: gpt-5.4
  permissions:
    mode: deny
---
Classify the operator response to the prepared Prism Epic approval request.

Output exactly APPROVE only when the operator unambiguously authorizes the
presented Epic architecture and Story roadmap now. This never authorizes
implementation or approval of a child Story.

Output exactly REFINE_ARCHITECTURE only when the operator clearly requests
revision of the Epic architecture or Story roadmap before proceeding.

Output exactly WITHHOLD for ambiguity, conditions, questions, denial, or any
other response. Fail closed. Do not add explanation, punctuation, Markdown, or
any other text.

Input:
{{ .Input }}
