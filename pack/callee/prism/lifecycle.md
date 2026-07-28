---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Prism lifecycle phase chain — specify, design, breakdown, apply, and verify in order.
    The human gate remains an external Beads transition between breakdown and apply,
    while apply itself owns story-level operational closure through the inner one-task loop.
  children:
    - ref: prism/phases/specify
      alias: specify
    - ref: prism/phases/design
      alias: design
      input: |
        Original lifecycle context:
        {{ .Input }}

        Specify result:
        {{ index .State.outputs "specify" }}
    - ref: prism/phases/breakdown
      alias: breakdown
      input: |
        Original lifecycle context:
        {{ .Input }}

        Specify result:
        {{ index .State.outputs "specify" }}

        Design result:
        {{ index .State.outputs "design" }}
    - ref: prism/phases/apply
      alias: apply
      input: |
        Original lifecycle context:
        {{ .Input }}

        Specify result:
        {{ index .State.outputs "specify" }}

        Design result:
        {{ index .State.outputs "design" }}

        Breakdown result:
        {{ index .State.outputs "breakdown" }}
    - ref: prism/phases/verify
      alias: verify
      input: |
        Original lifecycle context:
        {{ .Input }}

        Specify result:
        {{ index .State.outputs "specify" }}

        Design result:
        {{ index .State.outputs "design" }}

        Breakdown result:
        {{ index .State.outputs "breakdown" }}

        Apply result:
        {{ index .State.outputs "apply" }}
  output: |
    {{ index .State.outputs "verify" }}
---
{{ .Input }}
