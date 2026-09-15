# Contributing to Prism

## Ownership and integrity

`plugins/prism/` owns the router, Story and Epic skills. Canonical skills under
`skills/` and their `prefixed-skills/` counterparts are behavioral mirrors;
update both when changing a lifecycle contract. The
[ownership manifest](docs/lifecycle-ownership.json) records the checked sources
and digests. See [architecture](docs/architecture-spec.md) for the contracts.

The primary repository and [Prism Callee](https://github.com/baldaworks/prism-callee)
each have their own marketplace, integrity inventory and CI. They install and
validate independently. Keep the mandatory cross-links pointed at the exact
repository destinations.

## Validation

Run all six native checks from the repository root before completing a change:

```sh
./scripts/validate-plugin-packaging.sh
./scripts/validate-lifecycle-ownership.sh
./scripts/validate-documentation.sh
./scripts/test-lifecycle-drift-detection.sh
./scripts/test-documentation-drift-detection.sh
./scripts/test-lifecycle-forward-contracts.sh
```

Packaging and ownership checks protect manifests, mirrors and source digests.
Documentation checks cover required content, links and diagrams; mutation
fixtures prove that selected regressions fail validation. Forward fixtures use
a temporary Beads database and check lifecycle invariants. These checks do not
prove every model execution follows the instructions or validate every user's
live Story. Review the actual change and its relevant behavior as well.

When editing user documentation, keep the README focused on getting started.
Put product comparisons in [the comparison](docs/comparison.md), operational
guidance in [the team guide](docs/team-workflow.md), and maintenance here.

## Publication verification

Run `scripts/verify-published-split.sh` with the published Prism and Prism Callee
`main` commit SHAs, in that order:

```sh
./scripts/verify-published-split.sh <prism-main-sha> <prism-callee-main-sha>
```

This separate network check requires `gh`, `git`, `curl`, `jq`, `python3`, `rg`,
`bd`, and `callee`. It checks public links and successful CI, validates fresh
clones, and imports Callee into a temporary catalog without changing your
installed agents. It verifies already-published revisions; it does not publish
them and is not required for a local documentation-only change.

Provider-backed Human smoke tests are documented in
[Prism Callee](https://github.com/baldaworks/prism-callee/blob/main/docs/callee-lifecycle-smoke-test.md).
