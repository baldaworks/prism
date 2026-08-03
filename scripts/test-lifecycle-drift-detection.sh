#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temp_root="$(mktemp -d "${TMPDIR:-/tmp}/prism-lifecycle-drift.XXXXXX")"
trap 'rm -rf "$temp_root"' EXIT

baseline="$temp_root/baseline"
git clone --quiet --no-hardlinks "$repo_root" "$baseline"

# Overlay the complete task-scoped working state, including new untracked skills.
python3 - "$repo_root" "$baseline" <<'PY'
import pathlib
import shutil
import sys

source = pathlib.Path(sys.argv[1])
target = pathlib.Path(sys.argv[2])
directories = [
    "plugins/prism/skills",
    "plugins/prism/prefixed-skills",
    "plugins/prism-callee/skills",
    "plugins/prism-callee/prefixed-skills",
    "pack/callee/prism",
]
files = [
    "docs/lifecycle-ownership.json",
    "scripts/validate-lifecycle-ownership.sh",
    "scripts/test-lifecycle-drift-detection.sh",
]
for relative in directories:
    destination = target / relative
    shutil.rmtree(destination)
    shutil.copytree(source / relative, destination)
for relative in files:
    shutil.copy2(source / relative, target / relative)
PY

(
  cd "$baseline"
  ./scripts/validate-lifecycle-ownership.sh >/dev/null
)
printf 'PASS: digest-locked lifecycle baseline validates\n'

synchronized="$temp_root/synchronized-pack-change"
cp -a "$baseline" "$synchronized"
sed -i \
  's/explicit dependencies/necessary explicit dependencies/' \
  "$synchronized/pack/callee/prism/phases/breakdown.md"
python3 - "$synchronized" <<'PY'
import hashlib
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
mapping_path = root / "docs/lifecycle-ownership.json"
mapping = json.loads(mapping_path.read_text())
section = mapping["integrity"]["callee_pack"]
anchor = root / section["root"]
paths = [anchor / item["path"] for item in section["sources"]]
for item, path in zip(section["sources"], paths):
    item["sha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
digest = hashlib.sha256()
for path in sorted(paths, key=lambda item: item.relative_to(anchor).as_posix()):
    digest.update(path.relative_to(anchor).as_posix().encode())
    digest.update(b"\0")
    digest.update(path.read_bytes())
    digest.update(b"\0")
section["aggregate_sha256"] = digest.hexdigest()
mapping_path.write_text(json.dumps(mapping, indent=2) + "\n")
PY
if git -C "$synchronized" diff --quiet HEAD -- pack/callee; then
  printf 'disposable synchronized pack mutation did not differ from HEAD\n' >&2
  exit 1
fi
(
  cd "$synchronized"
  ./scripts/validate-lifecycle-ownership.sh >/dev/null
)
printf 'PASS: synchronized digest-locked Callee pack evolution validates before commit\n'

host_mutant="$temp_root/host-mutant"
cp -a "$baseline" "$host_mutant"
sed -i \
  's/then repeat interviewer → readiness gate/then continue without merging the answers/' \
  "$host_mutant/plugins/prism/skills/story/references/specify.md"

if (
  cd "$host_mutant"
  ./scripts/validate-lifecycle-ownership.sh >"$temp_root/host-mutant.log" 2>&1
); then
  printf 'canonical host-source drift unexpectedly passed validation\n' >&2
  exit 1
fi
if ! rg -Fq \
  'FAIL: host source digest matches: plugins/prism/skills/story/references/specify.md' \
  "$temp_root/host-mutant.log"
then
  printf 'canonical host-source mutant failed for an unexpected reason\n' >&2
  sed -n '1,220p' "$temp_root/host-mutant.log" >&2
  exit 1
fi
printf 'PASS: lifecycle validator rejects canonical host-source drift\n'

flat_mutant="$temp_root/flat-mutant"
cp -a "$baseline" "$flat_mutant"
sed -i \
  's/one outcome row for every snapshot ID/one partial outcome row for some snapshot IDs/' \
  "$flat_mutant/plugins/prism/prefixed-skills/prism-lifecycle/SKILL.md"

if (
  cd "$flat_mutant"
  ./scripts/validate-lifecycle-ownership.sh >"$temp_root/flat-mutant.log" 2>&1
); then
  printf 'flat mirror drift unexpectedly passed validation\n' >&2
  exit 1
fi
if ! rg -Fq 'FAIL: router mirror matches: SKILL.md' "$temp_root/flat-mutant.log"
then
  printf 'flat mirror mutant failed for an unexpected reason\n' >&2
  sed -n '1,220p' "$temp_root/flat-mutant.log" >&2
  exit 1
fi
printf 'PASS: lifecycle validator rejects flat mirror drift\n'

pack_mutant="$temp_root/pack-mutant"
cp -a "$baseline" "$pack_mutant"
sed -i \
  's/There is no numeric minimum or/Use a fixed child count; there is no/' \
  "$pack_mutant/pack/callee/prism/phases/breakdown.md"

if (
  cd "$pack_mutant"
  ./scripts/validate-lifecycle-ownership.sh >"$temp_root/pack-mutant.log" 2>&1
); then
  printf 'Callee pack drift unexpectedly passed validation\n' >&2
  exit 1
fi
if ! rg -Fq \
  'FAIL: Callee pack source digest matches: prism/phases/breakdown.md' \
  "$temp_root/pack-mutant.log"
then
  printf 'Callee pack mutant failed for an unexpected reason\n' >&2
  sed -n '1,220p' "$temp_root/pack-mutant.log" >&2
  exit 1
fi
printf 'PASS: lifecycle validator rejects Callee pack source drift\n'
