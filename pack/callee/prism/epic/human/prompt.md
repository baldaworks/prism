---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Human
spec:
  description: Requests explicit approval for the current Prism Epic architecture and roadmap.
  responseKey: approval
---
Prism Epic approval gate

{{ .Input }}

Reply in ordinary free-form language. Approval is granted only when your
intent to authorize this Epic's architecture and Story roadmap is unambiguous.
This does not authorize implementation or approval of any child Story.
Clearly request architecture refinement when the Epic design or roadmap must
change. Questions, conditions, and unclear responses withhold approval.
