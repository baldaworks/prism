#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temp_root="$(mktemp -d "${TMPDIR:-/tmp}/prism-lifecycle-drift.XXXXXX")"
trap 'rm -rf "$temp_root"' EXIT

git clone --quiet --no-hardlinks "$repo_root" "$temp_root/repo"

if ! git -C "$repo_root" diff --quiet HEAD -- \
  docs/lifecycle-ownership.json \
  plugins/prism/skills/lifecycle/references \
  plugins/prism/prefixed-skills/prism-lifecycle/references \
  scripts/validate-lifecycle-ownership.sh \
  scripts/test-lifecycle-drift-detection.sh
then
  git -C "$repo_root" diff --binary HEAD -- \
    docs/lifecycle-ownership.json \
    plugins/prism/skills/lifecycle/references \
    plugins/prism/prefixed-skills/prism-lifecycle/references \
    scripts/validate-lifecycle-ownership.sh \
    scripts/test-lifecycle-drift-detection.sh \
    | git -C "$temp_root/repo" apply
fi

(
  cd "$temp_root/repo"
  ./scripts/validate-lifecycle-ownership.sh >/dev/null
)

for reference in \
  "$temp_root/repo/plugins/prism/skills/lifecycle/references/specify.md" \
  "$temp_root/repo/plugins/prism/prefixed-skills/prism-lifecycle/references/specify.md"
do
  sed -i \
    's/then repeat interviewer → readiness gate/then continue without merging the answers/' \
    "$reference"
done

if (
  cd "$temp_root/repo"
  ./scripts/validate-lifecycle-ownership.sh >"$temp_root/mutant.log" 2>&1
); then
  printf 'semantic drift mutant unexpectedly passed validation\n' >&2
  cat "$temp_root/mutant.log" >&2
  exit 1
fi

if ! grep -Fq \
  'FAIL: specify full host reference matches its reviewed semantic digest' \
  "$temp_root/mutant.log"
then
  printf 'semantic drift mutant failed for an unexpected reason\n' >&2
  cat "$temp_root/mutant.log" >&2
  exit 1
fi

printf 'PASS: lifecycle validator rejects synchronized semantic drift in full-host prose\n'
