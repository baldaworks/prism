---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Loop
spec:
  description: |
    Prism apply — implement and review exactly one claimed beads task until the reviewer escalates.
  children:
    - ref: prism/roles/implementer
      alias: worker
      input: |
        Prism apply — one beads task only. Treat the following as the specification /
        change request for this single task (do not expand to sibling tasks).
        Honor the saved Prism Impact Lens and implement the mitigation and
        verification criteria assigned to this task.

        {{ .Input }}

        {{ with index .State.outputs "validator" }}
        Previous review feedback (repair this iteration):
        {{ . }}
        {{ end }}
      params:
        context: |
          Follow repository conventions. Smallest coherent change for one beads task.
          Run the most relevant checks after edits.
        project_name: prism-story
        implementation_artifacts: |
          Inspect the live repository working tree for current implementation.
          Story and task context:
          {{ .Input }}
        verification_artifacts: |
          Inspect and run existing tests related to this task in the repository.
    - ref: prism/roles/reviewer
      alias: validator
      canEscalate: true
      input: |
        Prism apply review — one task only.

        Goal / story + task:
        {{ .Input }}

        Worker result:
        {{ index .State.outputs "worker" }}

        Inspect the actual working tree and tests. If the task is satisfied without
        material defects, state acceptance and escalate to finish the loop. Otherwise
        return actionable findings without escalating.
      params:
        additional_protocols: none
        language: detect from repository sources under review
        review_focus: correctness, regressions, security, missing tests, Prism Impact Lens mitigation adherence
        context: |
          Single Prism task under a beads story. Judge against task description,
          story acceptance, and the affected Prism Impact Lens dimension.
          Worker output:
          {{ index .State.outputs "worker" }}
  output: |
    Prism apply finished:
    {{ index .State.outputs "validator" }}
  maxIterations: 5
  onExhausted: fail
---
{{ .Input }}
