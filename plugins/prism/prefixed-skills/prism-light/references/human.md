# Prism Light human gate

Run this reference only when the story label is `phase:story:human` or the
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
3. Confirm current-Story acceptance is complete and usable. If not, clear
   approval, write `prism,phase:story:specify`, and stop without an approval
   request.
4. Confirm the saved design is concrete and the task graph covers it. If not,
   move the story to `phase:story:design` or `phase:story:breakdown` as appropriate and do
   not ask for approval. Clear approval by writing only
   `prism,phase:story:design` or `prism,phase:story:breakdown` with `--set-labels`.
5. Do not perform implementation work.
6. Before asking for approval, present these sections in order:
   - `### Acceptance criteria`: reproduce the complete, untruncated acceptance
     field of the current Story only.
   - `### Design summary`: concisely summarize the saved design's goal,
     approach, affected areas, and material risks or open questions.
   - `### Task summary`: cover **every** current child task with its ID, title,
     state, and meaningful dependencies, blockers, or execution order.
   Derive all summaries from the current Beads story and child graph. Do not
   invent scope or omit a child merely to keep the response short.
7. After the summaries, present `### Approval request`. Explain that one
   informed approval covers the design and task graph. The human may approve in
   ordinary free-form language; they do not need a fixed token or to run `bd`.
8. If the user's latest message unambiguously authorizes implementation, persist
   that human decision atomically:

```bash
bd update <story> --set-labels prism,phase:story:apply,human:approved
```

   Then re-read the story and confirm the phase and approval labels. Free-form
   approval is explicit when its intent to start implementation is clear; it
   does not require a fixed token or exact phrase.
9. If the response explicitly requests design refinement, do not persist
   approval and do not start implementation. Clear any prior approval while
   returning the story to Design:

```bash
bd update <story> --set-labels prism,phase:story:design
```

   Preserve every existing child task and its status and dependencies. The next
   lifecycle invocation automatically runs Design and Breakdown, reconciles the
   child graph, re-enters this Human reference, and presents the refreshed
   approval request.
10. If the response is ambiguous, conditional, asks a question, requests
   changes without clearly sending the design for refinement, or merely
   discusses how approval should work, do not persist approval. Keep the story
   at `phase:story:human` and ask directly whether implementation is approved.

## Persist and advance

The human owns the authorization or refinement decision; the host owns
persisting an unambiguous decision to Beads. Advance to Apply only after
explicit human approval has been observed and the host has confirmed
`human:approved` with `phase:story:apply`. An explicit design-refinement request
instead clears approval, persists `phase:story:design`, preserves child state, and
stops this invocation.

## Stop when

- `human:approved` is absent
- the user has not explicitly granted implementation authority
- the user's intent is ambiguous
- an explicit design-refinement request has been persisted as `phase:story:design`

At `phase:story:human`, remain stopped until approval or an explicit refinement
decision is persisted.

## Never

- invent or silently add `human:approved`
- treat discussion of approval, a question, or conditional language as approval
- start apply work before the explicit decision is persisted and re-read
- change child-task scope while waiting at the gate
- truncate or replace current-Story acceptance with child acceptance
- delete, close, or reopen child tasks when returning to Design
