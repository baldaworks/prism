# Prism Epic Delivery phase

Run only for `phase:epic:delivery` with this Epic's `human:approved` label.

## Preconditions

- every direct child is a Story;
- the Story dependency graph is acyclic;
- Epic approval is persisted and re-read;
- no child approval is inferred from the Epic.

## Sequential delivery

1. Read the complete Story graph and determine ready children from Beads
   dependency state. Select one ready Story in deterministic priority,
   creation-time, then ID order.
2. Load and follow the sibling [Story skill](../../story/SKILL.md) for that Story.
3. Stop immediately when the Story requires Human clarification or approval,
   is blocked, has invalid state, or fails required checks. Report the child ID
   and next action without changing approval on any item.
4. If the Story closes successfully, re-read the Epic graph and advance the
   next ready Story. Continue sequentially until another stop condition or all
   Stories close.
5. If open Stories remain but none are ready, stop blocked and report the
   dependency evidence. Never bypass dependencies or invent work.
6. When every Story is closed, retain Epic approval and advance:

   ```bash
   bd update <epic> --set-labels prism,phase:epic:validation,human:approved
   ```

Delivery may mutate a child only through the Story lifecycle. It never creates
Tasks directly, approves Stories, or runs Stories concurrently.
