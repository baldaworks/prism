#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temp_root="$(mktemp -d "${TMPDIR:-/tmp}/prism-documentation-drift.XXXXXX")"
trap 'rm -rf "$temp_root"' EXIT

baseline="$temp_root/baseline"
git clone --quiet --no-hardlinks "$repo_root" "$baseline"

cp "$repo_root/README.md" "$baseline/README.md"
rm -rf "$baseline/docs"
cp -a "$repo_root/docs" "$baseline/docs"
cp "$repo_root/scripts/validate-documentation.sh" "$baseline/scripts/validate-documentation.sh"
cp "$repo_root/scripts/test-documentation-drift-detection.sh" "$baseline/scripts/test-documentation-drift-detection.sh"

"$baseline/scripts/validate-documentation.sh" "$baseline" >/dev/null
printf 'PASS: documentation baseline validates\n'

stale_version="$temp_root/stale-version"
cp -a "$baseline" "$stale_version"
sed -i 's/`callee` `0.19.0`/`callee` `0.18.0`/' "$stale_version/README.md"
if "$stale_version/scripts/validate-documentation.sh" "$stale_version" >"$temp_root/stale-version.log" 2>&1; then
  printf 'stale Callee version unexpectedly passed documentation validation\n' >&2
  exit 1
fi
rg -Fq 'FAIL: README documents the Callee 0.19.0 baseline' "$temp_root/stale-version.log"
printf 'PASS: validator rejects a stale Callee baseline\n'

horizontal_diagram="$temp_root/horizontal-diagram"
cp -a "$baseline" "$horizontal_diagram"
sed -i '0,/flowchart TB/s//flowchart LR/' "$horizontal_diagram/docs/architecture-light-lifecycle.md"
if "$horizontal_diagram/scripts/validate-documentation.sh" "$horizontal_diagram" >"$temp_root/horizontal-diagram.log" 2>&1; then
  printf 'horizontal lifecycle diagram unexpectedly passed documentation validation\n' >&2
  exit 1
fi
rg -Fq 'FAIL: docs/architecture-light-lifecycle.md keeps Mermaid diagrams vertical' "$temp_root/horizontal-diagram.log"
printf 'PASS: validator rejects a horizontal lifecycle diagram\n'

stale_catalog="$temp_root/stale-catalog"
cp -a "$baseline" "$stale_catalog"
sed -i 's/  --force/  --debug/' "$stale_catalog/docs/architecture-callee-lifecycle.md"
if "$stale_catalog/scripts/validate-documentation.sh" "$stale_catalog" >"$temp_root/stale-catalog.log" 2>&1; then
  printf 'missing Callee refresh command unexpectedly passed documentation validation\n' >&2
  exit 1
fi
rg -Fq 'FAIL: docs/architecture-callee-lifecycle.md contains the executable Callee force-import command' "$temp_root/stale-catalog.log"
printf 'PASS: validator rejects a missing Callee refresh path\n'

broken_link="$temp_root/broken-link"
cp -a "$baseline" "$broken_link"
sed -i 's|(architecture-host-lifecycle.md)|(missing-host-lifecycle.md)|' "$broken_link/docs/architecture-spec.md"
if "$broken_link/scripts/validate-documentation.sh" "$broken_link" >"$temp_root/broken-link.log" 2>&1; then
  printf 'broken documentation link unexpectedly passed validation\n' >&2
  exit 1
fi
rg -Fq 'FAIL: docs/architecture-spec.md local link resolves: missing-host-lifecycle.md' "$temp_root/broken-link.log"
printf 'PASS: validator rejects a broken local link\n'

printf 'PASS: documentation drift-detection fixtures\n'
