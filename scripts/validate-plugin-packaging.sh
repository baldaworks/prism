#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$repo_root" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])

namespaced_plugin_checks = [
    {
        "plugin": "prism",
        "root": root / "plugins/prism",
        "expected_name": "prism",
    },
    {
        "plugin": "prism-callee",
        "root": root / "plugins/prism-callee",
        "expected_name": "prism-callee",
    },
]

flat_plugin_checks = [
    {
        "plugin": "prism",
        "host": "cursor",
        "manifest": root / "plugins/prism/.cursor-plugin/plugin.json",
        "expected_name": "prism",
        "expected_skills": "./prefixed-skills/",
        "allowed_extra_fields": {"displayName"},
    },
    {
        "plugin": "prism-callee",
        "host": "cursor",
        "manifest": root / "plugins/prism-callee/.cursor-plugin/plugin.json",
        "expected_name": "prism-callee",
        "expected_skills": "./prefixed-skills/",
        "allowed_extra_fields": {"displayName"},
    },
    {
        "plugin": "prism",
        "host": "grok",
        "manifest": root / "plugins/prism/.grok-plugin/plugin.json",
        "expected_name": "prism",
        "expected_skills": "./prefixed-skills/",
        "allowed_extra_fields": set(),
    },
    {
        "plugin": "prism-callee",
        "host": "grok",
        "manifest": root / "plugins/prism-callee/.grok-plugin/plugin.json",
        "expected_name": "prism-callee",
        "expected_skills": "./prefixed-skills/",
        "allowed_extra_fields": set(),
    },
    {
        "plugin": "prism",
        "host": "generic",
        "manifest": root / "plugins/prism/.plugin/plugin.json",
        "expected_name": "prism",
        "expected_skills": "./prefixed-skills/",
        "allowed_extra_fields": set(),
    },
    {
        "plugin": "prism-callee",
        "host": "generic",
        "manifest": root / "plugins/prism-callee/.plugin/plugin.json",
        "expected_name": "prism-callee",
        "expected_skills": "./prefixed-skills/",
        "allowed_extra_fields": set(),
    },
]

namespaced_shared_manifest_fields = [
    "name",
    "description",
    "author",
    "homepage",
    "repository",
    "license",
    "keywords",
    "skills",
]

shared_interface_fields = [
    "displayName",
    "shortDescription",
    "longDescription",
    "developerName",
    "category",
    "capabilities",
]

flat_shared_manifest_fields = [
    "name",
    "description",
    "author",
    "homepage",
    "repository",
    "license",
    "keywords",
]

allowed_host_specific_fields = {
    "codex": set(),
    "claude": set(),
}

expected_default_prompts = {
    "prism": {
        "codex": "Use $prism:lifecycle to inspect the current Beads story state and advance the Prism lifecycle in this repository.",
        "claude": "Use /prism:lifecycle to inspect the current Beads story state and advance the Prism lifecycle in this repository.",
    },
    "prism-callee": {
        "codex": "Use $prism-callee:lifecycle to run a Prism story through specialized prism/* subagents and the explicit Callee Human approval gate.",
        "claude": "Use /prism-callee:lifecycle to run a Prism story through specialized prism/* subagents and the explicit Callee Human approval gate.",
    },
}

errors = []


def record(condition: bool, message: str) -> None:
    if condition:
        print(f"PASS: {message}")
    else:
        errors.append(message)
        print(f"FAIL: {message}")


def load_json(path: pathlib.Path):
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError as exc:
        errors.append(f"{path.relative_to(root)} is valid JSON: {exc}")
        print(f"FAIL: {path.relative_to(root)} is valid JSON: {exc}")
        return None


def expected_skills_dir(plugin_root: pathlib.Path, manifest_data: dict) -> pathlib.Path:
    return plugin_root / str(manifest_data.get("skills", "")).removeprefix("./")


def validate_manifest_common(
    manifest_path: pathlib.Path,
    manifest_data: dict,
    expected_name: str,
    expected_skills: str,
    plugin_root: pathlib.Path,
) -> None:
    record(
        manifest_data.get("name") == expected_name,
        f"{manifest_path.relative_to(root)} name is {expected_name}",
    )
    record(
        manifest_data.get("skills") == expected_skills,
        f"{manifest_path.relative_to(root)} skills path is {expected_skills}",
    )
    record(
        bool(str(manifest_data.get("description", "")).strip()),
        f"{manifest_path.relative_to(root)} has a non-empty description",
    )
    record(
        bool(str(manifest_data.get("version", "")).strip()),
        f"{manifest_path.relative_to(root)} has a non-empty version",
    )

    skills_dir = expected_skills_dir(plugin_root, manifest_data)
    record(
        skills_dir.is_dir(),
        f"{manifest_path.relative_to(root)} skills directory exists at {skills_dir.relative_to(root)}",
    )


def validate_namespaced_pair(check: dict) -> None:
    plugin_root = check["root"]
    codex_manifest_path = plugin_root / ".codex-plugin/plugin.json"
    claude_manifest_path = plugin_root / ".claude-plugin/plugin.json"

    record(codex_manifest_path.is_file(), f"{codex_manifest_path.relative_to(root)} exists")
    record(claude_manifest_path.is_file(), f"{claude_manifest_path.relative_to(root)} exists")
    if not codex_manifest_path.is_file() or not claude_manifest_path.is_file():
        return

    codex_data = load_json(codex_manifest_path)
    claude_data = load_json(claude_manifest_path)
    if codex_data is None or claude_data is None:
        return

    for manifest_path, data in [
        (codex_manifest_path, codex_data),
        (claude_manifest_path, claude_data),
    ]:
        validate_manifest_common(
            manifest_path,
            data,
            check["expected_name"],
            "./skills/",
            plugin_root,
        )

    for field in namespaced_shared_manifest_fields:
        record(
            codex_data.get(field) == claude_data.get(field),
            f"{check['plugin']} Codex and Claude manifests match for {field}",
        )

    codex_interface = codex_data.get("interface", {})
    claude_interface = claude_data.get("interface", {})
    for field in shared_interface_fields:
        record(
            codex_interface.get(field) == claude_interface.get(field),
            f"{check['plugin']} Codex and Claude interface matches for {field}",
        )

    expected_prompts = expected_default_prompts[check["plugin"]]
    record(
        codex_interface.get("defaultPrompt") == expected_prompts["codex"],
        f"{check['plugin']} Codex defaultPrompt matches the expected Codex entrypoint",
    )
    record(
        claude_interface.get("defaultPrompt") == expected_prompts["claude"],
        f"{check['plugin']} Claude defaultPrompt matches the expected Claude entrypoint",
    )

    expected_namespaced_fields = set(namespaced_shared_manifest_fields) | {"version", "interface"}
    codex_extra_fields = set(codex_data.keys()) - expected_namespaced_fields
    claude_extra_fields = set(claude_data.keys()) - expected_namespaced_fields
    record(
        codex_extra_fields == allowed_host_specific_fields["codex"],
        f"{check['plugin']} Codex-only manifest fields are explicit: {sorted(allowed_host_specific_fields['codex'])}",
    )
    record(
        claude_extra_fields == allowed_host_specific_fields["claude"],
        f"{check['plugin']} Claude-only manifest fields are explicit: {sorted(allowed_host_specific_fields['claude'])}",
    )


def validate_flat_manifest(check: dict, baseline: dict) -> None:
    manifest_path = check["manifest"]
    plugin_root = manifest_path.parent.parent

    record(manifest_path.is_file(), f"{manifest_path.relative_to(root)} exists")
    if not manifest_path.is_file():
        return

    manifest_data = load_json(manifest_path)
    if manifest_data is None:
        return

    validate_manifest_common(
        manifest_path,
        manifest_data,
        check["expected_name"],
        check["expected_skills"],
        plugin_root,
    )

    for field in flat_shared_manifest_fields:
        record(
            manifest_data.get(field) == baseline.get(field),
            f"{manifest_path.relative_to(root)} matches the prism Codex baseline for {field}",
        )

    expected_display_name = baseline.get("interface", {}).get("displayName")
    if "displayName" in check["allowed_extra_fields"]:
        record(
            manifest_data.get("displayName") == expected_display_name,
            f"{manifest_path.relative_to(root)} displayName matches the prism Codex baseline",
        )

    expected_fields = set(flat_shared_manifest_fields) | {"version", "skills"} | check["allowed_extra_fields"]
    extra_fields = set(manifest_data.keys()) - expected_fields
    record(
        extra_fields == set(),
        f"{manifest_path.relative_to(root)} host-specific fields are explicit: {sorted(check['allowed_extra_fields'])}",
    )


for check in namespaced_plugin_checks:
    validate_namespaced_pair(check)

prism_codex_manifest_path = root / "plugins/prism/.codex-plugin/plugin.json"
codex_baselines = {}
for check in namespaced_plugin_checks:
    baseline = load_json(check["root"] / ".codex-plugin/plugin.json")
    if baseline is not None:
        codex_baselines[check["plugin"]] = baseline

for check in flat_plugin_checks:
    baseline = codex_baselines.get(check["plugin"])
    if baseline is not None:
        validate_flat_manifest(check, baseline)

claude_marketplace_path = root / ".claude-plugin/marketplace.json"
record(claude_marketplace_path.is_file(), ".claude-plugin/marketplace.json exists")

if claude_marketplace_path.is_file():
    claude_marketplace = load_json(claude_marketplace_path)
    if claude_marketplace is not None:
        plugins = claude_marketplace.get("plugins", [])
        for check in namespaced_plugin_checks:
            expected_name = check["expected_name"]
            expected_source = f"./{check['root'].relative_to(root)}"
            claude_manifest = load_json(check["root"] / ".claude-plugin/plugin.json")
            if claude_manifest is None:
                continue

            match = next((item for item in plugins if item.get("name") == expected_name), None)
            record(
                match is not None,
                f".claude-plugin/marketplace.json lists plugin {expected_name}",
            )
            if match is None:
                continue

            record(
                match.get("source") == expected_source,
                f".claude-plugin/marketplace.json maps {expected_name} to {expected_source}",
            )
            record(
                match.get("description") == claude_manifest.get("description"),
                f".claude-plugin/marketplace.json description for {expected_name} matches the Claude manifest",
            )
            record(
                match.get("version") == claude_manifest.get("version"),
                f".claude-plugin/marketplace.json version for {expected_name} matches the Claude manifest",
            )
            record(
                match.get("author", {}).get("name") == claude_manifest.get("author", {}).get("name"),
                f".claude-plugin/marketplace.json author for {expected_name} matches the Claude manifest",
            )

agents_marketplace_path = root / ".agents/plugins/marketplace.json"
record(agents_marketplace_path.is_file(), ".agents/plugins/marketplace.json exists")

if agents_marketplace_path.is_file():
    agents_marketplace = load_json(agents_marketplace_path)
    if agents_marketplace is not None:
        plugins = agents_marketplace.get("plugins", [])
        expected_sources = {
            "prism": "./plugins/prism",
            "prism-callee": "./plugins/prism-callee",
        }
        for expected_name, expected_source in expected_sources.items():
            match = next((item for item in plugins if item.get("name") == expected_name), None)
            record(
                match is not None,
                f".agents/plugins/marketplace.json lists plugin {expected_name}",
            )
            if match is None:
                continue

            record(
                match.get("source", {}).get("path") == expected_source,
                f".agents/plugins/marketplace.json maps {expected_name} to {expected_source}",
            )
            record(
                match.get("category") == "Developer Tools",
                f".agents/plugins/marketplace.json gives {expected_name} category Developer Tools",
            )

cursor_marketplace_path = root / ".cursor-plugin/marketplace.json"
record(cursor_marketplace_path.is_file(), ".cursor-plugin/marketplace.json exists")

if cursor_marketplace_path.is_file():
    cursor_marketplace = load_json(cursor_marketplace_path)
    prism_cursor_manifest = load_json(root / "plugins/prism/.cursor-plugin/plugin.json")
    if cursor_marketplace is not None and prism_cursor_manifest is not None:
        record(
            cursor_marketplace.get("metadata", {}).get("version") == prism_cursor_manifest.get("version"),
            ".cursor-plugin/marketplace.json metadata version matches the Cursor manifest",
        )
        for expected_name, plugin_root in [
            ("prism", root / "plugins/prism"),
            ("prism-callee", root / "plugins/prism-callee"),
        ]:
            cursor_manifest = load_json(plugin_root / ".cursor-plugin/plugin.json")
            if cursor_manifest is None:
                continue

            match = next((item for item in cursor_marketplace.get("plugins", []) if item.get("name") == expected_name), None)
            record(match is not None, f".cursor-plugin/marketplace.json lists plugin {expected_name}")
            if match is not None:
                record(
                    match.get("source") == f"./{plugin_root.relative_to(root)}",
                    f".cursor-plugin/marketplace.json maps {expected_name} to ./{plugin_root.relative_to(root)}",
                )
                record(
                    match.get("description") == cursor_manifest.get("description"),
                    f".cursor-plugin/marketplace.json description for {expected_name} matches the Cursor manifest",
                )
                record(
                    match.get("version") == cursor_manifest.get("version"),
                    f".cursor-plugin/marketplace.json version for {expected_name} matches the Cursor manifest",
                )
                record(
                    match.get("tags") == cursor_manifest.get("keywords"),
                    f".cursor-plugin/marketplace.json tags for {expected_name} match the Cursor manifest keywords",
                )

grok_marketplace_path = root / ".grok-plugin/marketplace.json"
record(grok_marketplace_path.is_file(), ".grok-plugin/marketplace.json exists")

if grok_marketplace_path.is_file():
    grok_marketplace = load_json(grok_marketplace_path)
    if grok_marketplace is not None:
        for expected_name, plugin_root in [
            ("prism", root / "plugins/prism"),
            ("prism-callee", root / "plugins/prism-callee"),
        ]:
            grok_manifest = load_json(plugin_root / ".grok-plugin/plugin.json")
            if grok_manifest is None:
                continue

            match = next((item for item in grok_marketplace.get("plugins", []) if item.get("name") == expected_name), None)
            record(match is not None, f".grok-plugin/marketplace.json lists plugin {expected_name}")
            if match is not None:
                record(
                    match.get("source", {}).get("type") == "local",
                    f".grok-plugin/marketplace.json keeps {expected_name} as a local source",
                )
                record(
                    match.get("source", {}).get("path") == f"./{plugin_root.relative_to(root)}",
                    f".grok-plugin/marketplace.json maps {expected_name} to ./{plugin_root.relative_to(root)}",
                )
                record(
                    match.get("description") == grok_manifest.get("description"),
                    f".grok-plugin/marketplace.json description for {expected_name} matches the Grok manifest",
                )
                record(
                    match.get("version") == grok_manifest.get("version"),
                    f".grok-plugin/marketplace.json version for {expected_name} matches the Grok manifest",
                )
                record(
                    match.get("author") == grok_manifest.get("author"),
                    f".grok-plugin/marketplace.json author for {expected_name} matches the Grok manifest",
                )
                record(
                    match.get("homepage") == grok_manifest.get("homepage"),
                    f".grok-plugin/marketplace.json homepage for {expected_name} matches the Grok manifest",
                )
                record(
                    match.get("keywords") == grok_manifest.get("keywords"),
                    f".grok-plugin/marketplace.json keywords for {expected_name} match the Grok manifest",
                )

github_marketplace_path = root / ".github/plugin/marketplace.json"
record(github_marketplace_path.is_file(), ".github/plugin/marketplace.json exists")

if github_marketplace_path.is_file():
    github_marketplace = load_json(github_marketplace_path)
    if github_marketplace is not None:
        for expected_name, plugin_root in [
            ("prism", root / "plugins/prism"),
            ("prism-callee", root / "plugins/prism-callee"),
        ]:
            generic_manifest = load_json(plugin_root / ".plugin/plugin.json")
            if generic_manifest is None:
                continue

            match = next((item for item in github_marketplace.get("plugins", []) if item.get("name") == expected_name), None)
            record(match is not None, f".github/plugin/marketplace.json lists plugin {expected_name}")
            if match is not None:
                record(
                    match.get("source") == f"./{plugin_root.relative_to(root)}",
                    f".github/plugin/marketplace.json maps {expected_name} to ./{plugin_root.relative_to(root)}",
                )
                for field in [
                    "description",
                    "version",
                    "author",
                    "homepage",
                    "repository",
                    "license",
                    "keywords",
                ]:
                    record(
                        match.get(field) == generic_manifest.get(field),
                        f".github/plugin/marketplace.json {field} for {expected_name} matches the generic manifest",
                    )

if errors:
    print(f"\nValidation failed with {len(errors)} error(s).")
    sys.exit(1)

print("\nValidation passed.")
PY
