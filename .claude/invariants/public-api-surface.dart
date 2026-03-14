// Invariant: Public API surface — no cross-package src/ imports
// Packages must import other nexus_store_* packages via barrel files only,
// never reaching into src/ directories.
// Enforces: .claude/rules/architecture.md

import 'dart:io';

void main() {
  final violations = <String>[];
  final packagesDir = Directory('packages');

  if (!packagesDir.existsSync()) {
    print('No packages/ directory found');
    exit(0);
  }

  // Match imports like: import 'package:nexus_store_foo/src/...'
  final srcImportPattern = RegExp(r"import\s+'package:(nexus_store\w*)/src/");

  for (final pkgDir in packagesDir.listSync().whereType<Directory>()) {
    final pkgName = pkgDir.path.split('/').last;
    final libDir = Directory('${pkgDir.path}/lib');
    if (!libDir.existsSync()) continue;

    for (final file in libDir.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') || file.path.endsWith('.g.dart')) {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final match = srcImportPattern.firstMatch(lines[i]);
        if (match != null) {
          final importedPkg = match.group(1)!;
          // Allow a package to import its own src/
          if (importedPkg == pkgName) continue;
          violations.add(
            '${file.path}:${i + 1}: '
            '$pkgName imports $importedPkg/src/ — use barrel file import instead',
          );
        }
      }
    }
  }

  // Also check test/ directories for cross-package src/ imports
  for (final pkgDir in packagesDir.listSync().whereType<Directory>()) {
    final pkgName = pkgDir.path.split('/').last;
    final testDir = Directory('${pkgDir.path}/test');
    if (!testDir.existsSync()) continue;

    for (final file in testDir.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') || file.path.endsWith('.g.dart')) {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final match = srcImportPattern.firstMatch(lines[i]);
        if (match != null) {
          final importedPkg = match.group(1)!;
          if (importedPkg == pkgName) continue;
          violations.add(
            '${file.path}:${i + 1}: '
            '$pkgName test imports $importedPkg/src/ — use barrel file import instead',
          );
        }
      }
    }
  }

  if (violations.isEmpty) {
    print('public-api-surface: PASS (no cross-package src/ imports)');
    exit(0);
  }

  print('public-api-surface: FAIL (${violations.length} violations)');
  for (final v in violations) {
    print('  $v');
  }
  exit(1);
}
