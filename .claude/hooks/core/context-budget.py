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
import re
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

_SIZE_UNITS = {"B": 1, "KB": 1024, "MB": 1024 * 1024, "GB": 1024 ** 3}


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


def _parse_size_to_bytes(s: str) -> int:
    """Parse human-readable size string (e.g. '80.6KB') to bytes."""
    m = re.match(r"([\d.]+)\s*(B|KB|MB|GB)", s.strip(), re.IGNORECASE)
    if not m:
        return 0
    return int(float(m.group(1)) * _SIZE_UNITS.get(m.group(2).upper(), 1))


def _reset_cm_session_counters():
    """Reset session counters in cm-stats.json on /clear detection."""
    try:
        if CM_STATS_FILE.exists():
            stats = json.loads(CM_STATS_FILE.read_text())
            stats["session_entered_bytes"] = 0
            stats["session_raw_bytes"] = 0
            stats["session_call_count"] = 0
            stats.pop("session_reduction_pct", None)
            stats["updated_at"] = datetime.now(timezone.utc).isoformat()
            CM_STATS_FILE.write_text(json.dumps(stats, indent=2) + "\n")
    except (json.JSONDecodeError, OSError):
        pass


def _mark_cm_used_this_session():
    """Set cm_used_this_session = true in backup-state.json."""
    try:
        state = {}
        if BACKUP_STATE.exists():
            state = json.loads(BACKUP_STATE.read_text())
        if not state.get("cm_used_this_session", False):
            state["cm_used_this_session"] = True
            BACKUP_STATE.write_text(json.dumps(state, indent=2) + "\n")
    except (json.JSONDecodeError, OSError):
        pass


def _compute_token_savings(total_bytes: int, entered_bytes: int, window_size: int) -> tuple:
    """Compute token savings metrics from byte totals and context window size.

    Returns (saved_tokens_k, budget_pct) or (None, None) if insufficient data.
    """
    if total_bytes <= 0 or entered_bytes <= 0 or window_size <= 0:
        return None, None
    if total_bytes <= entered_bytes:
        return None, None

    ctx_entered_tokens = entered_bytes / 4  # approx bytes-to-tokens
    raw_tokens = total_bytes / 4
    saved_tokens = raw_tokens - ctx_entered_tokens
    saved_k = round(saved_tokens / 1000)
    budget_pct = round(saved_tokens / window_size * 100)

    if saved_k <= 0:
        return None, None
    return saved_k, budget_pct


def get_cm_tag(context_window: dict = None) -> str:
    """Return Context Mode status tag with live token savings stats.

    Uses context_window.context_window_size (live from StatusLine payload)
    combined with session byte tracking from cm-stats.json to compute
    token savings that update every turn.

    Data sources (best available wins):
      - Authoritative baseline (from ctx_stats) + session delta
      - Authoritative baseline only (no session ctx calls yet)
      - Session-only data (no baseline)
      - No data -> N/A
    """
    if not _is_cm_active():
        return ""

    # Check session flag FIRST -- after /clear, suppress until first ctx call
    try:
        if BACKUP_STATE.exists():
            state = json.loads(BACKUP_STATE.read_text())
            if not state.get("cm_used_this_session", False):
                return " [context-mode: not applicable]"
    except (json.JSONDecodeError, OSError):
        pass

    window_size = (context_window or {}).get("context_window_size", 0)

    has_fresh_stats = False
    try:
        if CM_STATS_FILE.exists():
            stats = json.loads(CM_STATS_FILE.read_text())
            from datetime import datetime as dt

            # Compute authoritative freshness from its own timestamp
            auth_updated_at = stats.get("authoritative_updated_at", "")
            auth_age = float("inf")
            if auth_updated_at:
                ts = dt.fromisoformat(auth_updated_at.replace("Z", "+00:00"))
                auth_age = (datetime.now(timezone.utc) - ts).total_seconds()

            # Compute accumulated freshness from general timestamp
            updated_at = stats.get("updated_at", "")
            acc_age = float("inf")
            if updated_at:
                ts = dt.fromisoformat(updated_at.replace("Z", "+00:00"))
                acc_age = (datetime.now(timezone.utc) - ts).total_seconds()

            is_auth_fresh = auth_age < CM_STATS_MAX_AGE_SECONDS
            is_acc_fresh = acc_age < CM_STATS_MAX_AGE_SECONDS

            has_authoritative = all(
                stats.get(k) for k in ("total_processed", "entered_context", "reduction_pct")
            )
            session_bytes = stats.get("session_entered_bytes", 0)
            session_calls = stats.get("session_call_count", 0)
            has_accumulated = session_calls > 0

            # Compute total_bytes and entered_bytes from best available data
            total_bytes = 0
            entered_bytes = 0

            if has_authoritative and is_auth_fresh:
                has_fresh_stats = True
                _mark_cm_used_this_session()
                base_total = _parse_size_to_bytes(stats["total_processed"])
                base_entered = _parse_size_to_bytes(stats["entered_context"])

                if has_accumulated and is_acc_fresh:
                    # Authoritative baseline + session delta
                    session_raw = stats.get("session_raw_bytes", 0)
                    ratio = int(stats.get("last_known_reduction_pct") or stats["reduction_pct"])
                    session_raw_est = int(session_bytes / (1 - ratio / 100)) if ratio < 100 else session_bytes
                    total_bytes = base_total + max(session_raw, session_raw_est)
                    entered_bytes = base_entered + session_bytes
                else:
                    # Authoritative only (no session ctx calls yet)
                    total_bytes = base_total
                    entered_bytes = base_entered

            elif has_accumulated and is_acc_fresh:
                has_fresh_stats = True
                _mark_cm_used_this_session()
                entered_bytes = session_bytes
                session_raw = stats.get("session_raw_bytes", 0)
                ratio = stats.get("last_known_reduction_pct") or stats.get("reduction_pct")
                if ratio:
                    # Ratio-based estimate is most reliable
                    pct = int(ratio)
                    estimated_total = int(entered_bytes / (1 - pct / 100)) if pct < 100 else entered_bytes
                    # Use max of raw and estimate -- footer-parsed raw can undercount
                    total_bytes = max(session_raw, estimated_total)
                elif session_raw > entered_bytes:
                    # No ratio but raw > entered -- raw is usable
                    total_bytes = session_raw
                else:
                    # No ratio known, raw unreliable -- show bytes only
                    approx = format_bytes(session_bytes)
                    hint = " (run ctx stats for %)" if session_calls % 20 == 0 else ""
                    return f" [Context Mode: ~{approx} in {session_calls} calls{hint}]"

            if has_fresh_stats and total_bytes > 0 and entered_bytes > 0:
                # Build unified display with token savings
                tag = f" [Context Mode: {format_bytes(total_bytes)} \u2192 {format_bytes(entered_bytes)}"
                saved_k, budget_pct = _compute_token_savings(total_bytes, entered_bytes, window_size)
                reduction_pct = round((1 - entered_bytes / total_bytes) * 100)
                if saved_k is not None:
                    tag += f" | saved ~{reduction_pct}%, ~{saved_k}k tokens"
                else:
                    tag += f" | saved: ~{reduction_pct}%"
                tag += "]"
                return tag

    except (json.JSONDecodeError, OSError, ValueError, KeyError):
        pass

    return " [Context Mode: N/A]"


FRESH_CONTEXT_THRESHOLD = 96.0  # Above this = definitely fresh context (/clear)
COMPACTION_JUMP_THRESHOLD = 95.0  # Above this + previous < 85 = likely /clear after deep use
COMPACTION_PREV_MAX = 85.0  # Compaction recovers to ~70-85%, not above this


def update_backup_state(zone: str, remaining_pct: float):
    """Update shared backup state for coordination with PreCompact handler.

    Detects session resets (/clear) via two heuristics:
      1. remaining > 96% — compaction can't recover this high, must be fresh context
      2. remaining > 95% AND previous < 85% — jump from deep usage to near-empty
    """
    try:
        state = {}
        if BACKUP_STATE.exists():
            state = json.loads(BACKUP_STATE.read_text())

        # Detect session reset
        last_remaining = state.get("last_remaining_pct")
        is_fresh_context = (
            remaining_pct > FRESH_CONTEXT_THRESHOLD
            and (last_remaining is None or last_remaining <= FRESH_CONTEXT_THRESHOLD)
        )
        is_jump_from_deep = (
            remaining_pct > COMPACTION_JUMP_THRESHOLD
            and (last_remaining is None or last_remaining < COMPACTION_PREV_MAX)
        )
        if is_fresh_context or is_jump_from_deep:
            state["cm_used_this_session"] = False
            # Also reset session counters in cm-stats.json
            _reset_cm_session_counters()

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
        # No valid input -- output empty status
        print("")
        return

    context_window = payload.get("context_window", {})
    remaining_pct = context_window.get("remaining_percentage")

    if remaining_pct is None:
        print("")
        return

    zone, icon, message = get_zone(remaining_pct)
    update_backup_state(zone, remaining_pct)

    # One-time harness health check (first invocation per session)
    harness_warning = ""
    try:
        import subprocess
        result = subprocess.run(
            ["python3", str(Path(PROJECT_DIR) / ".claude" / "hooks" / "core" / "harness-health-check.py")],
            capture_output=True, text=True, timeout=5,
            cwd=PROJECT_DIR,
            env={**os.environ, "CLAUDE_PROJECT_DIR": PROJECT_DIR},
        )
        if result.returncode == 0 and result.stdout.strip():
            harness_warning = " | " + result.stdout.strip()
    except (subprocess.TimeoutExpired, OSError):
        pass

    # Context Mode indicator with live token savings
    cm_tag = get_cm_tag(context_window)

    # Build StatusLine output (plain text)
    if zone == "green":
        print(f"ctx: {message}{cm_tag}{harness_warning}")
    else:
        print(f"ctx{icon} {message}{cm_tag}{harness_warning}")


if __name__ == "__main__":
    main()
