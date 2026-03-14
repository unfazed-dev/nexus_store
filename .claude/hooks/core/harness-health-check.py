#!/usr/bin/env python3
from __future__ import annotations
# review_by: 2026-09-14
"""StatusLine helper: one-time-per-session harness health check.

Called by context-budget.py on first invocation. Checks if harness
maintenance agents (doc-gardener, gc-agent, drift-detector) have been
run recently. Prints a warning if any are stale (>7 days).

Returns a short warning string or empty string.

Exit codes:
  0 = always
"""
# Hook Contract:
#   Event:        Called by context-budget.py (StatusLine), not a direct hook
#   Input:        none (reads filesystem)
#   Output:       Warning string on stdout (or empty)
#   Side effects: Writes last_harness_check timestamp to backup-state.json
#   Dependencies: .claude/test-history/test-runs.jsonl, backup-state.json
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

PROJECT_DIR = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
PROGRESS_DIR = Path(PROJECT_DIR) / ".claude" / "progress"
BACKUP_STATE = PROGRESS_DIR / "backup-state.json"
RUNS_FILE = Path(PROJECT_DIR) / ".claude" / "test-history" / "test-runs.jsonl"

STALE_DAYS = 7
HARNESS_AGENTS = ["doc-gardener", "gc-agent", "drift-detector"]


def read_backup_state() -> dict:
    try:
        if BACKUP_STATE.exists():
            return json.loads(BACKUP_STATE.read_text())
    except (json.JSONDecodeError, OSError):
        pass
    return {}


def write_backup_state(state: dict):
    try:
        PROGRESS_DIR.mkdir(parents=True, exist_ok=True)
        BACKUP_STATE.write_text(json.dumps(state, indent=2) + "\n")
    except OSError:
        pass


def already_checked_this_session(state: dict) -> bool:
    """Return True if harness health was already checked this session."""
    last_check = state.get("last_harness_check", "")
    if not last_check:
        return False
    try:
        ts = datetime.fromisoformat(last_check.replace("Z", "+00:00"))
        age_hours = (datetime.now(timezone.utc) - ts).total_seconds() / 3600
        return age_hours < 8  # Same session threshold as cm-stats
    except (ValueError, TypeError):
        return False


def find_last_agent_runs() -> dict[str, str | None]:
    """Find last run date for each harness agent from git log or progress files."""
    last_runs: dict[str, str | None] = {a: None for a in HARNESS_AGENTS}

    # Check progress directory for agent output files
    for agent in HARNESS_AGENTS:
        agent_file = PROGRESS_DIR / f"{agent}-last-run.json"
        if agent_file.exists():
            try:
                data = json.loads(agent_file.read_text())
                last_runs[agent] = data.get("run_date")
            except (json.JSONDecodeError, OSError):
                pass

    return last_runs


def check_staleness() -> str:
    """Check if any harness agents are stale and return warning string."""
    last_runs = find_last_agent_runs()
    now = datetime.now(timezone.utc)
    stale = []

    for agent, run_date in last_runs.items():
        if run_date is None:
            stale.append(f"{agent} (never run)")
            continue
        try:
            ts = datetime.fromisoformat(run_date.replace("Z", "+00:00"))
            age_days = (now - ts).days
            if age_days >= STALE_DAYS:
                stale.append(f"{agent} ({age_days}d ago)")
        except (ValueError, TypeError):
            stale.append(f"{agent} (unknown date)")

    if not stale:
        return ""

    return f"🔧 Harness maintenance due: {', '.join(stale)}. Run these agents to check for drift."


def main():
    state = read_backup_state()

    if already_checked_this_session(state):
        # Already checked — output nothing
        sys.exit(0)

    # Mark as checked
    state["last_harness_check"] = datetime.now(timezone.utc).isoformat()
    write_backup_state(state)

    warning = check_staleness()
    if warning:
        print(warning)

    sys.exit(0)


if __name__ == "__main__":
    main()
