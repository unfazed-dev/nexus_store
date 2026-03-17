# Orchestrators

Standalone scripts that combine multiple checks into a single structured result. Each orchestrator outputs JSON matching the contract below.

## JSON Output Contract

All orchestrators output this structure (regardless of implementation language):

```json
{
  "status": "pass|fail|warn",
  "checks": { "check_name": true|false },
  "recommendation": "Human-readable next step",
  "action_needed": true|false,
  "details": [],
  "acceptance_criteria": {
    "tests_pass": true,
    "lint_clean": true,
    "invariants_pass": true,
    "proof_items": ["CI green", "no new analyzer warnings"]
  },
  "accepted": true|false
}
```

- On **pass**: `details` is empty (asymmetric output — minimal noise on success)
- On **fail**: `details` contains full diagnostic information with remediation steps
- `accepted` acts as a gate — agents must address failures before proceeding

## Available Orchestrators

| Script | Language | Purpose |
|--------|----------|---------|
| `test-and-report.py` | Python | Wraps smart-test-run.py, captures and reports test results |
| `pre-commit-check.sh` | Bash | Sequential: format → analyze → invariants |
| `harness-maintenance.py` | Python | GC sweep (expirations, orphans, session rotation) + drift scan, updates harness-metrics.json |
| `verify-feature.py` | Python | Verify package completeness: docs, tests, barrel file, invariants |
| `test_orchestrators.py` | Python | Integration tests validating all orchestrators produce valid JSON contracts |

## Usage

```bash
# Run tests and get structured report
python3 .claude/orchestrators/test-and-report.py

# Pre-commit quality gate
bash .claude/orchestrators/pre-commit-check.sh

# Harness maintenance (GC + drift scan)
python3 .claude/orchestrators/harness-maintenance.py --all
python3 .claude/orchestrators/harness-maintenance.py --gc-only
python3 .claude/orchestrators/harness-maintenance.py --drift-only

# Verify a package's completeness
python3 .claude/orchestrators/verify-feature.py nexus_store
python3 .claude/orchestrators/verify-feature.py nexus_store_drift_adapter
python3 .claude/orchestrators/verify-feature.py --all

# Run orchestrator contract tests
python3 .claude/orchestrators/test_orchestrators.py
```

## Language Selection

- **Python** when parsing JSON, applying conditional logic, or wrapping existing Python tools
- **Bash** when running a thin sequential chain of commands

## Migration Path

If Claude Code ships a Programmatic Tool Calling API, wrap existing scripts — the JSON contract remains unchanged. The contract is the stable interface; implementation is swappable.
