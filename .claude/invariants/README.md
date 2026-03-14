# Invariants

Mechanical constraints that enforce architectural rules by scanning source files. Each invariant is a standalone Dart script that exits 0 on success or prints violations and exits 1 on failure.

## Running

```bash
# Run all invariants
for f in .claude/invariants/*.dart; do dart run "$f"; done

# Run a specific invariant
dart run .claude/invariants/layer-deps.dart
```

## Adding a New Invariant

1. Create a `.dart` file in this directory
2. Scan relevant source files for violations
3. Print actionable errors: `file:line — violation description — fix instruction`
4. Exit 0 if clean, exit 1 if violations found
5. Test: introduce a deliberate violation, confirm it's caught, revert

## Current Invariants

| File | Rule | Checks |
|------|------|--------|
| `layer-deps.dart` | Package dependency direction | core cannot import adapters/bindings/generators/widgets; adapters cannot import other adapters/bindings/generators; bindings cannot import other bindings/generators; generators cannot import adapters/bindings/widgets |
| `interface-naming.dart` | InterfaceXxx naming | No `IXxx` abstract class naming — use `InterfaceXxx` |
| `public-api-surface.dart` | Barrel file imports only | No cross-package `src/` imports — packages must use barrel files |
| `circular-deps.dart` | No circular dependencies | Parses pubspec.yaml files, builds dependency graph, detects cycles among nexus_store_* packages |
| `generated-file-check.dart` | No generated files in git | Verifies `.g.dart` files are not tracked by git |

## Error Message Format

```
packages/nexus_store/lib/src/store.dart:42
  VIOLATION: nexus_store imports forbidden package nexus_store_drift_adapter
  FIX: Core package must not depend on adapters — use interface abstractions
  RULE: .claude/rules/architecture.md
```
