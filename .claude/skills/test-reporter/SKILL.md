---
name: test-reporter
description: Dart/Flutter test analysis toolkit with 4 CLI tools for test reliability, coverage analysis, failure extraction, and unified reporting. Use when running tests, detecting flaky tests, improving coverage, debugging failures, or setting up CI pipelines.
---

# test_reporter Toolkit

Comprehensive test analysis for Dart/Flutter projects with flaky detection, coverage improvement, and CI integration.

## Quick Start

```bash
# Full analysis (coverage + reliability + failures)
dart run test_reporter:analyze_suite test/

# Detect flaky tests (10 runs)
dart run test_reporter:analyze_tests test/ --runs=10

# Improve coverage with auto-fix
dart run test_reporter:analyze_coverage lib/src --fix

# Extract and rerun failures
dart run test_reporter:extract_failures test/
```

## The 4 CLI Tools

| Tool | Purpose | Key Flag |
|------|---------|----------|
| `analyze_suite` | Full analysis dashboard | `--runs=N` |
| `analyze_tests` | Flaky detection & reliability | `--runs=N --performance` |
| `analyze_coverage` | Coverage with auto-fix | `--fix --min-coverage=N` |
| `extract_failures` | Failure triage | `--auto-rerun --group-by-file` |

## Core Workflows

### 1. Initial Project Analysis

Run complete analysis to understand test health:

```bash
dart run test_reporter:analyze_suite test/ --verbose
```

**Output:** 4 reports in `tests_reports/{quality,reliability,failures,suite}/`

### 2. Flaky Test Detection

Hunt intermittent failures with multiple runs:

```bash
# Standard detection (10 runs)
dart run test_reporter:analyze_tests test/ --runs=10 --performance

# Deep investigation (25 runs)
dart run test_reporter:analyze_tests test/ --runs=25 --verbose

# Continuous monitoring
dart run test_reporter:analyze_tests test/ --runs=5 --watch
```

**Look for:** Tests that pass sometimes and fail others (reliability < 100%)

### 3. Coverage Improvement

Boost coverage with auto-generated test stubs:

```bash
# Analyze and generate missing tests
dart run test_reporter:analyze_coverage lib/src --fix

# Enforce 80% minimum
dart run test_reporter:analyze_coverage lib/src --min-coverage=80

# Compare against baseline
dart run test_reporter:analyze_coverage lib/src --baseline=coverage.json --fail-on-decrease
```

### 4. Failure Triage

Debug failing tests efficiently:

```bash
# Extract failures and generate rerun commands
dart run test_reporter:extract_failures test/

# List only (no rerun)
dart run test_reporter:extract_failures test/ --list-only

# Auto-rerun to confirm
dart run test_reporter:extract_failures test/ --auto-rerun --group-by-file

# Watch mode for continuous debugging
dart run test_reporter:extract_failures test/ --watch
```

### 5. Pre-Commit Validation

Quick check before committing:

```bash
# Fast validation (3 runs)
dart run test_reporter:analyze_suite test/ --runs=3

# With performance check
dart run test_reporter:analyze_suite test/ --performance
```

## Common Flag Combinations

```bash
# CI Pipeline (strict)
dart run test_reporter:analyze_coverage lib/src --min-coverage=80 --fail-on-decrease

# Deep flaky hunt
dart run test_reporter:analyze_tests test/ --runs=25 --performance --verbose

# Quick smoke test
dart run test_reporter:analyze_suite test/ --runs=1

# Debug specific directory
dart run test_reporter:extract_failures test/unit/auth/ --verbose --auto-rerun

# Parallel for speed
dart run test_reporter:analyze_tests test/ --runs=5 --parallel
```

## Report System

### Output Directories

```
tests_reports/
├── quality/       # Coverage reports (analyze_coverage)
├── reliability/   # Test reliability (analyze_tests)
├── failures/      # Failed tests (extract_failures)
└── suite/         # Unified dashboard (analyze_suite)
```

### Naming Convention

```
{module}-{fo|fi}_{type}@HHMM_DDMMYY.{md|json}

Examples:
- auth-fo_coverage@1435_041125.md    # Folder analysis
- user_test-fi_tests@0930_051225.md  # File analysis
```

- `-fo` = folder analysis
- `-fi` = file analysis

### Reading Reports

Reports include:
1. **Summary** - Pass rate, coverage %, flaky count
2. **Details** - Per-test breakdown with error messages
3. **Suggestions** - Actionable fix recommendations
4. **JSON** - Machine-parseable data (embedded or separate file)

## Pattern Matching (Modern Dart)

### Sealed Failure Types

The package uses sealed classes for type-safe failure handling:

```dart
import 'package:test_reporter/test_reporter.dart';

// Exhaustive pattern matching
String handleFailure(FailureType failure) => switch (failure) {
  AssertionFailure(:final message) => 'Fix assertion: $message',
  NullError(:final variableName) => 'Add null check for $variableName',
  TimeoutFailure(:final duration) => 'Increase timeout beyond $duration',
  RangeError(:final index, :final validRange) => 'Index $index outside $validRange',
  TypeError(:final expectedType, :final actualType) => 'Cast $actualType to $expectedType',
  IOError(:final path) => 'Check file exists: $path',
  NetworkError(:final endpoint) => 'Mock network call to $endpoint',
  UnknownFailure(:final message) => 'Investigate: $message',
};
```

### Record Types

```dart
import 'package:test_reporter/test_reporter.dart';

// Destructure analysis results
final (success: ok, totalTests: count, :failedTests) = await runAnalysis();

if (!ok) {
  print('$failedTests of $count tests failed');
}

// Coverage results
final (coverage: pct, :uncoveredLines) = await runCoverage();
print('Coverage: ${pct.toStringAsFixed(1)}%');
```

## CI Integration

### GitHub Actions

```yaml
- name: Run test analysis
  run: dart run test_reporter:analyze_suite test/ --runs=3

- name: Check coverage threshold
  run: dart run test_reporter:analyze_coverage lib/src --min-coverage=80 --fail-on-decrease
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All tests passed, thresholds met |
| 1 | Test failures or threshold violations |
| 2 | Tool error (bad arguments, etc.) |

See `references/workflows.md` for complete CI workflow examples.

## Troubleshooting

### "No tests found"
- Check path argument: `dart run test_reporter:analyze_tests test/unit/`
- Ensure test files end with `_test.dart`

### "Coverage data not found"
- Run `dart test --coverage` first
- Check `coverage/lcov.info` exists

### "Flaky tests not detected"
- Increase runs: `--runs=25`
- Check for time-dependent tests
- Look for shared state between tests

### Reports not generated
- `analyze_suite` always generates reports (by design)
- Other tools: remove `--no-report` flag

### Slow analysis
- Use `--parallel` for multi-core execution
- Reduce `--runs` for quick checks
- Target specific directories instead of all tests

## Script Helpers

Helper scripts in `scripts/` directory:

| Script | Purpose |
|--------|---------|
| `quick-analyze.sh` | Fast full analysis |
| `flaky-detection.sh` | Deep flaky hunt |
| `coverage-boost.sh` | Coverage improvement |
| `failure-triage.sh` | Debug failures |
| `ci-test.sh` | Simulate CI locally |

## Reference Documentation

- **CLI Reference**: `references/cli-reference.md` - All flags and options
- **Failure Types**: `references/failure-types.md` - Sealed class guide
- **Result Types**: `references/result-types.md` - Record type guide
- **Workflows**: `references/workflows.md` - Complete workflow patterns

## Package Usage Modes

```bash
# As project dependency (dev_dependencies)
dart run test_reporter:analyze_suite

# Global activation
dart pub global activate test_reporter
analyze_suite test/

# Direct from bin/ (development)
dart bin/analyze_suite.dart test/
```
