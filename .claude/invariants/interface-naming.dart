// Invariant: Interface naming convention
// Interfaces must use InterfaceXxx naming, not IXxx
// Enforces: .claude/rules/architecture.md

import 'dart:io';

void main() {
  final violations = <String>[];
  final packagesDir = Directory('packages');

  if (!packagesDir.existsSync()) {
    print('No packages/ directory found');
    exit(0);
  }

  // Pattern: abstract class IFoo or abstract interface class IFoo
  // where I is followed by an uppercase letter (to avoid false positives like "Icon")
  final pattern = RegExp(r'abstract\s+(interface\s+)?class\s+I([A-Z][a-z])');

  for (final pkgDir in packagesDir.listSync().whereType<Directory>()) {
    final libDir = Directory('${pkgDir.path}/lib');
    if (!libDir.existsSync()) continue;

    for (final file in libDir.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') || file.path.endsWith('.g.dart')) {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final match = pattern.firstMatch(lines[i]);
        if (match != null) {
          final className = lines[i]
              .substring(lines[i].indexOf(RegExp('I[A-Z]')))
              .split(RegExp(r'[\s{<]'))
              .first;
          violations.add(
            '${file.path}:${i + 1}: '
            'Interface "$className" uses IXxx naming — rename to Interface${className.substring(1)}',
          );
        }
      }
    }
  }

  if (violations.isEmpty) {
    print('interface-naming: PASS (no IXxx naming violations)');
    exit(0);
  }

  print('interface-naming: FAIL (${violations.length} violations)');
  for (final v in violations) {
    print('  $v');
  }
  exit(1);
}
