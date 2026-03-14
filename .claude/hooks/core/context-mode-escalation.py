#!/usr/bin/env python3
# review_by: 2026-09-08
"""PostToolUse hook: progressive context budget escalation when Context Mode is active.

Reads the current zone from backup-state.json (written by context-budget.py StatusLine)
and takes progressive actions as context usage increases:

  Early Warning (~76.5%):  Log recommendation to prefer ctx_* tools
  Dumb Zone (~66.5%):      Write continuation plan + KB-index context
  Danger Zone (~56.5%):    Auto-trigger generate-handoff.py proactively

Only fires when Context Mode is active — without CM, the standard StatusLine
warnings are sufficient.
"""
# Hook Contract:
#   Event:        PostToolUse (matcher: Edit|Write|Bash)
#   Input:        {"tool_name": "...", "tool_input": {...}, "tool_response": [...]} via stdin
#   Output:       {"escalation_level": "<zone>", "action": "<description>"} on stdout
#   Side effects: Updates backup-state.json with escalation_level;
#                 may write continuation plan or trigger handoff
#   Dependencies: context_mode_utils.py, generate-handoff.py
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

PROJECT_DIR = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
PROGRESS_DIR = Path(PROJECT_DIR) / ".claude" / "progress"
BACKUP_STATE = PROGRESS_DIR / "backup-state.json"
CONTINUATION_PLAN = PROGRESS_DIR / "continuation-plan.json"
HOOKS_DIR = Path(PROJECT_DIR) / ".claude" / "hooks" / "core"

# Add hooks/core to path for context_mode_utils
sys.path.insert(0, str(HOOKS_DIR))
try:
    from context_mode_utils import is_context_mode_active
    _CM_AVAILABLE = True
except ImportError:
    _CM_AVAILABLE = False

# Zone thresholds (must match context-budget.py)
GREEN_THRESHOLD = 76.5
DUMB_ZONE_THRESHOLD = 66.5
DANGER_THRESHOLD = 56.5


def read_backup_state() -> dict:
    """Read current backup state."""
    try:
        if BACKUP_STATE.exists():
            return json.loads(BACKUP_STATE.read_text())
    except (json.JSONDecodeError, OSError):
        pass
    return {}


def write_backup_state(state: dict):
    """Write backup state atomically."""
    try:
        PROGRESS_DIR.mkdir(parents=True, exist_ok=True)
        BACKUP_STATE.write_text(json.dumps(state, indent=2) + "\n")
    except OSError:
        pass


def get_current_zone(state: dict) -> str:
    """Determine current zone from backup state."""
    return state.get("last_zone", "green")


def get_remaining_pct(state: dict) -> float:
    """Get last remaining percentage from backup state."""
    return state.get("last_remaining_pct", 100.0)


def has_escalated_to(state: dict, level: str) -> bool:
    """Check if we've already escalated to this level in this session."""
    return state.get("escalation_level", "") == level


def write_continuation_plan(state: dict):
    """Write a continuation plan file with current session context.

    This captures enough state for a new session to pick up where this one
    left off, without requiring the full context window.
    """
    try:
        plan = {
            "created_at": datetime.now(timezone.utc).isoformat(),
            "reason": "context_budget_dumb_zone",
            "remaining_pct": state.get("last_remaining_pct", 0),
            "zone": "dumb_zone",
            "context_mode_active": True,
            "recommendations": [
                "Use ctx_* tools exclusively for remaining work",
                "Delegate complex tasks to subagents",
                "Consider /compact if quality continues to decline",
                "Review session-handoff.json for prior context"
            ],
            "tracker_ref": state.get("tracker_ref", ""),
            "handoff_ref": str(PROGRESS_DIR / "session-handoff.json")
        }

        # Read current sprint for active work context
        sprint_path = PROGRESS_DIR / "current-sprint.md"
        if sprint_path.exists():
            sprint_text = sprint_path.read_text()
            plan["active_work_snapshot"] = sprint_text[:500]

        CONTINUATION_PLAN.write_text(json.dumps(plan, indent=2) + "\n")
    except OSError:
        pass


def trigger_proactive_handoff():
    """Trigger generate-handoff.py proactively before compaction forces it.

    Passes an empty transcript since we're pre-empting compaction.
    The handoff script will still capture backup-state and sprint info.
    """
    handoff_script = HOOKS_DIR / "generate-handoff.py"
    if not handoff_script.exists():
        return

    try:
        payload = json.dumps({
            "transcript": "",
            "custom_instructions": "Proactive handoff triggered by context-mode-escalation at danger zone."
        })
        subprocess.run(
            ["python3", str(handoff_script)],
            input=payload,
            capture_output=True,
            text=True,
            timeout=10,
            cwd=PROJECT_DIR,
            env={**os.environ, "CLAUDE_PROJECT_DIR": PROJECT_DIR}
        )
    except (subprocess.TimeoutExpired, OSError):
        pass


def main():
    # Read stdin (PostToolUse payload) — we don't need the content,
    # but must consume it to avoid broken pipe
    try:
        sys.stdin.read()
    except Exception:
        pass

    # Only act when Context Mode is active
    if not _CM_AVAILABLE:
        print(json.dumps({"escalation_level": "inactive", "action": "cm_not_available"}))
        return

    try:
        cm_active = is_context_mode_active()
    except Exception:
        cm_active = False

    if not cm_active:
        print(json.dumps({"escalation_level": "inactive", "action": "cm_not_active"}))
        return

    state = read_backup_state()
    zone = get_current_zone(state)
    remaining = get_remaining_pct(state)
    current_escalation = state.get("escalation_level", "green")
    action = "none"

    # Progressive escalation — only escalate upward, never downward
    # This prevents repeated actions on every tool call
    escalation_order = ["green", "early_warning", "dumb_zone", "danger"]

    def escalation_rank(level: str) -> int:
        try:
            return escalation_order.index(level)
        except ValueError:
            return 0

    zone_rank = escalation_rank(zone)
    current_rank = escalation_rank(current_escalation)

    if zone_rank <= current_rank:
        # Already at or past this escalation level
        print(json.dumps({
            "escalation_level": current_escalation,
            "action": "already_escalated"
        }))
        return

    # Escalate based on zone
    if zone == "early_warning" and current_rank < escalation_rank("early_warning"):
        state["escalation_level"] = "early_warning"
        action = "logged_ctx_recommendation"
        write_backup_state(state)
        print(json.dumps({
            "escalation_level": "early_warning",
            "action": action,
            "message": f"Context at {remaining}% — prefer ctx_* tools over raw Bash/Read for large outputs"
        }))
        return

    if zone == "dumb_zone" and current_rank < escalation_rank("dumb_zone"):
        state["escalation_level"] = "dumb_zone"
        write_backup_state(state)
        write_continuation_plan(state)
        action = "wrote_continuation_plan"
        print(json.dumps({
            "escalation_level": "dumb_zone",
            "action": action,
            "continuation_plan": str(CONTINUATION_PLAN),
            "message": f"Context at {remaining}% — continuation plan written, use subagents for remaining work"
        }))
        return

    if zone in ("danger", "critical") and current_rank < escalation_rank("danger"):
        state["escalation_level"] = "danger"
        write_backup_state(state)
        trigger_proactive_handoff()
        action = "triggered_proactive_handoff"
        print(json.dumps({
            "escalation_level": "danger",
            "action": action,
            "message": f"Context at {remaining}% — proactive handoff generated before compaction"
        }))
        return

    # Fallback
    print(json.dumps({"escalation_level": zone, "action": "none"}))


if __name__ == "__main__":
    main()
