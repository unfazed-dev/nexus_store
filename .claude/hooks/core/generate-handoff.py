#!/usr/bin/env python3
# review_by: 2026-09-08
"""PreCompact hook: generates session handoff before context compaction.

Receives transcript and custom_instructions via stdin (JSON).
Extracts decisions, blockers, file changes from the session transcript.
Writes structured handoff to .claude/progress/session-handoff.json.
Archives previous handoff to .claude/progress/sessions/.
"""
# Hook Contract:
#   Event:        PreCompact
#   Input:        {"transcript": "...", "custom_instructions": "..."} via stdin
#   Output:       {"handoff_generated": "<session_id>", "archived_files": N} on stdout
#   Side effects: Writes .claude/progress/session-handoff.json;
#                 archives previous handoff to .claude/progress/sessions/<session_id>.json;
#                 updates .claude/progress/backup-state.json with compaction count
#   Dependencies: none (stdlib only)
import json
import os
import re
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

PROJECT_DIR = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
PROGRESS_DIR = Path(PROJECT_DIR) / ".claude" / "progress"
HANDOFF_PATH = PROGRESS_DIR / "session-handoff.json"
SESSIONS_DIR = PROGRESS_DIR / "sessions"
BACKUP_STATE = PROGRESS_DIR / "backup-state.json"
MAX_SESSIONS = 20


def archive_previous_handoff():
    """Move current handoff to sessions/ archive."""
    if not HANDOFF_PATH.exists():
        return
    SESSIONS_DIR.mkdir(parents=True, exist_ok=True)
    try:
        current = json.loads(HANDOFF_PATH.read_text())
        session_id = current.get("session_id", "unknown")
        archive_name = f"{session_id}.json"
        # Sanitize filename
        archive_name = re.sub(r'[^\w\-.]', '_', archive_name)
        shutil.copy2(HANDOFF_PATH, SESSIONS_DIR / archive_name)
        rotate_sessions()
    except (json.JSONDecodeError, OSError):
        pass


def rotate_sessions():
    """Keep only the most recent MAX_SESSIONS archived handoffs."""
    if not SESSIONS_DIR.exists():
        return
    files = sorted(SESSIONS_DIR.glob("*.json"), key=lambda f: f.stat().st_mtime)
    while len(files) > MAX_SESSIONS:
        files[0].unlink()
        files.pop(0)


def extract_from_transcript(transcript: str) -> dict:
    """Extract decisions, blockers, and file changes from transcript text.

    This is a best-effort extraction using pattern matching.
    The transcript may be empty for auto-compaction events.
    """
    decisions = []
    blockers = []
    files_modified = []
    feature_progress = {}

    if not transcript:
        return {
            "decisions_made": decisions,
            "unresolved_blockers": blockers,
            "files_modified": files_modified,
            "feature_progress": feature_progress,
            "raw_outputs_summary": "Auto-compaction triggered. No transcript available."
        }

    # Extract file modifications (look for Write/Edit tool patterns)
    # Matches paths like packages/xxx/lib/..., packages/xxx/test/..., docs/...
    file_patterns = re.findall(
        r'(?:Created|Modified|Wrote|Edited|Write|Edit).*?["`]([^"`]+\.\w+)["`]',
        transcript, re.IGNORECASE
    )
    seen_files = set()
    for f in file_patterns:
        if f not in seen_files and not f.startswith("http"):
            seen_files.add(f)
            files_modified.append({
                "path": f,
                "reason": "modified during session",
                "action": "modified"
            })

    # Extract decision patterns
    decision_patterns = re.findall(
        r'(?:decided|decision|chose|choosing|went with|selected)[:\s]+(.+?)(?:\.|$)',
        transcript, re.IGNORECASE | re.MULTILINE
    )
    for d in decision_patterns[:10]:  # Cap at 10
        decisions.append({
            "decision": d.strip()[:200],
            "rationale": "Extracted from session transcript"
        })

    # Extract blocker patterns
    blocker_patterns = re.findall(
        r'(?:blocked|blocker|cannot|can\'t proceed|waiting for|need.*before)[:\s]+(.+?)(?:\.|$)',
        transcript, re.IGNORECASE | re.MULTILINE
    )
    for b in blocker_patterns[:5]:  # Cap at 5
        blockers.append({
            "blocker": b.strip()[:200],
            "context": "Extracted from session transcript"
        })

    # Build summary (truncate to reasonable size)
    summary_lines = []
    if files_modified:
        summary_lines.append(f"{len(files_modified)} files modified")
    if decisions:
        summary_lines.append(f"{len(decisions)} decisions captured")
    if blockers:
        summary_lines.append(f"{len(blockers)} blockers noted")

    raw_summary = ". ".join(summary_lines) if summary_lines else "Session compacted. Review handoff for details."

    return {
        "decisions_made": decisions,
        "unresolved_blockers": blockers,
        "files_modified": files_modified,
        "feature_progress": feature_progress,
        "raw_outputs_summary": raw_summary
    }


def update_backup_state(session_id: str):
    """Update shared backup state for coordination with StatusLine monitor."""
    try:
        state = {}
        if BACKUP_STATE.exists():
            state = json.loads(BACKUP_STATE.read_text())
        state["last_handoff"] = session_id
        state["last_handoff_time"] = datetime.now(timezone.utc).isoformat()
        state["compaction_count"] = state.get("compaction_count", 0) + 1
        BACKUP_STATE.write_text(json.dumps(state, indent=2) + "\n")
    except (json.JSONDecodeError, OSError):
        pass


def main():
    # Read hook input from stdin
    try:
        hook_input = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, ValueError):
        hook_input = {}

    transcript = hook_input.get("transcript", "")

    # Archive previous handoff
    archive_previous_handoff()

    # Generate new handoff
    now = datetime.now(timezone.utc)
    session_id = now.strftime("%Y-%m-%dT%H%M%S") + "-compact"

    extracted = extract_from_transcript(transcript)

    handoff = {
        "session_id": session_id,
        "timestamp": now.isoformat(),
        **extracted,
        "invariant_violations": [],
        "tracker_ref": ""
    }

    # Try to read tracker ref from current sprint
    sprint_path = PROGRESS_DIR / "current-sprint.md"
    if sprint_path.exists():
        sprint_text = sprint_path.read_text()
        tracker_match = re.search(r'(docs/trackers/\S+\.md)', sprint_text)
        if tracker_match:
            handoff["tracker_ref"] = tracker_match.group(1)

    # Write handoff
    PROGRESS_DIR.mkdir(parents=True, exist_ok=True)
    HANDOFF_PATH.write_text(json.dumps(handoff, indent=2) + "\n")

    # Update backup state
    update_backup_state(session_id)

    # Output minimal confirmation (asymmetric output: single line on success)
    print(json.dumps({"handoff_generated": session_id, "archived_files": len(extracted["files_modified"])}))


if __name__ == "__main__":
    main()
