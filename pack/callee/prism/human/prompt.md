---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Human
spec:
  description: Requests explicit operator approval for the Prism human gate.
  responseKey: approval
---
Prism human gate

Review the story state below.

If you approve automated implementation for this story, reply exactly:

APPROVE

Any other nonblank response means approval is withheld and this automated run
must stop before apply.

{{ .Input }}
