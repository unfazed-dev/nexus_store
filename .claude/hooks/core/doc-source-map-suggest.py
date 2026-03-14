#!/usr/bin/env python3
# review_by: 2026-09-14
"""PostToolUse hook: suggests doc-source-map.json entries for new doc files.

When a new file is created (Write) in docs/diagrams/, docs/features/, or
docs/architecture/, checks if it has a doc-source-map entry. If not, prints
a suggestion with likely source glob patterns.

Exit codes:
  0 = always (advisory only, never blocks)
"""
# Hook Contract:
#   Event:        PostToolUse (Write)
#   Matcher:      tool_name == "Write" and file_path matches doc directories
#   Input:        {"tool_name": "Write", "tool_input": {"file_path": "..."}} via stdin
#   Output:       Suggestion text on stdout; silent when not a new doc file or already mapped
#   Side effects: none (read-only check)
#   Dependencies: .claude/doc-source-map.json
import json
import os
import re
import sys
from pathlib import Path

PROJECT_DIR = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
DOC_SOURCE_MAP = Path(PROJECT_DIR) / ".claude" / "doc-source-map.json"

# Directories where doc-source-map entries make sense
DOC_DIRS = (
    "docs/diagrams/",
    "docs/features/",
    "docs/architecture/",
    "docs/domain/",
)

# Patterns to skip (non-code-documenting files)
SKIP_PATTERNS = (
    "README.md",
    "index.md",
    "STYLE-GUIDE.md",
    "CHANGELOG.md",
)


def load_source_map() -> dict:
    """Load existing doc-source-map.json."""
    try:
        if DOC_SOURCE_MAP.exists():
            data = json.loads(DOC_SOURCE_MAP.read_text())
            return {k: v for k, v in data.items() if not k.startswith("_")}
    except (json.JSONDecodeError, OSError):
        pass
    return {}


def suggest_source_globs(rel_path: str) -> list[str]:
    """Suggest likely source glob patterns based on doc file path."""
    suggestions = []

    # Extract feature/domain hints from path
    # e.g., docs/diagrams/flows/auth-login-flow.md -> lib/**/auth/**/*.dart
    parts = rel_path.replace("docs/", "").split("/")

    # Look for keywords that map to source directories
    keywords = []
    for part in parts:
        # Strip common prefixes/suffixes
        clean = part.replace(".md", "").replace("-flow", "").replace("-diagram", "")
        clean = re.sub(r"^(flow|sequence|state|er|architecture)-?", "", clean)
        if clean and clean not in ("diagrams", "flows", "features", "domain", "s"):
            keywords.append(clean)

    for kw in keywords[:2]:
        # Convert kebab-case to path component
        path_part = kw.replace("-", "_")
        suggestions.append(f"lib/**/{path_part}/**/*.dart")

    if not suggestions:
        suggestions.append("lib/**/*.dart  # <-- narrow this glob")

    return suggestions


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    file_path = tool_input.get("file_path", "")

    # Only act on Write (new files)
    if tool_name != "Write":
        sys.exit(0)

    # Get relative path
    rel_path = file_path
    if rel_path.startswith(PROJECT_DIR):
        rel_path = os.path.relpath(rel_path, PROJECT_DIR)

    # Only act on doc directories
    if not any(rel_path.startswith(d) for d in DOC_DIRS):
        sys.exit(0)

    # Skip non-documenting files
    basename = os.path.basename(rel_path)
    if basename in SKIP_PATTERNS:
        sys.exit(0)

    # Check if already in doc-source-map
    source_map = load_source_map()
    if rel_path in source_map:
        sys.exit(0)

    # Suggest entry
    globs = suggest_source_globs(rel_path)
    glob_json = json.dumps(globs)
    print(f"📎 New doc file not in doc-source-map.json: {rel_path}")
    print(f"   Suggested entry: \"{rel_path}\": {glob_json}")
    print(f"   Add to .claude/doc-source-map.json if this doc describes code behavior.")

    sys.exit(0)


if __name__ == "__main__":
    main()
