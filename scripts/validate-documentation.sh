#!/usr/bin/env bash

set -euo pipefail

repo_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

python3 - "$repo_root" <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1]).resolve()
failures = []


def record(condition: bool, message: str) -> None:
    if condition:
        print(f"PASS: {message}")
    else:
        print(f"FAIL: {message}", file=sys.stderr)
        failures.append(message)


def read(relative: str) -> str:
    path = root / relative
    record(path.is_file(), f"{relative} exists")
    return path.read_text() if path.is_file() else ""


documents = {
    "README.md": read("README.md"),
    "docs/architecture-spec.md": read("docs/architecture-spec.md"),
    "docs/architecture-host-lifecycle.md": read("docs/architecture-host-lifecycle.md"),
    "docs/architecture-story-lifecycle.md": read("docs/architecture-story-lifecycle.md"),
    "docs/architecture-epic-lifecycle.md": read("docs/architecture-epic-lifecycle.md"),
    "docs/architecture-callee-lifecycle.md": read("docs/architecture-callee-lifecycle.md"),
    "docs/architecture-light-lifecycle.md": read("docs/architecture-light-lifecycle.md"),
    "docs/callee-lifecycle-smoke-test.md": read("docs/callee-lifecycle-smoke-test.md"),
}

readme = documents["README.md"]
architecture = documents["docs/architecture-spec.md"]
callee_doc = documents["docs/architecture-callee-lifecycle.md"]

marketplace_path = root / ".agents/plugins/marketplace.json"
marketplace = json.loads(marketplace_path.read_text()) if marketplace_path.is_file() else {}
marketplace_names = [entry.get("name") for entry in marketplace.get("plugins", [])]
record(
    marketplace_names[:3] == ["prism", "prism-callee", "prism-light"],
    "Codex marketplace preserves Prism host, Prism Callee, Prism Light priority",
)

priority_markers = ["| 1 | **prism**", "| 2 | **prism-callee**", "| 3 | **prism-light**"]
positions = [readme.find(marker) for marker in priority_markers]
record(all(position >= 0 for position in positions) and positions == sorted(positions), "README documents plugin priority")

for marker in [
    "$prism:lifecycle",
    "$prism:story",
    "$prism:epic",
    "$prism-callee:lifecycle",
    "$prism-light:lifecycle",
    "/prism-lifecycle",
    "/prism-story",
    "/prism-epic",
    "/prism-callee-lifecycle",
    "/prism-light",
]:
    record(marker in readme, f"README documents public entrypoint {marker}")

combined_docs = "\n".join(documents.values())
for retired in ["@baldaworks/callee@0.18.0", "plugins/prism/skills/light", "$prism:light", "/prism:light"]:
    record(retired not in combined_docs, f"documentation excludes retired marker {retired}")
record("`callee` `0.19.0`" in readme, "README documents the Callee 0.19.0 baseline")

freeform_request = "Add CSV export to the report page."
for entrypoint in ["$prism:lifecycle", "$prism-callee:lifecycle", "$prism-light:lifecycle"]:
    record(
        f"{entrypoint} {freeform_request}" in readme,
        f"README shows a free-form request for {entrypoint}",
    )

for internal_marker in [
    "ROUTE=story",
    "ITEM_ID=",
    "ITEM_TYPE=",
    "BEADS_CONTEXT:",
    "callee agent run prism/lifecycle",
]:
    record(internal_marker not in readme, f"README hides internal Callee protocol: {internal_marker}")

for relative in ["README.md", "docs/architecture-callee-lifecycle.md", "docs/callee-lifecycle-smoke-test.md"]:
    text = documents[relative]
    for marker in [
        "callee agent import baldaworks/prism",
        "--path pack/callee/prism",
        "--prefix prism",
        "--force",
        "callee agent view prism/lifecycle --json",
        "callee agent view prism/story --json",
        "callee agent view prism/epic --json",
    ]:
        record(marker in text, f"{relative} documents Callee catalog operation: {marker}")
    normalized = " ".join(text.replace("\\\n", " ").split())
    force_import = "callee agent import baldaworks/prism --path pack/callee/prism --prefix prism --force"
    record(force_import in normalized, f"{relative} contains the executable Callee force-import command")

for marker in ["kind `Router`", "stale", "Sequential"]:
    record(marker in callee_doc, f"Callee architecture documents catalog invariant: {marker}")
for marker in [
    "## Public UX and internal runtime",
    "## Internal runner ABI",
    "not the public Prism Callee UX",
]:
    record(marker in callee_doc, f"Callee architecture marks the runner boundary: {marker}")

smoke_doc = documents["docs/callee-lifecycle-smoke-test.md"]
for marker in ["pack-level test entrypoints", "not the public free-form plugin UX"]:
    record(marker in smoke_doc, f"Callee smoke test keeps pack internals maintainer-only: {marker}")

pack_lifecycle = read("pack/callee/prism/lifecycle.md")
record("kind: Router" in pack_lifecycle, "checked-in prism/lifecycle is a Router")
record((root / "pack/callee/prism/story.md").is_file(), "checked-in prism/story root exists")
record((root / "pack/callee/prism/epic.md").is_file(), "checked-in prism/epic root exists")

diagram_minimums = {
    "README.md": 2,
    "docs/architecture-spec.md": 5,
    "docs/architecture-host-lifecycle.md": 2,
    "docs/architecture-story-lifecycle.md": 2,
    "docs/architecture-epic-lifecycle.md": 2,
    "docs/architecture-callee-lifecycle.md": 1,
    "docs/architecture-light-lifecycle.md": 1,
}
for relative, minimum in diagram_minimums.items():
    blocks = re.findall(r"```mermaid\s*\n(.*?)```", documents[relative], flags=re.DOTALL)
    record(len(blocks) >= minimum, f"{relative} has at least {minimum} Mermaid lifecycle diagram(s)")
    record(all(block.lstrip().startswith("flowchart TB") for block in blocks), f"{relative} keeps Mermaid diagrams vertical")

for stale_section in ["[KNOWN]", "[INFERRED]", "## 7. Contacts", "### 5.2 Network Architecture", "### 6.2 Performance"]:
    record(stale_section not in architecture, f"architecture specification excludes generated boilerplate {stale_section}")

for marker in [
    "./scripts/validate-documentation.sh",
    "./scripts/test-documentation-drift-detection.sh",
]:
    record(marker in readme, f"README lists documentation check {marker}")

link_pattern = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
for relative, text in documents.items():
    source = root / relative
    for raw_target in link_pattern.findall(text):
        target = raw_target.strip().strip("<>")
        if target.startswith(("http://", "https://", "mailto:", "codex://", "#")):
            continue
        file_target = target.split("#", 1)[0]
        if not file_target:
            continue
        resolved = (source.parent / file_target).resolve()
        record(resolved.exists(), f"{relative} local link resolves: {target}")

if failures:
    print(f"\nDocumentation validation failed with {len(failures)} finding(s).", file=sys.stderr)
    raise SystemExit(1)

print("\nPASS: documentation contracts are current")
PY
