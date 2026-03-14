#!/usr/bin/env python3
# review_by: 2026-09-10
"""
Smart test runner for Melos monorepo.

Analyzes git diff to determine which packages changed, then runs tests only
in affected packages using the appropriate test runner (dart test or flutter test).

Includes content-hash caching scoped per-package: tests whose source dependencies
haven't changed since the last PASS are automatically skipped.

Usage:
    python3 .claude/hooks/core/smart-test-run.py [OPTIONS]

Options:
    --against=<ref>   Compare against branch/commit (default: HEAD)
    --staged          Only consider staged changes
    --all             Run all tests (bypass smart detection)
    --dry-run         Show which tests would run without running them
    --verbose         Show mapping details
    --no-cache        Disable hash-based test caching (run all affected tests)
    --purge-cache     Purge the test cache before running
    --json            Output structured JSON summary

I/O:
    Stdin:  none (reads git diff and filesystem via subprocess)
    Stdout: run progress, test output, optional JSON summary (--json)
    Exit:   0 = all affected tests pass (or nothing to run); 1 = test failures

Dependencies:
    git CLI, dart CLI, flutter CLI
    test-cache.py      (dynamic import for hash-based skip logic)
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
HISTORY_DIR = PROJECT_ROOT / ".claude" / "test-history"
REPORTS_DIR = HISTORY_DIR / "reports"
RUNS_FILE = HISTORY_DIR / "test-runs.jsonl"


def is_flutter_package(package_dir):
    """Check if a package depends on Flutter (has flutter SDK dependency)."""
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


def run_tests_in_package(package_dir, test_files=None, trigger="smart"):
    """Run tests in a specific package directory with result capture."""
    timestamp = datetime.now().strftime("%Y-%m-%dT%H-%M-%S-%f")
    report_path = str(REPORTS_DIR / f"{timestamp}.jsonl")
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)

    cmd = get_test_command(package_dir)
    cmd.extend(["--file-reporter", f"json:{report_path}"])

    if test_files:
        # Convert to paths relative to package dir
        for tf in test_files:
            rel = os.path.relpath(str(PROJECT_ROOT / tf), str(package_dir))
            cmd.append(rel)

    exit_code = subprocess.call(cmd, cwd=str(package_dir))

    # Capture results from report file
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
        "against": "HEAD",
        "staged": False,
        "all": False,
        "dry_run": False,
        "verbose": False,
        "no_cache": False,
        "purge_cache": False,
        "json_output": False,
        "extra_paths": [],
    }
    for arg in argv:
        if arg.startswith("--against="):
            args["against"] = arg.split("=", 1)[1]
        elif arg == "--staged":
            args["staged"] = True
        elif arg == "--all":
            args["all"] = True
        elif arg == "--dry-run":
            args["dry_run"] = True
        elif arg in ("--verbose", "-v"):
            args["verbose"] = True
        elif arg == "--no-cache":
            args["no_cache"] = True
        elif arg == "--purge-cache":
            args["purge_cache"] = True
        elif arg == "--json":
            args["json_output"] = True
        elif not arg.startswith("--"):
            args["extra_paths"].append(arg)
    return args


def get_changed_files(against="HEAD", staged_only=False):
    """Get list of changed files from git."""
    changed = set()

    try:
        if against != "HEAD":
            result = subprocess.run(
                ["git", "diff", "--name-only", "--diff-filter=ACMR", against],
                capture_output=True, text=True, cwd=str(PROJECT_ROOT)
            )
            if result.returncode == 0:
                changed.update(f for f in result.stdout.strip().split("\n") if f)
            return {
                f for f in changed
                if f.endswith(".dart") or f.endswith("pubspec.yaml") or f.endswith("pubspec.lock")
            }

        if staged_only:
            result = subprocess.run(
                ["git", "diff", "--cached", "--name-only", "--diff-filter=ACMR"],
                capture_output=True, text=True, cwd=str(PROJECT_ROOT)
            )
            if result.returncode == 0:
                changed.update(f for f in result.stdout.strip().split("\n") if f)
        else:
            # Unstaged changes
            result = subprocess.run(
                ["git", "diff", "--name-only", "--diff-filter=ACMR"],
                capture_output=True, text=True, cwd=str(PROJECT_ROOT)
            )
            if result.returncode == 0:
                changed.update(f for f in result.stdout.strip().split("\n") if f)

            # Staged changes
            result = subprocess.run(
                ["git", "diff", "--cached", "--name-only", "--diff-filter=ACMR"],
                capture_output=True, text=True, cwd=str(PROJECT_ROOT)
            )
            if result.returncode == 0:
                changed.update(f for f in result.stdout.strip().split("\n") if f)

            # Untracked files
            result = subprocess.run(
                ["git", "ls-files", "--others", "--exclude-standard"],
                capture_output=True, text=True, cwd=str(PROJECT_ROOT)
            )
            if result.returncode == 0:
                changed.update(f for f in result.stdout.strip().split("\n") if f)

    except (OSError, subprocess.SubprocessError):
        pass

    return {
        f for f in changed
        if f.endswith(".dart") or f.endswith("pubspec.yaml") or f.endswith("pubspec.lock")
    }


def map_files_to_packages(changed_files):
    """Map changed files to their package directories.

    Returns {package_name: [changed_files]} for files under packages/.
    """
    package_files = defaultdict(list)

    for f in changed_files:
        if f.startswith("packages/"):
            parts = f.split("/")
            if len(parts) >= 2:
                package_name = parts[1]
                package_dir = PACKAGES_DIR / package_name
                if package_dir.is_dir():
                    package_files[package_name].append(f)

    return dict(package_files)


def find_test_files_for_package(package_name, changed_files, verbose=False):
    """Find test files to run for a package based on its changed files.

    Strategy:
    - If a test file changed, include it directly
    - If a lib/ file changed, find test files that might test it (convention-based)
    - If pubspec.yaml changed, run all tests in the package
    """
    package_dir = PACKAGES_DIR / package_name
    test_dir = package_dir / "test"

    if not test_dir.exists():
        if verbose:
            print(f"  [{package_name}] No test/ directory, skipping")
        return []

    run_all = False
    test_files = set()

    for f in changed_files:
        rel_to_pkg = f[len(f"packages/{package_name}/"):]

        # pubspec changed -> run all tests
        if rel_to_pkg in ("pubspec.yaml", "pubspec.lock"):
            run_all = True
            if verbose:
                print(f"  [{package_name}] pubspec changed -> run all tests")
            break

        # Test file changed -> include it
        if rel_to_pkg.startswith("test/") and rel_to_pkg.endswith("_test.dart"):
            test_files.add(f)
            if verbose:
                print(f"  [{package_name}] TEST: {rel_to_pkg}")
            continue

        # lib/ file changed -> find corresponding test
        if rel_to_pkg.startswith("lib/"):
            # Convention: lib/src/foo.dart -> test/src/foo_test.dart
            lib_path = rel_to_pkg[4:]  # strip 'lib/'
            if lib_path.endswith(".dart"):
                test_path = "test/" + lib_path[:-5] + "_test.dart"
                full_test = f"packages/{package_name}/{test_path}"
                if (PROJECT_ROOT / full_test).exists():
                    test_files.add(full_test)
                    if verbose:
                        print(f"  [{package_name}] MAP: {rel_to_pkg} -> {test_path}")
                else:
                    # No direct mapping; mark for full run
                    run_all = True
                    if verbose:
                        print(f"  [{package_name}] No test mapping for {rel_to_pkg} -> run all")
                    break

    if run_all:
        # Collect all test files in the package
        all_tests = []
        for tf in test_dir.rglob("*_test.dart"):
            rel = str(tf.relative_to(PROJECT_ROOT))
            all_tests.append(rel)
        return sorted(all_tests)

    return sorted(test_files)


def load_test_cache_module():
    """Dynamically load the test-cache module."""
    try:
        import importlib.util
        spec = importlib.util.spec_from_file_location(
            "test_cache",
            str(SCRIPT_DIR / "test-cache.py"),
        )
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        return mod
    except Exception:
        return None


def check_tdd_coverage(changed_files, verbose=False):
    """Warn when recently-created source files have no corresponding test file.

    Checks changed lib/ .dart files for a matching test/ *_test.dart file.
    Returns list of warnings (source files missing tests).
    """
    warnings = []
    skip_patterns = (
        ".g.dart",
        ".freezed.dart",
        ".config.dart",
    )
    skip_basenames = {
        # Barrel files, generated registrations
        "nexus_store.dart",
    }

    for f in sorted(changed_files):
        if not f.startswith("packages/"):
            continue
        parts = f.split("/")
        if len(parts) < 3:
            continue

        package_name = parts[1]
        rel_to_pkg = "/".join(parts[2:])

        # Only check lib/ source files
        if not rel_to_pkg.startswith("lib/") or not rel_to_pkg.endswith(".dart"):
            continue

        # Skip generated files, barrel files
        basename = os.path.basename(f)
        if any(f.endswith(pat) for pat in skip_patterns):
            continue
        if basename in skip_basenames:
            continue

        # Check for corresponding test file
        lib_path = rel_to_pkg[4:]  # strip 'lib/'
        test_path = f"packages/{package_name}/test/{lib_path[:-5]}_test.dart"
        if not (PROJECT_ROOT / test_path).exists():
            warnings.append((package_name, rel_to_pkg, test_path))

    if warnings:
        print(f"\n⚠ TDD coverage warning: {len(warnings)} source file(s) have no corresponding test file:")
        for pkg, src, expected_test in warnings:
            print(f"  [{pkg}] {src}")
            if verbose:
                print(f"           expected: {expected_test}")
        print("  Hint: write tests BEFORE implementation (RED → GREEN → REFACTOR)")
        print()

    return warnings


def main():
    args = parse_args(sys.argv[1:])

    # Purge cache if requested
    if args["purge_cache"]:
        cache_mod = load_test_cache_module()
        if cache_mod:
            cache_mod.save_cache({})
            print("Test cache purged.")

    # Bypass mode: run all tests in all packages
    if args["all"]:
        print("Running full test suite across all packages (--all flag)...")
        if args["dry_run"]:
            print("  DRY RUN: would run tests in all packages")
            return 0

        overall_exit = 0
        for pkg_dir in sorted(PACKAGES_DIR.iterdir()):
            if not pkg_dir.is_dir() or not (pkg_dir / "test").is_dir():
                continue
            print(f"\n--- {pkg_dir.name} ---")
            exit_code = run_tests_in_package(pkg_dir, trigger="full")
            if exit_code != 0:
                overall_exit = 1
        return overall_exit

    # Get changed files
    changed_files = get_changed_files(
        against=args["against"],
        staged_only=args["staged"],
    )

    # Add any extra paths
    for extra in args["extra_paths"]:
        full_path = PROJECT_ROOT / extra
        if full_path.is_dir():
            for tf in full_path.rglob("*_test.dart"):
                rel = str(tf.relative_to(PROJECT_ROOT))
                changed_files.add(rel)
        elif full_path.exists():
            changed_files.add(extra)

    if not changed_files:
        print("No changed files detected. Nothing to test.")
        return 0

    # TDD coverage diagnostic
    check_tdd_coverage(changed_files, verbose=args["verbose"])

    if args["verbose"]:
        print(f"Changed files ({len(changed_files)}):")
        for f in sorted(changed_files):
            print(f"  {f}")
        print()

    # Map files to packages
    package_map = map_files_to_packages(changed_files)

    if not package_map:
        print(f"Changed {len(changed_files)} files but none map to packages/. Nothing to test.")
        return 0

    # Resolve test files per package
    package_tests = {}
    for pkg_name, pkg_files in package_map.items():
        if args["verbose"]:
            print(f"Resolving tests for {pkg_name}:")
        tests = find_test_files_for_package(pkg_name, pkg_files, verbose=args["verbose"])
        if tests:
            package_tests[pkg_name] = tests

    if not package_tests:
        print(f"Changed files in {len(package_map)} package(s) but no tests found.")
        return 0

    # Cache filter
    cache_mod = None
    if not args["no_cache"]:
        cache_mod = load_test_cache_module()

    # Run tests per package
    total_tests = sum(len(t) for t in package_tests.values())
    print(f"\nRunning tests in {len(package_tests)} package(s) ({total_tests} test files):")

    overall_exit = 0
    all_ran_tests = []

    for pkg_name in sorted(package_tests.keys()):
        tests = package_tests[pkg_name]
        pkg_dir = PACKAGES_DIR / pkg_name

        # Apply cache filter (scoped per package)
        tests_to_run = tests
        if cache_mod:
            tests_to_run = cache_mod.filter_tests(tests, verbose=args["verbose"])
            skipped = len(tests) - len(tests_to_run)
            if skipped > 0:
                print(f"  [{pkg_name}] Cache: skipping {skipped} already-passed test(s)")

        if not tests_to_run:
            print(f"  [{pkg_name}] All {len(tests)} tests cached as passed. Skipping.")
            continue

        print(f"\n--- {pkg_name} ({len(tests_to_run)} test files) ---")
        for t in tests_to_run:
            print(f"  {t}")

        if args["dry_run"]:
            cmd = get_test_command(pkg_dir)
            print(f"  DRY RUN: {' '.join(cmd)} ...")
            continue

        exit_code = run_tests_in_package(pkg_dir, test_files=tests_to_run, trigger="smart")

        # Cache update
        if exit_code == 0 and cache_mod:
            cache_mod.update_cache(tests_to_run, result="pass")
        elif exit_code != 0 and cache_mod:
            cache_mod.invalidate_tests(tests_to_run)
            overall_exit = 1

        all_ran_tests.extend(tests_to_run)

    if args["json_output"]:
        summary = {
            "status": "pass" if overall_exit == 0 else "fail",
            "packages_tested": len(package_tests),
            "tests_run": len(all_ran_tests),
            "changed_files": len(changed_files),
            "action_needed": overall_exit != 0,
            "recommendation": (
                f"All tests pass across {len(package_tests)} package(s)"
                if overall_exit == 0
                else "Tests failed. Run: python3 .claude/hooks/core/rerun-failures.py"
            ),
        }
        print(json.dumps(summary, indent=2))

    return overall_exit


if __name__ == "__main__":
    sys.exit(main())
