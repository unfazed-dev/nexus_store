#!/usr/bin/env python3
"""Harness maintenance orchestrator.

Runs GC agent and drift detector scans, then updates harness-metrics.json.
Designed to be invoked periodically (e.g., weekly) or after major changes.

Usage:
    python3 .claude/orchestrators/harness-maintenance.py [--gc-only | --drift-only | --all]

When run manually (outside Claude Code), performs the checks directly
using local file scanning. When run inside Claude Code, use the Agent
tool to invoke gc-agent and drift-detector subagents instead.

This script performs the LOCAL (non-agent) version of maintenance:
  1. Expiration scan — checks review_by dates on all harness components
  2. Orphan scan — finds agent/skill files not in their index
  3. Session rotation — caps archived sessions at 20
  4. Drift scan — checks doc-source-map.json for stale mappings
  5. Metrics update — writes findings to harness-metrics.json

Orchestrator Contract:
    Invocation: python3 .claude/orchestrators/harness-maintenance.py [--gc-only|--drift-only|--all]
    Input:      optional mode flag; reads .claude/ directory tree and
                .claude/progress/harness-metrics.json
    Output:     JSON {timestamp, mode, expirations{total,expired,expiring_soon},
                      orphans{orphans[]}, sessions_rotated, drift{total_mappings,
                      stale_mappings,contradictions_found}}
    Exit codes: 0 = no issues found, 1 = expired/orphan/stale issues found
    Dependencies: none (pure Python stdlib + local file access)
    Side effects: Deletes oldest session archives if count > 20;
                  updates .claude/progress/harness-metrics.json
"""

import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, Set

ROOT = Path(__file__).resolve().parent.parent.parent
CLAUDE_DIR = ROOT / ".claude"
PROGRESS_DIR = CLAUDE_DIR / "progress"
METRICS_PATH = PROGRESS_DIR / "harness-metrics.json"
SESSIONS_DIR = PROGRESS_DIR / "sessions"
SESSION_CAP = 20


def parse_review_by(content: str, filepath: str) -> Optional[str]:
    """Extract review_by from frontmatter or header comment."""
    # YAML frontmatter
    match = re.search(r"review_by:\s*(\d{4}-\d{2}-\d{2})", content)
    if match:
        return match.group(1)
    # Python/Dart header comment
    match = re.search(r"review.by.*?(\d{4}-\d{2}-\d{2})", content, re.IGNORECASE)
    if match:
        return match.group(1)
    return None


def scan_expirations() -> dict:
    """Check all harness components for expired review_by dates."""
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    expired = []
    expiring_soon = []
    total = 0

    scan_dirs = [
        (CLAUDE_DIR / "invariants", "*.dart"),
        (CLAUDE_DIR / "orchestrators", "*"),
        (CLAUDE_DIR / "agents", "*.md"),
        (CLAUDE_DIR / "hooks" / "core", "*.py"),
    ]

    for scan_dir, pattern in scan_dirs:
        if not scan_dir.exists():
            continue
        for f in scan_dir.glob(pattern):
            if f.name in ("README.md", "__pycache__"):
                continue
            total += 1
            try:
                content = f.read_text()
            except Exception:
                continue
            review_by = parse_review_by(content, str(f))
            if not review_by:
                continue
            if review_by < today:
                expired.append({
                    "file": str(f.relative_to(ROOT)),
                    "review_by": review_by,
                })
            elif review_by <= (datetime.now(timezone.utc).strftime("%Y-%m-%d")[:8] + "30"):
                # Within ~30 days
                expiring_soon.append({
                    "file": str(f.relative_to(ROOT)),
                    "review_by": review_by,
                })

    return {
        "total": total,
        "expired": expired,
        "expiring_soon": expiring_soon,
    }


def _extract_indexed_names(data, key: str) -> Set[str]:
    """Extract names from index data, handling both dict and list formats."""
    items = data.get(key, {})
    if isinstance(items, dict):
        return set(items.keys())
    elif isinstance(items, list):
        return {item.get("name", "") for item in items if isinstance(item, dict)}
    return set()


def scan_orphans() -> dict:
    """Find agent/skill files not in their respective indexes."""
    orphans = []

    # Agent index check
    agent_index_path = CLAUDE_DIR / "agents" / "agent-index.json"
    if agent_index_path.exists():
        with open(agent_index_path) as f:
            index = json.load(f)
        indexed = _extract_indexed_names(index, "agents")
        for f in (CLAUDE_DIR / "agents").glob("*.md"):
            if f.name == "README.md":
                continue
            name = f.stem
            if name not in indexed:
                orphans.append({"file": str(f.relative_to(ROOT)), "index": "agent-index.json"})

    # Skill index check
    skill_index_path = CLAUDE_DIR / "skills" / "skill-index.json"
    if skill_index_path.exists():
        with open(skill_index_path) as f:
            index = json.load(f)
        indexed = _extract_indexed_names(index, "skills")
        for d in (CLAUDE_DIR / "skills").iterdir():
            if d.is_dir() and d.name not in indexed:
                orphans.append({"file": str(d.relative_to(ROOT)), "index": "skill-index.json"})

    return {"orphans": orphans}


def rotate_sessions() -> int:
    """Cap archived sessions at SESSION_CAP, deleting oldest."""
    if not SESSIONS_DIR.exists():
        return 0

    sessions = sorted(SESSIONS_DIR.glob("*.json"), key=lambda f: f.stat().st_mtime)
    rotated = 0
    while len(sessions) > SESSION_CAP:
        oldest = sessions.pop(0)
        oldest.unlink()
        rotated += 1

    return rotated


def _is_glob_pattern(path: str) -> bool:
    """Check if a path contains glob characters."""
    return any(c in path for c in ("*", "?", "[", "]"))


def _glob_has_matches(pattern: str) -> bool:
    """Check if a glob pattern resolves to at least one file."""
    import glob as globmod
    return len(globmod.glob(str(ROOT / pattern), recursive=True)) > 0


def scan_drift() -> dict:
    """Check doc-source-map.json for stale source paths."""
    map_path = CLAUDE_DIR / "doc-source-map.json"
    if not map_path.exists():
        return {"status": "skip", "reason": "doc-source-map.json not found"}

    with open(map_path) as f:
        source_map = json.load(f)

    stale = []
    total_mappings = 0

    # Skip metadata keys (start with _)
    METADATA_KEYS = {"_comment", "_updated", "_version", "_schema"}

    for doc, sources in source_map.items():
        if doc in METADATA_KEYS:
            continue

        source_list = sources if isinstance(sources, list) else [sources]
        for src in source_list:
            if not isinstance(src, str):
                continue
            total_mappings += 1
            if _is_glob_pattern(src):
                # Glob patterns: check if they resolve to at least one file
                if not _glob_has_matches(src):
                    stale.append({"doc": doc, "missing_source": src, "type": "glob_empty"})
            else:
                # Literal paths: check existence
                if not (ROOT / src).exists():
                    stale.append({"doc": doc, "missing_source": src, "type": "missing_file"})

    return {
        "total_mappings": total_mappings,
        "stale_mappings": stale,
        "contradictions_found": len(stale),
    }


def run_maintenance(mode: str = "all") -> dict:
    """Run all maintenance checks and update metrics."""
    now = datetime.now(timezone.utc).isoformat()
    results = {"timestamp": now, "mode": mode}

    if mode in ("all", "gc-only"):
        results["expirations"] = scan_expirations()
        results["orphans"] = scan_orphans()
        results["sessions_rotated"] = rotate_sessions()

    if mode in ("all", "drift-only"):
        results["drift"] = scan_drift()

    # Update metrics
    if METRICS_PATH.exists():
        with open(METRICS_PATH) as f:
            metrics = json.load(f)
    else:
        metrics = {}

    metrics["_updated"] = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    if "expirations" in results:
        exp = results["expirations"]
        # Harness components = rules + invariants + orchestrators + harness agents
        # (the curated count of harness-specific components, not all scanned files)
        rules_count = len([f for f in (CLAUDE_DIR / "rules").glob("*.md") if f.name != "README.md"])
        invariants_count = len(list((CLAUDE_DIR / "invariants").glob("*.dart")))
        orchestrators_count = len([f for f in (CLAUDE_DIR / "orchestrators").iterdir()
                                   if f.suffix in (".py", ".sh") and f.name != "README.md"
                                   and not f.name.startswith("test_")])
        harness_agents = {"doc-gardener", "drift-detector", "gc-agent"}
        harness_agent_count = len([f for f in (CLAUDE_DIR / "agents").glob("*.md")
                                   if f.stem in harness_agents])
        harness_total = rules_count + invariants_count + orchestrators_count + harness_agent_count

        metrics["harness_components"] = {
            "total": harness_total,
            "scanned": exp["total"],
            "expired": len(exp["expired"]),
            "expiring_soon": len(exp["expiring_soon"]),
        }
        metrics["last_gc_run"] = now

    if "drift" in results:
        drift = results["drift"]
        if drift.get("status") != "skip":
            metrics["drift"] = {
                "contradictions_found": drift.get("contradictions_found", 0),
                "last_scan_commits": drift.get("total_mappings", 0),
            }
        metrics["last_drift_scan"] = now

    with open(METRICS_PATH, "w") as f:
        json.dump(metrics, f, indent=2)
        f.write("\n")

    return results


def main():
    mode = "all"
    if len(sys.argv) > 1:
        arg = sys.argv[1].lstrip("-")
        if arg in ("gc-only", "gc"):
            mode = "gc-only"
        elif arg in ("drift-only", "drift"):
            mode = "drift-only"

    results = run_maintenance(mode)

    # Print summary
    print(json.dumps(results, indent=2))

    # Determine exit status
    issues = 0
    if "expirations" in results:
        issues += len(results["expirations"].get("expired", []))
    if "orphans" in results:
        issues += len(results["orphans"].get("orphans", []))
    if "drift" in results and results["drift"].get("status") != "skip":
        issues += results["drift"].get("contradictions_found", 0)

    if issues > 0:
        print(f"\n⚠️  {issues} issue(s) found. Review output above.")
        sys.exit(1)
    else:
        print("\n✅ All maintenance checks passed.")
        sys.exit(0)


if __name__ == "__main__":
    main()
