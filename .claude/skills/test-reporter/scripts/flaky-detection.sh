#!/bin/bash
# flaky-detection.sh - Deep flaky test analysis with multiple runs
#
# Usage: ./flaky-detection.sh [path] [options]
#   path          Test path to analyze (default: test/)
#   --runs=N      Number of test runs (default: 10)
#   --deep        Use 25 runs for thorough analysis
#   --watch       Enable watch mode for continuous detection
#   --parallel    Run tests in parallel
#
# Examples:
#   ./flaky-detection.sh                  # 10 runs on test/
#   ./flaky-detection.sh --deep           # 25 runs for thorough detection
#   ./flaky-detection.sh test/unit/ --runs=15
#   ./flaky-detection.sh --watch          # Continuous monitoring

set -e

# Default values
TEST_PATH="test/"
RUNS="10"
WATCH=""
PARALLEL=""
VERBOSE="--verbose"
PERFORMANCE="--performance"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --runs=*)
            RUNS="${1#*=}"
            shift
            ;;
        --deep)
            RUNS="25"
            shift
            ;;
        --watch|-w)
            WATCH="--watch"
            shift
            ;;
        --parallel)
            PARALLEL="--parallel"
            shift
            ;;
        --quiet|-q)
            VERBOSE=""
            shift
            ;;
        --help|-h)
            echo "Usage: flaky-detection.sh [path] [options]"
            echo ""
            echo "Options:"
            echo "  --runs=N     Number of test runs (default: 10)"
            echo "  --deep       Use 25 runs for thorough analysis"
            echo "  --watch, -w  Enable watch mode for continuous detection"
            echo "  --parallel   Run tests in parallel"
            echo "  --quiet, -q  Disable verbose output"
            echo "  --help, -h   Show this help message"
            exit 0
            ;;
        *)
            if [[ ! "$1" =~ ^- ]]; then
                TEST_PATH="$1"
            fi
            shift
            ;;
    esac
done

echo "========================================"
echo "  Flaky Test Detection"
echo "========================================"
echo ""
echo "Path: $TEST_PATH"
echo "Runs: $RUNS"
[[ -n "$WATCH" ]] && echo "Mode: Watch (continuous)"
[[ -n "$PARALLEL" ]] && echo "Parallel: enabled"
echo ""

# Run analyze_tests with multiple runs
echo "Starting flaky test detection..."
echo "This will run tests $RUNS times to find intermittent failures."
echo ""

dart run test_reporter:analyze_tests "$TEST_PATH" \
    --runs="$RUNS" \
    $VERBOSE \
    $PERFORMANCE \
    $WATCH \
    $PARALLEL

if [[ -z "$WATCH" ]]; then
    echo ""
    echo "========================================"
    echo "  Detection Complete!"
    echo "========================================"
    echo ""
    echo "Look for tests with reliability < 100% in:"
    echo "  tests_reports/reliability/"
    echo ""
    echo "Common causes of flaky tests:"
    echo "  - Shared mutable state between tests"
    echo "  - Time-dependent assertions"
    echo "  - Race conditions in async code"
    echo "  - External service dependencies"
fi
