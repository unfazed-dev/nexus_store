#!/usr/bin/env python3
# review_by: 2026-09-14
"""
Session-start knowledge base indexing for Context Mode.

Discovers all rule files, AGENTS.md DO NOT lines, and scoped CLAUDE.md files,
then outputs a JSON manifest for the agent to index via ctx_index MCP tool.

Usage:
  python3 .claude/hooks/core/index-rules-kb.py [--index | --manifest]

Modes:
  --manifest  (default) Output JSON array of {path, source} pairs
  --index     Output one ctx_index call per file (for agent copy-paste)
  --stats     Show counts only
"""
import json
import os
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent.parent


def discover_rule_files():
    """Find all rule files in .claude/rules/."""
    rules_dir = PROJECT_ROOT / ".claude" / "rules"
    if not rules_dir.exists():
        return []
    files = sorted(rules_dir.glob("*.md"))
    return [
        {
            "path": str(f),
            "source": f"rules: {f.stem}",
        }
        for f in files
    ]


def discover_agents_md():
    """Find AGENTS.md at project root."""
    agents_file = PROJECT_ROOT / "AGENTS.md"
    if not agents_file.exists():
        return []
    return [
        {
            "path": str(agents_file),
            "source": "agents: DO NOT patterns",
        }
    ]


def discover_scoped_claude_md():
    """Find scoped CLAUDE.md files throughout the repo.

    Indexes key scoped files that provide directory-specific context.
    Skips root CLAUDE.md (already loaded by Claude Code automatically).
    """
    results = []
    root_claude = PROJECT_ROOT / "CLAUDE.md"

    for claude_file in sorted(PROJECT_ROOT.rglob("CLAUDE.md")):
        # Skip root CLAUDE.md (auto-loaded by Claude Code)
        if claude_file == root_claude:
            continue
        # Skip anything in node_modules, .dart_tool, build dirs
        rel = claude_file.relative_to(PROJECT_ROOT)
        parts = rel.parts
        skip_dirs = {
            "node_modules", ".dart_tool", "build", ".git",
            "ios", "android", "macos", "windows", "linux", "web",
            ".pub-cache", ".pub",
        }
        if any(p in skip_dirs for p in parts):
            continue

        # Derive a meaningful source label from path
        parent_parts = parts[:-1]  # drop CLAUDE.md
        if len(parent_parts) >= 2 and parent_parts[0] == "packages":
            # packages/nexus_store/CLAUDE.md -> "scope: nexus_store"
            label = "/".join(parent_parts[1:])
        elif len(parent_parts) >= 1 and parent_parts[0] == "docs":
            label = "/".join(parent_parts)
        else:
            label = "/".join(parent_parts)

        results.append({
            "path": str(claude_file),
            "source": f"scope: {label}",
        })

    return results


def build_manifest():
    """Build complete indexing manifest."""
    manifest = []
    manifest.extend(discover_rule_files())
    manifest.extend(discover_agents_md())
    manifest.extend(discover_scoped_claude_md())
    return manifest


def main():
    mode = "--manifest"
    if len(sys.argv) > 1:
        mode = sys.argv[1]

    manifest = build_manifest()

    if mode == "--stats":
        rules = [m for m in manifest if m["source"].startswith("rules:")]
        agents = [m for m in manifest if m["source"].startswith("agents:")]
        scoped = [m for m in manifest if m["source"].startswith("scope:")]
        print(f"Rules files: {len(rules)}")
        print(f"AGENTS.md: {len(agents)}")
        print(f"Scoped CLAUDE.md: {len(scoped)}")
        print(f"Total files to index: {len(manifest)}")
        return

    if mode == "--index":
        print("# Index the following files via ctx_index MCP tool:")
        print(f"# Total: {len(manifest)} files")
        print("# Note: ctx_index requires absolute paths")
        print()
        for entry in manifest:
            print(f'ctx_index(path="{entry["path"]}", source="{entry["source"]}")')
        return

    # Default: JSON manifest
    print(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    main()
