#!/usr/bin/env dart
/// Parse and categorize Dart analyzer output
///
/// Usage: dart run analyze_project.dart [options]
///
/// Options:
///   --json         Output JSON format
///   --summary      Show summary only
///   --by-file      Group by file
///   --by-category  Group by issue category
///   --path <dir>   Target directory (default: current)
///   --help         Show this help message

import 'dart:convert';
import 'dart:io';

/// Issue severity levels
enum Severity { error, warning, info }

/// Issue categories for organization
enum IssueCategory {
  imports('Imports', ['unused_import', 'duplicate_import', 'directives_ordering', 'unnecessary_import']),
  types('Types', ['avoid_dynamic_calls', 'omit_local_variable_types', 'always_specify_types', 'type_annotate_public_apis']),
  style('Style', ['prefer_const_constructors', 'cascade_invocations', 'unnecessary_this', 'prefer_final_locals', 'unnecessary_new']),
  strings('Strings', ['prefer_single_quotes', 'unnecessary_brace_in_string_interps', 'unnecessary_string_interpolations']),
  resources('Resources', ['close_sinks', 'cancel_subscriptions', 'unawaited_futures']),
  documentation('Documentation', ['public_member_api_docs', 'slash_for_doc_comments']),
  exceptions('Exceptions', ['avoid_catches_without_on_clauses', 'only_throw_errors']),
  other('Other', []);

  final String displayName;
  final List<String> codes;

  const IssueCategory(this.displayName, this.codes);

  static IssueCategory fromCode(String code) {
    for (final category in IssueCategory.values) {
      if (category.codes.contains(code)) return category;
    }
    return IssueCategory.other;
  }
}

/// Represents an analyzer diagnostic
class AnalyzerIssue {
  final Severity severity;
  final String type;
  final String code;
  final String filePath;
  final int line;
  final int column;
  final int length;
  final String message;

  AnalyzerIssue({
    required this.severity,
    required this.type,
    required this.code,
    required this.filePath,
    required this.line,
    required this.column,
    required this.length,
    required this.message,
  });

  IssueCategory get category => IssueCategory.fromCode(code);

  bool get isAutoFixable {
    const autoFixable = {
      'unused_import', 'directives_ordering', 'prefer_const_constructors',
      'cascade_invocations', 'unnecessary_this', 'prefer_single_quotes',
      'unnecessary_brace_in_string_interps', 'prefer_final_locals',
      'unnecessary_new', 'unnecessary_string_interpolations',
    };
    return autoFixable.contains(code);
  }

  factory AnalyzerIssue.fromMachineLine(String line) {
    // Machine format: SEVERITY|TYPE|CODE|PATH|LINE|COLUMN|LENGTH|MESSAGE
    final parts = line.split('|');
    if (parts.length < 8) {
      throw FormatException('Invalid machine format: $line');
    }

    final severityStr = parts[0].toUpperCase();
    final severity = switch (severityStr) {
      'ERROR' => Severity.error,
      'WARNING' => Severity.warning,
      _ => Severity.info,
    };

    return AnalyzerIssue(
      severity: severity,
      type: parts[1],
      code: parts[2],
      filePath: parts[3],
      line: int.tryParse(parts[4]) ?? 0,
      column: int.tryParse(parts[5]) ?? 0,
      length: int.tryParse(parts[6]) ?? 0,
      message: parts.sublist(7).join('|'), // Message may contain |
    );
  }

  Map<String, dynamic> toJson() => {
    'severity': severity.name,
    'type': type,
    'code': code,
    'file': filePath,
    'line': line,
    'column': column,
    'length': length,
    'message': message,
    'category': category.name,
    'autoFixable': isAutoFixable,
  };
}

/// Analysis report
class AnalysisReport {
  final List<AnalyzerIssue> issues;
  final String targetPath;
  final DateTime timestamp;

  AnalysisReport({
    required this.issues,
    required this.targetPath,
    required this.timestamp,
  });

  int get errorCount => issues.where((i) => i.severity == Severity.error).length;
  int get warningCount => issues.where((i) => i.severity == Severity.warning).length;
  int get infoCount => issues.where((i) => i.severity == Severity.info).length;
  int get autoFixableCount => issues.where((i) => i.isAutoFixable).length;

  Map<IssueCategory, List<AnalyzerIssue>> get byCategory {
    final result = <IssueCategory, List<AnalyzerIssue>>{};
    for (final issue in issues) {
      result.putIfAbsent(issue.category, () => []).add(issue);
    }
    return result;
  }

  Map<String, List<AnalyzerIssue>> get byFile {
    final result = <String, List<AnalyzerIssue>>{};
    for (final issue in issues) {
      result.putIfAbsent(issue.filePath, () => []).add(issue);
    }
    return result;
  }

  Map<String, int> get codeFrequency {
    final result = <String, int>{};
    for (final issue in issues) {
      result[issue.code] = (result[issue.code] ?? 0) + 1;
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
    'targetPath': targetPath,
    'timestamp': timestamp.toIso8601String(),
    'summary': {
      'total': issues.length,
      'errors': errorCount,
      'warnings': warningCount,
      'infos': infoCount,
      'autoFixable': autoFixableCount,
    },
    'byCategory': byCategory.map((k, v) => MapEntry(k.name, v.length)),
    'codeFrequency': codeFrequency,
    'issues': issues.map((i) => i.toJson()).toList(),
  };

  void printSummary() {
    print('=== Analysis Summary ===');
    print('Path: $targetPath');
    print('Time: $timestamp');
    print('');
    print('Total issues: ${issues.length}');
    print('  Errors:   $errorCount');
    print('  Warnings: $warningCount');
    print('  Infos:    $infoCount');
    print('');
    print('Auto-fixable: $autoFixableCount (${(autoFixableCount / issues.length * 100).toStringAsFixed(1)}%)');
    print('');

    print('By Category:');
    for (final entry in byCategory.entries) {
      if (entry.value.isEmpty) continue;
      final autoFix = entry.value.where((i) => i.isAutoFixable).length;
      print('  ${entry.key.displayName}: ${entry.value.length} ($autoFix auto-fixable)');
    }
    print('');

    print('Top Issues:');
    final sortedCodes = codeFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedCodes.take(10)) {
      final sample = issues.firstWhere((i) => i.code == entry.key);
      final fixable = sample.isAutoFixable ? '[auto]' : '[manual]';
      print('  ${entry.key}: ${entry.value} $fixable');
    }
  }

  void printByFile() {
    print('=== Issues by File ===');
    final sortedFiles = byFile.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    for (final entry in sortedFiles) {
      print('');
      print('${entry.key} (${entry.value.length} issues):');
      for (final issue in entry.value) {
        final fixable = issue.isAutoFixable ? '[auto]' : '';
        print('  L${issue.line}: ${issue.code} $fixable');
      }
    }
  }

  void printByCategory() {
    print('=== Issues by Category ===');

    for (final category in IssueCategory.values) {
      final issues = byCategory[category];
      if (issues == null || issues.isEmpty) continue;

      print('');
      print('${category.displayName} (${issues.length}):');

      final bySeverity = <Severity, List<AnalyzerIssue>>{};
      for (final issue in issues) {
        bySeverity.putIfAbsent(issue.severity, () => []).add(issue);
      }

      for (final severity in Severity.values) {
        final sevIssues = bySeverity[severity];
        if (sevIssues == null || sevIssues.isEmpty) continue;

        print('  ${severity.name.toUpperCase()}S (${sevIssues.length}):');
        for (final issue in sevIssues.take(5)) {
          final fixable = issue.isAutoFixable ? '[auto]' : '';
          print('    ${issue.filePath}:${issue.line} - ${issue.code} $fixable');
        }
        if (sevIssues.length > 5) {
          print('    ... and ${sevIssues.length - 5} more');
        }
      }
    }
  }
}

Future<AnalysisReport> analyzeProject(String path) async {
  final result = await Process.run(
    'dart',
    ['analyze', '--format=machine', path],
    runInShell: true,
  );

  final issues = <AnalyzerIssue>[];
  final lines = (result.stderr as String).split('\n');

  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    if (!line.contains('|')) continue;

    try {
      issues.add(AnalyzerIssue.fromMachineLine(line));
    } catch (e) {
      // Skip unparseable lines
    }
  }

  return AnalysisReport(
    issues: issues,
    targetPath: path,
    timestamp: DateTime.now(),
  );
}

void printUsage() {
  print('''
analyze_project: Parse and categorize Dart analyzer output

Usage: dart run analyze_project.dart [options]

Options:
  --json         Output JSON format
  --summary      Show summary only (default)
  --by-file      Group issues by file
  --by-category  Group issues by category
  --path <dir>   Target directory (default: current)
  --help         Show this help message

Examples:
  dart run analyze_project.dart --summary
  dart run analyze_project.dart --by-category --path ./lib
  dart run analyze_project.dart --json > report.json
''');
}

Future<void> main(List<String> args) async {
  var outputJson = false;
  var showSummary = true;
  var showByFile = false;
  var showByCategory = false;
  var targetPath = '.';

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--help':
      case '-h':
        printUsage();
        return;
      case '--json':
        outputJson = true;
        break;
      case '--summary':
        showSummary = true;
        break;
      case '--by-file':
        showByFile = true;
        showSummary = false;
        break;
      case '--by-category':
        showByCategory = true;
        showSummary = false;
        break;
      case '--path':
        if (i + 1 < args.length) {
          targetPath = args[++i];
        }
        break;
    }
  }

  if (!Directory(targetPath).existsSync() && !File(targetPath).existsSync()) {
    stderr.writeln('Error: Path does not exist: $targetPath');
    exit(1);
  }

  final report = await analyzeProject(targetPath);

  if (outputJson) {
    print(const JsonEncoder.withIndent('  ').convert(report.toJson()));
  } else {
    if (showSummary) report.printSummary();
    if (showByFile) report.printByFile();
    if (showByCategory) report.printByCategory();
  }
}
