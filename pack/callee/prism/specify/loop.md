---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Loop
spec:
  description: |
    Prism specify — iteratively normalize one story into a design-ready requirements
    document. Loop until the specify gate can escalate, otherwise collect only the
    minimum missing answers from the human and try again.
  children:
    - ref: prism/roles/interviewer
      alias: normalizer
      input: |
        Prism specify phase for one story only.

        Original lifecycle / Beads story context:
        {{ .Input }}

        {{ with index .State.outputs "clarifications" }}
        Additional human clarification captured in the previous specify iteration:
        {{ . }}
        {{ end }}

        {{ with index .State.outputs "gate" }}
        Previous specify gate findings to resolve in this iteration:
        {{ . }}
        {{ end }}

        Return these top-level sections in this exact order:

        SPECIFY_DECISION: READY_FOR_DESIGN or NEEDS_CLARIFICATION

        MISSING_DIMENSIONS:
        - bullet list
        - use `- none` only when the story is ready for design

        FOLLOW_UP_QUESTIONS:
        1. numbered list of only the minimum questions still needed
        2. use `1. none` only when the story is ready for design

        REQUIREMENTS_DOCUMENT:
        <full requirements document>

        If clarification is still needed, keep unknowns explicit, avoid invention,
        and preserve only grounded requirements in the document.
      params:
        audience: expert engineers
        context: |
          Public phase owner: prism/interviewer.
          Normalize scope, constraints, non-goals, and acceptance only.
          Stop short of design or implementation decisions.
        project_name: prism-story
    - ref: prism/specify/gate
      alias: gate
      canEscalate: true
      input: |
        Prism specify gate review for one story only.

        Original lifecycle / Beads story context:
        {{ .Input }}

        Candidate requirements document from the normalizer:
        {{ index .State.outputs "normalizer" }}

        If the story is sufficiently specified for design, escalate to finish the loop.
        Otherwise do NOT escalate.

        Return these top-level sections in this exact order:

        SPECIFY_GATE_DECISION: READY_FOR_DESIGN or NEEDS_CLARIFICATION

        GATE_SUMMARY:
        <one short paragraph>

        MISSING_DIMENSIONS:
        - bullet list
        - use `- none` only when ready

        FOLLOW_UP_QUESTIONS:
        1. numbered list containing only the minimum questions still needed
        2. use `1. none` only when ready

        REQUIREMENTS_RISKS:
        - bullet list
        - use `- none` only when ready
      params:
        audience: prism specify workflow and human operator
        context: |
          Judge only whether design can proceed without product-intent guessing.
          Treat the normalizer output as ready for design only when all core story
          dimensions are specific enough for the design phase to inspect the repo
          without inventing missing product requirements.
        invariants: |
          INV-001: The requirements document MUST identify the user, actor, or
          external trigger for the requested change unless the story is purely
          internal tooling work and that is stated explicitly.
          INV-002: The requirements document MUST state the intended behavior
          change and observable success outcomes without requiring design to infer
          the product intent.
          INV-003: The requirements document MUST capture material constraints,
          non-goals, or explicitly state that none are known.
          INV-004: The acceptance criteria MUST be specific enough that design can
          reason about repository behavior without introducing placeholder product
          decisions.
          INV-005: No unresolved ambiguity may remain on a core requirement axis
          (actor, behavior, scope boundary, or acceptance outcome) if resolving it
          would materially change design.
        project_name: prism-story
    - ref: prism/specify/questions
      alias: clarifications
      input: |
        Prism specify still needs clarification for the same story.

        Story context:
        {{ .Input }}

        Specify gate report:
        {{ index .State.outputs "gate" }}
  output: |
    {{ index .State.outputs "normalizer" }}
  maxIterations: 5
  onExhausted: fail
---
{{ .Input }}
