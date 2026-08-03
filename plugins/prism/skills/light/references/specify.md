# Prism Light specify phase

Run this reference only when the story label is `phase:story:specify` or the
story is still missing usable description or acceptance criteria.

## Goal

Turn the requested change into a durable Beads story with:

- a concrete problem / change description
- explicit acceptance criteria
- known constraints and non-goals
- enough scope clarity to hand off to design without inventing requirements

## Required inputs

- `bd show <story> --long`
- the user's stated intent
- any already-known constraints, examples, or non-goals

## Host procedure

1. Load current state with `bd show <story> --long`.
2. Identify missing requirement dimensions:
   - actor / user
   - behavior change
   - constraints / non-goals
   - observable acceptance outcomes
3. When any dimension is missing or ambiguous, ask only the minimum direct
   clarifying questions needed from the human. Do not ask for confirmation to
   remain in Specify or to start another Specify iteration.
4. After the human answers, combine the answer with the current story, return
   to step 2, and repeat the readiness check. Keep the story in
   `phase:story:specify` throughout this clarification loop.
5. Once no core requirement dimension remains unresolved, rewrite the story into:
   - `description`: what changes and why
   - `acceptance`: observable outcomes, not implementation guesses
   Capture known constraints and non-goals in either field when they affect
   observable behavior or design choices.
6. Re-read the rewritten description and acceptance before persisting. If this
   reveals another material ambiguity, return to step 3. Otherwise they must be
   specific enough that a designer can inspect the repository without guessing
   product intent.

## Persist and advance

When description and acceptance are both usable:

```bash
bd update <story> \
  --description="..." \
  --acceptance="..." \
  --set-labels prism,phase:story:design
```

Advance only to `phase:story:design`.

## Stop when

- core requirements are still ambiguous after inspection
- acceptance would be speculative
- the human needs to answer a scope or intent question

If you stop to await an answer, leave the story in Specify and ask the human
directly in chat. The answer resumes the same clarification loop; it is not a
phase-transition approval.

## Never

- invent missing requirements just to move forward
- write design or task decomposition here
- encode implementation details as acceptance criteria
- move to design with placeholder text or unresolved core ambiguity
