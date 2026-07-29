# Prism specify phase

Run this reference only when the story assignee is `prism/specify` or the
story is still missing usable description or acceptance criteria.

## Goal

Turn the requested change into a durable Beads story with:

- a concrete problem / change description
- explicit acceptance criteria
- known Product, Process, People, Planet, or Prosperity constraints and non-goals
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
3. Ask direct clarifying questions in chat when any of those are missing or ambiguous.
4. Rewrite the story into:
   - `description`: what changes and why
   - `acceptance`: observable outcomes, not implementation guesses
   Capture any known impact constraints in either field, but do not rate the
   five Impact Lens dimensions in Specify; Design owns that assessment.
5. Re-read the rewritten description and acceptance before persisting. They must be specific enough that a designer can inspect the repository without guessing product intent.

## Persist and advance

When description and acceptance are both usable:

```bash
bd update <story> \
  --description="..." \
  --acceptance="..." \
  -a prism/design \
  --set-labels prism
```

Advance only to `prism/design`.

## Stop when

- core requirements are still ambiguous after inspection
- acceptance would be speculative
- the human needs to answer a scope or intent question

If you stop, leave the story in specify and ask the human directly in chat.

## Never

- invent missing requirements just to move forward
- write design or task decomposition here
- encode implementation details as acceptance criteria
- move to design with placeholder text or unresolved core ambiguity
