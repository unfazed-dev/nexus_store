#!/usr/bin/env python3
# review_by: 2026-09-10
"""
PreToolUse hook for Edit/Write operations.

Checks content being written to .dart files for known architectural violations
BEFORE the write happens. Catches issues at edit-time, not post-edit.

Checked patterns:
- Cross-package src/ imports: packages must not import another package's src/ directly

Exit codes:
  0 = allow (no violations or non-dart file)
  2 = block (violation found, emit rejection JSON)
"""
# Hook Contract:
#   Event:        PreToolUse (Edit, Write)
#   Matcher:      tool_name in ("Edit", "Write") and file_path ends with ".dart"
#   Input:        {"tool_name": "Edit"|"Write", "tool_input": {"file_path": "...",
#                  "new_string"|"content": "..."}} via stdin
#   Output:       {"decision": "block", "reason": "..."} on stdout when violations found;
#                 silent (exit 0) on pass or non-dart files
#   Side effects: Blocks write before it occurs; no filesystem changes on block
#   Dependencies: none (regex pattern matching only)
import json
import re
import sys


def detect_package_from_path(file_path):
    """Extract the package name from a file path like packages/xxx/lib/...

    Returns the package name or None if not inside a recognized package.
    """
    match = re.search(r"/packages/([^/]+)/", file_path)
    return match.group(1) if match else None


def check_violations(content, file_path):
    """Check content for architectural violations. Returns list of violations."""
    violations = []

    # Only check .dart files
    if not file_path.endswith(".dart"):
        return violations

    lines = content.split("\n") if content else []

    # Determine which package this file belongs to
    current_package = detect_package_from_path(file_path)

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith("//") or stripped.startswith("///"):
            continue

        # Cross-package src/ import check
        # Block: import 'package:other_package/src/...' when editing inside a different package
        if current_package and stripped.startswith("import"):
            src_import = re.search(r"import\s+'package:([^/]+)/src/", line)
            if src_import:
                imported_package = src_import.group(1)
                if imported_package != current_package:
                    violations.append({
                        "line": i + 1,
                        "rule": "cross-package-src-import",
                        "message": f"Cross-package src/ import: '{imported_package}/src/' from package '{current_package}'",
                        "content": stripped[:120],
                        "fix": f"Import the public API: package:{imported_package}/{{public_file}}.dart (not src/)",
                    })

    return violations


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

    file_path = tool_input.get("file_path", "")
    if not file_path.endswith(".dart"):
        sys.exit(0)

    # Skip invariant definition files — they contain banned patterns as detection regexes
    if "/.claude/invariants/" in file_path or "/.claude/hooks/" in file_path:
        sys.exit(0)

    # Get content to check
    if tool_name == "Write":
        content = tool_input.get("content", "")
    elif tool_name == "Edit":
        content = tool_input.get("new_string", "")
    else:
        sys.exit(0)

    violations = check_violations(content, file_path)

    if violations:
        # Block the edit with structured feedback
        message = f"Pre-edit guard: {len(violations)} violation(s) in {file_path}\n"
        for v in violations:
            message += f"  Line {v['line']}: [{v['rule']}] {v['message']}\n"
            message += f"    FIX: {v['fix']}\n"

        result = {
            "decision": "block",
            "reason": message.strip(),
        }
        print(json.dumps(result))
        sys.exit(2)

    # Allow — silent on success (asymmetric output)
    sys.exit(0)


if __name__ == "__main__":
    main()
