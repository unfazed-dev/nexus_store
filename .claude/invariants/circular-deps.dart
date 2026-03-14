// Invariant: Circular dependency detection
// Parses pubspec.yaml files from all packages/, builds a dependency graph
// of nexus_store_* packages, and detects cycles.
// Enforces: .claude/rules/architecture.md

import 'dart:io';

void main() {
  final packagesDir = Directory('packages');

  if (!packagesDir.existsSync()) {
    print('No packages/ directory found');
    exit(0);
  }

  // Build adjacency list: package -> [dependencies]
  final graph = <String, List<String>>{};
  final allPackages = <String>{};

  for (final pkgDir in packagesDir.listSync().whereType<Directory>()) {
    final pkgName = pkgDir.path.split('/').last;
    if (!pkgName.startsWith('nexus_store')) continue;
    allPackages.add(pkgName);

    final pubspec = File('${pkgDir.path}/pubspec.yaml');
    if (!pubspec.existsSync()) continue;

    final deps = _extractNexusDeps(pubspec.readAsStringSync());
    graph[pkgName] = deps;
  }

  // Detect cycles using DFS
  final cycles = <List<String>>[];
  final visited = <String>{};
  final inStack = <String>{};
  final path = <String>[];

  void dfs(String node) {
    if (inStack.contains(node)) {
      // Found a cycle — extract it
      final cycleStart = path.indexOf(node);
      if (cycleStart >= 0) {
        cycles.add([...path.sublist(cycleStart), node]);
      }
      return;
    }
    if (visited.contains(node)) return;

    visited.add(node);
    inStack.add(node);
    path.add(node);

    for (final dep in (graph[node] ?? [])) {
      if (allPackages.contains(dep)) {
        dfs(dep);
      }
    }

    path.removeLast();
    inStack.remove(node);
  }

  for (final pkg in allPackages) {
    dfs(pkg);
  }

  if (cycles.isEmpty) {
    print(
        'circular-deps: PASS (no circular dependencies among ${allPackages.length} packages)',);
    exit(0);
  }

  print('circular-deps: FAIL (${cycles.length} cycles detected)');
  for (final cycle in cycles) {
    print('  ${cycle.join(' -> ')}');
  }
  exit(1);
}

/// Simple YAML parser to extract nexus_store_* dependencies.
/// Handles both `dependencies:` and `dev_dependencies:` sections.
List<String> _extractNexusDeps(String yaml) {
  final deps = <String>[];
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

    // Match dependency lines like "  nexus_store_foo:" or "  nexus_store_foo: ^1.0.0"
    final match = RegExp(r'^\s{2}(nexus_store\w*):').firstMatch(line);
    if (match != null) {
      deps.add(match.group(1)!);
    }
  }

  return deps;
}
