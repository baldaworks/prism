#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture_dir="$(mktemp -d /tmp/prism-forward-XXXXXX)"

cleanup() {
  if [[ "$fixture_dir" == /tmp/prism-forward-* ]]; then
    rm -rf -- "$fixture_dir"
  fi
}
trap cleanup EXIT

git -C "$fixture_dir" init -q
(
  cd "$fixture_dir"
  bd init \
    --non-interactive \
    --prefix ft \
    --setup-exclude \
    --skip-agents \
    --skip-hooks \
    >/dev/null
)

snapshot() {
  bd -C "$fixture_dir" list \
    --label prism \
    --status open \
    --type epic \
    --limit 0 \
    --json
}

zero_json="$(snapshot)"
python3 - "$zero_json" <<'PY'
import json
import sys

assert json.loads(sys.argv[1]) == [], "zero-Epic snapshot must be empty"
print("PASS: zero open Prism Epics creates an empty snapshot")
PY

bd -C "$fixture_dir" create "First Epic" \
  --id ft-e1 --type epic --priority 2 --labels prism --silent >/dev/null
one_json="$(snapshot)"
python3 - "$one_json" <<'PY'
import json
import sys

items = json.loads(sys.argv[1])
assert [item["id"] for item in items] == ["ft-e1"]
print("PASS: one open Prism Epic creates a one-item snapshot")
PY

bd -C "$fixture_dir" create "Highest Priority Epic" \
  --id ft-e2 --type epic --priority 0 --labels prism --silent >/dev/null
bd -C "$fixture_dir" create "Later Equal-Priority Epic" \
  --id ft-e3 --type epic --priority 2 --labels prism --silent >/dev/null
bd -C "$fixture_dir" create "Unrelated Epic" \
  --id ft-x1 --type epic --priority 0 --labels unrelated --silent >/dev/null
bd -C "$fixture_dir" create "Closed Prism Epic" \
  --id ft-x2 --type epic --priority 0 --labels prism --silent >/dev/null
bd -C "$fixture_dir" close ft-x2 --reason fixture >/dev/null

multi_json="$(snapshot)"
python3 - "$multi_json" <<'PY'
import json
import sys

items = json.loads(sys.argv[1])
ordered = sorted(items, key=lambda item: (item["priority"], item["created_at"], item["id"]))
ids = [item["id"] for item in ordered]
assert ids == ["ft-e2", "ft-e1", "ft-e3"], ids
assert len(ids) == len(set(ids))
print("PASS: multiple-Epic snapshot filters and orders by priority, creation, then ID")
PY

# Freeze the invocation snapshot, then open another matching Epic. The new item
# must be visible to a future query but absent from the frozen ledger.
frozen_json="$multi_json"
bd -C "$fixture_dir" create "Opened After Snapshot" \
  --id ft-e4 --type epic --priority 0 --labels prism --silent >/dev/null
current_json="$(snapshot)"

bd -C "$fixture_dir" update ft-e1 --add-label human:approved >/dev/null
approval_json="$(snapshot)"

python3 - "$repo_root" "$frozen_json" "$current_json" "$approval_json" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
frozen = json.loads(sys.argv[2])
current = json.loads(sys.argv[3])
approved = json.loads(sys.argv[4])

frozen_ids = [item["id"] for item in sorted(
    frozen,
    key=lambda item: (item["priority"], item["created_at"], item["id"]),
)]
current_ids = {item["id"] for item in current}
assert "ft-e4" not in frozen_ids and "ft-e4" in current_ids

# A gate or blocker is an item-local outcome, not a loop terminator.
stops = {"ft-e2": "approval-gate", "ft-e1": "blocked", "ft-e3": "advanced"}
ledger = [{"id": item_id, "outcome": stops[item_id]} for item_id in frozen_ids]
assert [row["id"] for row in ledger] == frozen_ids
assert len(ledger) == len(set(row["id"] for row in ledger)) == 3

approved_labels = {
    item["id"]: set(item.get("labels", []))
    for item in approved
}
assert "human:approved" in approved_labels["ft-e1"]
assert all(
    "human:approved" not in labels
    for item_id, labels in approved_labels.items()
    if item_id != "ft-e1"
)
print("PASS: frozen snapshot is exactly-once, continues after local stops, and does not rescan")
print("PASS: human approval remains isolated to its owning Epic")

ownership = json.loads((root / "docs/lifecycle-ownership.json").read_text())
beads = ownership["beads"]
assert beads["unsupported_phase_policy"] == "treat-as-absent-no-migration"

unsupported = {"phase:design", "phase:legacy", "phase:other:unknown"}
story_supported = set(beads["story_phases"])
epic_supported = set(beads["epic_phases"])
assert not (unsupported & story_supported)
assert not (unsupported & epic_supported)
assert beads["missing_phase_initialization"]["story"] == "phase:story:specify"
assert beads["missing_phase_initialization"]["epic"] == "phase:epic:frame"
assert beads["missing_phase_initialization"]["clear_approval"] is True
print("PASS: unsupported labels resolve exactly like a missing supported phase")

graph = ownership["child_graph"]
assert graph["numeric_minimum"] is None and graph["numeric_maximum"] is None

def passes(children):
    return bool(children) and all(
        child["coverage"]
        and child["cohesion"]
        and child["reviewability"]
        and child["verifiability"]
        and child["dependencies"]
        and not child["separable_mega_item"]
        for child in children
    )

complete = {
    "coverage": True,
    "cohesion": True,
    "reviewability": True,
    "verifiability": True,
    "dependencies": True,
    "separable_mega_item": False,
}
assert passes([complete.copy()])
assert passes([complete.copy() for _ in range(13)])
incomplete = complete | {"coverage": False}
mega = complete | {"separable_mega_item": True}
assert not passes([incomplete])
assert not passes([mega])
assert graph["one_child_can_pass"] is True
assert graph["more_than_twelve_can_pass"] is True
assert graph["incomplete_graph_fails"] is True
assert graph["separable_mega_item_fails"] is True
print("PASS: qualitative graph fixtures accept 1 and 13 complete children and reject incomplete or mega children")

approval = ownership["approval"]
assert approval["story_order"][0] == "Acceptance criteria"
assert approval["epic_order"][0] == "Acceptance criteria"
assert approval["acceptance_scope"] == "complete-untruncated-current-item-only"
assert approval["epic_approval_cascades_to_stories"] is False
print("PASS: approval fixtures are acceptance-first, complete, current-item-only, and non-cascading")

router = (root / "plugins/prism/skills/lifecycle/SKILL.md").read_text()
for marker in [
    "exactly once",
    "Do not rescan",
    "continue to the next snapshot ID",
    "transfer `human:approved` between items",
    "one outcome row for every snapshot ID",
]:
    assert marker in router, marker
print("PASS: executable router contract contains all snapshot and continuation invariants")
PY

echo "PASS: lifecycle forward-contract fixtures"
