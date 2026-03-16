// Invariant: Interface naming convention
// Interfaces must use InterfaceXxx naming, not IXxx
// Enforces: .claude/rules/architecture.md
//
// Self-test: run with --self-test to verify detection of IXxx violations.

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

/// Self-test: create a temporary file with IXxx naming, verify detection.
void _runSelfTest() {
  print('interface-naming: running self-test...');

  final tmpDir = Directory.systemTemp.createTempSync('iface_naming_test_');
  final pkgDir = Directory('${tmpDir.path}/packages/test_pkg')
    ..createSync(recursive: true);
  final libDir = Directory('${pkgDir.path}/lib')..createSync(recursive: true);

  // Create a file with IXxx naming violation
  File('${libDir.path}/bad_interface.dart').writeAsStringSync(
    'abstract class IRepository {\n  void save();\n}\n',
  );

  // Create a file with correct InterfaceXxx naming (no violation)
  File('${libDir.path}/good_interface.dart').writeAsStringSync(
    'abstract class InterfaceRepository {\n  void save();\n}\n',
  );

  // Run detection
  final pattern = RegExp(r'abstract\s+(interface\s+)?class\s+I([A-Z][a-z])');
  final badFile = File('${libDir.path}/bad_interface.dart');
  final badLines = badFile.readAsLinesSync();
  var foundViolation = false;
  for (final line in badLines) {
    if (pattern.hasMatch(line)) foundViolation = true;
  }

  final goodFile = File('${libDir.path}/good_interface.dart');
  final goodLines = goodFile.readAsLinesSync();
  var falsePositive = false;
  for (final line in goodLines) {
    if (pattern.hasMatch(line)) falsePositive = true;
  }

  // Clean up
  tmpDir.deleteSync(recursive: true);

  if (foundViolation && !falsePositive) {
    print(
      'interface-naming: SELF-TEST PASS '
      '(detected IRepository violation, no false positive on InterfaceRepository)',
    );
    exit(0);
  } else {
    print(
      'interface-naming: SELF-TEST FAIL '
      '(foundViolation=$foundViolation, falsePositive=$falsePositive)',
    );
    exit(1);
  }
}
