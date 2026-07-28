# Prism human gate

Run this reference only when the inferred story phase is `phase:human` or the
story has open child tasks without `human:approved`.

## Goal

Stop safely and wait for explicit human authorization before implementation.

## Required inputs

- `bd show <story> --long`
- `bd children <story>`

## Host procedure

1. Confirm the story has planned child tasks and no `human:approved` label.
2. Confirm the story is actually waiting for authorization, not for more design or planning work.
3. Do not perform implementation work.
4. Ask the human to apply approval with:

```bash
bd update <story> -a prism/implementer --set-labels prism,phase:apply,human:approved
```

## Persist and advance

This phase does not self-advance.

Advance only after a human has actually added `human:approved` and the story is
in `phase:apply`.

## Stop when

- `human:approved` is absent
- the user has not explicitly granted implementation authority

Remain stopped until the label is present.

## Never

- invent or silently add `human:approved`
- start apply work from a chat implication alone
- change child-task scope while waiting at the gate
