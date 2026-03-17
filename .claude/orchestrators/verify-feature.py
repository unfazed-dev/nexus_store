#!/usr/bin/env python3
"""Orchestrator: Verify a package's feature completeness.

Checks that a NexusStore package has required documentation, passes invariants,
has tests, and has a proper barrel file.

Usage:
    python3 .claude/orchestrators/verify-feature.py <package>
    python3 .claude/orchestrators/verify-feature.py --all
    python3 .claude/orchestrators/verify-feature.py --help

Examples:
    python3 .claude/orchestrators/verify-feature.py nexus_store
    python3 .claude/orchestrators/verify-feature.py nexus_store_drift_adapter
    python3 .claude/orchestrators/verify-feature.py --all

Orchestrator Contract:
    Invocation: python3 .claude/orchestrators/verify-feature.py <package>
    Input:      positional arg: package name (directory under packages/)
                or --all to verify all packages
    Output:     JSON {status, checks{code_exists, barrel_exists, has_pubspec,
                      has_tests, has_lib_src, invariants_pass},
                      recommendation, action_needed, details,
                      acceptance_criteria, accepted}
    Exit codes: 0 = all checks pass, 1 = one or more checks failed
    Dependencies: dart CLI, .claude/invariants/*.dart
    Side effects: None (read-only)
"""

import json
import os
import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent

PACKAGES_DIR = PROJECT_ROOT / "packages"

# Core package gets stricter checks
CORE_PACKAGE = "nexus_store"

# Package categories for context
ADAPTERS = {
    "nexus_store_drift_adapter",
    "nexus_store_powersync_adapter",
    "nexus_store_supabase_adapter",
    "nexus_store_brick_adapter",
    "nexus_store_crdt_adapter",
}
BINDINGS = {
    "nexus_store_bloc_binding",
    "nexus_store_riverpod_binding",
    "nexus_store_riverpod_generator",
    "nexus_store_signals_binding",
}
GENERATORS = {
    "nexus_store_generator",
    "nexus_store_entity_generator",
}


def get_package_category(package_name):
    """Return the category of a package."""
    if package_name == CORE_PACKAGE:
        return "core"
    if package_name in ADAPTERS:
        return "adapter"
    if package_name in BINDINGS:
        return "binding"
    if package_name in GENERATORS:
        return "generator"
    if package_name == "nexus_store_flutter_widgets":
        return "widgets"
    return "unknown"


def check_package(package_name):
    """Run all checks for a package and return structured result."""
    checks = {}
    details = []

    package_dir = PACKAGES_DIR / package_name
    category = get_package_category(package_name)

    # 1. Check package directory exists
    checks["code_exists"] = package_dir.is_dir()
    if not checks["code_exists"]:
        details.append(f"Package directory not found: {package_dir}")
        # Early return — nothing else to check
        return {
            "status": "fail",
            "checks": checks,
            "recommendation": f"Package '{package_name}' not found under packages/",
            "action_needed": True,
            "details": details,
            "acceptance_criteria": {},
            "accepted": False,
        }

    # 2. Check pubspec.yaml exists
    pubspec = package_dir / "pubspec.yaml"
    checks["has_pubspec"] = pubspec.is_file()
    if not checks["has_pubspec"]:
        details.append(f"Missing pubspec.yaml in {package_dir}")

    # 3. Check barrel file exists (lib/<package_name>.dart)
    barrel = package_dir / "lib" / f"{package_name}.dart"
    checks["barrel_exists"] = barrel.is_file()
    if not checks["barrel_exists"]:
        details.append(f"Missing barrel file: {barrel}")

    # 4. Check lib/src/ directory exists
    lib_src = package_dir / "lib" / "src"
    checks["has_lib_src"] = lib_src.is_dir()
    if not checks["has_lib_src"]:
        details.append(f"Missing lib/src/ directory in {package_dir}")

    # 5. Check test files exist
    test_dir = package_dir / "test"
    has_tests = False
    test_count = 0
    if test_dir.is_dir():
        for f in test_dir.rglob("*_test.dart"):
            has_tests = True
            test_count += 1
    checks["has_tests"] = has_tests
    if not has_tests:
        details.append(f"No test files found for package '{package_name}'")

    # 6. Check CLAUDE.md exists (package-level documentation)
    claude_md = package_dir / "CLAUDE.md"
    checks["has_claude_md"] = claude_md.is_file()
    if not checks["has_claude_md"]:
        # Not a hard failure for all packages, just a note
        details.append(f"No package-level CLAUDE.md: {claude_md}")

    # 7. Run invariants
    invariants_dir = PROJECT_ROOT / ".claude" / "invariants"
    invariants_pass = True
    if invariants_dir.is_dir():
        for inv_file in sorted(invariants_dir.glob("*.dart")):
            result = subprocess.run(
                ["dart", "run", str(inv_file)],
                capture_output=True, text=True, cwd=str(PROJECT_ROOT),
            )
            if result.returncode != 0:
                invariants_pass = False
                details.append(f"Invariant failed: {inv_file.name}")
    checks["invariants_pass"] = invariants_pass

    # Build result
    all_pass = all(checks.values())
    return {
        "status": "pass" if all_pass else "fail",
        "checks": checks,
        "recommendation": (
            f"Package '{package_name}' ({category}) verified successfully."
            if all_pass
            else f"Package '{package_name}' ({category}) has issues. See details."
        ),
        "action_needed": not all_pass,
        "details": [] if all_pass else details,
        "acceptance_criteria": {
            "code_exists": checks["code_exists"],
            "barrel_exists": checks["barrel_exists"],
            "has_tests": checks["has_tests"],
            "invariants_pass": checks["invariants_pass"],
            "proof_items": [
                f"Category: {category}",
                f"{test_count} test file(s)",
                f"{'Has' if checks['has_claude_md'] else 'No'} CLAUDE.md",
            ],
        },
        "accepted": all_pass,
    }


def main():
    if len(sys.argv) < 2 or sys.argv[1] == "--help":
        print("Usage: python3 .claude/orchestrators/verify-feature.py <package>")
        print("       python3 .claude/orchestrators/verify-feature.py --all")
        print("\nExamples:")
        print("  python3 .claude/orchestrators/verify-feature.py nexus_store")
        print("  python3 .claude/orchestrators/verify-feature.py nexus_store_drift_adapter")
        print("  python3 .claude/orchestrators/verify-feature.py --all")
        sys.exit(0)

    if sys.argv[1] == "--all":
        # Verify all packages
        results = {}
        any_fail = False
        for pkg_dir in sorted(PACKAGES_DIR.iterdir()):
            if not pkg_dir.is_dir() or not (pkg_dir / "pubspec.yaml").is_file():
                continue
            result = check_package(pkg_dir.name)
            results[pkg_dir.name] = result
            if not result["accepted"]:
                any_fail = True

        output = {
            "status": "fail" if any_fail else "pass",
            "checks": {name: r["accepted"] for name, r in results.items()},
            "recommendation": (
                "All packages verified successfully."
                if not any_fail
                else f"{sum(1 for r in results.values() if not r['accepted'])} package(s) have issues."
            ),
            "action_needed": any_fail,
            "details": [
                detail
                for r in results.values()
                for detail in r["details"]
            ],
            "packages": results,
            "accepted": not any_fail,
        }
        print(json.dumps(output, indent=2))
        sys.exit(0 if not any_fail else 1)
    else:
        package_name = sys.argv[1]
        result = check_package(package_name)
        print(json.dumps(result, indent=2))
        sys.exit(0 if result["accepted"] else 1)


if __name__ == "__main__":
    main()
