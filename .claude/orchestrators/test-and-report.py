#!/usr/bin/env python3
"""Orchestrator: Run smart test runner and report results as structured JSON.

Wraps smart-test-run.py for the nexus_store monorepo, parses results from
test-runs.jsonl, and outputs a structured JSON report following the
orchestrator contract.

Usage:
    python3 .claude/orchestrators/test-and-report.py [OPTIONS]

Options:
    --against=<ref>   Compare against branch/commit (default: HEAD)
    --staged          Only consider staged changes
    --all             Run all tests
    --verbose         Show mapping details

Orchestrator Contract:
    Invocation: python3 .claude/orchestrators/test-and-report.py [--against=<ref>|--staged|--all|--verbose]
    Input:      optional flags forwarded to smart-test-run.py; reads
                .claude/test-history/test-runs.jsonl for result capture
    Output:     JSON {status, checks{tests_pass, results_captured},
                      recommendation, action_needed, details, summary{passed,failed,skipped,duration_ms},
                      acceptance_criteria, accepted}
    Exit codes: 0 = tests pass, 1 = tests fail or no results captured
    Dependencies: .claude/hooks/core/smart-test-run.py, dart CLI, melos
    Side effects: Appends run record to .claude/test-history/test-runs.jsonl
"""

import json
import os
import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
HOOKS_DIR = PROJECT_ROOT / ".claude" / "hooks" / "core"
RUNS_FILE = PROJECT_ROOT / ".claude" / "test-history" / "test-runs.jsonl"


def get_last_run():
    """Read the most recent test run from history."""
    if not RUNS_FILE.exists():
        return None
    try:
        with open(RUNS_FILE, "r", encoding="utf-8") as f:
            lines = f.readlines()
        if lines:
            return json.loads(lines[-1])
    except (json.JSONDecodeError, IndexError):
        pass
    return None


def main():
    # Record pre-run line count to detect new entries
    pre_count = 0
    if RUNS_FILE.exists():
        with open(RUNS_FILE, "r", encoding="utf-8") as f:
            pre_count = sum(1 for _ in f)

    # Forward all args to smart-test-run.py
    smart_runner = HOOKS_DIR / "smart-test-run.py"
    if smart_runner.exists():
        cmd = [sys.executable, str(smart_runner)] + sys.argv[1:]
    else:
        # Fallback: run melos test directly
        cmd = ["melos", "run", "test:dart"]
    exit_code = subprocess.call(cmd, cwd=str(PROJECT_ROOT))

    # Read new run data
    run_data = None
    if RUNS_FILE.exists():
        with open(RUNS_FILE, "r", encoding="utf-8") as f:
            lines = f.readlines()
        if len(lines) > pre_count:
            try:
                run_data = json.loads(lines[-1])
            except json.JSONDecodeError:
                pass

    # Build output
    if run_data:
        passed = run_data.get("passed", 0)
        failed = run_data.get("failed", 0)
        skipped = run_data.get("skipped", 0)
        duration = run_data.get("duration_ms", 0)
        success = run_data.get("overall_success", False)

        result = {
            "status": "pass" if success else "fail",
            "checks": {
                "tests_pass": success,
                "results_captured": True,
            },
            "recommendation": (
                f"All {passed} tests pass ({duration/1000:.1f}s)"
                if success
                else f"{failed} test(s) failed. Run: python3 .claude/hooks/core/rerun-failures.py"
            ),
            "action_needed": not success,
            "details": [] if success else run_data.get("failures", []),
            "summary": {
                "passed": passed,
                "failed": failed,
                "skipped": skipped,
                "duration_ms": duration,
            },
            "acceptance_criteria": {
                "tests_pass": success,
                "results_captured": True,
                "proof_items": [
                    f"{passed}p/{failed}f/{skipped}s in {duration/1000:.1f}s",
                ],
            },
            "accepted": success,
        }
    elif exit_code == 0:
        result = {
            "status": "pass",
            "checks": {"tests_pass": True, "results_captured": False},
            "recommendation": "Tests passed (no detailed results captured)",
            "action_needed": False,
            "details": [],
            "acceptance_criteria": {"tests_pass": True},
            "accepted": True,
        }
    else:
        result = {
            "status": "fail",
            "checks": {"tests_pass": False, "results_captured": False},
            "recommendation": "Tests failed. Check output above for details.",
            "action_needed": True,
            "details": [],
            "acceptance_criteria": {"tests_pass": False},
            "accepted": False,
        }

    print(json.dumps(result, indent=2))
    sys.exit(0 if result["accepted"] else 1)


if __name__ == "__main__":
    main()
