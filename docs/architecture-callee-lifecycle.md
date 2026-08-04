# Prism Callee Story and Epic Lifecycle

`prism-callee:lifecycle` is the host integration for the specialized
`prism/*` Callee pack. The host resolves Beads state and authorization;
the Callee Router selects exactly one direct Story or Epic graph.

## Public surface

| Surface | Responsibility |
| --- | --- |
| `prism/lifecycle` | Deterministic Router for one Story or Epic envelope |
| `prism/story` | Direct Story graph: Specify, Design, Breakdown, Human, Apply, Verify |
| `prism/epic` | Direct Epic graph: Frame, Architecture, Roadmap, Approval, Delivery, Validation |

The only supported hierarchy is Epic → Story → Task. Nested Epics and direct
Epic Tasks fail closed. Epic approval covers only Epic architecture and
roadmap; every child Story needs its own implementation approval.

## Host-managed state

Story phases use exactly one of:

1. `phase:story:specify`
2. `phase:story:design`
3. `phase:story:breakdown`
4. `phase:story:human`
5. `phase:story:apply`
6. `phase:story:verify`

Epic phases use exactly one of:

1. `phase:epic:frame`
2. `phase:epic:architecture`
3. `phase:epic:roadmap`
4. `phase:epic:approval`
5. `phase:epic:delivery`
6. `phase:epic:validation`

Unsupported phase labels are absent and never migrated. Multiple supported
phases or a phase from the other item namespace fails closed.

The host constructs the Router envelope with an exact first line
`ROUTE=story` or `ROUTE=epic` (or a single-line envelope ending at
EOF), then preserves the complete original
request and current Beads context. Explicit all-open-Epic mode freezes one
ordered snapshot, visits each Epic exactly once, continues after item-local
gates or failures, and reports one outcome row per snapshot item without
rescanning.

## Approval and output boundary

Before Story Human approval, the host presents complete current-item
Acceptance criteria, Design summary, Task summary, then Approval request.
Before Epic Approval, it presents complete current-item Acceptance criteria,
Architecture summary, Story roadmap, then Approval request.

Normal route, phase, status, error, and non-gate output must not emit a
standalone or unsolicited `### Acceptance criteria` section. The complete
section is permitted in the informed current-item Human or Approval request,
or after an explicit operator request. Approval is stored only on the item
being approved.

## Direct Callee execution

The public invocation is:

```sh
envelope='ROUTE=story
ITEM_ID=prism-...
ITEM_TYPE=story
ORIGINAL_REQUEST:
...
BEADS_CONTEXT:
...'
callee agent run prism/lifecycle --message "$envelope"
```

Normal plugin execution resolves imported resources through Callee's default
agent catalog and does not depend on a Prism repository checkout. Use
`--agent-root pack/callee` only when maintaining and validating the checked-in
pack. The host remains the only owner of durable Beads transitions, child
selection, persistence, and explicit batch coordination.

## Sources

| Surface | Source |
| --- | --- |
| Host wrapper | `plugins/prism-callee/skills/lifecycle/` |
| Flat host wrapper | `plugins/prism-callee/prefixed-skills/prism-callee-lifecycle/` |
| Callee pack | `pack/callee/prism/` |

Namespaced and flat skill trees are behavioral mirrors. Ownership metadata
records every managed host source and every Callee pack Markdown source with
per-file and aggregate SHA-256 digests.
