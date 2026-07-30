---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Sequential
spec:
  description: |
    Prism verify — story-level code review against acceptance after all child tasks are closed.
  children:
    - ref: prism/roles/reviewer
      alias: reviewer
      input: |
        Prism verify phase — full story acceptance review (not a single-task review).

        {{ .Prompt }}

        Inspect the working tree and tests against story acceptance criteria
        and the saved design. Check correctness, regressions, security, missing
        tests, and relevant design risks. State clearly whether the story is
        acceptable to close.
      params:
        additional_protocols: none
        language: detect from repository sources under review
        review_focus: correctness, regressions, security, missing tests, acceptance coverage, design adherence
        context: |
          Story-level Prism verify. Child beads tasks should already be closed.
          Story dump and acceptance are in the root prompt.
  output: |
    {{ index .State.outputs "reviewer" }}
---
{{ .Input }}
