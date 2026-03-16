// Invariant: Barrel export completeness
// Validates every public class/mixin/enum/extension in a package's lib/src/
// is exported via the barrel file lib/<package>.dart (directly or transitively).
// Enforces: .claude/rules/architecture.md
//
// Self-test: run with --self-test to verify detection of missing exports.

import 'dart:io';

void main(List<String> args) {
  final selfTest = args.contains('--self-test');

  if (selfTest) {
    _runSelfTest();
    return;
  }

  final violations = <String>[];
  final packagesDir = Directory('packages');

  if (!packagesDir.existsSync()) {
    print('No packages/ directory found');
    exit(0);
  }

  for (final pkgDir in packagesDir.listSync().whereType<Directory>()) {
    final pkgName = pkgDir.path.split('/').last;
    final barrelFile = File('${pkgDir.path}/lib/$pkgName.dart');
    final srcDir = Directory('${pkgDir.path}/lib/src');

    if (!barrelFile.existsSync() || !srcDir.existsSync()) continue;

    // Resolve the full set of transitively exported files from the barrel
    final libPath = '${pkgDir.path}/lib';
    final exportedSrcFiles = _resolveTransitiveExports(barrelFile, libPath);

    // Find all dart files in src/
    final srcFiles = _findDartFiles(srcDir);

    for (final srcFile in srcFiles) {
      final relativePath = srcFile.replaceFirst('$libPath/', '');

      if (!exportedSrcFiles.contains(relativePath)) {
        // Check if file has any public declarations
        final file = File(srcFile);
        final publicDecls = _findPublicDeclarations(file);
        if (publicDecls.isNotEmpty) {
          for (final decl in publicDecls) {
            violations.add(
              '$srcFile: public $decl not exported via $pkgName.dart',
            );
          }
        }
      }
    }
  }

  if (violations.isEmpty) {
    print(
      'barrel-export-completeness: PASS (all public declarations exported)',
    );
    exit(0);
  }

  print(
    'barrel-export-completeness: FAIL (${violations.length} missing exports)',
  );
  for (final v in violations) {
    print('  $v');
  }
  exit(1);
}

/// Resolve all src/ files that are transitively exported from the barrel file.
/// Follows export chains: barrel -> intermediate.dart -> leaf.dart
Set<String> _resolveTransitiveExports(File startFile, String libPath) {
  final resolved = <String>{};
  final visited = <String>{};
  final queue = <String>[startFile.path];

  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    if (visited.contains(current)) continue;
    visited.add(current);

    final file = File(current);
    if (!file.existsSync()) continue;

    final content = file.readAsStringSync();
    final exports = _extractExports(content);

    for (final exportPath in exports) {
      // Resolve relative export path against the current file's directory
      final currentDir = current.substring(0, current.lastIndexOf('/'));
      final resolvedPath = _resolvePath(currentDir, exportPath);

      // Only track src/ files
      final relativePath = resolvedPath.replaceFirst('$libPath/', '');
      if (relativePath.startsWith('src/')) {
        resolved.add(relativePath);
        // Follow this file's exports too
        queue.add(resolvedPath);
      }
    }
  }

  return resolved;
}

/// Extract export paths from a Dart file's content.
List<String> _extractExports(String content) {
  final exports = <String>[];
  final pattern = RegExp(r'''export\s+['"]([^'"]+)['"]''');
  for (final match in pattern.allMatches(content)) {
    final path = match.group(1)!;
    // Skip package: exports (cross-package)
    if (!path.startsWith('package:')) {
      exports.add(path);
    }
  }
  return exports;
}

/// Resolve a relative path against a directory.
String _resolvePath(String dir, String relativePath) {
  final parts = '$dir/$relativePath'.split('/');
  final resolved = <String>[];
  for (final part in parts) {
    if (part == '..') {
      if (resolved.isNotEmpty) resolved.removeLast();
    } else if (part != '.') {
      resolved.add(part);
    }
  }
  return resolved.join('/');
}

/// Find all .dart files in src/, excluding generated files.
List<String> _findDartFiles(Directory srcDir) {
  final files = <String>[];
  for (final entity in srcDir.listSync(recursive: true)) {
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        !entity.path.endsWith('.g.dart') &&
        !entity.path.endsWith('.freezed.dart')) {
      files.add(entity.path);
    }
  }
  files.sort();
  return files;
}

/// Find public class, mixin, enum, extension, and typedef declarations.
/// Public = no underscore prefix on the name.
List<String> _findPublicDeclarations(File file) {
  final decls = <String>[];
  final lines = file.readAsLinesSync();
  final pattern = RegExp(
    r'^(?:abstract\s+)?(?:base\s+)?(?:sealed\s+)?(?:final\s+)?(?:interface\s+)?'
    r'(class|mixin|enum|extension|typedef)\s+(\w+)',
  );

  for (final line in lines) {
    final match = pattern.firstMatch(line);
    if (match != null) {
      final kind = match.group(1)!;
      final name = match.group(2)!;
      // Skip private declarations (underscore prefix)
      if (!name.startsWith('_')) {
        // Skip extension without a name (extension on Type { ... })
        if (kind == 'extension' && name == 'on') continue;
        decls.add('$kind $name');
      }
    }
  }

  return decls;
}

/// Self-test: create a temporary package with both exported (via chain) and
/// unexported files, verify the unexported one is detected.
void _runSelfTest() {
  print('barrel-export-completeness: running self-test...');

  final tmpDir = Directory.systemTemp.createTempSync('barrel_test_');
  final pkgDir = Directory('${tmpDir.path}/packages/test_pkg')
    ..createSync(recursive: true);
  final libDir = Directory('${pkgDir.path}/lib')..createSync(recursive: true);
  final srcDir = Directory('${pkgDir.path}/lib/src')
    ..createSync(recursive: true);
  final subDir = Directory('${pkgDir.path}/lib/src/sub')
    ..createSync(recursive: true);

  // Barrel file exports an intermediate file
  File('${libDir.path}/test_pkg.dart').writeAsStringSync(
    "export 'src/sub/sub.dart';\n",
  );

  // Intermediate file re-exports a leaf
  File('${subDir.path}/sub.dart').writeAsStringSync(
    "export 'exported_leaf.dart';\n",
  );

  // Exported leaf (transitively exported via chain)
  File('${subDir.path}/exported_leaf.dart').writeAsStringSync(
    'class ExportedLeaf {}\n',
  );

  // Non-exported file with a public class (violation)
  File('${srcDir.path}/hidden.dart').writeAsStringSync(
    'class HiddenClass {}\n',
  );

  // Run detection
  final barrelFile = File('${libDir.path}/test_pkg.dart');
  final libPath = '${pkgDir.path}/lib';
  final exportedFiles = _resolveTransitiveExports(barrelFile, libPath);

  final hiddenExported = exportedFiles.contains('src/hidden.dart');
  final leafExported = exportedFiles.contains('src/sub/exported_leaf.dart');
  final hiddenDecls =
      _findPublicDeclarations(File('${srcDir.path}/hidden.dart'));

  // Clean up
  tmpDir.deleteSync(recursive: true);

  if (!hiddenExported && leafExported && hiddenDecls.isNotEmpty) {
    print(
      'barrel-export-completeness: SELF-TEST PASS '
      '(detected missing export for HiddenClass, correctly resolved transitive export for ExportedLeaf)',
    );
    exit(0);
  } else {
    print(
      'barrel-export-completeness: SELF-TEST FAIL '
      '(hiddenExported=$hiddenExported, leafExported=$leafExported, '
      'hiddenDecls=${hiddenDecls.length})',
    );
    exit(1);
  }
}
