---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Public Prism Epic Delivery phase. Produces one deterministic continuation
    decision for the host wrapper: one ready Story, a gate, a blocker, or
    completion. It never invokes a child Story or transfers approval.
  children:
    - ref: prism/epic/roles/delivery
      alias: delivery_executor
      input: |
        Decide the next sequential Epic delivery action from the complete context below.

        {{ .Input }}
  output: |
    {{ index .State.outputs "delivery_executor" }}
---
{{ .Input }}
