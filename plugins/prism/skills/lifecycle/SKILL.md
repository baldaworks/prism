---
name: lifecycle
description: >
  Route Prism work to the host-native story or epic lifecycle and, when
  explicitly requested, advance a deterministic snapshot of all open Prism
  epics. Use when the user runs $prism:lifecycle, /prism:lifecycle,
  /prism-lifecycle, /prism, asks to run or advance Prism, resumes an item, or
  asks to process all open Prism epics.
---

# Prism lifecycle router

Resolve the user's target, then follow exactly one sibling lifecycle contract:

- full story: [Story skill](../story/SKILL.md)
- epic: [Epic skill](../epic/SKILL.md)

This skill owns target resolution and explicit open-epic batch coordination.
It does not duplicate phase procedure and never invokes Callee. Select Prism
Prism Light only when the user explicitly invokes `$prism-light:lifecycle`,
`/prism-light:lifecycle`, or `/prism-light`.

## Prerequisites

1. Resolve the Beads workspace with `bd where`; follow the Beads skill or run
   `bd prime` when needed.
2. Require the repository and its native verification tools to be inspectable.
3. Use Beads issue type and parentage as durable routing evidence. Never infer
   item type or lifecycle phase from assignee.

## Resolution priority

Apply the first matching route:

1. An explicit request to process all open Prism epics enters **Epic batch**.
2. An explicit story or epic ID requires that Beads type and dispatches it.
3. An explicit task ID resolves its single parent and requires that parent to
   be a story; then dispatches the parent story.
4. An explicit resume request with no item ID resumes only when exactly one open
   Prism story or epic exists; otherwise ask for the target.
5. Clear initiative intent containing independently deliverable stories creates
   an epic in `prism,phase:epic:frame`, then dispatches it.
6. Ordinary change intent creates a story in `prism,phase:story:specify`, then
   dispatches it.

Never select Light implicitly. Fail closed on a missing item, unsupported Beads
type, missing or ambiguous task parent, nested epic, or direct task under epic.
The selected Story or Epic skill owns phase-label validation. Phase-like labels
outside the supported `phase:story:*` and `phase:epic:*` sets are treated as
absent and are never migrated.

## Single-item dispatch

1. Read the selected item with `bd show <id> --json` and verify its type.
2. For a story, load and follow [Story skill](../story/SKILL.md) in the same host
   invocation.
3. For an epic, load and follow [Epic skill](../epic/SKILL.md) in the same host
   invocation.
4. Preserve every stop condition, approval boundary, write rule, and required
   output of the selected sibling skill.

The router grants no authorization. `human:approved` is item-scoped and may be
written only by the selected lifecycle after unambiguous human approval.

## Epic batch

Enter batch mode only for explicit intent such as "process all open Prism
epics". A generic resume request is not batch intent.

1. Query once at invocation start:

   ```bash
   bd list --label prism --status=open --type=epic --limit 0 --json
   ```

2. Freeze the returned IDs before advancing any item. Sort the snapshot by
   numeric priority ascending, `created_at` ascending, then issue ID ascending.
3. If the snapshot is empty, report that no open Prism epics exist. Create and
   mutate nothing.
4. For each snapshot ID exactly once and sequentially:
   - re-read the epic and record a closed-or-missing race without substituting
     another item;
   - require `issue_type=epic` and label `prism`;
   - load and follow [Epic skill](../epic/SKILL.md) until its normal durable stop;
   - record ending status, supported phase, progress made, gate or blocker, and
     next action;
   - continue to the next snapshot ID after an item-local Human gate, child-story
     gate, blocker, invalid phase, or verification failure.
5. Do not rescan, append newly opened epics, revisit an ID, run items concurrently,
   or transfer `human:approved` between items.
6. Abort the whole batch only when the initial query/snapshot cannot be produced
   safely or Beads becomes unavailable globally.
7. End with one outcome row for every snapshot ID in snapshot order.

## Batch outcome

Use a compact table with these columns:

| Epic | Ending state | Progress | Gate or blocker | Next action |
| --- | --- | --- | --- | --- |

Report item-local failures without claiming the batch succeeded for that item.
The ledger is invocation output, not a second durable lifecycle store.

## Safety

- Beads remains the only durable lifecycle state store.
- Never invent item type, parentage, phase, approval, progress, or outcomes.
- Never invoke `callee agent run prism/...`.
- Never edit `pack/callee/**` while executing a lifecycle.
- Do not implement a story without that story's persisted approval.
- Epic approval never approves its child stories.
- Do not commit or push without repository and user authority.
