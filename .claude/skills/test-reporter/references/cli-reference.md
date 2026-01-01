# CLI Reference

Complete flag documentation for all 4 test_reporter CLI tools.

## analyze_tests

Test reliability analyzer with flaky detection, pattern recognition, and performance profiling.

```bash
dart run test_reporter:analyze_tests [path] [options]
```

### Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `path` | Directory or file to analyze | `test/` |

### Flags

| Flag | Short | Description | Default |
|------|-------|-------------|---------|
| `--runs=<n>` | | Number of test runs for flaky detection | `3` |
| `--verbose` | `-v` | Enable verbose output | off |
| `--performance` | `-p` | Enable performance profiling | off |
| `--watch` | `-w` | Watch mode (continuous testing) | off |
| `--parallel` | | Run tests in parallel | off |
| `--interactive` | `-i` | Interactive debugging mode | off |
| `--slow=<n>` | | Slow test threshold in seconds | `5` |
| `--workers=<n>` | | Max parallel workers | `4` |
| `--module-name=<name>` | | Override module name for reports | auto |
| `--[no-]report` | | Generate test analysis reports | on |
| `--[no-]fixes` | | Generate fix suggestions | on |
| `--[no-]checklist` | | Generate actionable checklists | on |
| `--minimal-checklist` | | Compact checklist format | off |
| `--include-fixtures` | | Include fixture tests | off |
| `--help` | `-h` | Show help | |

### Examples

```bash
# Basic analysis
dart run test_reporter:analyze_tests test/

# Flaky detection with 10 runs
dart run test_reporter:analyze_tests test/ --runs=10

# Performance profiling
dart run test_reporter:analyze_tests test/ --performance --verbose

# Watch mode for continuous testing
dart run test_reporter:analyze_tests test/ --watch

# Parallel execution for speed
dart run test_reporter:analyze_tests test/ --parallel --runs=5

# Interactive debugging
dart run test_reporter:analyze_tests test/unit/auth/ --interactive

# Skip report generation
dart run test_reporter:analyze_tests test/ --no-report
```

### Output

Reports saved to: `tests_reports/reliability/`

---

## analyze_coverage

Coverage analyzer with auto-fix capabilities, thresholds, and baseline comparison.

```bash
dart run test_reporter:analyze_coverage [path] [options]
```

### Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `path` | Source directory to analyze | `lib/src` |

### Flags

| Flag | Short | Description | Default |
|------|-------|-------------|---------|
| `--fix` | | Auto-generate missing test stubs | off |
| `--verbose` | `-v` | Enable verbose output | off |
| `--min-coverage=<n>` | | Minimum coverage threshold (0-100) | none |
| `--warn-coverage=<n>` | | Warning coverage threshold | none |
| `--baseline=<file>` | | Compare against baseline file | none |
| `--fail-on-decrease` | | Fail if coverage decreases | off |
| `--lib=<path>` | | Source path (alias: --source-path) | `lib/src` |
| `--test=<path>` | | Test path (alias: --test-path) | `test` |
| `--module-name=<name>` | | Override module name | auto |
| `--exclude=<pattern>` | | Exclude files matching pattern | none |
| `--[no-]report` | | Generate coverage report | on |
| `--[no-]checklist` | | Generate actionable checklists | on |
| `--minimal-checklist` | | Compact checklist format | off |
| `--json` | | Export JSON report | off |
| `--include-fixtures` | | Include fixture tests | off |
| `--help` | `-h` | Show help | |

### Examples

```bash
# Basic coverage analysis
dart run test_reporter:analyze_coverage lib/src

# Auto-generate missing tests
dart run test_reporter:analyze_coverage lib/src --fix

# Enforce 80% minimum coverage
dart run test_reporter:analyze_coverage lib/src --min-coverage=80

# Compare against baseline
dart run test_reporter:analyze_coverage lib/src --baseline=coverage.json

# Fail if coverage drops
dart run test_reporter:analyze_coverage lib/src --fail-on-decrease

# Exclude generated files
dart run test_reporter:analyze_coverage lib/src --exclude='**/*.g.dart'

# Custom paths
dart run test_reporter:analyze_coverage lib/src/auth --test-path=test/unit/auth
```

### Output

Reports saved to: `tests_reports/quality/`

---

## extract_failures

Failed test extractor with rerun commands and batch processing.

```bash
dart run test_reporter:extract_failures [path] [options]
```

### Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `path` | Test directory to analyze | `test/` |

### Flags

| Flag | Short | Description | Default |
|------|-------|-------------|---------|
| `--list-only` | `-l` | List failures without rerunning | off |
| `--[no-]auto-rerun` | `-r` | Automatically rerun failed tests | on |
| `--watch` | `-w` | Watch mode (continuous monitoring) | off |
| `--[no-]group-by-file` | `-g` | Group failures by file | on |
| `--parallel` | `-p` | Run tests in parallel | off |
| `--save-results` | `-s` | Save detailed failure report | off |
| `--module-name=<name>` | | Override module name | auto |
| `--timeout=<n>` | `-t` | Test timeout in seconds | `120` |
| `--max-failures=<n>` | | Max failures to extract (0=unlimited) | `0` |
| `--output=<dir>` | `-o` | Output directory (deprecated) | auto |
| `--verbose` | `-v` | Enable verbose output | off |
| `--[no-]checklist` | | Include actionable checklists | on |
| `--minimal-checklist` | | Compact checklist format | off |
| `--help` | `-h` | Show help | |

### Examples

```bash
# Extract and rerun failures
dart run test_reporter:extract_failures test/

# List failures only (no rerun)
dart run test_reporter:extract_failures test/ --list-only

# Watch mode for continuous debugging
dart run test_reporter:extract_failures test/ --watch

# Save detailed report
dart run test_reporter:extract_failures test/ --save-results

# Limit failures extracted
dart run test_reporter:extract_failures test/ --max-failures=10

# Custom timeout
dart run test_reporter:extract_failures test/ --timeout=60
```

### Output

Reports saved to: `tests_reports/failures/`

---

## analyze_suite

Unified test analysis orchestrator combining all tools.

```bash
dart run test_reporter:analyze_suite [path] [options]
```

### Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `path` | Test path to analyze | `test/` |

### Flags

| Flag | Short | Description | Default |
|------|-------|-------------|---------|
| `--path=<path>` | `-p` | Test path to analyze | `test/` |
| `--test-path=<path>` | | Explicit test path override | auto |
| `--source-path=<path>` | | Explicit source path override | auto |
| `--module-name=<name>` | | Override module name | auto |
| `--runs=<n>` | `-r` | Number of test runs | `3` |
| `--performance` | | Enable performance profiling | off |
| `--parallel` | | Run tests in parallel | off |
| `--verbose` | `-v` | Enable verbose output | off |
| `--[no-]checklist` | | Include actionable checklists | on |
| `--minimal-checklist` | | Compact checklist format | off |
| `--include-fixtures` | | Include fixture tests | off |
| `--help` | `-h` | Show help | |

**Note:** `analyze_suite` does NOT support `--no-report` by design. Its purpose IS to generate unified reports.

### Examples

```bash
# Full analysis with defaults
dart run test_reporter:analyze_suite

# Specific directory
dart run test_reporter:analyze_suite test/integration/

# More runs for flaky detection
dart run test_reporter:analyze_suite test/ --runs=5

# Performance profiling
dart run test_reporter:analyze_suite test/ --performance

# Parallel execution
dart run test_reporter:analyze_suite test/ --parallel

# Explicit path overrides
dart run test_reporter:analyze_suite test/ --test-path=test/ --source-path=lib/src/
```

### Output

Generates 4 reports in:
- `tests_reports/quality/` - Coverage analysis
- `tests_reports/reliability/` - Test reliability
- `tests_reports/failures/` - Failed tests
- `tests_reports/suite/` - Unified dashboard

---

## Exit Codes

All tools use consistent exit codes:

| Code | Meaning |
|------|---------|
| `0` | Success - all tests passed, thresholds met |
| `1` | Failure - test failures or threshold violations |
| `2` | Error - tool error (bad arguments, etc.) |

---

## Common Flag Patterns

### CI Pipeline (Strict)
```bash
dart run test_reporter:analyze_coverage lib/src --min-coverage=80 --fail-on-decrease
dart run test_reporter:analyze_suite test/ --runs=3
```

### Deep Flaky Analysis
```bash
dart run test_reporter:analyze_tests test/ --runs=25 --performance --verbose
```

### Quick Local Check
```bash
dart run test_reporter:analyze_suite test/ --runs=1
```

### Debug Specific Tests
```bash
dart run test_reporter:extract_failures test/unit/auth/ --verbose --auto-rerun
```

### Parallel Execution
```bash
dart run test_reporter:analyze_tests test/ --runs=5 --parallel
dart run test_reporter:analyze_suite test/ --parallel
```

### Coverage Improvement
```bash
dart run test_reporter:analyze_coverage lib/src --fix --verbose
```
