---
name: epic
description: >
  Run one host-native Prism epic lifecycle with Beads-backed Frame,
  Architecture, Roadmap, Approval, Delivery, and Validation phases. Use when
  the user runs $prism:epic, /prism:epic, /prism-epic, explicitly targets a
  Prism epic, or asks to continue a multi-story initiative.
---

# Prism epic lifecycle

Run one Prism epic in the current host. An Epic coordinates independently
approvable Story children; it never contains implementation Task children and
never grants approval to a child. Do not invoke Callee.

**Invoke:** Codex `$prism:epic`, Claude Code `/prism:epic`, or flat slash `/prism-epic`.

Lifecycle graph: [references/lifecycle.md](references/lifecycle.md). Keep lifecycle
diagrams vertical with Mermaid `flowchart TB`.

## Durable lifecycle state

| Phase | Epic label | Outcome |
| --- | --- | --- |
| Frame | `phase:epic:frame` | durable outcomes, boundaries, acceptance |
| Architecture | `phase:epic:architecture` | repository-backed cross-story design |
| Roadmap | `phase:epic:roadmap` | complete Story graph and dependencies |
| Approval | `phase:epic:approval` | informed authorization of architecture and roadmap |
| Delivery | `phase:epic:delivery` | sequential advancement of ready Stories |
| Validation | `phase:epic:validation` | integration review and close-or-bounce |

`prism` marks membership. `human:approved` authorizes only this Epic's
architecture and roadmap. It never authorizes implementation in a child Story.

Supported global phase labels are the Epic set above and the sibling Story
skill's `phase:story:*` set. Ignore any other phase-like label as absent and
never migrate it. A Story phase on an Epic is type-invalid and fails closed.
When no supported phase exists, initialize `prism,phase:epic:frame` and remove
stale authorization.

## Phase references

Load exactly one phase-local instruction:

- Frame: [references/frame.md](references/frame.md)
- Architecture: [references/architecture.md](references/architecture.md)
- Roadmap: [references/roadmap.md](references/roadmap.md)
- Approval: [references/approval.md](references/approval.md)
- Delivery: [references/delivery.md](references/delivery.md)
- Validation: [references/validation.md](references/validation.md)

## Output boundary

Normal host Epic output — target resolution, phase progress, status, errors,
blockers, and normal phase results — MUST NOT emit a standalone ### Acceptance criteria heading,
including a bullet-wrapped form such as `- ### Acceptance criteria`, or an unsolicited user-facing
approval-format acceptance block.

This boundary applies only to user-facing Markdown output. It does not prohibit
internal or machine-readable acceptance artifacts such as requirements
documents, the Beads acceptance field, or `ACCEPTANCE_CRITERIA:` sections in a
normal phase result. This prohibition includes the Epic Approval pre-approve
request. Only an explicit operator request for acceptance criteria allows the
complete, untruncated acceptance of the current Epic to be shown.

## Entry

1. Resolve Beads with `bd where`; follow the Beads skill or `bd prime` when needed.
2. Resolve the target Epic:
   - use an explicitly named ID and require `issue_type=epic`;
   - otherwise resume exactly one open Prism Epic;
   - otherwise create one from clear multi-story initiative intent:

     ```bash
     bd create "<derived title>" --type=epic -l prism,phase:epic:frame \
       --description="<raw user request>" --priority=2 --silent
     ```

3. Load `bd show <epic> --long` and `bd children <epic>`.
4. Require every direct child to have `issue_type=story`. Reject nested epics,
   direct tasks, and ambiguous hierarchy without mutating children.
5. Classify phase-like labels against both supported namespaces:
   - ignore labels outside both namespaces;
   - fail closed on a Story phase or multiple Epic phases;
   - when no supported phase remains, write `prism,phase:epic:frame`, clearing
     stale `human:approved` through replacement;
   - otherwise use the single Epic phase.
6. Load the matching phase reference, execute it, persist, and re-read state.
7. Continue through successful Frame, Architecture, and Roadmap in the same
   invocation. Stop at Approval, missing input, a child Story gate, a blocker,
   invalid state, failed verification, or an explicit phase stop.

## Phase selection

| Condition, in priority order | Action |
| --- | --- |
| Missing usable outcomes or acceptance | Frame |
| `phase:epic:validation`, or approved with every Story closed | Validation |
| `phase:epic:delivery` with Epic approval and open Stories | Delivery |
| Open Stories without Epic approval, or `phase:epic:approval` | Approval |
| `phase:epic:roadmap`, or architecture exists without adequate Stories | Roadmap |
| `phase:epic:architecture`, or framed requirements exist without architecture | Architecture |
| `phase:epic:frame` | Frame |

## Advance loop

Within one invocation:

1. derive the phase from the single supported Epic label;
2. load exactly one matching reference;
3. execute its complete contract;
4. persist and re-read the Epic and Story graph;
5. continue through successful pre-approval phases;
6. after Approval, Delivery may advance ready Stories sequentially until a
   durable stop condition is reached;
7. stop at every reference stop condition.

## Hard rules

1. Beads is the only durable lifecycle store.
2. Direct Epic children are Stories; direct Tasks and nested Epics are invalid.
3. Story children own their Task graphs and their own `human:approved` gates.
4. Epic approval never cascades, implies, copies, or writes Story approval.
5. Delivery advances one ready Story at a time through the sibling
   [Story skill](../story/SKILL.md).
6. Never invoke `callee agent run prism/...`.
7. Never edit `pack/callee/**` while executing an Epic lifecycle.
8. Validation is close-or-bounce and performs no repairs.
9. Never invent requirements, approval, repository evidence, or verification.
10. Do not commit or push without repository and user authority.
