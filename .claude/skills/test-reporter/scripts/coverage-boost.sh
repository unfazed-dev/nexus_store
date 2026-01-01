#!/bin/bash
# coverage-boost.sh - Coverage improvement workflow with auto-fix
#
# Usage: ./coverage-boost.sh [path] [options]
#   path              Source path to analyze (default: lib/src)
#   --fix             Auto-generate missing test stubs
#   --min=N           Set minimum coverage threshold (default: 80)
#   --baseline=FILE   Compare against baseline file
#   --test-path=PATH  Custom test directory
#
# Examples:
#   ./coverage-boost.sh                   # Analyze lib/src
#   ./coverage-boost.sh --fix             # Generate missing tests
#   ./coverage-boost.sh lib/src/auth --min=90
#   ./coverage-boost.sh --baseline=baseline.json

set -e

# Default values
SOURCE_PATH="lib/src"
FIX=""
MIN_COVERAGE="80"
BASELINE=""
TEST_PATH=""
VERBOSE="--verbose"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --fix)
            FIX="--fix"
            shift
            ;;
        --min=*)
            MIN_COVERAGE="${1#*=}"
            shift
            ;;
        --baseline=*)
            BASELINE="--baseline=${1#*=}"
            shift
            ;;
        --test-path=*)
            TEST_PATH="--test-path=${1#*=}"
            shift
            ;;
        --quiet|-q)
            VERBOSE=""
            shift
            ;;
        --help|-h)
            echo "Usage: coverage-boost.sh [path] [options]"
            echo ""
            echo "Options:"
            echo "  --fix           Auto-generate missing test stubs"
            echo "  --min=N         Minimum coverage threshold (default: 80)"
            echo "  --baseline=FILE Compare against baseline file"
            echo "  --test-path=PATH Custom test directory"
            echo "  --quiet, -q     Disable verbose output"
            echo "  --help, -h      Show this help message"
            exit 0
            ;;
        *)
            if [[ ! "$1" =~ ^- ]]; then
                SOURCE_PATH="$1"
            fi
            shift
            ;;
    esac
done

echo "========================================"
echo "  Coverage Boost"
echo "========================================"
echo ""
echo "Source path: $SOURCE_PATH"
echo "Min coverage: ${MIN_COVERAGE}%"
[[ -n "$FIX" ]] && echo "Auto-fix: enabled"
[[ -n "$BASELINE" ]] && echo "Baseline: ${BASELINE#*=}"
echo ""

# Run coverage analysis
echo "Analyzing coverage..."
echo ""

dart run test_reporter:analyze_coverage "$SOURCE_PATH" \
    --min-coverage="$MIN_COVERAGE" \
    $FIX \
    $BASELINE \
    $TEST_PATH \
    $VERBOSE

echo ""
echo "========================================"
echo "  Coverage Analysis Complete!"
echo "========================================"
echo ""
echo "Report saved to: tests_reports/quality/"
echo ""

if [[ -n "$FIX" ]]; then
    echo "Generated test stubs for uncovered code."
    echo "Review and implement the generated test files."
else
    echo "To auto-generate missing tests, run:"
    echo "  ./coverage-boost.sh --fix"
fi

echo ""
echo "Tips for improving coverage:"
echo "  - Focus on untested public methods first"
echo "  - Add edge case tests for conditionals"
echo "  - Test error handling paths"
echo "  - Use --baseline to track progress"
