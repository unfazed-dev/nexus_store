#!/bin/bash
# failure-triage.sh - Extract and debug failing tests
#
# Usage: ./failure-triage.sh [path] [options]
#   path            Test path to analyze (default: test/)
#   --list-only     List failures without rerunning
#   --auto-rerun    Automatically rerun failed tests
#   --watch         Watch mode for continuous debugging
#   --group-by-file Group failures by file for batch rerun
#
# Examples:
#   ./failure-triage.sh                   # Extract failures from test/
#   ./failure-triage.sh --list-only       # Just list, don't rerun
#   ./failure-triage.sh --auto-rerun      # Rerun to confirm failures
#   ./failure-triage.sh test/unit/ --watch

set -e

# Default values
TEST_PATH="test/"
LIST_ONLY=""
AUTO_RERUN=""
WATCH=""
GROUP_BY_FILE="--group-by-file"
VERBOSE="--verbose"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --list-only|-l)
            LIST_ONLY="--list-only"
            AUTO_RERUN=""
            shift
            ;;
        --auto-rerun|-r)
            AUTO_RERUN="--auto-rerun"
            LIST_ONLY=""
            shift
            ;;
        --watch|-w)
            WATCH="--watch"
            shift
            ;;
        --no-group)
            GROUP_BY_FILE=""
            shift
            ;;
        --quiet|-q)
            VERBOSE=""
            shift
            ;;
        --help|-h)
            echo "Usage: failure-triage.sh [path] [options]"
            echo ""
            echo "Options:"
            echo "  --list-only, -l   List failures without rerunning"
            echo "  --auto-rerun, -r  Automatically rerun failed tests"
            echo "  --watch, -w       Watch mode for continuous debugging"
            echo "  --no-group        Don't group failures by file"
            echo "  --quiet, -q       Disable verbose output"
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
echo "  Failure Triage"
echo "========================================"
echo ""
echo "Path: $TEST_PATH"
[[ -n "$LIST_ONLY" ]] && echo "Mode: List only"
[[ -n "$AUTO_RERUN" ]] && echo "Mode: Auto-rerun enabled"
[[ -n "$WATCH" ]] && echo "Mode: Watch (continuous)"
echo ""

# Run extract_failures
echo "Extracting failed tests..."
echo ""

dart run test_reporter:extract_failures "$TEST_PATH" \
    $LIST_ONLY \
    $AUTO_RERUN \
    $WATCH \
    $GROUP_BY_FILE \
    $VERBOSE \
    --save-results

if [[ -z "$WATCH" ]]; then
    echo ""
    echo "========================================"
    echo "  Triage Complete!"
    echo "========================================"
    echo ""
    echo "Report saved to: tests_reports/failures/"
    echo ""
    echo "Next steps:"
    echo "  1. Review failure patterns in the report"
    echo "  2. Use generated rerun commands to debug"
    echo "  3. Fix failures and run again to verify"
    echo ""
    echo "Common failure patterns:"
    echo "  - AssertionFailure: Check expected vs actual values"
    echo "  - NullError: Add null checks or mock setup"
    echo "  - TimeoutFailure: Increase timeout or optimize async"
    echo "  - TypeError: Verify type casts and generics"
fi
