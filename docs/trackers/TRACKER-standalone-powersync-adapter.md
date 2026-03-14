# TRACKER: Standalone PowerSync Adapter

## Status: COMPLETE

## Overview
Enhance `nexus_store_powersync_adapter` to be a "batteries included" solution that handles all PowerSync infrastructure internally (schema, connector, database lifecycle, sync rules generation), eliminating the need for separate manual configuration files.

## New API

```dart
final backend = PowerSyncBackend<User, String>.withSupabase(
  supabase: Supabase.instance.client,
  powerSyncUrl: 'https://xxx.powersync.co',
  tableName: 'users',
  columns: [
    PSColumn.text('name'),
    PSColumn.text('email'),
    PSColumn.integer('age'),
  ],
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,
);

await backend.initialize(); // Handles everything internally
```

## Tasks

### Phase 1: Column Definition API
- [x] Create `PSColumn` class with `.text()`, `.integer()`, `.real()` factories
- [x] Create `PSTableDefinition` to hold table name + columns
- [x] Add schema generation from column definitions

### Phase 2: Built-in Supabase Connector
- [x] Create `SupabasePowerSyncConnector` class
- [x] Implement `fetchCredentials()` using Supabase session
- [x] Implement `uploadData()` routing to Supabase PostgREST
- [x] Handle upsert/update/delete operations

### Phase 3: Database Lifecycle Management
- [x] Create `PowerSyncBackendConfig` for configuration
- [x] Add `PowerSyncBackend.withSupabase()` factory constructor
- [x] Implement internal `PowerSyncDatabase` creation and initialization
- [x] Handle `db.connect(connector)` internally
- [x] Add `dispose()` method for cleanup
- [x] Support custom db path or auto-generate

### Phase 4: Multi-Table Support
- [x] Create `PowerSyncManager` for apps with multiple tables
- [x] Share single `PowerSyncDatabase` across multiple backends
- [x] Provide registry pattern for table definitions (PSTableConfig)

### Phase 5: Testing & Documentation
- [x] Add unit tests for new components (102 tests passing)
- [x] Update package README with new API
- [x] Update nexus-store skill documentation

### Phase 6: Sync Rules Generation
- [x] Create `PSSyncRules` container class
- [x] Create `PSBucket` class with `.global()`, `.userScoped()`, `.parameterized()` factories
- [x] Create `PSQuery` class for SELECT statements
- [x] Implement `toYaml()` method for YAML generation
- [x] Add `saveToFile()` helper method

## Files

### New Files
- [x] `lib/src/column_definition.dart` - PSColumn and PSTableDefinition
- [x] `lib/src/supabase_connector.dart` - Built-in Supabase connector
- [x] `lib/src/powersync_backend_factory.dart` - PowerSyncBackendConfig
- [x] `lib/src/powersync_manager.dart` - Multi-table manager
- [x] `lib/src/ps_table_config.dart` - Table configuration class
- [x] `lib/src/sync_rules/sync_rules.dart` - Barrel export
- [x] `lib/src/sync_rules/ps_bucket.dart` - PSBucket definitions
- [x] `lib/src/sync_rules/ps_query.dart` - PSQuery class
- [x] `lib/src/sync_rules/ps_sync_rules.dart` - PSSyncRules with YAML generation

### Modified Files
- [x] `lib/src/powersync_backend.dart` - Add `.withSupabase()` factory and `dispose()`
- [x] `lib/nexus_store_powersync_adapter.dart` - Export new classes
- [x] `pubspec.yaml` - Added supabase dependency
- [x] `README.md` - Update documentation

## Dependencies Added

```yaml
dependencies:
  supabase: ^2.8.0  # Added (using supabase instead of supabase_flutter for pure Dart)
```

## Breaking Changes
- Remove `PowerSyncBackend(db: ...)` constructor
- New API: `PowerSyncBackend.withSupabase(...)` handles everything
- Single developer using package - no migration concerns

## Out of Scope
- Auto-deployment of sync rules (manual via PowerSync Dashboard)

## Notes
- No backward compatibility needed - single developer using package
- Sync rules YAML is generated but deployed manually
- Native FFI testing limitations apply (coverage exclusions)
- Using `supabase` package instead of `supabase_flutter` for pure Dart compatibility

## Test Summary
- 102 unit tests passing
- Column definition: 14 tests
- Supabase connector: 8 tests
- Backend config: 5 tests
- withSupabase factory: 9 tests
- Sync rules (PSQuery): 11 tests
- Sync rules (PSBucket): 19 tests
- Sync rules (PSSyncRules): 13 tests
- PSTableConfig: 11 tests
- PowerSyncManager: 12 tests

## History
- 2026-01-09: Tracker created, plan approved
- 2026-01-09: Phase 1 complete - PSColumn, PSTableDefinition implemented with TDD
- 2026-01-09: Phase 2 complete - SupabasePowerSyncConnector with auth/data providers
- 2026-01-09: Phase 3 complete - withSupabase() factory, initialize, dispose() methods
- 2026-01-09: Phase 6 complete - PSQuery, PSBucket, PSSyncRules with YAML generation (43 new tests)
- 2026-01-09: Phase 4 complete - PowerSyncManager, PSTableConfig for multi-table support (23 new tests)
- 2026-01-09: Phase 5 complete - README and nexus-store skill documentation updated
