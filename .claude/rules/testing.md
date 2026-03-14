# Testing Rules

## TDD Discipline
- Always write tests BEFORE implementation: RED → GREEN → REFACTOR
- Test behavior and outcomes, NOT implementation details

## Running Tests
- **PREFER NARROW TARGETS:** `cd packages/nexus_store && dart test test/specific_test.dart`
- **Smart runner:** `python3 .claude/hooks/core/smart-test-run.py` (auto-detects changed packages)
- **Melos test commands:**
  - `melos run test:dart` — run tests for pure Dart packages
  - `melos run test:flutter` — run tests for Flutter packages
  - `melos run test:coverage` — run tests with coverage collection
- **Full suite BLOCKED** unless user explicitly requests it

## Test Organization
- Tests mirror `lib/src/` structure under `test/`
- Unit tests for models, services, repositories
- Integration tests for adapter-specific behavior
- Each package has its own test suite

## Results Tracking
- Results auto-captured to `.claude/test-history/test-runs.jsonl`

## Coverage Enforcement
- **Threshold:** 95% line coverage required for all changed packages
- **Tool:** `python3 .claude/hooks/core/check-coverage.py --changed`
- **Integrated:** Pre-commit orchestrator stage 4
- **Scope:** Only packages with modified files (not all 13)
- **Skip:** Packages without `test/` directory are exempt
- **Override:** `CHECK_COVERAGE=false` for non-code phases
- **Generated files excluded:** `.g.dart`, `.freezed.dart` filtered from coverage data

## Enforcement
- **Hook:** `.claude/hooks/core/inject-test-reporter.py` — intercepts full-suite runs, forces smart runner
- **Hook:** `.claude/hooks/core/capture-test-results.py` — auto-captures results to test-runs.jsonl
- **Hook:** `.claude/hooks/core/check-coverage.py` — enforces 95% line coverage at pre-commit
- **Manual only:** TDD discipline and narrow-target preference are not automatically enforced
