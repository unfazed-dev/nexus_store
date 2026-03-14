#!/usr/bin/env python3
# review_by: 2026-09-14
"""PostToolUse hook: auto-syncs current-sprint.md when a TRACKER-*.md file is edited.

Extracts the 'Current State' block from the tracker and writes it to
.claude/progress/current-sprint.md so session resumption always has fresh context.

Exit codes:
  0 = always (advisory only, never blocks)
"""
# Hook Contract:
#   Event:        PostToolUse (Edit)
#   Matcher:      tool_name == "Edit" and "TRACKER-" in file_path
#   Input:        {"tool_name": "Edit", "tool_input": {"file_path": "..."}} via stdin
#   Output:       One-line confirmation on stdout; silent when not a tracker edit
#   Side effects: Writes .claude/progress/current-sprint.md
#   Dependencies: none (stdlib only)
import json
import os
import re
import sys
from pathlib import Path

PROJECT_DIR = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
PROGRESS_DIR = Path(PROJECT_DIR) / ".claude" / "progress"
SPRINT_FILE = PROGRESS_DIR / "current-sprint.md"


def extract_current_state(tracker_path: str) -> str | None:
    """Extract the Current State block from a tracker file."""
    try:
        content = Path(tracker_path).read_text()
    except OSError:
        return None

    # Extract tracker title
    title_match = re.search(r"^#\s*TRACKER:\s*(.+)$", content, re.MULTILINE)
    title = title_match.group(1).strip() if title_match else "Unknown"

    # Extract Current State block
    state_match = re.search(
        r"\*\*Current State.*?\*\*.*?\n((?:- .+\n)+)",
        content,
        re.MULTILINE,
    )
    if not state_match:
        return None

    state_lines = state_match.group(1).strip()

    # Extract progress bar
    progress_match = re.search(r"\*\*Overall:\*\*\s*(.+)$", content, re.MULTILINE)
    progress = progress_match.group(1).strip() if progress_match else ""

    # Extract test counts
    tests_match = re.search(r"\*\*Tests:\*\*\s*(.+)$", content, re.MULTILINE)
    tests = tests_match.group(1).strip() if tests_match else ""

    # Get relative tracker path
    rel_path = tracker_path
    if rel_path.startswith(PROJECT_DIR):
        rel_path = os.path.relpath(rel_path, PROJECT_DIR)

    lines = [
        f"# Active: {title}",
        f"**Tracker:** `{rel_path}`",
    ]
    if progress:
        lines.append(f"**Progress:** {progress}")
    if tests:
        lines.append(f"**Tests:** {tests}")
    lines.append("")
    lines.append("## Current State")
    lines.append(state_lines)
    lines.append("")
    lines.append(f"_Auto-synced from tracker by tracker-sprint-sync hook_")

    return "\n".join(lines)


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_input = input_data.get("tool_input", {})
    file_path = tool_input.get("file_path", "")

    # Only act on TRACKER-*.md edits
    basename = os.path.basename(file_path)
    if not basename.startswith("TRACKER-") or not basename.endswith(".md"):
        sys.exit(0)

    sprint_content = extract_current_state(file_path)
    if not sprint_content:
        sys.exit(0)

    try:
        PROGRESS_DIR.mkdir(parents=True, exist_ok=True)
        SPRINT_FILE.write_text(sprint_content + "\n")
        print(f"📋 current-sprint.md synced from {basename}")
    except OSError:
        pass

    sys.exit(0)


if __name__ == "__main__":
    main()
