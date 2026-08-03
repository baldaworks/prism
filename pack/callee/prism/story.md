---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Direct Prism Story graph. Preserves the six Story phases — specify,
    design, breakdown, informed human approval, apply, and verify — while
    forwarding the complete caller input, including a route envelope, to every
    phase that needs lifecycle context. The graph is Story-only; Epic routing
    belongs to the public lifecycle Router.
  children:
    - ref: prism/phases/specify
      alias: specify
      input: |
        Original route envelope and lifecycle context:
        {{ .Input }}
    - ref: prism/phases/design
      alias: design
      input: |
        Original route envelope and lifecycle context:
        {{ .Input }}

        Specify result:
        {{ index .State.outputs "specify" }}
    - ref: prism/phases/breakdown
      alias: breakdown
      input: |
        Original route envelope and lifecycle context:
        {{ .Input }}

        Specify result:
        {{ index .State.outputs "specify" }}

        Design result:
        {{ index .State.outputs "design" }}
    - ref: prism/phases/human
      alias: human
      input: |
        Original route envelope and lifecycle context:
        {{ .Input }}

        ### Acceptance criteria
        The complete current-item acceptance is contained in the Specify
        result below. Do not emit this section outside this informed approval
        request unless the operator explicitly asks for acceptance criteria.
        {{ index .State.outputs "specify" }}

        ### Design summary
        {{ index .State.outputs "design" }}

        ### Task summary
        {{ index .State.outputs "breakdown" }}

        ### Approval request
        Approve automated implementation of this Story design and task graph?
        One informed approval covers the design and tasks.
    - ref: prism/phases/apply
      alias: apply
      input: |
        Original route envelope and lifecycle context:
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
        Original route envelope and lifecycle context:
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
