#!/usr/bin/env python3
"""Integration test suite for orchestrators.

NOT an orchestrator itself — this is a test runner that validates each
orchestrator produces valid JSON matching the shared contract schema.

Run this after modifying any orchestrator to confirm the output contract
is preserved. Validates: required fields present, status is valid enum,
checks/details/action_needed have correct types, acceptance_criteria
and accepted follow contract types when present.

Usage:
    python3 .claude/orchestrators/test_orchestrators.py

Exit codes: 0 = all orchestrators pass contract validation, 1 = failures found
"""

import json
import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent

REQUIRED_FIELDS = {"status", "checks", "recommendation", "action_needed", "details"}
VALID_STATUSES = {"pass", "fail", "warn"}

failures = []
passed = 0


def run_orchestrator(cmd, name, timeout=300):
    """Run an orchestrator and validate its JSON output."""
    global passed, failures
    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True,
            cwd=str(PROJECT_ROOT), timeout=timeout,
        )
        # Extract JSON from output (skip non-JSON lines)
        output = result.stdout.strip()
        lines = output.split("\n")

        # Find JSON block
        json_start = None
        for i, line in enumerate(lines):
            if line.strip().startswith("{"):
                json_start = i
                break

        if json_start is None:
            failures.append(f"{name}: No JSON found in output")
            return

        json_text = "\n".join(lines[json_start:])
        data = json.loads(json_text)

        # Validate required fields
        missing = REQUIRED_FIELDS - set(data.keys())
        if missing:
            failures.append(f"{name}: Missing required fields: {missing}")
            return

        # Validate status
        if data["status"] not in VALID_STATUSES:
            failures.append(f"{name}: Invalid status '{data['status']}'")
            return

        # Validate types
        if not isinstance(data["checks"], dict):
            failures.append(f"{name}: 'checks' must be a dict")
            return
        if not isinstance(data["details"], list):
            failures.append(f"{name}: 'details' must be a list")
            return
        if not isinstance(data["action_needed"], bool):
            failures.append(f"{name}: 'action_needed' must be a bool")
            return

        # Validate acceptance_criteria if present
        if "acceptance_criteria" in data:
            if not isinstance(data["acceptance_criteria"], dict):
                failures.append(f"{name}: 'acceptance_criteria' must be a dict")
                return

        # Validate accepted if present
        if "accepted" in data:
            if not isinstance(data["accepted"], bool):
                failures.append(f"{name}: 'accepted' must be a bool")
                return

        passed += 1
        print(f"  PASS: {name} (status={data['status']})")

    except json.JSONDecodeError as e:
        failures.append(f"{name}: Invalid JSON output: {e}")
    except subprocess.TimeoutExpired:
        failures.append(f"{name}: Timed out after {timeout}s")
    except Exception as e:
        failures.append(f"{name}: Unexpected error: {e}")


def main():
    print("Running orchestrator integration tests...\n")

    # Test verify-feature with core package
    run_orchestrator(
        [sys.executable, str(SCRIPT_DIR / "verify-feature.py"), "nexus_store"],
        "verify-feature (nexus_store)",
    )

    # Test verify-feature with an adapter package
    run_orchestrator(
        [sys.executable, str(SCRIPT_DIR / "verify-feature.py"), "nexus_store_drift_adapter"],
        "verify-feature (nexus_store_drift_adapter)",
    )

    # Test verify-feature with --all flag
    run_orchestrator(
        [sys.executable, str(SCRIPT_DIR / "verify-feature.py"), "--all"],
        "verify-feature (--all)",
    )

    # Test verify-feature with non-existent package (should fail gracefully)
    run_orchestrator(
        [sys.executable, str(SCRIPT_DIR / "verify-feature.py"), "nonexistent_package"],
        "verify-feature (nonexistent - expect fail)",
    )

    # Test pre-commit-check
    run_orchestrator(
        ["bash", str(SCRIPT_DIR / "pre-commit-check.sh")],
        "pre-commit-check",
    )

    # Test harness-maintenance (if it exists)
    harness_maint = SCRIPT_DIR / "harness-maintenance.py"
    if harness_maint.exists():
        run_orchestrator(
            [sys.executable, str(harness_maint), "--gc-only"],
            "harness-maintenance (--gc-only)",
        )

    # Test test-and-report (if it exists)
    test_report = SCRIPT_DIR / "test-and-report.py"
    if test_report.exists():
        run_orchestrator(
            [sys.executable, str(test_report), "--dry-run"],
            "test-and-report (--dry-run)",
        )

    # Summary
    print(f"\n{'='*40}")
    total = passed + len(failures)
    if failures:
        print(f"FAIL: {passed}/{total} tests passed\n")
        for f in failures:
            print(f"  FAIL: {f}")
        sys.exit(1)
    else:
        print(f"PASS: {passed}/{total} tests passed")
        sys.exit(0)


if __name__ == "__main__":
    main()
