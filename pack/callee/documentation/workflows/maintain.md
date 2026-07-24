---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Loop
spec:
  description: |
    Documentation maintain — update repository documentation with a PromptKit
    writer, then audit for drift with a PromptKit reviewer until the reviewer escalates.
  children:
    - ref: documentation/roles/writer
      alias: writer
      input: |
        Documentation maintenance goal:

        {{ .Input }}

        {{ with index .State.outputs "reviewer" }}
        Previous documentation review feedback (repair this iteration):
        {{ . }}
        {{ end }}

        Inspect the live repository. Update or author documentation so it matches
        verified implementation behavior. Prefer README, architecture notes, and
        operator docs over inventing features that do not exist.
      params:
        audience: repository users, contributors, and operators
        project_name: project-under-documentation
        requirements_doc: |
          Treat the root maintenance goal and any cited docs as the documentation target.
          The maintained documentation MUST include the vertical lifecycle workflow requirement
          when describing repository workflows and lifecycle behavior.
          Goal:
          {{ .Input }}
        technical_context: |
          Inspect the working tree, existing docs, and implementation. Prefer verified
          repository facts over assumptions. Mermaid diagrams use flowchart TB when used.
          Preserve and correctly describe the vertical lifecycle workflow requirement in the
          resulting documentation when that workflow is part of the documented behavior.
          {{ with index .State.outputs "reviewer" }}
          Prior review feedback:
          {{ . }}
          {{ end }}
    - ref: documentation/roles/reviewer
      alias: reviewer
      canEscalate: true
      input: |
        Documentation under review (writer output — treat as the specification/docs to audit):

        {{ index .State.outputs "writer" }}

        Maintenance goal:
        {{ .Input }}

        Audit the documentation against the live codebase. If documentation is accurate,
        complete, and ready to hand off, state that clearly and escalate to finish the loop.
        Otherwise return actionable findings without escalating so the writer can repair.
      params:
        audience: maintainers and contributors
        project_name: project-under-documentation
        code_context: |
          Inspect the live repository working tree for source, tests, and existing docs.
          Maintenance goal:
          {{ .Input }}
        design_doc: |
          None unless the writer output includes a design section.
          Writer output:
          {{ index .State.outputs "writer" }}
        focus_areas: documentation accuracy, completeness, consistency with repository behavior, vertical lifecycle workflow requirement
  output: |
    Documentation maintain finished:
    {{ index .State.outputs "reviewer" }}
  maxIterations: 5
  onExhausted: fail
---
{{ .Input }}
