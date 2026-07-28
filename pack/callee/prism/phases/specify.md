---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Public Prism specify phase entrypoint. Delegates to the internal specify loop
    while preserving phase ownership semantics.
  children:
    - ref: prism/specify/loop
      alias: specify_executor
      input: |
        Prism specify phase for one story.

        Use the following lifecycle entry context to iteratively clarify and
        normalize the story description and acceptance criteria for the same
        story only:

        {{ .Input }}
    - ref: prism/specify/extract
      alias: requirements_doc
  output: |
    {{ index .State.outputs "requirements_doc" }}
---
{{ .Input }}
