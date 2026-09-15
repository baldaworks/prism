# Prism, OpenSpec and BMAD

## One workflow from request to result

Run `prism:story` with a change request. Prism manages requirements, design,
task breakdown, approval, implementation, review and final verification. You
do not need to choose a new command for each phase. It pauses for necessary
clarification, approval or a blocker, then continues the same Story workflow.
See the [Story contract](../plugins/prism/skills/story/SKILL.md).

This is not a claim that only Prism offers end-to-end work. BMAD Build also
combines planning, implementation and review for a development unit. OpenSpec's
regular workflow exposes separate proposal, apply and archive actions; its
optional onboarding skill walks through a complete change as a tutorial.
[BMAD Build](https://docs.bmad-method.org/build/build-a-change/),
[OpenSpec skills](https://openspec.dev/docs/skills).

## Workflow comparison

| Dimension | Prism | OpenSpec | BMAD |
| --- | --- | --- | --- |
| Entry and orchestration | One Story skill owns the full six-phase lifecycle; the router can select Story or Epic. | Regular propose, apply and archive actions are separate. | Build handles one development unit; broader planning uses additional skills. |
| Approval | Required for every Story; Epic approval does not approve children. | Propose stops before implementation; Apply is separate. | The light path can implement without a separate full-plan approval; flagged designs require approval. |
| Requirements and design | REQ IDs, per-requirement acceptance and saved design in Beads. | Proposal, specification deltas, conditional design and tasks. | SPEC capabilities and success conditions; PRD, UX and architecture when needed. |
| Decomposition | Epic → Story → Task with acyclic dependencies; ready Stories delivered sequentially. | Change directories and configurable artifact schemas. | Spec-backed epic Stories or project-level epics and sprint planning. |
| Review | Required logical review pass over the actual diff and checks; not necessarily another model/process. | Optional Verify reports implementation alignment. | Build includes review/triage; standalone review has configurable reviewer layers. |
| Completion | Verify closes or returns to the defective phase; it does not repair code. | Verify reports; archive updates baseline specs and files the change away. | Build reviews and fixes its unit; larger work has tracking and additional checks. |
| Revising intent | Returning before Apply clears approval. | Edit Markdown or use Update, then continue Apply. | Update SPEC through its skill; Build can return a problem to the plan or intent. |
| Customization | Defined phase/role contracts in skills. | Artifact schemas, templates and dependencies. | Workflow/agent overrides, templates and review depth. |

Prism sources: [architecture](architecture-spec.md),
[Specify](../plugins/prism/skills/story/references/specify.md),
[Apply](../plugins/prism/skills/story/references/apply.md),
[Verify](../plugins/prism/skills/story/references/verify.md).
OpenSpec sources: [quickstart](https://openspec.dev/docs/quickstart),
[skills](https://openspec.dev/docs/skills),
[schemas](https://openspec.dev/docs/customize-schemas).
BMAD sources: [Build](https://docs.bmad-method.org/build/build-a-change/),
[specifications](https://docs.bmad-method.org/plan/define-requirements-and-a-specification/),
[tracking](https://docs.bmad-method.org/plan/break-work-into-stories-and-track-it/),
[review](https://docs.bmad-method.org/build/review-a-change/),
[customization](https://docs.bmad-method.org/customize/customize-bmad/).

## Skill counts

Count a distinct active skill, not a phase, alias, reference file or copy for
another coding agent. These are available capabilities, not required calls.

| Count | Prism | OpenSpec | BMAD v6.12.0 |
| --- | --- | --- | --- |
| Active skills in the compared scope | **3**: lifecycle, story, epic | **12**: 6 core + 6 optional | **29**: 8 core + 16 BMM workflows/tasks + 5 agent-persona skills |
| Default/optional distinction | Three primary skills; separate Callee integration excluded. | Core profile installs six; optional workflows must be selected. | Installed subset depends on selection; extra ecosystem modules excluded. |
| Duplicates excluded | Three prefixed mirrors; commands and phase references. | Coding-agent copies and slash aliases. | 21 compatibility shims; test fixtures and web bundles. |
| Typical user entry points | Story directly; router + Story uses two distinct skills. An Epic can involve all three. | Propose/apply/archive; optionally explore or verify. | Build alone for one unit; planning and internal helper calls vary. |

Counting method and evidence:

- Prism: count immediate `SKILL.md` children in
  [canonical skills](../plugins/prism/skills); do not add
  [prefixed mirrors](../plugins/prism/prefixed-skills).
- OpenSpec: count the six Core and six Optional entries in the
  [official catalog](https://openspec.dev/docs/skills), accessed 2026-09-15.
- BMAD: enumerate `src/**/SKILL.md` at
  [v6.12.0](https://github.com/bmad-code-org/BMAD-METHOD/tree/v6.12.0/src).
  There are 50 files, including 20 under `v6-shims/` and one additional
  [deprecated project-context shim](https://github.com/bmad-code-org/BMAD-METHOD/blob/v6.12.0/src/bmm-skills/plan/bmad-generate-project-context/SKILL.md)
  marked `metadata.lifecycle: shim`: 50 − 20 − 1 = 29. Five are personas.
  Counting only directories named `v6-shims` would incorrectly produce 30.

## Git multiplayer

| Mechanism | Prism / Beads | OpenSpec | BMAD |
| --- | --- | --- | --- |
| Shared state | Dolt records, alongside source Git history but not inside ordinary source commits. | Versioned specs, change artifacts and task files. | Versioned planning, implementation records and tracking files, if tracked by the team. |
| Transport | Source Git push/pull plus separate Beads Dolt push/pull; a Git remote can hold Dolt data in `refs/dolt/data`. | Normal Git commits, branches and PRs; Stores share planning across repos. | Normal Git workflow for tracked artifacts; team overrides are committed, personal overrides gitignored. |
| Concurrent work | Dependencies and ready selection; no global distributed Story lease in the Prism contract. | Separate change folders reduce collisions, but changes can conflict in shared specs. | Separate Stories reduce collisions, but shared sprint tracking can conflict. |
| Code/state consistency | No atomic transaction spanning source Git and Dolt history. | One commit can include code and artifacts in one repo, not atomically across repos. | One commit can include code and tracked artifacts in one repo. |

The transport descriptions follow
[Beads sync concepts](https://github.com/gastownhall/beads/blob/main/docs/core-concepts/sync-concepts.md),
[OpenSpec quickstart](https://openspec.dev/docs/quickstart),
[Stores (beta)](https://openspec.dev/docs/stores) and
[BMAD team adoption](https://docs.bmad-method.org/customize/adopt-bmad-across-a-team/).
The concurrency and atomicity limits are engineering implications of those
mechanisms, not measured failure rates. Git merging does not establish semantic
agreement. Prism's sequential delivery applies to one invocation, not a lock on
all clones. See [team workflow](team-workflow.md) for the practical handoff.

## Durability

| Level | Prism | OpenSpec | BMAD |
| --- | --- | --- | --- |
| Survives a chat ending | Saved Beads requirements, phase, approval and child graph. | Saved Markdown and task checkboxes. | Saved specifications, implementation records and tracking. |
| Version history | Dolt history separately from source Git; commit policy is configurable. | Git history after committing artifacts. | Git history after committing artifacts. |
| Machine loss | Requires a current remote copy or off-machine backup. | Requires pushed commits or another backup. | Requires pushed commits or another backup. |
| Interrupted execution | Re-read records and inspect code before resuming. | Reconcile task checkboxes with code before continuing. | Reconcile the implementation record/tracking with code. |
| Additional mechanisms | Beads native backup and issue export serve different purposes. | Schemas and artifacts can be versioned with the project. | Sprint generation uses atomic file replacement; rendered instructions have content-addressed snapshots. |

Stored state is not exactly-once execution. An agent can modify code before
recording progress. None of these descriptions establishes a transaction over
every filesystem edit, test, record update and external side effect.
Sources: [Prism state](architecture-spec.md),
[OpenSpec resumption](https://openspec.dev/docs/quickstart),
[Beads storage](https://github.com/gastownhall/beads/blob/main/docs/architecture/dolt.md),
BMAD v6.12.0 [sprint generator](https://github.com/bmad-code-org/BMAD-METHOD/blob/v6.12.0/src/bmm-skills/plan/bmad-sprint-planning/scripts/sprint_plan.py)
and [instruction renderer](https://github.com/bmad-code-org/BMAD-METHOD/blob/v6.12.0/src/scripts/render_skill.py).
An instruction snapshot is not a checkpoint of the model's execution.

## Validation

| Layer | Prism | OpenSpec | BMAD |
| --- | --- | --- | --- |
| Package integrity | Checks manifests, ownership, SHA-256 inventory, mirrors and documentation contracts. | Distinct from validating a user's specs. | Repository skill/link checks are distinct from project correctness. |
| Structural artifacts | Beads provides structured storage; Prism's own CI is not a universal validator of live Stories. | `openspec validate` checks changes/specs; `--strict` makes warnings fail and `--json` provides a report. | Python sprint tooling checks keys, statuses, dates and action items, preserving existing progress. |
| Semantic review | Readiness gates, task review, Story Verify and Epic Validation are model-executed contracts. | Optional Verify compares code with the plan; structural validation does not. | Model-based readiness and review lenses complement programmatic tracking. |
| Application tests | Relevant repository-native checks are required by Apply and Verify. | Run application tests separately from spec-format validation. | Build runs project checks; dedicated API/E2E generation and optional Test Architect add coverage. |

Sources: Prism [ownership validator](../scripts/validate-lifecycle-ownership.sh)
and [forward fixtures](../scripts/test-lifecycle-forward-contracts.sh),
[OpenSpec CLI](https://openspec.dev/docs/cli),
[BMAD readiness](https://docs.bmad-method.org/plan/break-work-into-stories-and-track-it/),
[review](https://docs.bmad-method.org/build/review-a-change/),
[QA](https://docs.bmad-method.org/build/test-completed-work/), and the versioned
sprint generator linked above.

In BMAD **v6.12.0**, `sprint_plan.py validate` normally exits 0 even when its
JSON says `valid: false`; CI must inspect `valid`, not just the process exit
code. Generate has a different failure contract and post-write validation.

Prism's forward fixtures use a real temporary Beads database, but also model
invariants with assertions and inspect instruction text. They do not prove that
every LLM execution obeys approval or correctly judges completion. Enforce
critical repository policies with permissions, branch protection and required
CI in addition to workflow instructions.

## Choosing a fit

Our assessment: choose Prism when you want one entry into a defined Story/Epic
lifecycle without manually coordinating phase commands. Choose OpenSpec when
maintaining and merging an evolving specification baseline is central. Consider
BMAD when you want adaptive Build plus a broader selection of product and
delivery tools. Three skills do not imply three steps, and a larger catalog
does not imply that every skill must run.

Evidence was checked on 2026-09-15 against Prism's source contracts, the
versioned BMAD files above and live official documentation. Counts are scoped
snapshots, not permanently current totals. This is a contract comparison, not
a benchmark of speed, token cost or defect rates. Upstream docs can move ahead
of a package; use the documentation for the version you install.
