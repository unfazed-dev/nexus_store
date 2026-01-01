# Result Types Reference

test_reporter uses **records** for lightweight, immutable multi-value returns.

## Import

```dart
import 'package:test_reporter/test_reporter.dart';
```

---

## Core Result Types

### AnalysisResult

Result from test analysis operations.

```dart
typedef AnalysisResult = ({
  bool success,
  int totalTests,
  int passedTests,
  int failedTests,
  String? error,
});
```

**Usage:**
```dart
final result = await runTestAnalysis();

// Destructuring
final (success: ok, totalTests: total, :failedTests, :error) = result;

if (!ok) {
  print('Error: $error');
  print('$failedTests of $total tests failed');
}

// Direct field access
print('Pass rate: ${result.passedTests / result.totalTests * 100}%');
```

**Helper Functions:**
```dart
// Create successful result
final success = successfulAnalysis(
  totalTests: 100,
  passedTests: 95,
  failedTests: 5,
);

// Create failed result
final failed = failedAnalysis('Test runner crashed');

// Handle both cases
final message = handleAnalysisResult(
  result,
  onSuccess: (total, passed, failed) => '$passed/$total passed',
  onError: (error) => 'Error: $error',
);
```

---

### CoverageResult

Result from coverage analysis.

```dart
typedef CoverageResult = ({
  bool success,
  double coverage,
  int totalLines,
  int coveredLines,
  String? error,
});
```

**Usage:**
```dart
final result = await runCoverageAnalysis();

// Destructuring
final (success: ok, :coverage, :totalLines, :coveredLines) = result;

if (ok) {
  print('Coverage: ${coverage.toStringAsFixed(1)}%');
  print('Lines: $coveredLines / $totalLines');
}

// Pattern matching
switch (result) {
  case (success: true, coverage: >= 80):
    print('Coverage target met!');
  case (success: true, coverage: < 80):
    print('Coverage below target');
  case (success: false, :final error):
    print('Analysis failed: $error');
}
```

**Helper Functions:**
```dart
// Create successful result
final success = successfulCoverage(
  coverage: 85.5,
  totalLines: 1000,
  coveredLines: 855,
);

// Create failed result
final failed = failedCoverage('No lcov.info found');

// Extract on success
final coverageValue = onCoverageSuccess(result, (cov) => cov.coverage);
```

---

### TestFileResult

Result from loading a test file.

```dart
typedef TestFileResult = ({
  bool success,
  String filePath,
  int loadTimeMs,
  String? error,
});
```

**Usage:**
```dart
final result = loadTestFile('test/example_test.dart');

// Destructuring
final (success: loaded, :filePath, :loadTimeMs, :error) = result;

if (loaded) {
  print('Loaded $filePath in ${loadTimeMs}ms');
} else {
  print('Failed to load: $error');
}
```

**Helper Functions:**
```dart
final success = successfulLoad('test/example_test.dart', loadTimeMs: 150);
final failed = failedLoad('test/missing_test.dart', error: 'File not found');
```

---

### TestRunResult

Result from an individual test run.

```dart
typedef TestRunResult = ({
  bool passed,
  String testName,
  int durationMs,
  String? errorMessage,
  String? stackTrace,
});
```

**Usage:**
```dart
final result = runTest('should return 42');

// Destructuring
final (:passed, :testName, :durationMs, :errorMessage) = result;

if (!passed) {
  print('FAIL: $testName (${durationMs}ms)');
  print('  Error: $errorMessage');
}
```

**Helper Functions:**
```dart
final pass = passingTest('should add numbers', durationMs: 50);
final fail = failingTest(
  'should validate input',
  durationMs: 30,
  errorMessage: 'Expected true but got false',
  stackTrace: 'at test/validator_test.dart:42:5',
);
```

---

## Metrics Types

### PerformanceMetrics

Performance statistics from test runs.

```dart
typedef PerformanceMetrics = ({
  double averageDuration,
  double maxDuration,
  double minDuration,
  int sampleSize,
});
```

**Usage:**
```dart
final metrics = calculatePerformanceMetrics(durations);

print('Average: ${metrics.averageDuration.toStringAsFixed(2)}ms');
print('Max: ${metrics.maxDuration}ms');
print('Min: ${metrics.minDuration}ms');
print('Samples: ${metrics.sampleSize}');
```

**Helper Function:**
```dart
final durations = [100.0, 150.0, 120.0, 130.0, 110.0];
final metrics = calculatePerformanceMetrics(durations);
// Returns (averageDuration: 122.0, maxDuration: 150.0, minDuration: 100.0, sampleSize: 5)
```

---

### CoverageSummary

Summary of coverage analysis.

```dart
typedef CoverageSummary = ({
  double overallCoverage,
  int filesAnalyzed,
  int totalLines,
  int coveredLines,
  int uncoveredLines,
});
```

**Usage:**
```dart
final summary = createCoverageSummary(files: fileResults);

print('Overall: ${summary.overallCoverage.toStringAsFixed(1)}%');
print('Files: ${summary.filesAnalyzed}');
print('Covered: ${summary.coveredLines}/${summary.totalLines}');
print('Uncovered: ${summary.uncoveredLines}');
```

---

### ReliabilityMetrics

Test reliability statistics.

```dart
typedef ReliabilityMetrics = ({
  double passRate,
  double stabilityScore,
  int totalTests,
  int consistentPasses,
  int consistentFailures,
  int flakyTests,
});
```

**Usage:**
```dart
final metrics = createReliabilityMetrics(testResults: results, runs: 10);

print('Pass rate: ${metrics.passRate.toStringAsFixed(1)}%');
print('Stability: ${metrics.stabilityScore.toStringAsFixed(1)}%');
print('Flaky tests: ${metrics.flakyTests}');
print('Consistent failures: ${metrics.consistentFailures}');
```

---

### FileCoverage

Per-file coverage data.

```dart
typedef FileCoverage = ({
  String filePath,
  double coverage,
  int totalLines,
  int coveredLines,
  int uncoveredLines,
});
```

**Usage:**
```dart
final files = analyzeFileCoverage();

for (final file in files) {
  final (:filePath, :coverage, :uncoveredLines) = file;
  print('$filePath: ${coverage.toStringAsFixed(1)}% ($uncoveredLines uncovered)');
}

// Sort by coverage
files.sort((a, b) => a.coverage.compareTo(b.coverage));
```

---

### TestTiming

Individual test timing data.

```dart
typedef TestTiming = ({
  String testId,
  int duration,
  DateTime timestamp,
  bool passed,
});
```

**Usage:**
```dart
final timings = collectTestTimings(results);

// Find slowest tests
final slowest = timings
  .where((t) => t.duration > 1000)
  .toList()
  ..sort((a, b) => b.duration.compareTo(a.duration));

for (final (:testId, :duration, :passed) in slowest) {
  print('${passed ? "PASS" : "FAIL"}: $testId (${duration}ms)');
}
```

---

## Pattern Matching with Records

### Basic Destructuring

```dart
// Named fields
final (success: ok, coverage: cov) = result;

// Shorthand (when variable name matches field name)
final (:success, :coverage) = result;

// Mixed
final (success: ok, :coverage, :error) = result;
```

### Pattern Matching in Switch

```dart
String describeCoverage(CoverageResult result) => switch (result) {
  (success: true, coverage: >= 90) => 'Excellent coverage!',
  (success: true, coverage: >= 80) => 'Good coverage',
  (success: true, coverage: >= 60) => 'Acceptable coverage',
  (success: true, coverage: _) => 'Low coverage - needs improvement',
  (success: false, error: final e) => 'Error: $e',
};
```

### Pattern Matching in If

```dart
if (result case (success: true, coverage: >= 80)) {
  print('Coverage target met!');
}

if (result case (success: false, error: final e?)) {
  print('Error occurred: $e');
}
```

### Guard Clauses

```dart
switch (result) {
  case (success: true, :final coverage) when coverage >= 80:
    print('Target met: $coverage%');
  case (success: true, :final coverage):
    print('Below target: $coverage%');
  case (success: false, :final error):
    print('Failed: $error');
}
```

---

## Creating Records

### Inline Creation

```dart
final result = (
  success: true,
  totalTests: 100,
  passedTests: 95,
  failedTests: 5,
  error: null,
);
```

### From Functions

```dart
AnalysisResult analyze(List<TestResult> results) {
  final passed = results.where((r) => r.passed).length;
  final failed = results.length - passed;

  return (
    success: failed == 0,
    totalTests: results.length,
    passedTests: passed,
    failedTests: failed,
    error: failed > 0 ? '$failed tests failed' : null,
  );
}
```

### Transformation

```dart
// Transform one record type to another
CoverageSummary toSummary(List<FileCoverage> files) {
  final totalLines = files.fold(0, (sum, f) => sum + f.totalLines);
  final coveredLines = files.fold(0, (sum, f) => sum + f.coveredLines);

  return (
    overallCoverage: coveredLines / totalLines * 100,
    filesAnalyzed: files.length,
    totalLines: totalLines,
    coveredLines: coveredLines,
    uncoveredLines: totalLines - coveredLines,
  );
}
```

---

## Best Practices

1. **Use descriptive destructuring** - Name variables clearly
2. **Leverage pattern matching** - Use switch for complex conditions
3. **Handle all cases** - Check success/failure states
4. **Use helper functions** - Create records consistently
5. **Prefer records over classes** - For simple data transfer
6. **Document field meanings** - Comments for non-obvious fields
