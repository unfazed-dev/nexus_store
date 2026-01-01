#!/bin/bash
# quick-analyze.sh - Fast full test analysis with smart defaults
#
# Usage: ./quick-analyze.sh [path] [options]
#   path          Test path to analyze (default: test/)
#   --verbose     Enable verbose output
#   --performance Enable performance profiling
#   --runs=N      Number of test runs (default: 3)
#
# Examples:
#   ./quick-analyze.sh                    # Analyze test/ with defaults
#   ./quick-analyze.sh test/unit/         # Analyze specific directory
#   ./quick-analyze.sh --verbose          # With verbose output
#   ./quick-analyze.sh --runs=5           # More runs for flaky detection

set -e

# Default values
TEST_PATH="test/"
VERBOSE=""
PERFORMANCE=""
RUNS="3"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE="--verbose"
            shift
            ;;
        --performance|-p)
            PERFORMANCE="--performance"
            shift
            ;;
        --runs=*)
            RUNS="${1#*=}"
            shift
            ;;
        --help|-h)
            echo "Usage: quick-analyze.sh [path] [options]"
            echo ""
            echo "Options:"
            echo "  --verbose, -v     Enable verbose output"
            echo "  --performance, -p Enable performance profiling"
            echo "  --runs=N          Number of test runs (default: 3)"
            echo "  --help, -h        Show this help message"
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
echo "  test_reporter Quick Analysis"
echo "========================================"
echo ""
echo "Path: $TEST_PATH"
echo "Runs: $RUNS"
[[ -n "$VERBOSE" ]] && echo "Verbose: enabled"
[[ -n "$PERFORMANCE" ]] && echo "Performance: enabled"
echo ""

# Run analyze_suite
echo "Running full suite analysis..."
echo ""

dart run test_reporter:analyze_suite "$TEST_PATH" \
    --runs="$RUNS" \
    $VERBOSE \
    $PERFORMANCE

echo ""
echo "========================================"
echo "  Analysis Complete!"
echo "========================================"
echo ""
echo "Reports saved to: tests_reports/"
echo "  - quality/     Coverage analysis"
echo "  - reliability/ Test reliability"
echo "  - failures/    Failed tests"
echo "  - suite/       Unified dashboard"
