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
        targets = ["https://github.com/baldaworks/prism-callee"]
        for target in targets:
            for replacement in ["", "https://example.invalid/wrong"]:
                cases.append(("README.md", "(" + target + ")", "(" + replacement + ")",
                              "FAIL: mandatory cross-link: " + target))
        cases.extend([
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
