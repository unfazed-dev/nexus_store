#!/usr/bin/env python3
# review_by: 2026-09-14
"""PreToolUse hook: enforces context-mode tool usage in dumb/danger zones.

When Context Mode is active and the context budget is in dumb_zone or danger,
this hook blocks Bash commands and Read calls that have ctx_* equivalents,
returning a suggestion to use the context-mode tool instead.

Allows: git, mkdir, rm, mv, ls, chmod, ln (short-output commands)
Blocks: cat, head, tail, grep, rg, find, curl, dart test, flutter test (large-output commands)
"""
# Hook Contract:
#   Event:        PreToolUse (Bash, Read)
#   Matcher:      tool_name in ("Bash", "Read")
#   Input:        {"tool_name": "Bash"|"Read", "tool_input": {...}} via stdin
#   Output:       JSON with "decision": "block"|"approve" and optional "reason"
#   Side effects: none (read-only check of backup-state.json)
#   Dependencies: backup-state.json, context_mode_utils.py
import json
import os
import re
import sys
from pathlib import Path

PROJECT_DIR = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
PROGRESS_DIR = Path(PROJECT_DIR) / ".claude" / "progress"
BACKUP_STATE = PROGRESS_DIR / "backup-state.json"
HOOKS_DIR = Path(PROJECT_DIR) / ".claude" / "hooks" / "core"

# Add hooks/core to path for context_mode_utils
sys.path.insert(0, str(HOOKS_DIR))
try:
    from context_mode_utils import is_context_mode_active
    _CM_AVAILABLE = True
except ImportError:
    _CM_AVAILABLE = False

# Bash commands that are safe (short output, no ctx_ equivalent)
SAFE_BASH_PATTERNS = [
    r"^git\b",
    r"^gh\b",
    r"^mkdir\b",
    r"^rm\b",
    r"^mv\b",
    r"^cp\b",
    r"^ls\b",
    r"^chmod\b",
    r"^ln\b",
    r"^cd\b",
    r"^pwd\b",
    r"^echo\b",
    r"^python3\s+\.claude/",  # Our own hooks/orchestrators
    r"^bash\s+\.claude/",
    r"^dart\s+run\s+\.claude/",  # Invariants
    r"^melos\b",
    r"^dart\s+pub\b",
    r"^flutter\s+pub\b",
    r"^dart\s+format\b",
    r"^dart\s+fix\b",
    r"^open\b",
    r"^tree\b",
    r"^wc\b",
    r"^file\b",
    r"^pgrep\b",
    r"^pkill\b",
]

# Bash commands that should use ctx_ tools instead
BLOCKABLE_BASH_PATTERNS = {
    r"\bcat\b": "Use ctx_execute_file() or Read (if editing) instead of cat",
    r"\bhead\b": "Use ctx_execute_file() instead of head",
    r"\btail\b": "Use ctx_execute_file() instead of tail",
    r"\bgrep\b": "Use Grep tool or ctx_execute() instead of grep",
    r"\brg\b": "Use Grep tool or ctx_execute() instead of rg",
    r"\bfind\b": "Use Glob tool or ctx_execute() instead of find",
    r"\bcurl\b": "Use ctx_fetch_and_index() instead of curl",
    r"\bdart\s+test\b": "Use ctx_execute() to run tests with output capture",
    r"\bflutter\s+test\b": "Use ctx_execute() to run tests with output capture",
    r"\bdart\s+analyze\b": "Use ctx_execute() to run analyze with output capture",
    r"\bflutter\s+analyze\b": "Use ctx_execute() to run analyze with output capture",
}

# Zones that trigger enforcement
ENFORCEMENT_ZONES = {"dumb_zone", "danger", "critical"}


def read_backup_state() -> dict:
    try:
        if BACKUP_STATE.exists():
            return json.loads(BACKUP_STATE.read_text())
    except (json.JSONDecodeError, OSError):
        pass
    return {}


def is_safe_bash(command: str) -> bool:
    """Check if a bash command is safe (short output, no ctx_ equivalent)."""
    cmd = command.strip()
    # Check multi-command chains — if first command is safe, allow
    # (e.g., "git add foo && git commit" is safe)
    first_cmd = re.split(r"\s*&&\s*|\s*;\s*|\s*\|\s*", cmd)[0].strip()
    return any(re.search(pat, first_cmd) for pat in SAFE_BASH_PATTERNS)


def get_block_reason(command: str) -> str | None:
    """Get the block reason for a bash command, or None if not blockable."""
    cmd = command.strip()
    for pattern, reason in BLOCKABLE_BASH_PATTERNS.items():
        if re.search(pattern, cmd):
            return reason
    return None


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        print(json.dumps({"decision": "approve"}))
        sys.exit(0)

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})

    # Only enforce for Bash and Read
    if tool_name not in ("Bash", "Read"):
        print(json.dumps({"decision": "approve"}))
        sys.exit(0)

    # Only enforce when CM is active
    if not _CM_AVAILABLE:
        print(json.dumps({"decision": "approve"}))
        sys.exit(0)

    try:
        cm_active = is_context_mode_active()
    except Exception:
        cm_active = False

    if not cm_active:
        print(json.dumps({"decision": "approve"}))
        sys.exit(0)

    # Check current zone
    state = read_backup_state()
    zone = state.get("last_zone", "green")

    if zone not in ENFORCEMENT_ZONES:
        print(json.dumps({"decision": "approve"}))
        sys.exit(0)

    # === Zone is dumb/danger — enforce ctx_ usage ===

    if tool_name == "Read":
        file_path = tool_input.get("file_path", "")
        # Allow Read for files that will be edited (small, targeted reads)
        # Block Read for large analysis files
        # Heuristic: allow .dart, .yaml, .json, .md files (likely edit targets)
        # Block if reading logs, large outputs, etc.
        allowed_extensions = {".dart", ".yaml", ".yml", ".json", ".md", ".py", ".sh", ".toml"}
        ext = os.path.splitext(file_path)[1].lower()
        if ext in allowed_extensions:
            print(json.dumps({"decision": "approve"}))
            sys.exit(0)
        # Block non-standard file reads
        print(json.dumps({
            "decision": "block",
            "reason": f"⚠ Context budget in {zone} — use ctx_execute_file() instead of Read for non-source files. "
                      f"Read is allowed for .dart/.yaml/.json/.md/.py files you intend to Edit."
        }))
        sys.exit(0)

    if tool_name == "Bash":
        command = tool_input.get("command", "")

        # Allow safe commands
        if is_safe_bash(command):
            print(json.dumps({"decision": "approve"}))
            sys.exit(0)

        # Check for blockable patterns
        reason = get_block_reason(command)
        if reason:
            print(json.dumps({
                "decision": "block",
                "reason": f"⚠ Context budget in {zone} — {reason}. "
                          f"Large outputs waste context. Use context-mode tools to keep data in sandbox."
            }))
            sys.exit(0)

        # Unknown command — allow but warn
        print(json.dumps({
            "decision": "approve",
            "reason": f"⚠ Context at {zone} — consider using ctx_execute() if this produces large output."
        }))
        sys.exit(0)

    print(json.dumps({"decision": "approve"}))
    sys.exit(0)


if __name__ == "__main__":
    main()
