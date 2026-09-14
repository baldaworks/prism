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



documents = {relative: read(relative) for relative in ["README.md","docs/architecture-spec.md","docs/architecture-host-lifecycle.md","docs/architecture-story-lifecycle.md","docs/architecture-epic-lifecycle.md"]}
readme = documents["README.md"]
plugin_name = "prism"
marketplace = json.loads(read(".agents/plugins/marketplace.json"))
record([p.get("name") for p in marketplace.get("plugins", [])] == [plugin_name], "marketplace contains only its own plugin")
record(marketplace.get("name") == plugin_name, "marketplace identity matches repository")
for marker in ["$prism:lifecycle","$prism:story","$prism:epic","/prism-lifecycle","/prism-story","/prism-epic"]:
    record(marker in readme, f"README documents public entrypoint {marker}")
record(f"${plugin_name}:lifecycle Add CSV export to the report page." in readme, f"README shows a free-form request for ${plugin_name}:lifecycle")
for marker in ["ROUTE=story", "ITEM_ID=", "ITEM_TYPE=", "BEADS_CONTEXT:", "callee agent run prism/lifecycle"]:
    record(marker not in readme, f"README hides internal Callee protocol: {marker}")
required_links = ["https://github.com/baldaworks/prism-callee"]
readme_links = re.findall(r"\[[^\]]+\]\(([^)]+)\)", readme)
for target in required_links:
    record(target in readme_links, f"mandatory cross-link: {target}")
for marker in ["./scripts/validate-documentation.sh", "./scripts/test-documentation-drift-detection.sh"]:
    record(marker in readme, f"README lists documentation check {marker}")
for relative, text in documents.items():
    record("callee agent import baldaworks/prism " not in text, f"{relative} excludes old Callee import source")
record("no Callee installation is required" in readme, "host installation is independent of Callee")
architecture = documents["docs/architecture-spec.md"]
for marker in ["[KNOWN]", "[INFERRED]", "## 7. Contacts", "### 5.2 Network Architecture", "### 6.2 Performance"]:
    record(marker not in architecture, f"architecture specification excludes generated boilerplate {marker}")

diagram_minimums = {"README.md":2,"docs/architecture-spec.md":5,"docs/architecture-host-lifecycle.md":2,"docs/architecture-story-lifecycle.md":2,"docs/architecture-epic-lifecycle.md":2}
for relative, minimum in diagram_minimums.items():
    blocks = re.findall(r"```mermaid\s*\n(.*?)```", documents[relative], flags=re.DOTALL)
    record(len(blocks) >= minimum, f"{relative} has at least {minimum} Mermaid lifecycle diagram(s)")
    record(all(block.lstrip().startswith("flowchart TB") for block in blocks), f"{relative} keeps Mermaid diagrams vertical")

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
