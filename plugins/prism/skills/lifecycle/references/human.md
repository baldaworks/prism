# Prism human gate

Run this reference only when the story assignee is `prism/human` or the
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
3. Validate the saved `## Prism Impact Lens` and task coverage. If the lens is
   missing, invalid, contains `unknown`, or has an uncovered actionable
   mitigation, clear `human:approved`, move the story to `prism/design` or
   `prism/breakdown` as appropriate, and do not ask for approval.
4. Do not perform implementation work.
5. Before asking for approval, present these sections in order:
   - `### Design summary`: concisely summarize the saved design's goal,
     approach, affected areas, and material risks or open questions.
   - `### Prism Impact Lens`: reproduce or faithfully summarize all five
     dimensions, ratings, evidence, and mitigations or residual-impact
     dispositions.
   - `### Task summary`: cover **every** current child task with its ID, title,
     state, and meaningful dependencies, blockers, or execution order.
   Derive all summaries from the current Beads story and child graph. Do not
   invent scope or omit a child merely to keep the response short.
6. After the summaries, present `### Approval request`. Explain that one
   informed approval covers the design, task graph, mitigations, and explicitly
   disclosed residual impacts. The human may approve in ordinary free-form language;
   they do not need a fixed token or to run `bd`.
7. If the user's latest message unambiguously authorizes implementation, persist
   that human decision atomically:

```bash
bd update <story> -a prism/apply --set-labels prism,human:approved
```

   Then re-read the story and confirm both the assignee and labels. Free-form
   approval is explicit when its intent to start implementation is clear; it
   does not require a fixed token or exact phrase.
8. If the response is ambiguous, conditional, asks a question, requests design
   or task changes, or merely discusses how approval should work, do not
   persist approval. Keep the story at `prism/human` and ask directly whether
   implementation is approved.

## Persist and advance

The human owns the authorization decision; the host owns persisting an
unambiguous decision to Beads. Advance only after explicit human approval has
been observed and the host has confirmed `human:approved` with assignee
`prism/apply`.

## Stop when

- `human:approved` is absent
- the user has not explicitly granted implementation authority
- the user's intent is ambiguous or requests changes

Remain stopped until the label is present.

## Never

- invent or silently add `human:approved`
- treat discussion of approval, a question, or conditional language as approval
- start apply work before the explicit decision is persisted and re-read
- change child-task scope while waiting at the gate
