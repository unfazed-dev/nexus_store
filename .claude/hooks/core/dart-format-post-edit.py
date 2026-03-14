#!/usr/bin/env python3
# review_by: 2026-09-10
"""
PostToolUse hook to auto-format Dart files after Edit/Write operations.
Runs `dart format` on modified .dart files to ensure consistent formatting.
"""
# Hook Contract:
#   Event:        PostToolUse (Edit, Write)
#   Matcher:      tool_name in ("Edit", "Write") and file_path ends with ".dart"
#   Input:        {"tool_name": "Edit"|"Write", "tool_input": {"file_path": "..."}} via stdin
#   Output:       {"hookSpecificOutput": {"hookEventName": "PostToolUse", "message": "..."}}
#                 only when formatting was applied; silent otherwise; never blocks
#   Side effects: Runs `dart format <file>` in place on the edited .dart file
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
        # Run dart format on the file
        result = subprocess.run(
            ["dart", "format", file_path],
            capture_output=True,
            text=True,
            timeout=30
        )

        if result.returncode == 0:
            # Format successful - file may have been modified
            if "Formatted" in result.stdout:
                basename = os.path.basename(file_path)
                detail = f"Auto-formatted: {basename}\n{result.stdout.strip()}"
                summary = f"Auto-formatted: {basename}"
                message = compress_output("dart-format", summary, detail)
                print(json.dumps({
                    "hookSpecificOutput": {
                        "hookEventName": "PostToolUse",
                        "message": message
                    }
                }))
        else:
            # Format failed - report but don't block
            detail = f"Format warning: {result.stderr.strip()}"
            summary = f"Format warning: {result.stderr.strip()[:100]}"
            message = compress_output("dart-format", summary, detail)
            print(json.dumps({
                "hookSpecificOutput": {
                    "hookEventName": "PostToolUse",
                    "message": message
                }
            }))

    except subprocess.TimeoutExpired:
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "message": "Format timeout - skipped"
            }
        }))
    except FileNotFoundError:
        # dart command not found - skip silently
        pass
    except Exception:
        # Other errors - skip silently
        pass

    sys.exit(0)


if __name__ == "__main__":
    main()
