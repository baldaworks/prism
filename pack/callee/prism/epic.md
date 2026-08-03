---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Direct Prism Epic graph. Frames one Epic, authors cross-Story
    architecture, reconciles a qualitative Story roadmap, requests
    item-scoped Epic approval, produces a sequential Delivery decision, and
    validates integration. Direct children are Stories only; Tasks and nested
    Epics are rejected by the host wrapper. The graph never approves or runs
    a child Story implicitly.
  children:
    - ref: prism/epic/phases/frame
      alias: frame
      input: |
        Original route envelope and Epic lifecycle context:
        {{ .Input }}
    - ref: prism/epic/phases/architecture
      alias: architecture
      input: |
        Original route envelope and Epic lifecycle context:
        {{ .Input }}

        Frame result:
        {{ index .State.outputs "frame" }}
    - ref: prism/epic/phases/roadmap
      alias: roadmap
      input: |
        Original route envelope and Epic lifecycle context:
        {{ .Input }}

        Frame result:
        {{ index .State.outputs "frame" }}

        Architecture result:
        {{ index .State.outputs "architecture" }}
    - ref: prism/epic/phases/approval
      alias: approval
      input: |
        Original route envelope and Epic lifecycle context:
        {{ .Input }}

        ### Acceptance criteria
        The complete current-item acceptance is contained in the Frame result
        below. Do not emit this section outside this informed approval request
        unless the operator explicitly asks for acceptance criteria.
        {{ index .State.outputs "frame" }}

        ### Architecture summary
        {{ index .State.outputs "architecture" }}

        ### Story roadmap
        {{ index .State.outputs "roadmap" }}

        ### Approval request
        Approve this Epic architecture and Story roadmap only. This approval
        does not authorize implementation or approval of any child Story.
    - ref: prism/epic/phases/delivery
      alias: delivery
      input: |
        Original route envelope and Epic lifecycle context:
        {{ .Input }}

        Frame result:
        {{ index .State.outputs "frame" }}

        Architecture result:
        {{ index .State.outputs "architecture" }}

        Story roadmap:
        {{ index .State.outputs "roadmap" }}

        Epic approval result:
        {{ index .State.outputs "approval" }}
    - ref: prism/epic/phases/validation
      alias: validation
      input: |
        Original route envelope and Epic lifecycle context:
        {{ .Input }}

        Frame result:
        {{ index .State.outputs "frame" }}

        Architecture result:
        {{ index .State.outputs "architecture" }}

        Story roadmap:
        {{ index .State.outputs "roadmap" }}

        Delivery result:
        {{ index .State.outputs "delivery" }}
  output: |
    {{ index .State.outputs "validation" }}
---
{{ .Input }}
