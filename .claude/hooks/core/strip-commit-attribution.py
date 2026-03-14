#!/usr/bin/env python3
# review_by: 2026-09-10
"""
Hook to strip Claude Code attribution and enforce single-line commit messages.
Runs as PreToolUse hook on Bash commands.

- Strips Co-Authored-By and Claude Code emoji footer
- Collapses multi-line messages to first line only
- Converts HEREDOC format to simple -m "message"
"""
# Hook Contract:
#   Event:        PreToolUse (Bash)
#   Matcher:      tool_name == "Bash" and "git commit" in command
#   Input:        {"tool_name": "Bash", "tool_input": {"command": "..."}} via stdin
#   Output:       {"hookSpecificOutput": {"hookEventName": "PreToolUse",
#                  "permissionDecision": "allow", "updatedInput": {"command": "..."}}}
#                 (only emitted when command was modified; silent on pass-through)
#   Side effects: Strips Co-Authored-By footer and Claude emoji; collapses HEREDOC/multi-line
#                 commit messages to single -m "first line" format
#   Dependencies: none (regex only)
import json
import sys
import re


def extract_first_line(message: str) -> str:
    """Extract the first non-empty line from a commit message."""
    for line in message.strip().split('\n'):
        line = line.strip()
        if line:
            return line
    return message.strip()


def simplify_commit_command(command: str) -> str:
    """Convert any git commit format to single-line -m format."""

    # Pattern 1: HEREDOC format — git commit -m "$(cat <<'EOF'\n...\nEOF\n)"
    heredoc_pattern = r'git commit(.*?)-m\s*"\$\(cat\s*<<\'?EOF\'?\n(.*?)\nEOF\n\)"'
    match = re.search(heredoc_pattern, command, re.DOTALL)
    if match:
        flags_before = match.group(1)
        message_body = match.group(2)
        first_line = extract_first_line(message_body)
        # Escape double quotes in the message
        first_line = first_line.replace('"', '\\"')
        replacement = f'git commit{flags_before}-m "{first_line}"'
        return command[:match.start()] + replacement + command[match.end():]

    # Pattern 2: Simple -m with multi-line string — git commit -m "line1\nline2\n..."
    simple_pattern = r'(git commit\s.*?-m\s*")(.*?)(")'
    match = re.search(simple_pattern, command, re.DOTALL)
    if match:
        prefix = match.group(1)
        message_body = match.group(2)
        suffix = match.group(3)
        # Strip attribution patterns first
        for pattern in [
            r'\n*🤖 Generated with \[Claude Code\]\(https://claude\.com/claude-code\)\n*',
            r'\n*Co-Authored-By: Claude[^\n"]*',
        ]:
            message_body = re.sub(pattern, '', message_body)
        first_line = extract_first_line(message_body)
        return command[:match.start()] + prefix + first_line + suffix + command[match.end():]

    return command


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    command = tool_input.get("command", "")

    # Only process git commit commands
    if tool_name != "Bash" or "git commit" not in command:
        sys.exit(0)

    modified_command = simplify_commit_command(command)

    if modified_command != command:
        result = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "updatedInput": {
                    "command": modified_command
                }
            }
        }
        print(json.dumps(result))

    sys.exit(0)


if __name__ == "__main__":
    main()
