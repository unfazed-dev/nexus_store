#!/usr/bin/env python3
# review_by: 2026-09-15
"""
Coverage enforcement script — portable across monorepo and single-app projects.

Auto-detects mode from project structure:
- Monorepo (melos.yaml present): per-package coverage via `dart test --coverage`
- Single app (no melos.yaml): `flutter test --coverage`, parses coverage/lcov.info

Parses LCOV natively in Python — no `lcov` CLI dependency.
Filters out .g.dart and .freezed.dart generated files.

Usage:
    python3 .claude/hooks/core/check-coverage.py [OPTIONS]

Options:
    --changed             Only check packages with changed files (monorepo mode)
    --packages=p1,p2      Check specific packages (monorepo mode)
    --app                 Single-app mode (flutter test --coverage)
    --threshold=N         Coverage threshold percentage (default: 95)
    --exclude=pattern     Exclude packages matching pattern (repeatable)
    --json                Output structured JSON
    --dry-run             Show what would be checked without running tests
    --delta[=COMMIT]      Compute delta coverage for lines introduced by COMMIT
                          (omit hash for pre-commit mode using git diff HEAD)

I/O:
    Stdout: Progress, results, optional JSON summary (--json)
    Exit:   0 = all meet threshold, 1 = at least one below
"""
from __future__ import annotations

import dataclasses
import json
import os
import re
import subprocess
import sys
from pathlib import Path


@dataclasses.dataclass
class _CoverageResult:
    lcov_path: Path | None
    tests_failed: bool = False
    failed_tests: list[str] = dataclasses.field(default_factory=list)


# Regex to strip ANSI escape codes from test output
_ANSI_RE = re.compile(r'\x1b\[[0-9;]*m')

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent.parent

# Generated file patterns to exclude from coverage
GENERATED_FILE_PATTERNS = (
    ".g.dart",
    ".freezed.dart",
    ".gr.dart",
    ".config.dart",
    ".mocks.dart",
)

DEFAULT_THRESHOLD = 95


def parse_args(argv: list[str]) -> dict:
    """Parse command line arguments."""
    args = {
        "changed": False,
        "packages": [],
        "app": False,
        "threshold": DEFAULT_THRESHOLD,
        "exclude": [],
        "json_output": False,
        "dry_run": False,
        "delta": None,  # None = off, "" = pre-commit mode, "hash" = specific commit
    }
    for arg in argv:
        if arg == "--changed":
            args["changed"] = True
        elif arg.startswith("--packages="):
            args["packages"] = arg.split("=", 1)[1].split(",")
        elif arg == "--app":
            args["app"] = True
        elif arg.startswith("--threshold="):
            try:
                args["threshold"] = float(arg.split("=", 1)[1])
            except ValueError:
                pass
        elif arg.startswith("--exclude="):
            args["exclude"].append(arg.split("=", 1)[1])
        elif arg == "--json":
            args["json_output"] = True
        elif arg == "--dry-run":
            args["dry_run"] = True
        elif arg == "--delta":
            args["delta"] = ""  # pre-commit mode
        elif arg.startswith("--delta="):
            args["delta"] = arg.split("=", 1)[1]
    return args


def detect_mode() -> str:
    """Auto-detect monorepo vs single-app mode."""
    if (PROJECT_ROOT / "melos.yaml").exists():
        return "monorepo"
    return "app"


def get_changed_packages() -> list[str]:
    """Get list of packages with changed files (monorepo mode)."""
    packages_dir = PROJECT_ROOT / "packages"
    if not packages_dir.is_dir():
        return []

    changed = set()
    try:
        # Unstaged changes
        result = subprocess.run(
            ["git", "diff", "--name-only", "--diff-filter=ACMR"],
            capture_output=True, text=True, cwd=str(PROJECT_ROOT),
        )
        if result.returncode == 0:
            for f in result.stdout.strip().split("\n"):
                if f and f.startswith("packages/"):
                    parts = f.split("/")
                    if len(parts) >= 2:
                        changed.add(parts[1])

        # Staged changes
        result = subprocess.run(
            ["git", "diff", "--cached", "--name-only", "--diff-filter=ACMR"],
            capture_output=True, text=True, cwd=str(PROJECT_ROOT),
        )
        if result.returncode == 0:
            for f in result.stdout.strip().split("\n"):
                if f and f.startswith("packages/"):
                    parts = f.split("/")
                    if len(parts) >= 2:
                        changed.add(parts[1])

        # Untracked files
        result = subprocess.run(
            ["git", "ls-files", "--others", "--exclude-standard"],
            capture_output=True, text=True, cwd=str(PROJECT_ROOT),
        )
        if result.returncode == 0:
            for f in result.stdout.strip().split("\n"):
                if f and f.startswith("packages/"):
                    parts = f.split("/")
                    if len(parts) >= 2:
                        changed.add(parts[1])

    except (OSError, subprocess.SubprocessError):
        pass

    # Filter to packages that actually exist and have test directories
    valid = []
    for pkg in sorted(changed):
        pkg_dir = packages_dir / pkg
        if pkg_dir.is_dir() and (pkg_dir / "test").is_dir():
            valid.append(pkg)
    return valid


def is_flutter_package(package_dir: Path) -> bool:
    """Check if a package depends on Flutter."""
    pubspec = package_dir / "pubspec.yaml"
    if not pubspec.exists():
        return False
    try:
        content = pubspec.read_text()
        return "flutter:" in content and "sdk: flutter" in content
    except OSError:
        return False


def _try_format_coverage(coverage_dir: Path, package_dir: Path) -> Path | None:
    """Try to format coverage JSON files into lcov.info. Returns path or None."""
    lcov_path = coverage_dir / "lcov.info"
    if lcov_path.exists():
        return lcov_path

    if not coverage_dir.is_dir():
        return None

    fmt_cmd = [
        "dart", "run", "coverage:format_coverage",
        "--lcov",
        f"--in={coverage_dir}",
        f"--out={lcov_path}",
        f"--report-on=lib/",
    ]
    fmt_result = subprocess.run(
        fmt_cmd, cwd=str(package_dir),
        capture_output=True, text=True,
    )
    if fmt_result.returncode != 0:
        print(f"  Warning: Could not format coverage for {package_dir.name}")
        return None

    return lcov_path if lcov_path.exists() else None


def run_coverage_for_package(package_dir: Path) -> _CoverageResult:
    """Run tests with coverage for a package. Returns _CoverageResult."""
    coverage_dir = package_dir / "coverage"

    if is_flutter_package(package_dir):
        cmd = ["flutter", "test", "--coverage"]
    else:
        cmd = ["dart", "test", "--coverage=coverage"]

    print(f"  Running: {' '.join(cmd)} in {package_dir.name}/")
    result = subprocess.run(cmd, cwd=str(package_dir), capture_output=True, text=True)

    if result.returncode != 0:
        print(f"  Tests failed in {package_dir.name}")
        if result.stderr:
            lines = result.stderr.strip().split("\n")
            for line in lines[-5:]:
                print(f"    {line}")

        # Surface failing test names from stdout
        failed_test_names: list[str] = []
        if result.stdout:
            clean = _ANSI_RE.sub('', result.stdout)
            failed = [l.strip() for l in clean.split('\n') if '[E]' in l]
            if failed:
                print(f"  Failed tests ({len(failed)}):")
                for name in failed[:10]:
                    print(f"    {name}")
                if len(failed) > 10:
                    print(f"    ... and {len(failed) - 10} more")
                failed_test_names = failed

        # Still try to collect partial coverage data
        lcov_path = _try_format_coverage(coverage_dir, package_dir)
        return _CoverageResult(
            lcov_path=lcov_path,
            tests_failed=True,
            failed_tests=failed_test_names,
        )

    lcov_path = _try_format_coverage(coverage_dir, package_dir)
    return _CoverageResult(lcov_path=lcov_path)


def run_coverage_for_app() -> Path | None:
    """Run flutter test --coverage for a single-app project."""
    cmd = ["flutter", "test", "--coverage"]
    print(f"  Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, cwd=str(PROJECT_ROOT), capture_output=True, text=True)

    if result.returncode != 0:
        print("  Tests failed")
        if result.stderr:
            lines = result.stderr.strip().split("\n")
            for line in lines[-5:]:
                print(f"    {line}")
        return None

    lcov_path = PROJECT_ROOT / "coverage" / "lcov.info"
    if lcov_path.exists():
        return lcov_path
    return None


def parse_lcov(lcov_path: Path) -> dict:
    """Parse LCOV file natively. Returns {file: {hit, total}} per source file.

    LCOV format:
        SF:<source file path>
        DA:<line_number>,<execution_count>
        end_of_record
    """
    files = {}
    current_file = None
    lines_hit = 0
    lines_total = 0

    try:
        with open(lcov_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line.startswith("SF:"):
                    current_file = line[3:]
                    lines_hit = 0
                    lines_total = 0
                elif line.startswith("DA:"):
                    parts = line[3:].split(",")
                    if len(parts) >= 2:
                        lines_total += 1
                        try:
                            if int(parts[1]) > 0:
                                lines_hit += 1
                        except ValueError:
                            pass
                elif line == "end_of_record":
                    if current_file is not None:
                        files[current_file] = {
                            "hit": lines_hit,
                            "total": lines_total,
                        }
                    current_file = None
    except (OSError, UnicodeDecodeError) as e:
        print(f"  Warning: could not parse lcov file {lcov_path}: {e}")

    return files


def filter_generated_files(file_coverage: dict) -> dict:
    """Remove generated files from coverage data."""
    filtered = {}
    for filepath, data in file_coverage.items():
        if any(filepath.endswith(pat) for pat in GENERATED_FILE_PATTERNS):
            continue
        filtered[filepath] = data

    excluded = len(file_coverage) - len(filtered)
    if excluded > 0:
        raw_hit = sum(d["hit"] for d in file_coverage.values())
        raw_total = sum(d["total"] for d in file_coverage.values())
        raw_pct = round((raw_hit / raw_total) * 100, 2) if raw_total else 100.0
        print(f"  Filtered {excluded} generated file(s) "
              f"(raw: {raw_pct}%, filtered will be higher)")

    return filtered


def compute_coverage(file_coverage: dict) -> tuple[int, int, float]:
    """Compute aggregate coverage from file-level data.

    Returns (lines_hit, lines_total, coverage_pct).
    """
    total_hit = sum(d["hit"] for d in file_coverage.values())
    total_lines = sum(d["total"] for d in file_coverage.values())
    if total_lines == 0:
        return 0, 0, 100.0  # No instrumentable lines = 100% coverage
    pct = (total_hit / total_lines) * 100
    return total_hit, total_lines, round(pct, 2)


def parse_lcov_line_level(lcov_path: Path) -> dict[str, dict[int, bool]]:
    """Parse LCOV file returning per-line coverage data.

    Returns {filepath: {line_num: is_covered}} where is_covered = count > 0.
    """
    files: dict[str, dict[int, bool]] = {}
    current_file = None
    current_lines: dict[int, bool] = {}

    try:
        with open(lcov_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line.startswith("SF:"):
                    current_file = line[3:]
                    current_lines = {}
                elif line.startswith("DA:"):
                    parts = line[3:].split(",")
                    if len(parts) >= 2:
                        try:
                            line_num = int(parts[0])
                            count = int(parts[1])
                            current_lines[line_num] = count > 0
                        except ValueError:
                            pass
                elif line == "end_of_record":
                    if current_file is not None:
                        files[current_file] = current_lines
                    current_file = None
                    current_lines = {}
    except (OSError, UnicodeDecodeError) as e:
        print(f"  Warning: could not parse lcov file {lcov_path}: {e}")

    return files


def get_lines_for_commit(commit_hash: str, package_dir: Path) -> dict[str, set[int]]:
    """Get current line numbers introduced by a specific commit using git blame.

    Returns {abs_filepath: {current_line_numbers}} for lib/ files only,
    excluding generated files.
    Falls back to git diff hunk parsing when commit_hash is empty (pre-commit).
    """
    changed_lines: dict[str, set[int]] = {}
    lib_dir = package_dir / "lib"

    if not lib_dir.is_dir():
        return changed_lines

    if not commit_hash:
        # Pre-commit mode: use git diff HEAD
        return _get_lines_from_diff(package_dir)

    # Walk all .dart files in lib/
    for dart_file in lib_dir.rglob("*.dart"):
        # Skip generated files
        if any(str(dart_file).endswith(pat) for pat in GENERATED_FILE_PATTERNS):
            continue

        try:
            result = subprocess.run(
                ["git", "blame", "--porcelain", str(dart_file)],
                capture_output=True, text=True, cwd=str(PROJECT_ROOT),
            )
            if result.returncode != 0:
                continue

            lines_for_file: set[int] = set()
            for blame_line in result.stdout.split("\n"):
                # Lines starting with a commit hash (40 hex chars) followed by line info
                if len(blame_line) >= 40 and blame_line[0] in "0123456789abcdef":
                    parts = blame_line.split()
                    if len(parts) >= 3:
                        blame_commit = parts[0]
                        # parts[2] is the final (current) line number
                        try:
                            final_line = int(parts[2])
                        except (ValueError, IndexError):
                            continue
                        if blame_commit.startswith(commit_hash[:8]):
                            lines_for_file.add(final_line)

            if lines_for_file:
                changed_lines[str(dart_file.resolve())] = lines_for_file

        except (OSError, subprocess.SubprocessError):
            continue

    return changed_lines


_HUNK_RE = re.compile(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@')


def _get_lines_from_diff(package_dir: Path) -> dict[str, set[int]]:
    """Fallback: parse git diff HEAD hunk headers for pre-commit delta coverage."""
    changed_lines: dict[str, set[int]] = {}
    rel_lib = str(package_dir.relative_to(PROJECT_ROOT) / "lib")

    try:
        result = subprocess.run(
            ["git", "diff", "-U0", "HEAD", "--", f"{rel_lib}/"],
            capture_output=True, text=True, cwd=str(PROJECT_ROOT),
        )
        if result.returncode != 0:
            return changed_lines

        current_file = None
        for line in result.stdout.split("\n"):
            if line.startswith("+++ b/"):
                filepath = line[6:]
                abs_path = str((PROJECT_ROOT / filepath).resolve())
                # Skip generated files
                if any(abs_path.endswith(pat) for pat in GENERATED_FILE_PATTERNS):
                    current_file = None
                else:
                    current_file = abs_path
            elif line.startswith("@@") and current_file:
                m = _HUNK_RE.match(line)
                if m:
                    start = int(m.group(1))
                    count = int(m.group(2)) if m.group(2) else 1
                    if current_file not in changed_lines:
                        changed_lines[current_file] = set()
                    for ln in range(start, start + count):
                        changed_lines[current_file].add(ln)

    except (OSError, subprocess.SubprocessError):
        pass

    return changed_lines


def compute_delta_coverage(
    changed_lines: dict[str, set[int]],
    lcov_line_data: dict[str, dict[int, bool]],
    package_dir: Path,
) -> dict:
    """Cross-reference changed lines against LCOV line-level data.

    Lines in diff but NOT in LCOV = non-executable (excluded from denominator).
    Lines in diff AND in LCOV with count=0 = uncovered.
    Lines in diff AND in LCOV with count>0 = covered.

    Returns {"delta_coverage_pct": float|None, "delta_lines_hit": int,
             "delta_lines_total": int, "delta_files": list[dict]}.
    """
    if not changed_lines:
        return {
            "delta_coverage_pct": None,
            "delta_lines_hit": 0,
            "delta_lines_total": 0,
            "delta_files": [],
        }

    delta_hit = 0
    delta_total = 0
    per_file: dict[str, dict] = {}  # abs_path -> {hit, total}

    for filepath, line_nums in changed_lines.items():
        # Map blame abs path to LCOV SF path — try direct match and relative variants
        lcov_data = lcov_line_data.get(filepath)
        if lcov_data is None:
            # Try relative path from project root as LCOV key
            try:
                rel_path = str(Path(filepath).relative_to(PROJECT_ROOT))
                for sf_key, sf_data in lcov_line_data.items():
                    if sf_key.endswith(rel_path) or sf_key == filepath:
                        lcov_data = sf_data
                        break
            except ValueError:
                pass

        if lcov_data is None:
            # File not in LCOV at all — skip (no executable lines)
            continue

        file_hit = 0
        file_total = 0
        for ln in line_nums:
            if ln in lcov_data:
                file_total += 1
                delta_total += 1
                if lcov_data[ln]:
                    file_hit += 1
                    delta_hit += 1
            # else: line not in LCOV = non-executable, skip

        if file_total > 0:
            # Store with relative path from package dir
            try:
                rel_path = str(Path(filepath).relative_to(package_dir))
            except ValueError:
                rel_path = filepath
            per_file[rel_path] = {"hit": file_hit, "total": file_total}

    if delta_total == 0:
        return {
            "delta_coverage_pct": None,
            "delta_lines_hit": 0,
            "delta_lines_total": 0,
            "delta_files": [],
        }

    pct = round((delta_hit / delta_total) * 100, 1)

    # Build delta_files list sorted by pct ascending (worst first)
    delta_files = []
    for path, data in per_file.items():
        file_pct = round((data["hit"] / data["total"]) * 100, 1) if data["total"] > 0 else 100.0
        delta_files.append({
            "path": path,
            "hit": data["hit"],
            "total": data["total"],
            "pct": file_pct,
        })
    delta_files.sort(key=lambda f: f["pct"])

    return {
        "delta_coverage_pct": pct,
        "delta_lines_hit": delta_hit,
        "delta_lines_total": delta_total,
        "delta_files": delta_files,
    }


def check_package(
    package_name: str,
    threshold: float,
    dry_run: bool = False,
    delta: str | None = None,
) -> dict:
    """Check coverage for a single package. Returns result dict.

    Args:
        delta: None = no delta, "" = pre-commit mode, "hash" = specific commit.
    """
    packages_dir = PROJECT_ROOT / "packages"
    package_dir = packages_dir / package_name

    if not (package_dir / "test").is_dir():
        return {
            "name": package_name,
            "coverage_pct": None,
            "threshold": threshold,
            "passed": True,  # Exempt — no tests
            "exempt": True,
            "reason": "no test/ directory",
        }

    if dry_run:
        return {
            "name": package_name,
            "coverage_pct": None,
            "threshold": threshold,
            "passed": True,
            "dry_run": True,
        }

    result = run_coverage_for_package(package_dir)

    # Try to parse coverage data regardless of test success
    if result.lcov_path is not None:
        file_coverage = parse_lcov(result.lcov_path)
        file_coverage = filter_generated_files(file_coverage)
        lines_hit, lines_total, pct = compute_coverage(file_coverage)
    else:
        lines_hit, lines_total, pct = 0, 0, 0.0

    output = {
        "name": package_name,
        "coverage_pct": pct,
        "lines_hit": lines_hit,
        "lines_total": lines_total,
        "threshold": threshold,
    }

    if result.tests_failed:
        output["passed"] = False
        output["tests_failed"] = True
        output["failed_tests"] = result.failed_tests[:10]
        if pct > 0:
            output["partial_coverage_pct"] = pct
            output["reason"] = f"tests failed (partial coverage: {pct}%)"
        else:
            output["reason"] = "tests failed and no coverage data collected"
    elif lines_total == 0 and result.lcov_path is None:
        output["passed"] = False
        output["reason"] = "no coverage data"
    else:
        output["passed"] = pct >= threshold

    # Delta coverage (informational — does not affect pass/fail gate)
    if delta is not None and result.lcov_path is not None:
        lcov_line_data = parse_lcov_line_level(result.lcov_path)
        # Filter generated files from line-level data
        lcov_line_data = {
            fp: lines for fp, lines in lcov_line_data.items()
            if not any(fp.endswith(pat) for pat in GENERATED_FILE_PATTERNS)
        }
        changed_lines = get_lines_for_commit(delta, package_dir)
        delta_result = compute_delta_coverage(changed_lines, lcov_line_data, package_dir)
        output["delta_coverage_pct"] = delta_result["delta_coverage_pct"]
        output["delta_lines_hit"] = delta_result["delta_lines_hit"]
        output["delta_lines_total"] = delta_result["delta_lines_total"]
        output["delta_files"] = delta_result["delta_files"]
    elif delta is not None:
        output["delta_coverage_pct"] = None
        output["delta_lines_hit"] = 0
        output["delta_lines_total"] = 0
        output["delta_files"] = []

    return output


def check_app(threshold: float, dry_run: bool = False) -> dict:
    """Check coverage for a single-app project. Returns result dict."""
    if dry_run:
        return {
            "name": PROJECT_ROOT.name,
            "coverage_pct": None,
            "threshold": threshold,
            "passed": True,
            "dry_run": True,
        }

    lcov_path = run_coverage_for_app()
    if lcov_path is None:
        return {
            "name": PROJECT_ROOT.name,
            "coverage_pct": 0.0,
            "threshold": threshold,
            "passed": False,
            "reason": "tests failed or no coverage data",
        }

    file_coverage = parse_lcov(lcov_path)
    file_coverage = filter_generated_files(file_coverage)
    lines_hit, lines_total, pct = compute_coverage(file_coverage)

    return {
        "name": PROJECT_ROOT.name,
        "coverage_pct": pct,
        "lines_hit": lines_hit,
        "lines_total": lines_total,
        "threshold": threshold,
        "passed": pct >= threshold,
    }


def main() -> int:
    args = parse_args(sys.argv[1:])
    threshold = args["threshold"]
    mode = "app" if args["app"] else detect_mode()

    print(f"Coverage check (threshold: {threshold}%, mode: {mode})")

    package_results = []

    if mode == "app":
        result = check_app(threshold, dry_run=args["dry_run"])
        package_results.append(result)

    else:  # monorepo
        # Determine which packages to check
        if args["packages"]:
            packages = args["packages"]
        elif args["changed"]:
            packages = get_changed_packages()
            if not packages:
                print("No changed packages with tests detected.")
                if args["json_output"]:
                    output = {
                        "status": "pass",
                        "checks": {"coverage_met": True},
                        "package_results": [],
                        "accepted": True,
                    }
                    print(json.dumps(output, indent=2))
                return 0
        else:
            # All packages with test directories
            packages_dir = PROJECT_ROOT / "packages"
            packages = sorted(
                d.name for d in packages_dir.iterdir()
                if d.is_dir() and (d / "test").is_dir()
            )

        # Apply exclusions
        if args["exclude"]:
            packages = [
                p for p in packages
                if not any(re.search(exc, p) for exc in args["exclude"])
            ]

        print(f"Checking {len(packages)} package(s): {', '.join(packages)}")

        for pkg in packages:
            result = check_package(pkg, threshold, dry_run=args["dry_run"], delta=args["delta"])
            package_results.append(result)

            # Print per-package result
            if result.get("exempt"):
                print(f"  [{pkg}] EXEMPT — {result.get('reason', 'no tests')}")
            elif result.get("dry_run"):
                print(f"  [{pkg}] DRY RUN — would check coverage")
            elif result["passed"]:
                msg = (f"  [{pkg}] PASS — {result['coverage_pct']}% "
                       f"({result.get('lines_hit', 0)}/{result.get('lines_total', 0)} lines)")
                if "delta_coverage_pct" in result and result["delta_coverage_pct"] is not None:
                    msg += (f" | Delta: {result['delta_coverage_pct']}% "
                            f"({result['delta_lines_hit']}/{result['delta_lines_total']} lines)")
                print(msg)
                for df in result.get("delta_files", []):
                    print(f"    {df['path']}: {df['pct']}% ({df['hit']}/{df['total']})")
            else:
                msg = (f"  [{pkg}] FAIL — {result['coverage_pct']}% "
                       f"(threshold: {threshold}%) "
                       f"({result.get('lines_hit', 0)}/{result.get('lines_total', 0)} lines)")
                if "delta_coverage_pct" in result and result["delta_coverage_pct"] is not None:
                    msg += (f" | Delta: {result['delta_coverage_pct']}% "
                            f"({result['delta_lines_hit']}/{result['delta_lines_total']} lines)")
                print(msg)
                for df in result.get("delta_files", []):
                    print(f"    {df['path']}: {df['pct']}% ({df['hit']}/{df['total']})")

    # Determine overall result
    all_passed = all(r["passed"] for r in package_results)
    status = "pass" if all_passed else "fail"

    if args["json_output"]:
        output = {
            "status": status,
            "checks": {"coverage_met": all_passed},
            "package_results": package_results,
            "accepted": all_passed,
        }
        print(json.dumps(output, indent=2))

    if all_passed:
        print(f"\nCoverage check PASSED — all packages meet {threshold}% threshold")
    else:
        failed = [r for r in package_results if not r["passed"]]
        print(f"\nCoverage check FAILED — {len(failed)} package(s) below {threshold}%:")
        for r in failed:
            pct = r.get("coverage_pct", "N/A")
            print(f"  {r['name']}: {pct}%")

    return 0 if all_passed else 1


if __name__ == "__main__":
    sys.exit(main())
