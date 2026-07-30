# Prism human gate

Run this reference only when the story label is `phase:human` or the
story has open child tasks without `human:approved`.

## Goal

Stop safely and wait for explicit human authorization before implementation.

## Required inputs

- `bd show <story> --long`
- `bd children <story>`
- `bd blocked`

## Host procedure

1. Confirm the story has planned child tasks and no `human:approved` label.
2. Confirm the story is actually waiting for authorization, not for more design or planning work.
3. Confirm the saved design is concrete and the task graph covers it. If not,
   move the story to `phase:design` or `phase:breakdown` as appropriate and do
   not ask for approval. Clear approval by writing only
   `prism,phase:design` or `prism,phase:breakdown` with `--set-labels`.
4. Do not perform implementation work.
5. Before asking for approval, present these sections in order:
   - `### Design summary`: concisely summarize the saved design's goal,
     approach, affected areas, and material risks or open questions.
   - `### Task summary`: cover **every** current child task with its ID, title,
     state, and meaningful dependencies, blockers, or execution order.
   Derive all summaries from the current Beads story and child graph. Do not
   invent scope or omit a child merely to keep the response short.
6. After the summaries, present `### Approval request`. Explain that one
   informed approval covers the design and task graph. The human may approve in
   ordinary free-form language; they do not need a fixed token or to run `bd`.
7. If the user's latest message unambiguously authorizes implementation, persist
   that human decision atomically:

```bash
bd update <story> --set-labels prism,phase:apply,human:approved
```

   Then re-read the story and confirm the phase and approval labels. Free-form
   approval is explicit when its intent to start implementation is clear; it
   does not require a fixed token or exact phrase.
8. If the response explicitly requests design refinement, do not persist
   approval and do not start implementation. Clear any prior approval while
   returning the story to Design:

```bash
bd update <story> --set-labels prism,phase:design
```

   Preserve every existing child task and its status and dependencies. The next
   lifecycle invocation automatically runs Design and Breakdown, reconciles the
   child graph, and returns to the Human gate.
9. If the response is ambiguous, conditional, asks a question, requests
   changes without clearly sending the design for refinement, or merely
   discusses how approval should work, do not persist approval. Keep the story
   at `phase:human` and ask directly whether implementation is approved.

## Persist and advance

The human owns the authorization or refinement decision; the host owns
persisting an unambiguous decision to Beads. Advance to Apply only after
explicit human approval has been observed and the host has confirmed
`human:approved` with `phase:apply`. An explicit design-refinement request
instead clears approval, persists `phase:design`, preserves child state, and
stops this invocation.

## Stop when

- `human:approved` is absent
- the user has not explicitly granted implementation authority
- the user's intent is ambiguous
- an explicit design-refinement request has been persisted as `phase:design`

At `phase:human`, remain stopped until approval or an explicit refinement
decision is persisted.

## Never

- invent or silently add `human:approved`
- treat discussion of approval, a question, or conditional language as approval
- start apply work before the explicit decision is persisted and re-read
- change child-task scope while waiting at the gate
- delete, close, or reopen child tasks when returning to Design
