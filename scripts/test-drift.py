"""Exercise validators against isolated copies of the current working tree."""
import pathlib
import shutil
import subprocess
import sys
import tempfile

root = pathlib.Path(sys.argv[1]).resolve()
kind = sys.argv[2]
plugin = "prism"
validator = "validate-documentation.sh" if kind == "documentation" else "validate-lifecycle-ownership.sh"

def validate(path):
    return subprocess.run(["bash", str(path / "scripts" / validator), str(path)],
                          cwd=path, capture_output=True, text=True, check=False)

with tempfile.TemporaryDirectory(prefix="prism-drift-") as temporary:
    temp = pathlib.Path(temporary)
    baseline = temp / "baseline"
    shutil.copytree(root, baseline, ignore=shutil.ignore_patterns(
        ".git", ".beads", ".dolt", ".callee", "__pycache__"))
    result = validate(baseline)
    assert result.returncode == 0, result.stdout + result.stderr
    print("PASS: isolated working-tree baseline validates")
    cases = []
    if kind == "documentation":
        targets = ["https://github.com/baldaworks/prism-callee", "CONTRIBUTING.md",
                   "docs/comparison.md", "docs/team-workflow.md"]
        for target in targets:
            for replacement in ["", "https://example.invalid/wrong"]:
                cases.append(("README.md", "(" + target + ")", "(" + replacement + ")",
                              "FAIL: mandatory cross-link: " + target))
        cases.extend([
            ("README.md", "$prism:story Add CSV export to the report page.",
             "$prism:story", "FAIL: README shows a free-form request for $prism:story"),
            ("README.md", "## Quick start", "```text\n$prism:lifecycle\n```\n\n## Quick start",
             "FAIL: README primary example is the complete Story request"),
            ("README.md", "## Requirements", "Callee integration.\n\n## Requirements",
             "FAIL: README introduces Prism before optional Callee integration"),
            ("README.md", "## Optional integration", "## Other integration",
             "FAIL: Callee cross-link belongs to Optional integration"),
            ("README.md", "## Learn more", "## Ownership and validation\n\n## Learn more",
             "FAIL: README excludes maintenance policy: ## Ownership and validation"),
            ("README.md", "## License", "## Authority and license",
             "FAIL: README has a plain License section"),
            ("README.md", "## Learn more", "./scripts/validate-documentation.sh\n\n## Learn more",
             "FAIL: README excludes maintenance check ./scripts/validate-documentation.sh"),
            ("CONTRIBUTING.md", "./scripts/validate-documentation.sh", "",
             "FAIL: CONTRIBUTING lists maintenance check ./scripts/validate-documentation.sh"),
            ("CONTRIBUTING.md", "./scripts/test-documentation-drift-detection.sh", "",
             "FAIL: CONTRIBUTING lists maintenance check ./scripts/test-documentation-drift-detection.sh"),
            ("docs/comparison.md", "## Skill counts", "## Catalog",
             "FAIL: comparison covers ## Skill counts"),
            ("docs/comparison.md", "(team-workflow.md)", "(missing-team-guide.md)",
             "FAIL: docs/comparison.md local link resolves: missing-team-guide.md"),
            ("docs/team-workflow.md", "refs/dolt/data", "source branch",
             "FAIL: team guide covers refs/dolt/data"),
            ("docs/team-workflow.md", "Semantic review", "Review",
             "FAIL: docs/team-workflow.md distinguishes Semantic review"),
            ("docs/architecture-spec.md", "(../CONTRIBUTING.md)", "(../missing-contributing.md)",
             "FAIL: architecture links ../CONTRIBUTING.md"),
            ("README.md", f"${plugin}:lifecycle Add CSV export to the report page.",
             f"${plugin}:lifecycle", "FAIL: README shows a free-form request"),
            ("README.md", "## Quick start", "ROUTE=story\n\n## Quick start",
             "FAIL: README hides internal Callee protocol: ROUTE=story"),
            ("README.md", "(LICENSE)", "(missing-license)", "FAIL: README.md local link resolves: missing-license"),
            ("docs/architecture-host-lifecycle.md",
             "flowchart TB", "flowchart LR", "keeps Mermaid diagrams vertical"),
        ])

    else:
        cases.extend([
            ("plugins/prism/skills/story/references/specify.md",
             "then repeat interviewer → readiness gate", "silently bypass this step",
             "FAIL: host source digest matches:"),
            ("plugins/prism/prefixed-skills/prism-lifecycle/SKILL.md",
             "one outcome row for every snapshot ID", "silently bypass this step",
             "FAIL: router mirror matches: SKILL.md"),
        ])

    for index, (relative, old, new, expected) in enumerate(cases):
        mutant = temp / str(index)
        shutil.copytree(baseline, mutant)
        path = mutant / relative
        before = path.read_text()
        assert old in before, (relative, old)
        path.write_text(before.replace(old, new))
        result = validate(mutant)
        output = result.stdout + result.stderr
        assert result.returncode != 0 and expected in output, (relative, expected, output)
        print(f"PASS: rejects mutation {index + 1}: {relative}")
print(f"PASS: {kind} drift-detection fixtures")
