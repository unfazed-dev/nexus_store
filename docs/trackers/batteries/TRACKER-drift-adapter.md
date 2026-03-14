# TRACKER: Drift Adapter Batteries Included

## Status: COMPLETED

## Overview

Add batteries-included features to `nexus_store_drift_adapter` including type-safe column definitions, table configuration bundling, factory methods, and multi-table manager coordination.

## Spec Reference

- [SPEC-batteries-included-enhancements.md](../../specs/SPEC-batteries-included-enhancements.md)
- Implements: REQ-001, REQ-002, REQ-003, REQ-004

## Skills to Use

- `/tdd-flutter` - Test-Driven Development for all implementations
- `/commit-helper` - Semantic commit messages for all changes

## Related Trackers

- [Main Tracker](TRACKER-batteries-main.md)

## Tasks

### Phase 1: Column Definitions
- [x] Create `DriftColumn` class with factory methods
  - [x] `DriftColumn.text()`
  - [x] `DriftColumn.integer()`
  - [x] `DriftColumn.real()`
  - [x] `DriftColumn.boolean()`
  - [x] `DriftColumn.dateTime()`
  - [x] `DriftColumn.blob()`
- [x] Implement `toSqlDefinition()` method
- [x] Add validation for column names

### Phase 2: Table Configuration
- [x] Create `DriftTableConfig<T, ID>` class
- [x] Create `DriftTableDefinition` class
- [x] Create `DriftIndex` class
- [x] Implement `toTableDefinition()` method
- [x] Add field mapping support

### Phase 3: Factory Method
- [x] Add `DriftBackend.withDatabase()` factory
- [x] Handle database path generation
- [x] Implement automatic schema creation
- [x] Wire up lifecycle management

### Phase 4: Manager Class
- [x] Create `DriftManager` class
- [x] Implement `DriftManager.withDatabase()` factory
- [x] Implement `initialize()` method
- [x] Implement `getBackend(tableName)` method (returns dynamic backend)
- [x] Implement `dispose()` method
- [x] Add shared database connection management

### Phase 5: Integration
- [x] Update barrel export (`lib/nexus_store_drift_adapter.dart`)
- [x] Add unit tests for column definitions (27 tests)
- [x] Add unit tests for table config (15 tests)
- [x] Add unit tests for factory method (7 tests)
- [x] Add unit tests for manager (8 tests)
- [x] Update README with examples

## Files

### New Files
| File | Description | Status |
|------|-------------|--------|
| `lib/src/drift_column.dart` | Type-safe column definitions | Created |
| `lib/src/drift_table_config.dart` | Table configuration bundling | Created |
| `lib/src/drift_manager.dart` | Multi-table coordination | Created |

### Modified Files
| File | Changes | Status |
|------|---------|--------|
| `lib/src/drift_backend.dart` | Add `withDatabase()` factory | Modified |
| `lib/nexus_store_drift_adapter.dart` | Export new classes | Modified |
| `README.md` | Document batteries-included usage | Completed |

### Test Files
| File | Description | Status |
|------|-------------|--------|
| `test/unit/drift_column_test.dart` | Column definition tests (27 tests) | Created |
| `test/unit/drift_table_config_test.dart` | Config tests (15 tests) | Created |
| `test/unit/drift_backend_factory_test.dart` | Factory method tests (7 tests) | Created |
| `test/unit/drift_manager_test.dart` | Manager tests (8 tests) | Created |

## Dependencies

- drift: ^2.0.0 (existing)
- sqlite3_flutter_libs: any (existing)

## API Design

```dart
// Column definitions
final columns = [
  DriftColumn.text('name'),
  DriftColumn.text('email'),
  DriftColumn.integer('age', nullable: true),
];

// Single table factory
final backend = DriftBackend<User, String>.withDatabase(
  tableName: 'users',
  columns: columns,
  getId: (u) => u.id,
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
);
await backend.initialize();

// Multi-table manager
final manager = DriftManager.withDatabase(
  tables: [
    DriftTableConfig<User, String>(
      tableName: 'users',
      columns: [...],
      fromJson: User.fromJson,
      toJson: (u) => u.toJson(),
      getId: (u) => u.id,
    ),
    DriftTableConfig<Post, String>(...),
  ],
);
await manager.initialize();
final userBackend = manager.getBackend('users');
```

## Implementation Notes

- DriftColumn provides type-safe factory methods for SQLite column types
- DriftTableConfig bundles table metadata with serialization functions
- DriftManager coordinates multiple tables with a shared database connection
- Dynamic type wrappers bypass Dart's function type contravariance for manager
- All 57 unit tests passing

## Notes

- Drift uses compile-time code generation for type safety
- This enhancement provides runtime flexibility for dynamic schemas
- Complement existing Drift patterns, don't replace them

## History

| Date | Update |
|------|--------|
| 2026-01-10 | Tracker created |
| 2026-01-10 | Phase 1-4 completed (all tests passing) |
| 2026-01-11 | README documentation updated |
