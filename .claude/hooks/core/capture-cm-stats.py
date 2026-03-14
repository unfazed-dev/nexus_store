#!/usr/bin/env python3
# review_by: 2026-09-08
"""PostToolUse hook: captures Context Mode stats from ctx_* tool calls.

Two modes:
  - Authoritative: parses ctx_stats markdown table for precise metrics
  - Accumulated: tracks response bytes from all other ctx_* tools

Writes metrics to .claude/progress/cm-stats.json for the statusline.
"""
# Hook Contract:
#   Event:        PostToolUse (matcher: mcp__plugin_context-mode_context-mode__ctx_)
#   Input:        {"tool_name": "...", "tool_response": [{"type": "text", "text": "..."}]} via stdin
#   Output:       {"status": "ok"} on stdout (non-blocking)
#   Side effects: Writes .claude/progress/cm-stats.json
#   Dependencies: none (stdlib only)
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

PROJECT_DIR = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
CM_STATS_FILE = Path(PROJECT_DIR) / ".claude" / "progress" / "cm-stats.json"
BACKUP_STATE = Path(PROJECT_DIR) / ".claude" / "progress" / "backup-state.json"

SESSION_RESET_SECONDS = 8 * 3600  # 8 hours


def parse_stats(text: str) -> dict:
    """Extract key metrics from ctx_stats markdown output."""
    stats = {}

    # Total data processed | **450.2KB**
    m = re.search(r"Total data processed\s*\|\s*\*\*(.+?)\*\*", text)
    if m:
        stats["total_processed"] = m.group(1).strip()

    # Entered context | 120.1KB |
    m = re.search(r"Entered context\s*\|\s*(.+?)\s*\|", text)
    if m:
        stats["entered_context"] = m.group(1).strip()

    # 68% reduction
    m = re.search(r"(\d+)%\s*reduction", text)
    if m:
        stats["reduction_pct"] = m.group(1)

    return stats


def read_existing_stats() -> dict:
    """Read existing cm-stats.json or return empty dict."""
    try:
        if CM_STATS_FILE.exists():
            return json.loads(CM_STATS_FILE.read_text())
    except (json.JSONDecodeError, OSError):
        pass
    return {}


def should_reset_session(stats: dict) -> bool:
    """Return True if accumulated counters should be reset (stale session)."""
    updated_at = stats.get("updated_at", "")
    if not updated_at:
        return True
    try:
        ts = datetime.fromisoformat(updated_at.replace("Z", "+00:00"))
        age = (datetime.now(timezone.utc) - ts).total_seconds()
        return age > SESSION_RESET_SECONDS
    except (ValueError, TypeError):
        return True


def extract_response_text(payload: dict) -> str:
    """Extract text content from tool response payload."""
    tool_response = payload.get("tool_response", [])
    text = ""
    for block in tool_response:
        if isinstance(block, dict) and block.get("type") == "text":
            text += block.get("text", "")
        elif isinstance(block, str):
            text += block
    return text


_SIZE_UNITS = {"B": 1, "KB": 1024, "MB": 1024 * 1024, "GB": 1024 ** 3}


def parse_size_to_bytes(s: str) -> int:
    """Parse human-readable size string (e.g. '80.6KB') to bytes."""
    m = re.match(r"([\d.]+)\s*(B|KB|MB|GB)", s.strip(), re.IGNORECASE)
    if not m:
        return 0
    return int(float(m.group(1)) * _SIZE_UNITS.get(m.group(2).upper(), 1))


def format_size(n: int) -> str:
    """Format bytes to human-readable string (e.g. '165.1KB')."""
    if n < 1024:
        return f"{n}B"
    if n < 1024 * 1024:
        return f"{n / 1024:.1f}KB"
    return f"{n / (1024 * 1024):.1f}MB"


def write_stats(stats: dict):
    """Write stats to cm-stats.json."""
    try:
        CM_STATS_FILE.parent.mkdir(parents=True, exist_ok=True)
        CM_STATS_FILE.write_text(json.dumps(stats, indent=2) + "\n")
    except OSError:
        pass


def mark_cm_used_this_session():
    """Set cm_used_this_session = True in backup-state.json.

    Called after any ctx_* tool fires so the statusline knows
    context-mode has been used in the current session.
    """
    try:
        state = {}
        if BACKUP_STATE.exists():
            state = json.loads(BACKUP_STATE.read_text())
        state["cm_used_this_session"] = True
        BACKUP_STATE.write_text(json.dumps(state, indent=2) + "\n")
    except (json.JSONDecodeError, OSError):
        pass


def main():
    try:
        payload = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, ValueError):
        print(json.dumps({"status": "ok"}))
        return

    tool_name = payload.get("tool_name", "")
    text = extract_response_text(payload)

    if not text:
        print(json.dumps({"status": "ok"}))
        return

    is_stats_tool = tool_name.endswith("ctx_stats")
    now = datetime.now(timezone.utc).isoformat()

    if is_stats_tool:
        # Path A: Authoritative — parse ctx_stats output
        stats = parse_stats(text)
        if not stats:
            print(json.dumps({"status": "ok"}))
            return

        stats["source"] = "authoritative"
        stats["session_entered_bytes"] = 0
        stats["session_call_count"] = 0
        stats["updated_at"] = now
        stats["authoritative_updated_at"] = now
        # Persist reduction ratio for hybrid display between ctx_stats calls
        if stats.get("reduction_pct"):
            stats["last_known_reduction_pct"] = stats["reduction_pct"]
        write_stats(stats)
        mark_cm_used_this_session()
    else:
        # Path B: Accumulated — track response bytes from any ctx_* tool
        # Also dynamically update authoritative totals if baseline exists
        response_bytes = len(text.encode("utf-8"))
        existing = read_existing_stats()

        if should_reset_session(existing):
            existing["session_entered_bytes"] = 0
            existing["session_call_count"] = 0

        existing["session_entered_bytes"] = existing.get("session_entered_bytes", 0) + response_bytes
        existing["session_call_count"] = existing.get("session_call_count", 0) + 1

        existing["source"] = "accumulated"
        existing["updated_at"] = now
        write_stats(existing)
        mark_cm_used_this_session()

    print(json.dumps({"status": "ok"}))


if __name__ == "__main__":
    main()
