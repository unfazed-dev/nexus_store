#!/usr/bin/env python3
# review_by: 2026-09-14
"""
Test health dashboard showing aggregate statistics from test history.

Reads test-runs.jsonl and displays pass rates, recent failures, flaky test
detection, and run history.

Usage:
    python3 .claude/hooks/core/test-dashboard.py [OPTIONS]

Options:
    --last=N      Show stats for last N runs (default: 10)
    --failures    Show only failure details
    --flaky       Show tests that flap between pass/fail
    --json        Output as JSON (for scripts)
    --gc          Garbage collect: trim history to last 500 runs
    --compact     Compact summary (one-liner)

I/O:
    Stdin:  none
    Stdout: formatted dashboard table, or JSON (--json), or one-liner (--compact)
    Exit:   0 always

Dependencies:
    .claude/test-history/test-runs.jsonl  (written by capture-test-results.py)
"""
import json
import sys
from collections import defaultdict
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent.parent
RUNS_FILE = PROJECT_ROOT / ".claude" / "test-history" / "test-runs.jsonl"
MAX_RUNS_GC = 500


def parse_args(argv):
    """Parse command line arguments."""
    args = {
        "last": 10,
        "failures": False,
        "flaky": False,
        "json_output": False,
        "gc": False,
        "compact": False,
    }
    for arg in argv:
        if arg.startswith("--last="):
            try:
                args["last"] = int(arg.split("=", 1)[1])
            except ValueError:
                pass
        elif arg == "--failures":
            args["failures"] = True
        elif arg == "--flaky":
            args["flaky"] = True
        elif arg == "--json":
            args["json_output"] = True
        elif arg == "--gc":
            args["gc"] = True
        elif arg == "--compact":
            args["compact"] = True
    return args


def load_runs(n=None):
    """Load runs from history, optionally limited to last N."""
    if not RUNS_FILE.exists():
        return []

    try:
        with open(RUNS_FILE, "r", encoding="utf-8") as f:
            lines = f.readlines()

        if n:
            lines = lines[-n:]

        runs = []
        for line in lines:
            line = line.strip()
            if line:
                try:
                    runs.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
        return runs
    except OSError:
        return []


def gc_history():
    """Trim history to last MAX_RUNS_GC entries."""
    if not RUNS_FILE.exists():
        print("No history file to clean.")
        return

    try:
        with open(RUNS_FILE, "r", encoding="utf-8") as f:
            lines = f.readlines()

        original_count = len(lines)
        if original_count <= MAX_RUNS_GC:
            print(f"History has {original_count} entries (under {MAX_RUNS_GC} limit). No cleanup needed.")
            return

        trimmed = lines[-MAX_RUNS_GC:]
        with open(RUNS_FILE, "w", encoding="utf-8") as f:
            f.writelines(trimmed)

        print(f"Trimmed history from {original_count} to {len(trimmed)} entries.")
    except OSError as e:
        print(f"Error during GC: {e}", file=sys.stderr)


def detect_flaky_tests(runs):
    """Find tests that pass in some runs and fail in others."""
    test_history = defaultdict(list)
    for run in runs:
        for test in run.get("tests", []):
            key = (test.get("file", ""), test.get("name", ""))
            test_history[key].append(test.get("result", "unknown"))

    flaky = []
    for (file, name), results in test_history.items():
        if len(results) < 2:
            continue
        has_success = "success" in results
        has_failure = "failure" in results or "error" in results
        if has_success and has_failure:
            fail_count = sum(1 for r in results if r in ("failure", "error"))
            flaky.append({
                "file": file,
                "name": name,
                "total_runs": len(results),
                "fail_count": fail_count,
                "pass_rate": (len(results) - fail_count) / len(results) * 100,
            })

    return sorted(flaky, key=lambda x: x["pass_rate"])


def print_compact(runs):
    """Print a single-line summary."""
    if not runs:
        print("No test history.")
        return

    last = runs[-1]
    status = "PASS" if last.get("overall_success") else "FAIL"
    total = sum(r.get("total", 0) for r in runs)
    passed = sum(r.get("passed", 0) for r in runs)
    rate = (passed / total * 100) if total > 0 else 0
    print(f"[{status}] Last run: {last.get('passed', 0)}p/{last.get('failed', 0)}f/{last.get('skipped', 0)}s | Overall: {rate:.1f}% pass rate across {len(runs)} runs")


def print_dashboard(runs, args):
    """Print the full dashboard."""
    if not runs:
        print("No test history found.")
        print(f"  Expected: {RUNS_FILE}")
        print("  Run some tests to start tracking.")
        return

    total_tests = sum(r.get("total", 0) for r in runs)
    total_passed = sum(r.get("passed", 0) for r in runs)
    total_failed = sum(r.get("failed", 0) for r in runs)
    pass_rate = (total_passed / total_tests * 100) if total_tests > 0 else 0

    last_run = runs[-1]
    last_status = "PASS" if last_run.get("overall_success") else "FAIL"
    last_timestamp = last_run.get("timestamp", "unknown")

    print()
    print("=" * 58)
    print(f"  Test Health Dashboard (last {len(runs)} runs)")
    print("=" * 58)
    print()
    print(f"  Overall Pass Rate:  {pass_rate:.1f}% ({total_passed:,} / {total_tests:,})")
    print(f"  Runs Tracked:       {len(runs)}")
    print(f"  Last Run:           {last_timestamp[:19]}")
    last_summary = f"{last_run.get('passed', 0)} passed"
    if last_run.get("failed", 0):
        last_summary += f", {last_run['failed']} failed"
    if last_run.get("errors", 0):
        last_summary += f", {last_run['errors']} errors"
    if last_run.get("skipped", 0):
        last_summary += f", {last_run['skipped']} skipped"
    print(f"  Last Run Status:    {last_status} ({last_summary})")

    # Recent failures
    all_failures = []
    for run in runs:
        for test in run.get("tests", []):
            if test.get("result") in ("failure", "error"):
                all_failures.append({
                    "file": test.get("file", "unknown"),
                    "name": test.get("name", "unknown"),
                    "error": test.get("error", ""),
                    "run_id": run.get("id", ""),
                    "timestamp": run.get("timestamp", ""),
                })

    if all_failures or args["failures"]:
        print()
        print(f"  --- Recent Failures ({len(all_failures)}) ---")
        if all_failures:
            by_file = defaultdict(list)
            for f in all_failures:
                by_file[f["file"]].append(f)
            for file, failures in sorted(by_file.items()):
                print(f"  {file}")
                seen_names = set()
                for f in failures:
                    if f["name"] not in seen_names:
                        seen_names.add(f["name"])
                        print(f"    \"{f['name']}\"")
                        if f.get("error"):
                            print(f"    {f['error'][:100]}")
        else:
            print("  None - all tests passing!")

    # Flaky test detection
    flaky = detect_flaky_tests(runs)
    if flaky or args["flaky"]:
        print()
        print(f"  --- Flaky Tests ({len(flaky)}) ---")
        if flaky:
            for ft in flaky[:10]:
                print(f"  {ft['file']}")
                print(f"    \"{ft['name']}\"")
                print(f"    Failed {ft['fail_count']}/{ft['total_runs']} runs ({ft['pass_rate']:.0f}% pass rate)")
        else:
            print("  None detected - test suite is stable!")

    # Run history
    print()
    print("  --- Run History ---")
    for i, run in enumerate(reversed(runs[-15:])):
        idx = len(runs) - i
        status = "PASS" if run.get("overall_success") else "FAIL"
        ts = run.get("timestamp", "")[:16]
        total = run.get("total", 0)
        passed = run.get("passed", 0)
        failed = run.get("failed", 0)
        trigger = run.get("trigger", "manual")
        duration = run.get("duration_ms", 0) / 1000

        line = f"  #{idx:<4} {ts}  {status}  {passed}/{total}"
        if failed:
            line += f"  ({failed} failed)"
        line += f"  [{trigger}] {duration:.1f}s"
        print(line)

    print()
    print("=" * 58)
    print()


def main():
    args = parse_args(sys.argv[1:])

    if args["gc"]:
        gc_history()
        return 0

    runs = load_runs(args["last"])

    if args["json_output"]:
        data = {
            "total_runs": len(runs),
            "total_tests": sum(r.get("total", 0) for r in runs),
            "total_passed": sum(r.get("passed", 0) for r in runs),
            "total_failed": sum(r.get("failed", 0) for r in runs),
            "flaky_tests": detect_flaky_tests(runs),
            "last_run": runs[-1] if runs else None,
        }
        print(json.dumps(data, indent=2))
        return 0

    if args["compact"]:
        print_compact(runs)
        return 0

    print_dashboard(runs, args)
    return 0


if __name__ == "__main__":
    sys.exit(main())
