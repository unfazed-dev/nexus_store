#!/usr/bin/env python3
# review_by: 2026-09-14
"""
Re-run only previously failed tests from test history.

Reads the test-runs.jsonl history file, collects test files with failures,
and re-runs them in the correct package directory using the appropriate
test runner (dart test or flutter test).

Usage:
    python3 .claude/hooks/core/rerun-failures.py [OPTIONS]

Options:
    --last=N      Look at last N runs (default: 1)
    --dry-run     Show which tests would run without running them
    --by-name     Use --name filter for individual test re-run (more precise)
    --verbose     Show detailed failure info
    --json        Output structured JSON summary

I/O:
    Stdin:  none
    Stdout: test run output + JSON summary (--json flag) or plain progress
    Exit:   0 = all reruns pass or no failures found; 1 = failures remain or no history

Dependencies:
    dart CLI, flutter CLI
    .claude/test-history/test-runs.jsonl  (written by capture-test-results.py)
    capture-test-results.py  (dynamic import for result logging)
"""
import json
import os
import subprocess
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent.parent
PACKAGES_DIR = PROJECT_ROOT / "packages"
RUNS_FILE = PROJECT_ROOT / ".claude" / "test-history" / "test-runs.jsonl"
HISTORY_DIR = PROJECT_ROOT / ".claude" / "test-history"
REPORTS_DIR = HISTORY_DIR / "reports"


def is_flutter_package(package_dir):
    """Check if a package depends on Flutter."""
    pubspec = package_dir / "pubspec.yaml"
    if not pubspec.exists():
        return False
    try:
        content = pubspec.read_text()
        return "flutter:" in content and "sdk: flutter" in content
    except OSError:
        return False


def get_test_command(package_dir):
    """Return the appropriate test command for a package."""
    if is_flutter_package(package_dir):
        return ["flutter", "test"]
    return ["dart", "test"]


def detect_package_for_test(test_file):
    """Determine which package a test file belongs to.

    Returns (package_name, package_dir) or (None, None).
    """
    if test_file.startswith("packages/"):
        parts = test_file.split("/")
        if len(parts) >= 2:
            pkg_name = parts[1]
            pkg_dir = PACKAGES_DIR / pkg_name
            if pkg_dir.is_dir():
                return pkg_name, pkg_dir
    return None, None


def run_tests_in_package(package_dir, test_files, trigger="rerun"):
    """Run tests in a specific package with result capture."""
    timestamp = datetime.now().strftime("%Y-%m-%dT%H-%M-%S-%f")
    report_path = str(REPORTS_DIR / f"{timestamp}.jsonl")
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)

    cmd = get_test_command(package_dir)
    cmd.extend(["--file-reporter", f"json:{report_path}"])

    # Convert paths to be relative to the package directory
    for tf in test_files:
        rel = os.path.relpath(str(PROJECT_ROOT / tf), str(package_dir))
        cmd.append(rel)

    exit_code = subprocess.call(cmd, cwd=str(package_dir))

    if os.path.exists(report_path):
        try:
            import importlib.util
            spec = importlib.util.spec_from_file_location(
                "capture_test_results",
                str(SCRIPT_DIR / "capture-test-results.py"),
            )
            capture = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(capture)
            run_data = capture.parse_json_report(report_path)
            if run_data:
                run_data["command"] = " ".join(cmd)
                run_data["trigger"] = trigger
                run_data["package"] = package_dir.name
                with open(RUNS_FILE, "a", encoding="utf-8") as f:
                    f.write(json.dumps(run_data) + "\n")
                status = "PASS" if run_data.get("overall_success") else "FAIL"
                print(f"\n[{package_dir.name}] Test results: {status} "
                      f"({run_data['passed']}p/{run_data['failed']}f/{run_data['skipped']}s) "
                      f"in {run_data['duration_ms']/1000:.1f}s")
        except Exception:
            pass

    return exit_code


def parse_args(argv):
    """Parse command line arguments."""
    args = {
        "last": 1,
        "dry_run": False,
        "by_name": False,
        "verbose": False,
        "json_output": False,
    }
    for arg in argv:
        if arg.startswith("--last="):
            try:
                args["last"] = int(arg.split("=", 1)[1])
            except ValueError:
                pass
        elif arg == "--dry-run":
            args["dry_run"] = True
        elif arg == "--by-name":
            args["by_name"] = True
        elif arg in ("--verbose", "-v"):
            args["verbose"] = True
        elif arg == "--json":
            args["json_output"] = True
    return args


def load_recent_runs(n):
    """Load the last N runs from history."""
    if not RUNS_FILE.exists():
        return []

    try:
        with open(RUNS_FILE, "r", encoding="utf-8") as f:
            lines = f.readlines()

        runs = []
        for line in lines[-n:]:
            line = line.strip()
            if line:
                try:
                    runs.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
        return runs
    except OSError:
        return []


def main():
    args = parse_args(sys.argv[1:])

    if not RUNS_FILE.exists():
        print("No test history found. Run some tests first.")
        print(f"  Expected: {RUNS_FILE}")
        return 1

    runs = load_recent_runs(args["last"])
    if not runs:
        print("No test runs found in history.")
        return 1

    # Collect failures
    failed_files = set()
    failed_tests = []
    for run in runs:
        for test in run.get("tests", []):
            if test.get("result") in ("failure", "error"):
                failed_files.add(test.get("file", ""))
                failed_tests.append({
                    "file": test.get("file", "unknown"),
                    "name": test.get("name", "unknown"),
                    "result": test.get("result", "unknown"),
                    "error": test.get("error", ""),
                })

    # Remove invalid entries
    failed_files.discard("")
    failed_files.discard("unknown")

    if not failed_files and not failed_tests:
        if args["json_output"]:
            print(json.dumps({
                "status": "pass",
                "recommendation": f"No failures in last {args['last']} run(s)",
                "action_needed": False,
            }, indent=2))
        else:
            print(f"No failures found in the last {args['last']} run(s). All clear!")
        return 0

    # Filter to existing files
    existing_files = [
        f for f in failed_files
        if (PROJECT_ROOT / f).exists()
    ]

    print(f"Found {len(failed_tests)} failed test(s) across {len(existing_files)} file(s)")
    print(f"From last {args['last']} run(s)")
    print()

    if args["verbose"]:
        for ft in failed_tests:
            status = "FAIL" if ft["result"] == "failure" else "ERROR"
            print(f"  [{status}] {ft['name']}")
            print(f"         in {ft['file']}")
            if ft.get("error"):
                print(f"         {ft['error'][:120]}")
            print()

    if not existing_files:
        print("No test files found on disk (may have been moved/deleted).")
        return 1

    # Group failed files by package
    package_files = defaultdict(list)
    for f in sorted(existing_files):
        pkg_name, pkg_dir = detect_package_for_test(f)
        if pkg_name:
            package_files[pkg_name].append(f)
        else:
            # Fallback: try to run from project root
            package_files["_root"].append(f)

    overall_exit = 0

    for pkg_name in sorted(package_files.keys()):
        files = package_files[pkg_name]

        if pkg_name == "_root":
            print(f"Re-running {len(files)} test file(s) from project root:")
            for f in files:
                print(f"  {f}")
            if args["dry_run"]:
                print("  DRY RUN")
                continue
            # Fallback: run with dart test from project root
            cmd = ["dart", "test"] + files
            exit_code = subprocess.call(cmd, cwd=str(PROJECT_ROOT))
        else:
            pkg_dir = PACKAGES_DIR / pkg_name
            print(f"Re-running {len(files)} test file(s) in {pkg_name}:")
            for f in files:
                count = sum(1 for t in failed_tests if t.get("file") == f)
                print(f"  {f} ({count} failure(s))")

            if args["dry_run"]:
                cmd = get_test_command(pkg_dir)
                print(f"  DRY RUN: {' '.join(cmd)} ...")
                continue

            exit_code = run_tests_in_package(pkg_dir, files, trigger="rerun")

        if exit_code != 0:
            overall_exit = 1

    return overall_exit


if __name__ == "__main__":
    sys.exit(main())
