// Invariant: No envied or .env usage in library packages
// Library packages must not use envied or .env files — all configuration
// is provided via constructor injection.
// Enforces: .claude/rules/environment.md
//
// Self-test: run with --self-test to verify detection of envied violations.

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

    // Check 1: envied in pubspec.yaml dependencies
    final pubspec = File('${pkgDir.path}/pubspec.yaml');
    if (pubspec.existsSync()) {
      final content = pubspec.readAsStringSync();
      if (_hasEnviedDependency(content)) {
        violations.add(
          '${pubspec.path}: $pkgName has envied dependency — '
          'use constructor injection instead',
        );
      }
    }

    // Check 2: .env files in the package
    for (final entity in pkgDir.listSync()) {
      if (entity is File) {
        final name = entity.path.split('/').last;
        if (name == '.env' ||
            name == '.env.local' ||
            name == '.env.development' ||
            name == '.env.production' ||
            name == '.env.example' ||
            name == '.env.test') {
          violations.add(
            '${entity.path}: $pkgName contains $name file — '
            'library packages must not use .env files',
          );
        }
      }
    }

    // Check 3: envied imports in Dart files
    final libDir = Directory('${pkgDir.path}/lib');
    if (libDir.existsSync()) {
      for (final file in libDir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart') || file.path.endsWith('.g.dart')) {
          continue;
        }
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].contains('package:envied/') ||
              lines[i].contains('package:envied_generator/')) {
            violations.add(
              '${file.path}:${i + 1}: imports envied — '
              'use constructor injection instead',
            );
          }
        }
      }
    }

    // Check 4: @Envied annotation usage in Dart files
    if (libDir.existsSync()) {
      for (final file in libDir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart') || file.path.endsWith('.g.dart')) {
          continue;
        }
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (RegExp(r'@Envied\b').hasMatch(lines[i])) {
            violations.add(
              '${file.path}:${i + 1}: uses @Envied annotation — '
              'use constructor injection instead',
            );
          }
        }
      }
    }
  }

  if (violations.isEmpty) {
    print('no-envied: PASS (no envied or .env usage found)');
    exit(0);
  }

  print('no-envied: FAIL (${violations.length} violations)');
  for (final v in violations) {
    print('  $v');
  }
  exit(1);
}

/// Check if pubspec.yaml has envied in dependencies or dev_dependencies.
bool _hasEnviedDependency(String yaml) {
  final lines = yaml.split('\n');
  var inDepsSection = false;

  for (final line in lines) {
    // Detect top-level section headers
    if (RegExp(r'^\w').hasMatch(line)) {
      inDepsSection = line.startsWith('dependencies:') ||
          line.startsWith('dev_dependencies:');
      continue;
    }

    if (!inDepsSection) continue;

    // Match envied or envied_generator dependency
    if (RegExp(r'^\s{2}envied(_generator)?:').hasMatch(line)) {
      return true;
    }
  }

  return false;
}

/// Self-test: create temporary package with envied violations, verify detection.
void _runSelfTest() {
  print('no-envied: running self-test...');

  final tmpDir = Directory.systemTemp.createTempSync('envied_test_');
  final pkgDir = Directory('${tmpDir.path}/packages/test_pkg')
    ..createSync(recursive: true);
  final libDir = Directory('${pkgDir.path}/lib')..createSync(recursive: true);

  // Create pubspec with envied dependency (violation)
  File('${pkgDir.path}/pubspec.yaml').writeAsStringSync('''
name: test_pkg
version: 1.0.0

dependencies:
  envied: ^0.5.0

dev_dependencies:
  envied_generator: ^0.5.0
''');

  // Create .env file (violation)
  File('${pkgDir.path}/.env').writeAsStringSync('API_KEY=secret\n');

  // Create Dart file with envied import (violation)
  File('${libDir.path}/config.dart').writeAsStringSync('''
import 'package:envied/envied.dart';

@Envied()
abstract class Env {
  @EnviedField(varName: 'API_KEY')
  static const String apiKey = _Env.apiKey;
}
''');

  // Run checks
  var violationCount = 0;

  // Check pubspec
  final pubContent = File('${pkgDir.path}/pubspec.yaml').readAsStringSync();
  if (_hasEnviedDependency(pubContent)) violationCount++;

  // Check .env file
  for (final entity in pkgDir.listSync()) {
    if (entity is File && entity.path.split('/').last == '.env') {
      violationCount++;
    }
  }

  // Check Dart imports
  final configFile = File('${libDir.path}/config.dart');
  final lines = configFile.readAsLinesSync();
  for (final line in lines) {
    if (line.contains('package:envied/')) violationCount++;
    if (RegExp(r'@Envied\b').hasMatch(line)) violationCount++;
  }

  // Clean up
  tmpDir.deleteSync(recursive: true);

  if (violationCount >= 3) {
    print(
        'no-envied: SELF-TEST PASS (detected $violationCount violations in test fixture)',);
    exit(0);
  } else {
    print(
        'no-envied: SELF-TEST FAIL (expected >=3 violations, got $violationCount)',);
    exit(1);
  }
}
