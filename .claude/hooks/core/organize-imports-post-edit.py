#!/usr/bin/env python3
# review_by: 2026-09-10
"""
PostToolUse hook to organize imports in Dart files after Edit/Write operations.
Runs `dart fix --apply` to automatically fix import organization issues.
"""
# Hook Contract:
#   Event:        PostToolUse (Edit, Write)
#   Matcher:      tool_name in ("Edit", "Write") and file_path ends with ".dart"
#   Input:        {"tool_name": "Edit"|"Write", "tool_input": {"file_path": "..."}} via stdin
#   Output:       {"hookSpecificOutput": {"hookEventName": "PostToolUse", "message": "..."}}
#                 only when fixes were applied; silent otherwise; never blocks
#   Side effects: Runs `dart fix --apply <file>` to auto-fix import ordering/organization
#   Dependencies: dart CLI
import json
import subprocess
import sys
import os
from pathlib import Path

# Import Context Mode utilities
sys.path.insert(0, str(Path(__file__).resolve().parent))
from context_mode_utils import compress_output


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})

    # Only process Edit and Write tools
    if tool_name not in ("Edit", "Write"):
        sys.exit(0)

    # Get the file path
    file_path = tool_input.get("file_path", "")

    # Only process .dart files
    if not file_path.endswith(".dart"):
        sys.exit(0)

    # Check if file exists
    if not os.path.exists(file_path):
        sys.exit(0)

    try:
        # Run dart fix --apply on the specific file
        # This fixes import organization and other auto-fixable issues
        result = subprocess.run(
            ["dart", "fix", "--apply", file_path],
            capture_output=True,
            text=True,
            timeout=30,
            cwd=os.path.dirname(file_path) or "."
        )

        if result.returncode == 0:
            # Check if any fixes were applied
            if "fixed" in result.stdout.lower() or "applied" in result.stdout.lower():
                basename = os.path.basename(file_path)
                detail = f"Auto-fixed imports: {basename}\n{result.stdout.strip()}"
                summary = f"Auto-fixed imports: {basename}"
                message = compress_output("organize-imports", summary, detail)
                print(json.dumps({
                    "hookSpecificOutput": {
                        "hookEventName": "PostToolUse",
                        "message": message
                    }
                }))
        # Don't report failures - dart fix may not always have fixes to apply

    except subprocess.TimeoutExpired:
        pass  # Skip silently on timeout
    except FileNotFoundError:
        pass  # dart command not found - skip silently
    except Exception:
        pass  # Other errors - skip silently

    sys.exit(0)


if __name__ == "__main__":
    main()
