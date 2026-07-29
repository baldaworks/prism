---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Prism lifecycle phase chain — specify, design with Prism Impact Lens,
    breakdown, informed human approval, apply, and verify in order. The human
    gate accepts free-form intent through a fail-closed classifier before apply
    begins, while apply owns story-level operational closure through the inner
    one-task loop.
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
    - ref: prism/phases/human
      alias: human
      input: |
        ### Design summary
        {{ index .State.outputs "design" }}

        ### Prism Impact Lens
        Reproduce the exact `## Prism Impact Lens` section from this design:
        {{ index .State.outputs "design" }}

        ### Task summary
        {{ index .State.outputs "breakdown" }}

        ### Approval request
        Approve automated implementation of this design and task graph? One
        informed approval covers the design, tasks, mitigations, and disclosed
        residual impacts.
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

        Human approval result:
        {{ index .State.outputs "human" }}
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
