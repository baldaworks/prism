---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Human
spec:
  description: Requests the minimum missing clarification needed to finish Prism specify.
  responseKey: clarification
---
Prism specify clarification

The story is not ready for design yet.

Answer only the numbered items from the `FOLLOW_UP_QUESTIONS` section in the
gate report below. Keep each answer concise. If you do not know, reply `UNKNOWN`
for that item rather than guessing.

{{ .Input }}
