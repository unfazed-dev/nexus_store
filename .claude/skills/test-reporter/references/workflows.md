# Workflows Reference

Complete workflow patterns for common test_reporter use cases.

---

## 1. First-Time Project Setup

Set up test_reporter for a new project.

### Step 1: Install

```bash
# Option A: Add as dev dependency
dart pub add --dev test_reporter

# Option B: Global installation
dart pub global activate test_reporter
```

### Step 2: Initial Analysis

```bash
# Run full suite to understand current state
dart run test_reporter:analyze_suite test/ --verbose

# Or with global install
analyze_suite test/ --verbose
```

### Step 3: Review Reports

Check generated reports in `tests_reports/`:

```
tests_reports/
├── quality/       # Coverage baseline
├── reliability/   # Test reliability baseline
├── failures/      # Any existing failures
└── suite/         # Unified summary
```

### Step 4: Establish Baseline

```bash
# Save coverage baseline for future comparison
cp tests_reports/quality/*_coverage*.json coverage-baseline.json
```

### Step 5: Add to CI

See [CI Integration](#6-ci-pipeline-integration) workflow.

---

## 2. Deep Flaky Test Investigation

Thoroughly analyze intermittent test failures.

### Step 1: Initial Detection

```bash
# Start with 10 runs
dart run test_reporter:analyze_tests test/ --runs=10 --performance --verbose
```

### Step 2: Review Reliability Report

Look for tests with `reliability < 100%` in `tests_reports/reliability/`.

Key metrics:
- **Reliability Score**: Pass rate across runs
- **Failure Pattern**: Consistent vs intermittent
- **Timing Variance**: Duration consistency

### Step 3: Deep Investigation

```bash
# Increase runs for suspected flaky tests
dart run test_reporter:analyze_tests test/unit/suspected_flaky/ --runs=25 --verbose
```

### Step 4: Root Cause Analysis

Common causes:
- **Shared state**: Tests modifying shared variables
- **Time-dependent**: `DateTime.now()` in tests
- **Order-dependent**: Tests relying on execution order
- **Race conditions**: Async operations without proper awaits
- **External dependencies**: Network, filesystem, databases

### Step 5: Fix and Verify

```bash
# After fixing, verify with multiple runs
dart run test_reporter:analyze_tests test/unit/fixed_test.dart --runs=10

# Confirm 100% reliability
```

### Step 6: Monitor

```bash
# Use watch mode for ongoing monitoring
dart run test_reporter:analyze_tests test/ --runs=3 --watch
```

---

## 3. Coverage Improvement Sprint

Systematically increase test coverage.

### Step 1: Baseline

```bash
# Get current coverage
dart run test_reporter:analyze_coverage lib/src --verbose
```

### Step 2: Identify Gaps

Review report for:
- Files with 0% coverage
- Functions with low coverage
- Uncovered branches

### Step 3: Auto-Generate Stubs

```bash
# Generate test stubs for uncovered code
dart run test_reporter:analyze_coverage lib/src --fix
```

### Step 4: Prioritize

Focus on:
1. **Critical paths**: Authentication, payments, data handling
2. **High-change areas**: Frequently modified code
3. **Complex logic**: Functions with many branches

### Step 5: Implement Tests

```bash
# After writing tests, verify improvement
dart run test_reporter:analyze_coverage lib/src --baseline=coverage-baseline.json
```

### Step 6: Set Threshold

```bash
# Enforce minimum coverage
dart run test_reporter:analyze_coverage lib/src --min-coverage=80

# Prevent coverage regression
dart run test_reporter:analyze_coverage lib/src --fail-on-decrease
```

### Step 7: Update Baseline

```bash
# Save new baseline
cp tests_reports/quality/*_coverage*.json coverage-baseline.json
```

---

## 4. Debugging Specific Failures

Efficiently debug failing tests.

### Step 1: Extract Failures

```bash
# List all failures
dart run test_reporter:extract_failures test/ --list-only --verbose
```

### Step 2: Analyze Patterns

Review failure report for:
- **Failure type**: Assertion, null, timeout, etc.
- **Location**: File and line number
- **Frequency**: Consistent vs intermittent

### Step 3: Group by File

```bash
# Group for batch debugging
dart run test_reporter:extract_failures test/ --group-by-file
```

### Step 4: Rerun to Confirm

```bash
# Auto-rerun to confirm failures
dart run test_reporter:extract_failures test/ --auto-rerun
```

### Step 5: Debug Individual Tests

```bash
# Run specific failing test with verbose output
dart test test/unit/auth/login_test.dart --name="should validate email" -r expanded
```

### Step 6: Interactive Mode

```bash
# Use interactive debugging for complex failures
dart run test_reporter:analyze_tests test/unit/auth/ --interactive
```

### Step 7: Verify Fixes

```bash
# After fixing, verify all related tests pass
dart run test_reporter:extract_failures test/unit/auth/ --auto-rerun
```

---

## 5. Pre-Release Validation

Comprehensive validation before releasing.

### Step 1: Static Analysis

```bash
dart analyze
dart format --set-exit-if-changed .
```

### Step 2: Full Test Suite

```bash
# Run with multiple runs to catch flaky tests
dart run test_reporter:analyze_suite test/ --runs=5 --performance
```

### Step 3: Coverage Check

```bash
# Ensure coverage meets threshold
dart run test_reporter:analyze_coverage lib/src --min-coverage=80 --fail-on-decrease
```

### Step 4: Failure Triage

```bash
# Ensure no failures
dart run test_reporter:extract_failures test/ --list-only
```

### Step 5: Review Reports

Check all reports in `tests_reports/suite/` for:
- 0 failures
- 0 flaky tests
- Coverage >= target
- No performance regressions

### Step 6: Final Check

```bash
# Quick final validation
dart run test_reporter:analyze_suite test/ --runs=3
```

---

## 6. CI Pipeline Integration

Set up continuous integration with test_reporter.

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable

      - name: Install dependencies
        run: dart pub get

      - name: Analyze
        run: dart analyze

      - name: Format check
        run: dart format --set-exit-if-changed .

      - name: Run test suite
        run: dart run test_reporter:analyze_suite test/ --runs=3

      - name: Check coverage
        run: dart run test_reporter:analyze_coverage lib/src --min-coverage=80

      - name: Upload reports
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-reports
          path: tests_reports/
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - test

test:
  image: dart:stable
  stage: test
  script:
    - dart pub get
    - dart analyze
    - dart format --set-exit-if-changed .
    - dart run test_reporter:analyze_suite test/ --runs=3
    - dart run test_reporter:analyze_coverage lib/src --min-coverage=80
  artifacts:
    when: always
    paths:
      - tests_reports/
    reports:
      junit: tests_reports/suite/*.xml
```

### Local CI Simulation

```bash
# Use ci-test script
./scripts/ci-test.sh

# Or manually
dart analyze && \
dart format --set-exit-if-changed . && \
dart run test_reporter:analyze_suite test/ --runs=3 && \
dart run test_reporter:analyze_coverage lib/src --min-coverage=80
```

---

## 7. Watch Mode Development

Continuous testing during development.

### Test Reliability Watch

```bash
# Watch for flaky tests during development
dart run test_reporter:analyze_tests test/ --runs=3 --watch
```

### Failure Watch

```bash
# Continuously monitor and rerun failures
dart run test_reporter:extract_failures test/ --watch --auto-rerun
```

### Development Loop

1. Make code changes
2. Watch mode detects changes
3. Tests run automatically
4. Review failures/flaky tests
5. Fix issues
6. Repeat

### Tips

- Use specific directories: `--watch test/unit/auth/`
- Combine with `--parallel` for speed
- Use `--verbose` for detailed output

---

## 8. Performance Optimization

Identify and fix slow tests.

### Step 1: Profile

```bash
dart run test_reporter:analyze_tests test/ --performance --verbose
```

### Step 2: Identify Slow Tests

Review report for tests exceeding threshold (default 5s).

### Step 3: Analyze Causes

Common causes:
- **Large setup/teardown**: Heavy initialization
- **Actual delays**: `sleep()`, `Future.delayed()`
- **External calls**: Network, database
- **Large data**: Processing big datasets

### Step 4: Optimize

Strategies:
- Use `setUpAll` for shared setup
- Mock external services
- Use smaller test data
- Parallelize independent tests

### Step 5: Verify

```bash
# After optimization, verify improvement
dart run test_reporter:analyze_tests test/ --performance

# Set stricter threshold
dart run test_reporter:analyze_tests test/ --slow=2 --performance
```

### Step 6: Parallel Execution

```bash
# Use parallel for faster execution
dart run test_reporter:analyze_tests test/ --parallel --workers=4
```

---

## Quick Reference

| Goal | Command |
|------|---------|
| First analysis | `analyze_suite test/ --verbose` |
| Flaky detection | `analyze_tests test/ --runs=10` |
| Coverage check | `analyze_coverage lib/src --min-coverage=80` |
| Fix coverage | `analyze_coverage lib/src --fix` |
| List failures | `extract_failures test/ --list-only` |
| Debug failures | `extract_failures test/ --auto-rerun --verbose` |
| CI simulation | `./scripts/ci-test.sh` |
| Watch mode | `analyze_tests test/ --watch` |
| Performance | `analyze_tests test/ --performance` |
| Pre-release | `analyze_suite test/ --runs=5 --performance` |
