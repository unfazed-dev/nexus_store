#!/usr/bin/env bash
# Orchestrator: Pre-commit quality gate.
#
# Runs format check, analyzer, and invariants sequentially.
# Outputs structured JSON matching the orchestrator contract.
#
# Orchestrator Contract:
#   Invocation: bash .claude/orchestrators/pre-commit-check.sh
#   Input:      none (reads project files directly)
#   Output:     JSON {status, checks{format_clean, analyze_clean, invariants_pass, coverage_met},
#                      recommendation, action_needed, details, acceptance_criteria, accepted}
#   Exit codes: 0 = all checks pass, 1 = one or more checks failed
#   Dependencies: dart CLI, .claude/invariants/*.dart, python3, check-coverage.py
#   Side effects: None (read-only — does NOT modify files)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

# Track results
format_ok=true
analyze_ok=true
invariants_ok=true
coverage_ok=true
details=()

# 1. Format check
if ! dart format --set-exit-if-changed . > /dev/null 2>&1; then
    format_ok=false
    details+=("dart format: files need formatting. Run: dart format .")
fi

# 2. Analyzer
analyze_output=$(dart analyze --fatal-infos 2>&1)
analyze_exit=$?
if [ $analyze_exit -ne 0 ]; then
    analyze_ok=false
    error_count=$(echo "$analyze_output" | grep -cE '[[:space:]](error|warning|info)[[:space:]]' || true)
    details+=("dart analyze: $error_count issue(s)")
fi

# 3. Invariants
invariant_failures=()
for f in .claude/invariants/*.dart; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .dart)
    if ! dart run "$f" > /dev/null 2>&1; then
        invariants_ok=false
        invariant_failures+=("$name")
        details+=("Invariant failed: $name")
    fi
done

# 4. Coverage check (changed packages only)
if [ "${CHECK_COVERAGE:-true}" = "true" ]; then
    if ! python3 .claude/hooks/core/check-coverage.py --changed --threshold=95 --json > /dev/null 2>&1; then
        coverage_ok=false
        details+=("Coverage: one or more packages below 95% threshold")
    fi
fi

# Build JSON output
if $format_ok && $analyze_ok && $invariants_ok && $coverage_ok; then
    status="pass"
    recommendation="All pre-commit checks pass"
    action_needed=false
    accepted=true
else
    status="fail"
    recommendation="Fix issues before committing"
    action_needed=true
    accepted=false
fi

# Output JSON using python for reliable formatting
python3 -c "
import json
result = {
    'status': '$status',
    'checks': {
        'format_clean': $( $format_ok && echo 'True' || echo 'False' ),
        'analyze_clean': $( $analyze_ok && echo 'True' || echo 'False' ),
        'invariants_pass': $( $invariants_ok && echo 'True' || echo 'False' ),
        'coverage_met': $( $coverage_ok && echo 'True' || echo 'False' ),
    },
    'recommendation': '$recommendation',
    'action_needed': $( $action_needed && echo 'True' || echo 'False' ),
    'details': $(python3 -c "import json; print(json.dumps([$(if [ ${#details[@]} -gt 0 ]; then printf '"%s",' "${details[@]}"; fi)]))" 2>/dev/null || echo '[]'),
    'acceptance_criteria': {
        'format_clean': $( $format_ok && echo 'True' || echo 'False' ),
        'lint_clean': $( $analyze_ok && echo 'True' || echo 'False' ),
        'invariants_pass': $( $invariants_ok && echo 'True' || echo 'False' ),
        'coverage_met': $( $coverage_ok && echo 'True' || echo 'False' ),
        'proof_items': ['format', 'analyze', 'invariants', 'coverage'],
    },
    'accepted': $( $accepted && echo 'True' || echo 'False' ),
}
print(json.dumps(result, indent=2))
"

$accepted && exit 0 || exit 1
