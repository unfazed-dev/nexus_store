#!/usr/bin/env python3
# review_by: 2026-09-10
"""
PostToolUse hook to run lint checks on Dart files after Edit/Write operations.
Runs `dart analyze` on modified .dart files to catch issues early.
Reports warnings/errors without blocking the operation.
"""
# Hook Contract:
#   Event:        PostToolUse (Edit, Write)
#   Matcher:      tool_name in ("Edit", "Write") and file_path ends with ".dart" (skips test files)
#   Input:        {"tool_name": "Edit"|"Write", "tool_input": {"file_path": "..."}} via stdin
#   Output:       {"hookSpecificOutput": {"hookEventName": "PostToolUse", "message": "..."}}
#                 only when errors/warnings found; silent on clean files; never blocks
#   Side effects: Runs `dart analyze <file>` and surfaces issues as advisory messages
#   Dependencies: dart CLI
import json
import subprocess
import sys
import os


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

    # Skip test files - they often have intentional issues
    if "/test/" in file_path or file_path.endswith("_test.dart"):
        sys.exit(0)

    # Check if file exists
    if not os.path.exists(file_path):
        sys.exit(0)

    try:
        # Run dart analyze on the specific file
        result = subprocess.run(
            ["dart", "analyze", file_path],
            capture_output=True,
            text=True,
            timeout=60
        )

        # Parse output for issues
        output = result.stdout + result.stderr
        lines = output.strip().split("\n")

        errors = []
        warnings = []

        for line in lines:
            line_lower = line.lower()
            if "error" in line_lower and "-" in line:
                errors.append(line.strip())
            elif "warning" in line_lower and "-" in line:
                warnings.append(line.strip())

        # Report issues if found
        if errors or warnings:
            issues = []
            if errors:
                issues.append(f"{len(errors)} error(s)")
            if warnings:
                issues.append(f"{len(warnings)} warning(s)")

            # Get first issue as example
            first_issue = (errors + warnings)[0] if (errors + warnings) else ""
            if len(first_issue) > 80:
                first_issue = first_issue[:77] + "..."

            print(json.dumps({
                "hookSpecificOutput": {
                    "hookEventName": "PostToolUse",
                    "message": f"Lint: {', '.join(issues)} in {os.path.basename(file_path)}"
                }
            }))
        # Don't report if no issues - keeps output clean

    except subprocess.TimeoutExpired:
        pass  # Skip silently on timeout
    except FileNotFoundError:
        pass  # dart command not found - skip silently
    except Exception:
        pass  # Other errors - skip silently

    sys.exit(0)


if __name__ == "__main__":
    main()
