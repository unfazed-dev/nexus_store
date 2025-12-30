#!/usr/bin/env dart
/// Auto-fix Dart/Flutter analyzer issues
///
/// Usage: dart run fix_analyzer_issues.dart [options]
///
/// Options:
///   --all          Fix all auto-fixable issues
///   --fix-imports  Fix import issues (unused, ordering)
///   --fix-style    Fix style issues (const, cascades, this)
///   --fix-strings  Fix string issues (quotes, interpolation)
///   --dry-run      Show what would be fixed without applying
///   --path <dir>   Target directory (default: current)
///   --verbose      Show detailed output
///   --help         Show this help message

import 'dart:convert';
import 'dart:io';

/// Categories of auto-fixable issues
enum FixCategory {
  imports,
  style,
  strings,
  types,
  docs,
}

/// Represents an analyzer diagnostic
class AnalyzerIssue {
  final String severity;
  final String code;
  final String message;
  final String filePath;
  final int line;
  final int column;

  AnalyzerIssue({
    required this.severity,
    required this.code,
    required this.message,
    required this.filePath,
    required this.line,
    required this.column,
  });

  factory AnalyzerIssue.fromMachineLine(String line) {
    // Machine format: SEVERITY|TYPE|CODE|PATH|LINE|COLUMN|LENGTH|MESSAGE
    final parts = line.split('|');
    if (parts.length < 8) {
      throw FormatException('Invalid machine format line: $line');
    }
    return AnalyzerIssue(
      severity: parts[0],
      code: parts[2],
      message: parts[7],
      filePath: parts[3],
      line: int.tryParse(parts[4]) ?? 0,
      column: int.tryParse(parts[5]) ?? 0,
    );
  }

  FixCategory? get category {
    if (_importIssues.contains(code)) return FixCategory.imports;
    if (_styleIssues.contains(code)) return FixCategory.style;
    if (_stringIssues.contains(code)) return FixCategory.strings;
    if (_typeIssues.contains(code)) return FixCategory.types;
    if (_docIssues.contains(code)) return FixCategory.docs;
    return null;
  }

  bool get isAutoFixable => category != null;

  static const _importIssues = {
    'unused_import',
    'duplicate_import',
    'unnecessary_import',
    'directives_ordering',
    'unused_shown_name',
  };

  static const _styleIssues = {
    'prefer_const_constructors',
    'prefer_const_declarations',
    'prefer_const_literals_to_create_immutables',
    'cascade_invocations',
    'unnecessary_this',
    'prefer_final_locals',
    'prefer_final_fields',
    'unnecessary_late',
    'unnecessary_new',
    'unnecessary_null_aware_assignments',
    'unnecessary_nullable_for_final_variable_declarations',
  };

  static const _stringIssues = {
    'prefer_single_quotes',
    'unnecessary_brace_in_string_interps',
    'prefer_interpolation_to_compose_strings',
    'unnecessary_string_interpolations',
    'unnecessary_string_escapes',
  };

  static const _typeIssues = {
    'omit_local_variable_types',
    'always_specify_types',
    'type_annotate_public_apis',
    'prefer_typing_uninitialized_variables',
  };

  static const _docIssues = {
    'public_member_api_docs',
    'slash_for_doc_comments',
  };
}

/// Fix result for a single issue
class FixResult {
  final AnalyzerIssue issue;
  final bool fixed;
  final String? error;

  FixResult({required this.issue, required this.fixed, this.error});
}

/// Main fixer class
class AnalyzerFixer {
  final String targetPath;
  final bool dryRun;
  final bool verbose;
  final Set<FixCategory> categories;

  AnalyzerFixer({
    required this.targetPath,
    required this.dryRun,
    required this.verbose,
    required this.categories,
  });

  /// Run dart analyze and get issues
  Future<List<AnalyzerIssue>> analyzeProject() async {
    final result = await Process.run(
      'dart',
      ['analyze', '--format=machine', targetPath],
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
        if (verbose) {
          stderr.writeln('Warning: Could not parse line: $line');
        }
      }
    }

    return issues;
  }

  /// Apply dart fix for auto-fixable issues
  Future<int> applyDartFix() async {
    final args = ['fix'];
    if (dryRun) {
      args.add('--dry-run');
    } else {
      args.add('--apply');
    }
    args.add(targetPath);

    if (verbose) {
      print('Running: dart ${args.join(' ')}');
    }

    final result = await Process.run('dart', args, runInShell: true);

    if (verbose) {
      print(result.stdout);
      if (result.stderr.toString().isNotEmpty) {
        stderr.write(result.stderr);
      }
    }

    return result.exitCode;
  }

  /// Fix import ordering in a file
  Future<FixResult> fixImportOrdering(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return FixResult(
          issue: AnalyzerIssue(
            severity: 'INFO',
            code: 'directives_ordering',
            message: 'File not found',
            filePath: filePath,
            line: 0,
            column: 0,
          ),
          fixed: false,
          error: 'File not found',
        );
      }

      final content = file.readAsStringSync();
      final lines = content.split('\n');

      // Extract imports
      final dartImports = <String>[];
      final packageImports = <String>[];
      final relativeImports = <String>[];
      final exports = <String>[];
      final parts = <String>[];

      final nonImportLines = <String>[];
      var inImportSection = false;
      var importSectionStart = -1;
      var importSectionEnd = -1;

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();

        if (line.startsWith('import ')) {
          if (!inImportSection) {
            inImportSection = true;
            importSectionStart = i;
          }
          importSectionEnd = i;

          if (line.contains("'dart:")) {
            dartImports.add(lines[i]);
          } else if (line.contains("'package:")) {
            packageImports.add(lines[i]);
          } else {
            relativeImports.add(lines[i]);
          }
        } else if (line.startsWith('export ')) {
          exports.add(lines[i]);
          if (inImportSection) importSectionEnd = i;
        } else if (line.startsWith('part ')) {
          parts.add(lines[i]);
          if (inImportSection) importSectionEnd = i;
        } else if (inImportSection && line.isEmpty) {
          // Allow empty lines in import section
          importSectionEnd = i;
        } else if (inImportSection && !line.isEmpty) {
          inImportSection = false;
        }
      }

      if (importSectionStart == -1) {
        return FixResult(
          issue: AnalyzerIssue(
            severity: 'INFO',
            code: 'directives_ordering',
            message: 'No imports found',
            filePath: filePath,
            line: 0,
            column: 0,
          ),
          fixed: false,
          error: 'No imports to reorder',
        );
      }

      // Sort each category
      dartImports.sort();
      packageImports.sort();
      relativeImports.sort();
      exports.sort();
      parts.sort();

      // Build new import section
      final newImportLines = <String>[];

      if (dartImports.isNotEmpty) {
        newImportLines.addAll(dartImports);
        if (packageImports.isNotEmpty || relativeImports.isNotEmpty) {
          newImportLines.add('');
        }
      }

      if (packageImports.isNotEmpty) {
        newImportLines.addAll(packageImports);
        if (relativeImports.isNotEmpty) {
          newImportLines.add('');
        }
      }

      if (relativeImports.isNotEmpty) {
        newImportLines.addAll(relativeImports);
      }

      if (exports.isNotEmpty) {
        if (newImportLines.isNotEmpty) newImportLines.add('');
        newImportLines.addAll(exports);
      }

      if (parts.isNotEmpty) {
        if (newImportLines.isNotEmpty) newImportLines.add('');
        newImportLines.addAll(parts);
      }

      // Reconstruct file
      final newLines = <String>[];
      newLines.addAll(lines.sublist(0, importSectionStart));
      newLines.addAll(newImportLines);
      newLines.addAll(lines.sublist(importSectionEnd + 1));

      final newContent = newLines.join('\n');

      if (!dryRun && newContent != content) {
        file.writeAsStringSync(newContent);
      }

      return FixResult(
        issue: AnalyzerIssue(
          severity: 'INFO',
          code: 'directives_ordering',
          message: 'Imports reordered',
          filePath: filePath,
          line: importSectionStart,
          column: 0,
        ),
        fixed: newContent != content,
      );
    } catch (e) {
      return FixResult(
        issue: AnalyzerIssue(
          severity: 'ERROR',
          code: 'directives_ordering',
          message: e.toString(),
          filePath: filePath,
          line: 0,
          column: 0,
        ),
        fixed: false,
        error: e.toString(),
      );
    }
  }

  /// Remove unused imports from a file
  Future<int> removeUnusedImports(List<AnalyzerIssue> issues) async {
    final fileIssues = <String, List<AnalyzerIssue>>{};

    for (final issue in issues) {
      if (issue.code != 'unused_import') continue;
      fileIssues.putIfAbsent(issue.filePath, () => []).add(issue);
    }

    var fixedCount = 0;

    for (final entry in fileIssues.entries) {
      final file = File(entry.key);
      if (!file.existsSync()) continue;

      final lines = file.readAsLinesSync();
      final linesToRemove = entry.value.map((i) => i.line - 1).toSet();

      final newLines = <String>[];
      for (var i = 0; i < lines.length; i++) {
        if (!linesToRemove.contains(i)) {
          newLines.add(lines[i]);
        } else {
          fixedCount++;
          if (verbose) {
            print('Removing unused import at ${entry.key}:${i + 1}');
          }
        }
      }

      if (!dryRun && linesToRemove.isNotEmpty) {
        file.writeAsStringSync(newLines.join('\n'));
      }
    }

    return fixedCount;
  }

  /// Run all fixes
  Future<Map<String, int>> runFixes() async {
    final results = <String, int>{
      'dart_fix': 0,
      'import_ordering': 0,
      'unused_imports': 0,
    };

    print('Analyzing project at: $targetPath');
    print(dryRun ? '(Dry run - no changes will be made)' : '');
    print('');

    // Get current issues
    final issues = await analyzeProject();
    final autoFixable = issues.where((i) => i.isAutoFixable).toList();

    print('Found ${issues.length} total issues');
    print('Auto-fixable: ${autoFixable.length}');
    print('');

    // Apply dart fix first (handles most style issues)
    if (categories.contains(FixCategory.style) ||
        categories.contains(FixCategory.strings)) {
      print('Running dart fix...');
      final exitCode = await applyDartFix();
      results['dart_fix'] = exitCode == 0 ? 1 : 0;
    }

    // Fix import issues
    if (categories.contains(FixCategory.imports)) {
      print('Fixing import issues...');

      // Remove unused imports
      final unusedImports =
          issues.where((i) => i.code == 'unused_import').toList();
      if (unusedImports.isNotEmpty) {
        results['unused_imports'] = await removeUnusedImports(issues);
      }

      // Fix import ordering
      final orderingIssues =
          issues.where((i) => i.code == 'directives_ordering').toList();
      final filesWithOrdering = orderingIssues.map((i) => i.filePath).toSet();

      for (final filePath in filesWithOrdering) {
        final result = await fixImportOrdering(filePath);
        if (result.fixed) {
          results['import_ordering'] = (results['import_ordering'] ?? 0) + 1;
        }
      }
    }

    return results;
  }
}

void printUsage() {
  print('''
dart-analyzer-fixer: Auto-fix Dart/Flutter analyzer issues

Usage: dart run fix_analyzer_issues.dart [options]

Options:
  --all          Fix all auto-fixable issues (default)
  --fix-imports  Fix import issues only (unused, ordering)
  --fix-style    Fix style issues only (const, cascades, this)
  --fix-strings  Fix string issues only (quotes, interpolation)
  --dry-run      Show what would be fixed without applying
  --path <dir>   Target directory (default: current)
  --verbose      Show detailed output
  --help         Show this help message

Examples:
  dart run fix_analyzer_issues.dart --all
  dart run fix_analyzer_issues.dart --fix-imports --dry-run
  dart run fix_analyzer_issues.dart --path ./lib --verbose
''');
}

Future<void> main(List<String> args) async {
  // Parse arguments
  var dryRun = false;
  var verbose = false;
  var targetPath = '.';
  final categories = <FixCategory>{};

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--help':
      case '-h':
        printUsage();
        return;
      case '--dry-run':
        dryRun = true;
        break;
      case '--verbose':
      case '-v':
        verbose = true;
        break;
      case '--path':
        if (i + 1 < args.length) {
          targetPath = args[++i];
        }
        break;
      case '--all':
        categories.addAll(FixCategory.values);
        break;
      case '--fix-imports':
        categories.add(FixCategory.imports);
        break;
      case '--fix-style':
        categories.add(FixCategory.style);
        break;
      case '--fix-strings':
        categories.add(FixCategory.strings);
        break;
      case '--fix-types':
        categories.add(FixCategory.types);
        break;
      case '--fix-docs':
        categories.add(FixCategory.docs);
        break;
    }
  }

  // Default to all if no categories specified
  if (categories.isEmpty) {
    categories.addAll(FixCategory.values);
  }

  // Verify path exists
  if (!Directory(targetPath).existsSync() && !File(targetPath).existsSync()) {
    stderr.writeln('Error: Path does not exist: $targetPath');
    exit(1);
  }

  final fixer = AnalyzerFixer(
    targetPath: targetPath,
    dryRun: dryRun,
    verbose: verbose,
    categories: categories,
  );

  try {
    final results = await fixer.runFixes();

    print('');
    print('=== Results ===');
    print('dart fix applied: ${results['dart_fix'] == 1 ? 'Yes' : 'No'}');
    print('Unused imports removed: ${results['unused_imports']}');
    print('Files with imports reordered: ${results['import_ordering']}');

    if (dryRun) {
      print('');
      print('(Dry run - no changes were made)');
    }
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
