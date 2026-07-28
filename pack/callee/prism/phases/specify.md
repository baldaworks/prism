---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Public Prism specify phase entrypoint. Delegates requirements clarification to
    the interviewer role while preserving phase ownership semantics.
  children:
    - ref: prism/roles/interviewer
      alias: interviewer
      input: |
        Prism specify phase for one story.

        Use the following lifecycle entry context to clarify and normalize the
        story description and acceptance criteria for the same story only:

        {{ .Input }}
      params:
        context: |
          Public phase owner: prism/interviewer.
          Keep the story scope stable. Clarify requirements and acceptance only.
        existing_artifacts: |
          Lifecycle entry context:
          {{ .Input }}
        project_name: prism-story
  output: |
    {{ index .State.outputs "interviewer" }}
---
{{ .Input }}
