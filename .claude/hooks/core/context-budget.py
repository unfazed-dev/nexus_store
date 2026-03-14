#!/usr/bin/env python3
# review_by: 2026-09-08
"""StatusLine script: real-time context budget monitoring.

Receives JSON payload with context_window.remaining_percentage on every turn.
Adjusts for 16.5% auto-compaction buffer.
Outputs graduated warnings based on utilization zones.

Zones (expressed as remaining_percentage accounting for 16.5% buffer):
  Green:   remaining > 76.5%  (utilization < ~23.5%)
  Early:   remaining ~ 76.5%  (utilization ~ 35%)
  Degraded: remaining ~ 66.5% (utilization ~ 50%)
  Critical: remaining ~ 56.5% (utilization ~ 60%)
  Auto-compaction fires at ~16.5% remaining (~83.5% utilization)
"""
# Hook Contract:
#   Event:        StatusLine (fires every conversation turn)
#   Input:        {"context_window": {"remaining_percentage": <float>}} via stdin
#   Output:       Plain text string on stdout (e.g. "ctx: 20% [Context Mode]")
#   Side effects: Updates .claude/progress/backup-state.json with last_zone and remaining_pct
#   Dependencies: none (stdlib only)
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

PROJECT_DIR = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
BACKUP_STATE = Path(PROJECT_DIR) / ".claude" / "progress" / "backup-state.json"

# Add hooks/core to path for context_mode_utils
sys.path.insert(0, str(Path(PROJECT_DIR) / ".claude" / "hooks" / "core"))
try:
    from context_mode_utils import is_context_mode_active
    _CM_AVAILABLE = True
except ImportError:
    _CM_AVAILABLE = False

# Thresholds (remaining_percentage values)
GREEN_THRESHOLD = 76.5      # Below this = early warning
DUMB_ZONE_THRESHOLD = 66.5  # Below this = Dumb Zone
DANGER_THRESHOLD = 56.5     # Below this = Danger Zone
BUFFER = 16.5               # Auto-compaction buffer


def get_zone(remaining_pct: float) -> tuple:
    """Return (zone_name, icon, message) based on remaining percentage."""
    actual_free = remaining_pct - BUFFER
    utilization = round(100 - remaining_pct, 1)

    if actual_free < 0:
        return ("critical", "!!!", "compaction imminent \u2014 handoff now")

    if remaining_pct <= DANGER_THRESHOLD:
        return (
            "danger",
            "!!!",
            f"{utilization}% \u2014 handoff recommended, save session state"
        )

    if remaining_pct <= DUMB_ZONE_THRESHOLD:
        return (
            "dumb_zone",
            "!!",
            f"{utilization}% \u2014 quality declining, use /compact or subagents"
        )

    if remaining_pct <= GREEN_THRESHOLD:
        return (
            "early_warning",
            "!",
            f"{utilization}% \u2014 consider delegating to subagents"
        )

    return ("green", "", f"{utilization}%")


CM_STATS_FILE = Path(PROJECT_DIR) / ".claude" / "progress" / "cm-stats.json"
CM_STATS_MAX_AGE_SECONDS = 7200  # 2 hours


def _is_cm_active() -> bool:
    """Check if Context Mode is active (cached per invocation)."""
    if not _CM_AVAILABLE:
        return False
    try:
        return is_context_mode_active()
    except Exception:
        return False


def format_bytes(n: int) -> str:
    """Convert raw bytes to human-readable KB/MB."""
    if n < 1024:
        return f"{n}B"
    if n < 1024 * 1024:
        return f"{n / 1024:.1f}KB"
    return f"{n / (1024 * 1024):.1f}MB"


def get_cm_tag() -> str:
    """Return Context Mode status tag with savings stats if available.

    Priority:
      1. Authoritative + fresh (<2h): full reduction stats
      2. Accumulated: approximate bytes in N calls
      3. Stale authoritative + fresh accumulated: show accumulated
      4. No data: N/A
    """
    if not _is_cm_active():
        return ""

    # Check session flag — suppress stale stats after /clear
    try:
        if BACKUP_STATE.exists():
            state = json.loads(BACKUP_STATE.read_text())
            if not state.get("cm_used_this_session", False):
                return ""
    except (json.JSONDecodeError, OSError):
        pass

    try:
        if CM_STATS_FILE.exists():
            stats = json.loads(CM_STATS_FILE.read_text())
            updated_at = stats.get("updated_at", "")
            source = stats.get("source", "")
            age = float("inf")
            if updated_at:
                from datetime import datetime as dt
                ts = dt.fromisoformat(updated_at.replace("Z", "+00:00"))
                age = (datetime.now(timezone.utc) - ts).total_seconds()

            is_fresh = age < CM_STATS_MAX_AGE_SECONDS
            has_authoritative = all(
                stats.get(k) for k in ("total_processed", "entered_context", "reduction_pct")
            )
            session_bytes = stats.get("session_entered_bytes", 0)
            session_calls = stats.get("session_call_count", 0)
            has_accumulated = session_calls > 0

            # Priority 1: Fresh authoritative stats (shown regardless of source)
            if has_authoritative and is_fresh:
                total = stats["total_processed"]
                entered = stats["entered_context"]
                pct = stats["reduction_pct"]
                return f" [Context Mode: {total} \u2192 {entered} | saved: {pct}%]"

            # Priority 2/3: Accumulated stats (fresh)
            if has_accumulated and is_fresh:
                approx = format_bytes(session_bytes)
                return f" [Context Mode: ~{approx} in {session_calls} calls]"

    except (json.JSONDecodeError, OSError, ValueError, KeyError):
        pass
    return " [Context Mode: N/A]"


SESSION_RESET_THRESHOLD = 95.0  # remaining_pct above this = fresh context (/clear)
SESSION_RESET_PREV_MAX = 85.0   # previous remaining must be below this to confirm jump


def update_backup_state(zone: str, remaining_pct: float):
    """Update shared backup state for coordination with PreCompact handler.

    Detects session resets (/clear) by observing remaining_pct jumping above 95%
    from a previous value below 85%. Compaction typically recovers to ~70-85%,
    so 95% is a safe threshold for detecting fresh context windows.
    """
    try:
        state = {}
        if BACKUP_STATE.exists():
            state = json.loads(BACKUP_STATE.read_text())

        # Detect session reset: remaining jumped above 95% (fresh context after /clear)
        last_remaining = state.get("last_remaining_pct")
        if remaining_pct > SESSION_RESET_THRESHOLD:
            if last_remaining is None or last_remaining < SESSION_RESET_PREV_MAX:
                state["cm_used_this_session"] = False

        state["last_zone"] = zone
        state["last_remaining_pct"] = remaining_pct
        state["last_check"] = datetime.now(timezone.utc).isoformat()
        state["context_mode_active"] = _is_cm_active()
        BACKUP_STATE.write_text(json.dumps(state, indent=2) + "\n")
    except (json.JSONDecodeError, OSError):
        pass


def main():
    try:
        payload = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, ValueError):
        # No valid input — output empty status
        print("")
        return

    context_window = payload.get("context_window", {})
    remaining_pct = context_window.get("remaining_percentage")

    if remaining_pct is None:
        print("")
        return

    zone, icon, message = get_zone(remaining_pct)
    update_backup_state(zone, remaining_pct)

    # Context Mode indicator with savings stats
    cm_tag = get_cm_tag()

    # Build StatusLine output (plain text)
    if zone == "green":
        print(f"ctx: {message}{cm_tag}")
    else:
        print(f"ctx{icon} {message}{cm_tag}")


if __name__ == "__main__":
    main()
