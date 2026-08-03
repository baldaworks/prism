#!/usr/bin/env bash

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
fixture_root="$(mktemp -d /tmp/prism-callee-forward.XXXXXX)"
trap 'rm -rf "$fixture_root"' EXIT

cp -a "$repo_root/pack/callee" "$fixture_root/callee"
callee_root="$fixture_root/callee"

while IFS= read -r -d '' resource; do
  callee agent validate "$resource" >/dev/null
done < <(find "$callee_root/prism" -type f -name '*.md' -print0)

callee agent view prism/lifecycle --agent-root "$callee_root" --json >"$fixture_root/router.json"
callee agent view prism/story --agent-root "$callee_root" --json >"$fixture_root/story.json"
callee agent view prism/epic --agent-root "$callee_root" --json >"$fixture_root/epic.json"

python3 - "$repo_root" "$fixture_root" <<'PY'
import json
import pathlib
import re
import sys

repo_root = pathlib.Path(sys.argv[1])
fixture_root = pathlib.Path(sys.argv[2])
pack_root = fixture_root / "callee" / "prism"


def load(name: str) -> dict:
    return json.loads((fixture_root / name).read_text())


router = load("router.json")
story = load("story.json")
epic = load("epic.json")

router_resource = router["resource"]
router_spec = router_resource["spec"]
assert router_resource["kind"] == "Router"
assert [child["alias"] for child in router_spec["children"]] == ["story", "epic"]
assert [child["route"] for child in router_spec["children"]] == ["story", "epic"]
assert "regexFind" in router_spec["route"]
assert "trimPrefix" in router_spec["route"]
assert "default" not in router_spec
assert router_spec["body"].strip() == "{{ .Prompt }}"
router_tree = router["resolvedTree"]
assert [child["resourceId"] for child in router_tree["children"]] == ["prism/story", "prism/epic"]
print("PASS: isolated Router resolves exactly the declared Story and Epic branches")


def check_sequential_graph(
    graph: dict, expected_aliases: list[str], expected_refs: list[str]
) -> str:
    resource = graph["resource"]
    spec = resource["spec"]
    assert resource["kind"] == "Sequential"
    children = spec["children"]
    assert [child["alias"] for child in children] == expected_aliases
    assert [child["ref"] for child in children] == expected_refs
    assert all("{{ .Input }}" in child["input"] for child in children)
    assert spec["body"].strip() == "{{ .Input }}"
    return "\n".join(child["input"] for child in children)


story_inputs = check_sequential_graph(
    story,
    ["specify", "design", "breakdown", "human", "apply", "verify"],
    [
        "prism/phases/specify",
        "prism/phases/design",
        "prism/phases/breakdown",
        "prism/phases/human",
        "prism/phases/apply",
        "prism/phases/verify",
    ],
)
epic_inputs = check_sequential_graph(
    epic,
    ["frame", "architecture", "roadmap", "approval", "delivery", "validation"],
    [
        "prism/epic/phases/frame",
        "prism/epic/phases/architecture",
        "prism/epic/phases/roadmap",
        "prism/epic/phases/approval",
        "prism/epic/phases/delivery",
        "prism/epic/phases/validation",
    ],
)
assert all("prism/epic/" not in child["ref"] for child in story["resource"]["spec"]["children"])
assert all("prism/phases/" not in child["ref"] for child in epic["resource"]["spec"]["children"])
print("PASS: direct Story and Epic graphs preserve ordered, isolated six-phase contracts")


def approval_order(text: str, markers: list[str]) -> None:
    positions = [text.index(marker) for marker in markers]
    assert positions == sorted(positions)


story_text = (pack_root / "story.md").read_text()
epic_text = (pack_root / "epic.md").read_text()
lifecycle_text = (pack_root / "lifecycle.md").read_text()
marker = "### Acceptance criteria"
story_markers = [marker, "### Design summary", "### Task summary", "### Approval request"]
epic_markers = [marker, "### Architecture summary", "### Story roadmap", "### Approval request"]
approval_order(story_text, story_markers)
approval_order(epic_text, epic_markers)
assert story_text.count(marker) == 1 and epic_text.count(marker) == 1
assert marker not in lifecycle_text
assert "Do not emit this section outside" in story_text
assert "Do not emit this section outside" in epic_text
assert "MUST NOT emit a standalone ### Acceptance criteria heading" in (
    repo_root / "plugins/prism-callee/skills/lifecycle/SKILL.md"
).read_text()
print("PASS: normal Router output has no acceptance heading; Story/Epic approval is acceptance-first")


def route_for(message: str) -> str | None:
    match = re.match(r"^ROUTE=(story|epic)(?:\r?\n|$)", message)
    return match.group(1) if match else None


route_fixtures = {
    "ROUTE=story\nITEM_ID=prism-s1\n": "story",
    "ROUTE=epic\nITEM_ID=prism-e1\n": "epic",
    "ROUTE=story": "story",
    "ROUTE=unknown\nITEM_ID=prism-x1\n": None,
    "ITEM_ID=prism-x1\nROUTE=story\n": None,
    "ROUTE=story extra\nITEM_ID=prism-x1\n": None,
    "ROUTE=\nITEM_ID=prism-x1\n": None,
}
for message, expected in route_fixtures.items():
    assert route_for(message) == expected, (message, expected, route_for(message))
assert {route_for(message) for message in route_fixtures if route_for(message)} == {
    "story",
    "epic",
}
print("PASS: route fixtures accept Story/Epic envelopes and fail closed for malformed or unknown routes")


normal_outputs = [
    "ROUTE=story selected; phase=phase:story:design; status=advanced",
    "ROUTE=epic selected; phase=phase:epic:delivery; status=blocked",
    "error: unknown target; next action is to provide one Beads item ID",
    "batch ledger: prism-e1 outcome=approval-gate",
]
assert all(marker not in output for output in normal_outputs)
approval_outputs = [
    next(
        child["input"]
        for child in graph["resource"]["spec"]["children"]
        if child["alias"] == "human"
    )
    for graph in [story]
]
approval_outputs.append(
    next(
        child["input"]
        for child in epic["resource"]["spec"]["children"]
        if child["alias"] == "approval"
    )
)
assert all(marker in output for output in approval_outputs)
explicit_operator_output = "The operator explicitly requested acceptance criteria.\n### Acceptance criteria\ncomplete"
assert marker in explicit_operator_output
print("PASS: normal status/error fixtures suppress acceptance; informed and explicit requests permit it")


ownership = json.loads((repo_root / "docs/lifecycle-ownership.json").read_text())
assert ownership["beads"]["hierarchy"] == {
    "epic_children": "story",
    "story_children": "task",
    "nested_epics": False,
    "direct_epic_tasks": False,
}
assert ownership["approval"]["epic_approval_cascades_to_stories"] is False
graph = ownership["child_graph"]
complete = {
    "coverage": True,
    "cohesion": True,
    "reviewability": True,
    "verifiability": True,
    "dependencies": True,
    "separable_mega_item": False,
}
assert graph["numeric_minimum"] is None and graph["numeric_maximum"] is None
assert graph["one_child_can_pass"] and graph["more_than_twelve_can_pass"]
assert all(complete[key] for key in complete if key != "separable_mega_item")
assert not complete["separable_mega_item"]
assert not (complete | {"coverage": False})["coverage"]
assert (complete | {"separable_mega_item": True})["separable_mega_item"]
print("PASS: hierarchy, approval isolation, and qualitative graph fixtures are complete")
PY

"$repo_root/scripts/test-lifecycle-forward-contracts.sh"
echo "PASS: Callee lifecycle forward-contract fixtures"
