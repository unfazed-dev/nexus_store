#!/usr/bin/env python3
# review_by: 2026-09-07
"""
PostToolUse hook for source file edits — checks doc-source-map.json
to warn when edited source files have mapped documentation that may
need updating.

Unlike invariant-check-post-edit.py (which does filename-based matching),
this hook uses the explicit doc-source-map.json for precise mapping.

Exit codes:
  0 = always (advisory only, never blocks)
"""
# Hook Contract:
#   Event:        PostToolUse (Edit, Write)
#   Matcher:      tool_name in ("Edit", "Write") and file_path ends with ".dart"
#   Input:        {"tool_name": "Edit"|"Write", "tool_input": {"file_path": "..."}} via stdin
#   Output:       Plain text warnings on stdout listing mapped docs that may need review;
#                 never blocks (advisory only); silent when no mapped docs found
#   Side effects: Reads .claude/doc-source-map.json; no writes
#   Dependencies: .claude/doc-source-map.json
import fnmatch
import json
import os
import sys
from pathlib import Path

# Import Context Mode utilities
sys.path.insert(0, str(Path(__file__).resolve().parent))
from context_mode_utils import compress_output

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent.parent
DOC_SOURCE_MAP = PROJECT_ROOT / ".claude" / "doc-source-map.json"


def load_source_map():
    """Load doc-source-map.json, return {doc_path: [source_globs]}."""
    if not DOC_SOURCE_MAP.exists():
        return {}
    try:
        with open(DOC_SOURCE_MAP) as f:
            data = json.load(f)
        # Filter out comment keys
        return {k: v for k, v in data.items() if not k.startswith("_")}
    except (json.JSONDecodeError, OSError):
        return {}


def find_affected_docs(rel_path, source_map):
    """Find docs whose source globs match the edited file path."""
    affected = []
    for doc_path, source_globs in source_map.items():
        for glob_pattern in source_globs:
            if fnmatch.fnmatch(rel_path, glob_pattern):
                affected.append(doc_path)
                break
    return affected


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})

    if tool_name not in ("Edit", "Write"):
        sys.exit(0)

    file_path = tool_input.get("file_path", "")
    if not file_path.endswith(".dart"):
        sys.exit(0)

    # Get relative path from project root
    rel_path = file_path
    project_str = str(PROJECT_ROOT)
    if rel_path.startswith(project_str):
        rel_path = os.path.relpath(rel_path, project_str)

    source_map = load_source_map()
    if not source_map:
        sys.exit(0)

    affected = find_affected_docs(rel_path, source_map)
    if not affected:
        sys.exit(0)

    # Build full detail and one-line summary
    basename = os.path.basename(file_path)
    detail_lines = [f"\n📋 {len(affected)} mapped doc(s) may need review after editing {basename}:"]
    for doc in affected[:5]:
        detail_lines.append(f"  → {doc}")
    if len(affected) > 5:
        detail_lines.append(f"  ... and {len(affected) - 5} more")
    detail_lines.append("  Run drift-detector agent to check for contradictions.")
    detail = "\n".join(detail_lines)

    summary = f"📋 {len(affected)} mapped doc(s) may need review after editing {basename}"
    output = compress_output("doc-freshness", summary, detail)
    print(output)

    sys.exit(0)


if __name__ == "__main__":
    main()
