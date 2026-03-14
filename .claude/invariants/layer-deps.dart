// Invariant: Package dependency direction
// core -> adapters -> bindings -> generators (no reverse, no lateral)
// Enforces: .claude/rules/architecture.md

import 'dart:io';

// Package categories
final _core = ['nexus_store'];
final _adapters = [
  'nexus_store_drift_adapter',
  'nexus_store_powersync_adapter',
  'nexus_store_supabase_adapter',
  'nexus_store_brick_adapter',
  'nexus_store_crdt_adapter',
];
final _bindings = [
  'nexus_store_bloc_binding',
  'nexus_store_riverpod_binding',
  'nexus_store_signals_binding',
];
final _generators = [
  'nexus_store_generator',
  'nexus_store_entity_generator',
  'nexus_store_riverpod_generator',
];
final _widgets = ['nexus_store_flutter_widgets'];

void main() {
  final violations = <String>[];
  final packagesDir = Directory('packages');

  if (!packagesDir.existsSync()) {
    print('No packages/ directory found');
    exit(0);
  }

  for (final pkgDir in packagesDir.listSync().whereType<Directory>()) {
    final pkgName = pkgDir.path.split('/').last;
    final libDir = Directory('${pkgDir.path}/lib');
    if (!libDir.existsSync()) continue;

    final forbidden = _getForbiddenImports(pkgName);
    if (forbidden.isEmpty) continue;

    for (final file in libDir.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') || file.path.endsWith('.g.dart')) {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!line.trimLeft().startsWith('import ')) continue;
        for (final pkg in forbidden) {
          if (line.contains("'package:$pkg/") ||
              line.contains("'package:$pkg'")) {
            violations.add(
              '${file.path}:${i + 1}: $pkgName imports forbidden package $pkg',
            );
          }
        }
      }
    }
  }

  if (violations.isEmpty) {
    print('layer-deps: PASS (no dependency direction violations)');
    exit(0);
  }

  print('layer-deps: FAIL (${violations.length} violations)');
  for (final v in violations) {
    print('  $v');
  }
  exit(1);
}

List<String> _getForbiddenImports(String pkgName) {
  if (_core.contains(pkgName)) {
    return [..._adapters, ..._bindings, ..._generators, ..._widgets];
  }
  if (_adapters.contains(pkgName)) {
    return [
      ..._adapters.where((a) => a != pkgName),
      ..._bindings,
      ..._generators,
    ];
  }
  if (_bindings.contains(pkgName)) {
    return [..._bindings.where((b) => b != pkgName), ..._generators];
  }
  if (_generators.contains(pkgName)) {
    // nexus_store_riverpod_generator legitimately depends on the binding
    // package because it generates code referencing binding types
    final allowedBindings = <String>[];
    if (pkgName == 'nexus_store_riverpod_generator') {
      allowedBindings.add('nexus_store_riverpod_binding');
    }
    return [
      ..._adapters,
      ..._bindings.where((b) => !allowedBindings.contains(b)),
      ..._widgets,
    ];
  }
  return [];
}
