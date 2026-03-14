#!/usr/bin/env python3
# review_by: 2026-09-14
"""PostToolUse hook: auto-updates route hashes when FLOWS.md is edited.

Runs update-route-hashes.py automatically after any FLOWS.md edit to keep
route_hash frontmatter in sync, preventing flow-route-sync invariant failures.

Exit codes:
  0 = always (advisory only, never blocks)
"""
# Hook Contract:
#   Event:        PostToolUse (Edit, Write)
#   Matcher:      tool_name in ("Edit", "Write") and file_path ends with "FLOWS.md"
#   Input:        {"tool_name": "Edit"|"Write", "tool_input": {"file_path": "..."}} via stdin
#   Output:       One-line confirmation on stdout; silent when not a FLOWS.md edit
#   Side effects: Runs update-route-hashes.py which modifies FLOWS.md frontmatter
#   Dependencies: update-route-hashes.py
import json
import os
import subprocess
import sys
from pathlib import Path

PROJECT_DIR = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
HOOKS_DIR = Path(PROJECT_DIR) / ".claude" / "hooks" / "core"
HASH_UPDATER = HOOKS_DIR / "update-route-hashes.py"


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_input = input_data.get("tool_input", {})
    file_path = tool_input.get("file_path", "")

    # Only act on FLOWS.md edits
    if not file_path.endswith("FLOWS.md"):
        sys.exit(0)

    # Check if updater script exists
    if not HASH_UPDATER.exists():
        sys.exit(0)

    try:
        result = subprocess.run(
            ["python3", str(HASH_UPDATER)],
            capture_output=True,
            text=True,
            timeout=15,
            cwd=PROJECT_DIR,
            env={**os.environ, "CLAUDE_PROJECT_DIR": PROJECT_DIR},
        )
        if result.returncode == 0:
            basename = os.path.basename(file_path)
            print(f"🔗 Route hashes auto-updated after editing {basename}")
        else:
            print(f"⚠ Route hash update failed: {result.stderr[:200]}")
    except subprocess.TimeoutExpired:
        print("⚠ Route hash update timed out")
    except OSError:
        pass

    sys.exit(0)


if __name__ == "__main__":
    main()
