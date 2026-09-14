#!/usr/bin/env bash
# Explicit, network-backed release check; not part of offline host validation.
set -euo pipefail

if [[ $# != 2 ]]; then
  echo 'usage: verify-published-split.sh <prism-main-sha> <prism-callee-main-sha>' >&2
  exit 2
fi
host_sha="$1"
callee_sha="$2"
verification_root="$(mktemp -d /tmp/prism-published.XXXXXX)"
trap 'rm -rf -- "$verification_root"' EXIT

public_link() {
  local url="$1" marker="$2"
  curl -q --fail --silent --show-error --location --retry 2 "$url" >"$verification_root/page"
  if ! rg -Fq "$marker" "$verification_root/page"; then
    echo "FAIL: public destination content does not match: $url" >&2
    exit 1
  fi
  echo "PASS: public link $url"
}

public_link https://github.com/baldaworks/prism 'baldaworks/prism'
public_link https://github.com/baldaworks/prism-callee 'baldaworks/prism-callee'
for skill in lifecycle story epic; do
  public_link "https://github.com/baldaworks/prism/blob/main/plugins/prism/skills/$skill/SKILL.md" "name: $skill"
done
public_link https://github.com/baldaworks/prism-callee/tree/main/pack/callee/prism 'prism'

for repo in prism prism-callee; do
  expected="$host_sha"
  [[ "$repo" != prism-callee ]] || expected="$callee_sha"
  metadata="$(gh api "repos/baldaworks/$repo")"
  jq -e '.visibility == "public" and .default_branch == "main"' <<<"$metadata" >/dev/null
  git clone --quiet --branch main --single-branch "https://github.com/baldaworks/$repo.git" "$verification_root/$repo"
  actual="$(git -C "$verification_root/$repo" rev-parse HEAD)"
  [[ "$actual" == "$expected" ]] || { echo "FAIL: $repo main changed: $actual" >&2; exit 1; }
  gh run list --repo "baldaworks/$repo" --workflow ci.yml --commit "$actual" --event push --limit 1 \
    --json headSha,status,conclusion | jq -e --arg sha "$actual" \
    'length == 1 and .[0].headSha == $sha and .[0].status == "completed" and .[0].conclusion == "success"' >/dev/null
  (
    cd "$verification_root/$repo"
    ./scripts/validate-plugin-packaging.sh
    ./scripts/validate-lifecycle-ownership.sh
    ./scripts/validate-documentation.sh
    ./scripts/test-lifecycle-drift-detection.sh
    ./scripts/test-documentation-drift-detection.sh
    if [[ "$repo" == prism ]]; then
      ./scripts/test-lifecycle-forward-contracts.sh
    else
      ./scripts/test-callee-lifecycle-forward-contracts.sh
    fi
  )
  echo "PASS: $repo published head $actual, CI and clean-clone checks"
done

test ! -e "$verification_root/prism/pack/callee"
test ! -e "$verification_root/prism/plugins/prism-callee"
test ! -e "$verification_root/prism-callee/plugins/prism"
python3 - "$verification_root/prism-callee" <<'PY'
import hashlib
import json
import pathlib
import sys
root = pathlib.Path(sys.argv[1])
provenance = json.loads((root / 'docs/extraction-provenance.json').read_text())
actual = sorted(p.relative_to(root).as_posix() for p in (root / 'pack/callee').rglob('*') if p.is_file())
assert actual == sorted(item['path'] for item in provenance['files'])
for item in provenance['files']:
    assert hashlib.sha256((root / item['path']).read_bytes()).hexdigest() == item['sha256'], item['path']
print(f"PASS: all {len(actual)} published pack files match extraction provenance")
PY

callee agent import baldaworks/prism-callee --ref "$callee_sha" \
  --path pack/callee/prism --prefix prism --agent-root "$verification_root/catalog"
callee agent list --agent-root "$verification_root/catalog" --json >"$verification_root/catalog.json"
for entry in lifecycle story epic; do
  expected_kind=Sequential
  [[ "$entry" != lifecycle ]] || expected_kind=Router
  callee agent view "prism/$entry" --agent-root "$verification_root/catalog" --json |
    jq -e --arg kind "$expected_kind" '.resource.kind == $kind' >/dev/null
done
echo 'PASS: published Callee import resolves Router, Story and Epic in an isolated catalog'
echo 'PASS: published split verification'
