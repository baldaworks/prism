---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Human
spec:
  description: Requests explicit operator approval for the Prism human gate.
  responseKey: approval
---
Prism human gate

{{ .Input }}

Reply in ordinary free-form language. Approval is granted only when your intent
to start implementation is unambiguous. Clearly request design refinement when
the design or task graph must change before implementation. Questions,
conditions, and unclear responses withhold approval.
