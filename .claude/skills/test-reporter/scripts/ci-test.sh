#!/bin/bash
# ci-test.sh - Simulate CI environment locally
#
# Usage: ./ci-test.sh [options]
#   --min-coverage=N  Minimum coverage threshold (default: 80)
#   --runs=N          Number of test runs (default: 3)
#   --strict          Fail on any warning
#   --quick           Quick mode (1 run, no coverage threshold)
#
# Examples:
#   ./ci-test.sh                    # Standard CI simulation
#   ./ci-test.sh --strict           # Strict mode
#   ./ci-test.sh --min-coverage=90  # Higher threshold
#   ./ci-test.sh --quick            # Fast pre-push check

set -e

# Default values
MIN_COVERAGE="80"
RUNS="3"
STRICT=""
QUICK=""
EXIT_CODE=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --min-coverage=*)
            MIN_COVERAGE="${1#*=}"
            shift
            ;;
        --runs=*)
            RUNS="${1#*=}"
            shift
            ;;
        --strict)
            STRICT="true"
            shift
            ;;
        --quick)
            QUICK="true"
            RUNS="1"
            MIN_COVERAGE="0"
            shift
            ;;
        --help|-h)
            echo "Usage: ci-test.sh [options]"
            echo ""
            echo "Options:"
            echo "  --min-coverage=N  Minimum coverage threshold (default: 80)"
            echo "  --runs=N          Number of test runs (default: 3)"
            echo "  --strict          Fail on any warning"
            echo "  --quick           Quick mode (1 run, no coverage threshold)"
            echo "  --help, -h        Show this help message"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

echo "========================================"
echo "  CI Test Simulation"
echo "========================================"
echo ""
echo "Configuration:"
echo "  Min coverage: ${MIN_COVERAGE}%"
echo "  Test runs: $RUNS"
[[ -n "$STRICT" ]] && echo "  Mode: Strict"
[[ -n "$QUICK" ]] && echo "  Mode: Quick"
echo ""

# Step 1: Analyze code
echo "----------------------------------------"
echo "Step 1: Static Analysis"
echo "----------------------------------------"
if ! dart analyze; then
    echo "FAILED: Static analysis found issues"
    [[ -n "$STRICT" ]] && exit 1
    EXIT_CODE=1
else
    echo "PASSED: Static analysis"
fi
echo ""

# Step 2: Format check
echo "----------------------------------------"
echo "Step 2: Format Check"
echo "----------------------------------------"
if ! dart format --set-exit-if-changed --output=none .; then
    echo "FAILED: Code formatting issues found"
    echo "Run 'dart format .' to fix"
    [[ -n "$STRICT" ]] && exit 1
    EXIT_CODE=1
else
    echo "PASSED: Code formatting"
fi
echo ""

# Step 3: Run tests with analyze_suite
echo "----------------------------------------"
echo "Step 3: Test Suite Analysis"
echo "----------------------------------------"
if ! dart run test_reporter:analyze_suite test/ --runs="$RUNS"; then
    echo "FAILED: Test suite analysis"
    EXIT_CODE=1
else
    echo "PASSED: Test suite analysis"
fi
echo ""

# Step 4: Coverage threshold (skip in quick mode)
if [[ -z "$QUICK" && "$MIN_COVERAGE" -gt 0 ]]; then
    echo "----------------------------------------"
    echo "Step 4: Coverage Threshold"
    echo "----------------------------------------"
    if ! dart run test_reporter:analyze_coverage lib/src --min-coverage="$MIN_COVERAGE" --no-report; then
        echo "FAILED: Coverage below ${MIN_COVERAGE}%"
        EXIT_CODE=1
    else
        echo "PASSED: Coverage meets ${MIN_COVERAGE}% threshold"
    fi
    echo ""
fi

# Summary
echo "========================================"
echo "  CI Simulation Complete"
echo "========================================"
echo ""

if [[ $EXIT_CODE -eq 0 ]]; then
    echo "STATUS: ALL CHECKS PASSED"
    echo ""
    echo "Safe to push!"
else
    echo "STATUS: SOME CHECKS FAILED"
    echo ""
    echo "Review failures above before pushing."
fi

exit $EXIT_CODE
