#!/usr/bin/env dart
/// TDD Analysis Hook - Integration with Red-Green-Refactor cycle
///
/// Usage: dart run tdd_analysis_hook.dart <phase> [options]
///
/// Phases:
///   red       Skip analysis (failing test expected)
///   green     Run analysis, warn on NEW issues only
///   refactor  Run auto-fix, then analysis with regression check
///
/// Options:
///   --baseline <file>  Path to baseline issues file
///   --save-baseline    Save current issues as baseline
///   --path <dir>       Target directory (default: current)
///   --strict           Fail on any new issues
///   --help             Show this help message

import 'dart:convert';
import 'dart:io';

/// TDD phases
enum TddPhase { red, green, refactor }

/// Represents the analysis state for comparison
class AnalysisBaseline {
  final Set<String> issueKeys;
  final int totalCount;
  final DateTime timestamp;

  AnalysisBaseline({
    required this.issueKeys,
    required this.totalCount,
    required this.timestamp,
  });

  factory AnalysisBaseline.fromJson(Map<String, dynamic> json) {
    return AnalysisBaseline(
      issueKeys: Set<String>.from(json['issueKeys'] as List),
      totalCount: json['totalCount'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'issueKeys': issueKeys.toList(),
    'totalCount': totalCount,
    'timestamp': timestamp.toIso8601String(),
  };

  factory AnalysisBaseline.empty() => AnalysisBaseline(
    issueKeys: {},
    totalCount: 0,
    timestamp: DateTime.now(),
  );
}

/// Issue key generator for comparison
String issueKey(String code, String file, int line) => '$code:$file:$line';

/// Run dart analyze and get issue keys
Future<(Set<String>, int)> getIssueKeys(String path) async {
  final result = await Process.run(
    'dart',
    ['analyze', '--format=machine', path],
    runInShell: true,
  );

  final keys = <String>{};
  final lines = (result.stderr as String).split('\n');

  for (final line in lines) {
    if (line.trim().isEmpty || !line.contains('|')) continue;

    final parts = line.split('|');
    if (parts.length < 8) continue;

    final code = parts[2];
    final file = parts[3];
    final lineNum = int.tryParse(parts[4]) ?? 0;

    keys.add(issueKey(code, file, lineNum));
  }

  return (keys, keys.length);
}

/// Run auto-fix
Future<void> runAutoFix(String path) async {
  print('Running auto-fix...');
  await Process.run('dart', ['fix', '--apply', path], runInShell: true);
}

/// Load baseline from file
Future<AnalysisBaseline> loadBaseline(String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    return AnalysisBaseline.empty();
  }

  try {
    final content = file.readAsStringSync();
    final json = jsonDecode(content) as Map<String, dynamic>;
    return AnalysisBaseline.fromJson(json);
  } catch (e) {
    print('Warning: Could not load baseline: $e');
    return AnalysisBaseline.empty();
  }
}

/// Save baseline to file
Future<void> saveBaseline(AnalysisBaseline baseline, String path) async {
  final file = File(path);
  final content = const JsonEncoder.withIndent('  ').convert(baseline.toJson());
  file.writeAsStringSync(content);
  print('Baseline saved to: $path');
}

/// Calculate delta between baselines
class AnalysisDelta {
  final Set<String> newIssues;
  final Set<String> resolvedIssues;
  final int totalBefore;
  final int totalAfter;

  AnalysisDelta({
    required this.newIssues,
    required this.resolvedIssues,
    required this.totalBefore,
    required this.totalAfter,
  });

  int get netChange => totalAfter - totalBefore;
  bool get hasRegressions => newIssues.isNotEmpty;
  bool get hasImprovements => resolvedIssues.isNotEmpty;

  void printReport() {
    print('');
    print('=== Analysis Delta ===');
    print('Before: $totalBefore issues');
    print('After:  $totalAfter issues');
    print('Net change: ${netChange >= 0 ? '+' : ''}$netChange');
    print('');

    if (resolvedIssues.isNotEmpty) {
      print('RESOLVED (${resolvedIssues.length}):');
      for (final key in resolvedIssues.take(10)) {
        print('  - $key');
      }
      if (resolvedIssues.length > 10) {
        print('  ... and ${resolvedIssues.length - 10} more');
      }
    }

    if (newIssues.isNotEmpty) {
      print('');
      print('NEW ISSUES (${newIssues.length}):');
      for (final key in newIssues.take(10)) {
        print('  + $key');
      }
      if (newIssues.length > 10) {
        print('  ... and ${newIssues.length - 10} more');
      }
    }
  }
}

void printUsage() {
  print('''
tdd_analysis_hook: TDD Integration for Dart analyzer

Usage: dart run tdd_analysis_hook.dart <phase> [options]

Phases:
  red       Skip analysis (failing test expected)
  green     Run analysis, warn on NEW issues only
  refactor  Run auto-fix, then analysis with regression check

Options:
  --baseline <file>  Path to baseline issues file (default: .analysis_baseline.json)
  --save-baseline    Save current issues as baseline
  --path <dir>       Target directory (default: current)
  --strict           Fail on any new issues
  --help             Show this help message

TDD Workflow:
  1. RED phase: Write failing test, skip analysis
  2. GREEN phase: Make test pass, check for new issues
  3. REFACTOR phase: Clean up code, auto-fix, ensure no regressions

Examples:
  dart run tdd_analysis_hook.dart red
  dart run tdd_analysis_hook.dart green --save-baseline
  dart run tdd_analysis_hook.dart refactor --strict
''');
}

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    printUsage();
    return;
  }

  // Parse phase
  final phaseStr = args.first.toLowerCase();
  final phase = switch (phaseStr) {
    'red' => TddPhase.red,
    'green' => TddPhase.green,
    'refactor' => TddPhase.refactor,
    _ => null,
  };

  if (phase == null) {
    stderr.writeln('Error: Invalid phase "$phaseStr". Use red, green, or refactor.');
    exit(1);
  }

  // Parse options
  var baselinePath = '.analysis_baseline.json';
  var saveBaseline = false;
  var targetPath = '.';
  var strict = false;

  for (var i = 1; i < args.length; i++) {
    switch (args[i]) {
      case '--baseline':
        if (i + 1 < args.length) {
          baselinePath = args[++i];
        }
        break;
      case '--save-baseline':
        saveBaseline = true;
        break;
      case '--path':
        if (i + 1 < args.length) {
          targetPath = args[++i];
        }
        break;
      case '--strict':
        strict = true;
        break;
    }
  }

  // Execute phase
  switch (phase) {
    case TddPhase.red:
      print('=== RED PHASE ===');
      print('Skipping analysis (failing test expected)');
      print('Focus on writing the failing test first.');
      exit(0);

    case TddPhase.green:
      print('=== GREEN PHASE ===');
      print('Running analysis to check for new issues...');

      final baseline = await loadBaseline(baselinePath);
      final (currentKeys, currentCount) = await getIssueKeys(targetPath);

      final newIssues = currentKeys.difference(baseline.issueKeys);
      final resolvedIssues = baseline.issueKeys.difference(currentKeys);

      final delta = AnalysisDelta(
        newIssues: newIssues,
        resolvedIssues: resolvedIssues,
        totalBefore: baseline.totalCount,
        totalAfter: currentCount,
      );

      delta.printReport();

      if (saveBaseline) {
        await AnalysisBaseline(
          issueKeys: currentKeys,
          totalCount: currentCount,
          timestamp: DateTime.now(),
        ).toJson().then((json) => saveBaseline);
      }

      if (strict && delta.hasRegressions) {
        stderr.writeln('');
        stderr.writeln('FAIL: ${newIssues.length} new issues introduced');
        exit(1);
      }

      if (delta.hasRegressions) {
        print('');
        print('WARNING: ${newIssues.length} new issues. Consider fixing before continuing.');
      } else {
        print('');
        print('No new issues introduced. Ready to refactor!');
      }
      break;

    case TddPhase.refactor:
      print('=== REFACTOR PHASE ===');

      // Load baseline before changes
      final baseline = await loadBaseline(baselinePath);

      // Run auto-fix
      await runAutoFix(targetPath);

      // Get current state
      final (currentKeys, currentCount) = await getIssueKeys(targetPath);

      final newIssues = currentKeys.difference(baseline.issueKeys);
      final resolvedIssues = baseline.issueKeys.difference(currentKeys);

      final delta = AnalysisDelta(
        newIssues: newIssues,
        resolvedIssues: resolvedIssues,
        totalBefore: baseline.totalCount,
        totalAfter: currentCount,
      );

      delta.printReport();

      if (delta.hasImprovements && !delta.hasRegressions) {
        print('');
        print('SUCCESS: Refactoring improved code quality!');

        // Save new baseline
        await saveBaseline(
          AnalysisBaseline(
            issueKeys: currentKeys,
            totalCount: currentCount,
            timestamp: DateTime.now(),
          ),
          baselinePath,
        );
      } else if (delta.hasRegressions) {
        stderr.writeln('');
        stderr.writeln('WARNING: ${newIssues.length} new issues after refactoring');
        if (strict) {
          stderr.writeln('FAIL: Regressions detected in strict mode');
          exit(1);
        }
      } else {
        print('');
        print('No changes in analysis results.');
      }
      break;
  }
}
