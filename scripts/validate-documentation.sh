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



documents = {relative: read(relative) for relative in [
    "README.md", "CONTRIBUTING.md", "docs/comparison.md", "docs/team-workflow.md",
    "docs/architecture-spec.md", "docs/architecture-host-lifecycle.md",
    "docs/architecture-story-lifecycle.md", "docs/architecture-epic-lifecycle.md",
]}
readme = documents["README.md"]
contributing = documents["CONTRIBUTING.md"]
plugin_name = "prism"
marketplace = json.loads(read(".agents/plugins/marketplace.json"))
record([p.get("name") for p in marketplace.get("plugins", [])] == [plugin_name], "marketplace contains only its own plugin")
record(marketplace.get("name") == plugin_name, "marketplace identity matches repository")
for marker in ["$prism:lifecycle","$prism:story","$prism:epic","/prism-lifecycle","/prism-story","/prism-epic"]:
    record(marker in readme, f"README documents public entrypoint {marker}")
record(f"${plugin_name}:lifecycle Add CSV export to the report page." in readme, f"README shows a free-form request for ${plugin_name}:lifecycle")
story_example = "$prism:story Add CSV export to the report page."
record(story_example in readme, "README shows a free-form request for $prism:story")
examples = re.findall(r"```text\s*\n(.*?)```", readme, flags=re.DOTALL)
record(bool(examples) and examples[0].strip() == story_example, "README primary example is the complete Story request")
record("Callee" not in readme.partition("## Story lifecycle")[0], "README introduces Prism before optional Callee integration")
for marker in ["## Ownership and validation", "## Authority and license",
               "Verified repository tasks are", "pushing and publishing require"]:
    record(marker not in readme, f"README excludes maintenance policy: {marker}")
record("## License\n" in readme, "README has a plain License section")
for marker in ["ROUTE=story", "ITEM_ID=", "ITEM_TYPE=", "BEADS_CONTEXT:", "callee agent run prism/lifecycle"]:
    record(marker not in readme, f"README hides internal Callee protocol: {marker}")
required_links = ["https://github.com/baldaworks/prism-callee", "CONTRIBUTING.md",
                  "docs/comparison.md", "docs/team-workflow.md"]
readme_links = re.findall(r"\[[^\]]+\]\(([^)]+)\)", readme)
for target in required_links:
    record(target in readme_links, f"mandatory cross-link: {target}")
optional = readme.partition("## Optional integration\n")[2]
record("(https://github.com/baldaworks/prism-callee)" in optional, "Callee cross-link belongs to Optional integration")
for marker in ["./scripts/validate-plugin-packaging.sh", "./scripts/validate-lifecycle-ownership.sh",
               "./scripts/validate-documentation.sh", "./scripts/test-lifecycle-drift-detection.sh",
               "./scripts/test-documentation-drift-detection.sh", "./scripts/test-lifecycle-forward-contracts.sh",
               "scripts/verify-published-split.sh"]:
    record(marker in contributing, f"CONTRIBUTING lists maintenance check {marker}")
    record(marker not in readme, f"README excludes maintenance check {marker}")
record("(docs/lifecycle-ownership.json)" in contributing, "CONTRIBUTING links ownership inventory")
comparison = documents["docs/comparison.md"]
for marker in ["## One workflow from request to result", "| Dimension | Prism | OpenSpec | BMAD |",
               "## Skill counts", "## Git multiplayer", "## Durability", "## Validation"]:
    record(marker in comparison, f"comparison covers {marker}")
team = documents["docs/team-workflow.md"]
for marker in ["## Git multiplayer", "## Durability and interrupted work", "## Validation layers",
               "bd bootstrap --dry-run", "bd dolt pull", "bd dolt push", "refs/dolt/data"]:
    record(marker in team, f"team guide covers {marker}")
for relative in ["docs/comparison.md", "docs/team-workflow.md"]:
    for layer in ["Package integrity", "Structural artifacts", "Semantic review", "Application tests"]:
        record(layer in documents[relative], f"{relative} distinguishes {layer}")
for relative, text in documents.items():
    record("callee agent import baldaworks/prism " not in text, f"{relative} excludes old Callee import source")
record("no Callee installation is required" in optional, "coding agent installation is independent of Callee")
architecture = documents["docs/architecture-spec.md"]
for target in ["../CONTRIBUTING.md", "comparison.md", "team-workflow.md"]:
    record(f"({target})" in architecture, f"architecture links {target}")
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
