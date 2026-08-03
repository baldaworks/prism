---
name: lifecycle
description: >
  Run the Prism lifecycle through the Callee Router and its Story or Epic
  graphs. Beads stores durable state. Use when the user runs
  $prism-callee:lifecycle, /prism-callee:lifecycle, /prism-callee-lifecycle,
  or asks to run Prism through Callee subagents.
---

# Prism Callee lifecycle

This is the only Prism surface that may execute callee agent run prism/... .
PromptKit role/workflow contract: references/promptkit.md.

The host owns Beads resolution, durable labels, approval authority, Epic batch
coordination, and persistence after every Callee return. The Callee Router owns
only deterministic selection between the declared Story and Epic graphs.

## Public Callee surface

| Agent ID | Role |
| --- | --- |
| prism/lifecycle | Router selecting exactly one Story or Epic graph |
| prism/story | Direct six-phase Story graph |
| prism/epic | Direct six-phase Epic graph |
| prism/phases/* | Story phase resources used by prism/story |
| prism/epic/phases/* | Epic phase resources used by prism/epic |

The canonical resources are under pack/callee/prism. Validate and inspect the
three public roots before execution:

    callee agent validate pack/callee/prism/lifecycle.md
    callee agent view prism/lifecycle --agent-root pack/callee --json
    callee agent view prism/story --agent-root pack/callee --json
    callee agent view prism/epic --agent-root pack/callee --json

## Durable lifecycle state

Story phases:

| Phase | Beads label | Callee graph phase |
| --- | --- | --- |
| Specify | phase:story:specify | prism/phases/specify |
| Design | phase:story:design | prism/phases/design |
| Breakdown | phase:story:breakdown | prism/phases/breakdown |
| Human | phase:story:human | prism/phases/human |
| Apply | phase:story:apply | prism/phases/apply |
| Verify | phase:story:verify | prism/phases/verify |

Epic phases:

| Phase | Beads label | Callee graph phase |
| --- | --- | --- |
| Frame | phase:epic:frame | prism/epic/phases/frame |
| Architecture | phase:epic:architecture | prism/epic/phases/architecture |
| Roadmap | phase:epic:roadmap | prism/epic/phases/roadmap |
| Approval | phase:epic:approval | prism/epic/phases/approval |
| Delivery | phase:epic:delivery | prism/epic/phases/delivery |
| Validation | phase:epic:validation | prism/epic/phases/validation |

prism is the membership label. human:approved authorizes only the current
item: Story implementation for a Story, or Epic architecture and roadmap for
an Epic. It never authorizes a child Story and never transfers between items.

Ignore phase-like labels outside the supported Story and Epic namespaces as
absent and never migrate them. Multiple supported phases fail closed. A Story
with an Epic phase, an Epic with a Story phase, or any other type-incompatible
supported phase fails closed without mutating children. A missing supported
phase initializes a Story at phase:story:specify or an Epic at
phase:epic:frame and clears stale approval.

The only valid hierarchy is Epic → Story → Task. Direct Epic Tasks and nested
Epics fail closed. Story Tasks retain prism/apply/implementer and
prism/apply/reviewer ownership inside the Story Apply loop.

## Prerequisites

1. Beads and a project workspace: bd where and bd prime.
2. Callee 0.19.0 or a compatible Router-capable release on PATH, with provider
   authentication for Role phases.
3. Discoverable Prism resources: callee agent list --agent-root pack/callee.

Do not use provider output to select a route. Do not invoke a direct Callee
graph when host Beads resolution is required; route the current item through
prism/lifecycle.

## Target resolver

Resolve exactly one operation using this priority order:

1. Explicit all-open-Epic batch intent. This is the only operation that
   traverses more than one item.
2. Explicit Story or Epic ID. Require the matching Beads issue type.
3. Explicit Task ID. Resolve exactly one Story parent; missing or ambiguous
   parentage fails closed.
4. Resume with no ID only when exactly one open Prism Story or Epic is
   unambiguous. Multiple candidates fail closed.
5. Clear multi-Story initiative intent. Create or resume an Epic.
6. Ordinary change intent. Create or resume a Story.

For a new Story use prism,phase:story:specify. For a new Epic use
prism,phase:epic:frame. Replace labels rather than inheriting a parent phase.
Never use an assignee as phase state.

## Route envelope

The host constructs one complete envelope before invoking the Router:

    ROUTE=story
    ITEM_ID=prism-...
    ITEM_TYPE=story
    ORIGINAL_REQUEST:
    <complete operator request>
    BEADS_CONTEXT:
    <current item, labels, phase, approval, children, and dependencies>

For an Epic, the first line is ROUTE=epic and ITEM_TYPE is epic. The first line
must be exactly ROUTE=story or ROUTE=epic followed by a newline (or end of input
when there is no further context). The Router's
anchored route template rejects unknown, blank, or malformed first lines; it
has no default child and never retries a different branch. The Router body
forwards the complete original prompt to the selected graph. The host never
lets a provider select an undeclared route.

Invoke the public root only after constructing the envelope:

    callee agent run prism/lifecycle --agent-root pack/callee --message "$envelope"

Persist the Callee artifact and Beads transition before selecting the next
phase. A selected child failure remains attached to the current item.

## Advance loop

For a Story, continue successful Specify → Design → Breakdown phases in one
invocation, enter Human, and stop for approval or refinement. After approval,
Apply advances one ready Task at a time and Verify closes or bounces.

For an Epic, continue Frame → Architecture → Roadmap in one invocation, enter
Approval, and stop for Epic-only approval. After approval, Delivery selects one
ready Story at a time. Each Story runs through the Story lifecycle and its own
approval; Epic approval never substitutes for it. Validation closes or bounces
the Epic without repairing implementation.

Persist and re-read the item after every Callee return. Do not ask the operator
to confirm routine phase transitions. Ask only for genuinely missing product
input or an approval/refinement decision.

## Output boundary

Normal host output — target resolution, route selection, phase progress, status,
errors, blockers, batch ledger rows, and normal Story or Epic phase results —
MUST NOT emit a standalone ### Acceptance criteria heading or an unsolicited
complete acceptance block.

The lifecycle-generated exception is the informed approval request for the
current item. It MUST present the complete current-item acceptance first. An
explicit operator request for acceptance criteria is also allowed. No other
phase, status, error, route, or batch output may print that section.

## Approval contracts

Story Human request, in exact order:

1. ### Acceptance criteria — complete, current Story only, untruncated.
2. ### Design summary.
3. ### Task summary.
4. ### Approval request.

Epic Approval request, in exact order:

1. ### Acceptance criteria — complete, current Epic only, untruncated.
2. ### Architecture summary.
3. ### Story roadmap.
4. ### Approval request explaining that child Stories still need their own
   implementation approvals.

Only an exact Callee Human approval result persists human:approved for the
same item. Refinement clears approval and returns Story to Design or Epic to
Architecture. Ambiguous, conditional, inquisitive, denied, or failed results
withhold approval at the current gate.

## Epic delivery and batch rules

Epic Delivery reads Beads readiness, selects one direct Story by priority,
creation time, then ID, and invokes that Story through a Story route envelope.
It stops at a child gate, blocker, invalid state, or failed checks. It never
creates direct Tasks, invokes children concurrently, or transfers approval.

Explicit all-open-Epic mode takes one invocation-start snapshot of open Beads
Epics labeled prism, sorted by priority, creation time, then ID. Maintain an
exactly-once ledger and one outcome row per snapshot ID, including an empty
snapshot. Continue after item-local gates, blockers, or failures. Do not rescan
newly opened Epics and do not transfer approval between items. Abort only when
the initial snapshot cannot be produced safely.

## Apply and Verify

Before each Story Task, claim exactly one ready child as
prism/apply/implementer, run the project-native checks, then assign
prism/apply/reviewer and inspect the actual diff independently. Close only
after checks and review pass. Repeat until no open child remains.

When all Story Tasks close, use phase:story:verify with human:approved. Verify
is close-or-bounce and never an implementation repair loop. For an Epic, use
phase:epic:validation after all direct Stories close.

## Failure and recovery

Fail closed before child activity for unknown or malformed routes, missing or
ambiguous targets, invalid hierarchy, multiple supported phases, missing
acceptance, ambiguous approval, unsafe reconciliation, missing Router support,
or digest/resolved-tree mismatch. Preserve the current item and report the
phase and next action. Batch item-local failures do not terminate later
snapshot items.

Do not modify unrelated lifecycle surfaces, bump release versions, or push.
