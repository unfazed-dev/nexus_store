# SPEC: Batteries Included Enhancements for nexus_store Adapters

## Metadata

- **Version**: 1.0.0
- **Status**: Approved
- **Author**: Claude (AI-assisted)
- **Date**: 2026-01-10
- **Packages**: 7 (drift, supabase, crdt, brick adapters + riverpod, signals, bloc bindings)

---

## Package Overview

**Problem Statement**: The nexus_store monorepo contains 13 packages for data persistence and state management in Flutter/Dart. While all packages are fully implemented, only `nexus_store_powersync_adapter` follows a "batteries included" pattern that significantly reduces developer boilerplate. Other adapters require manual setup of database connections, schema definitions, and lifecycle management.

**Target Users**: Flutter/Dart developers building apps with nexus_store who want minimal configuration and maximum productivity.

**Package Type**: Enhancement to existing Pure Dart and Flutter packages.

---

## Requirements

### REQ-001: Type-Safe Column Definitions

**User Story**:
As a developer
I want to define table schemas using type-safe factory methods
So that I can avoid string-based configuration errors and get IDE autocomplete.

**Acceptance Criteria**:
- GIVEN a developer needs to define a table schema
  WHEN they use `XXXColumn.text('name')` factory methods
  THEN the column is created with correct SQL type and nullability

- GIVEN a column definition exists
  WHEN `toSqlDefinition()` is called
  THEN it returns valid SQL column definition string

- GIVEN invalid parameters (empty name, reserved keywords)
  WHEN column factory is called
  THEN an `ArgumentError` is thrown with descriptive message

**Priority**: Must Have

---

### REQ-002: Table Configuration Bundling

**User Story**:
As a developer
I want to bundle table name, columns, and serialization functions in one object
So that configuration is centralized and type-safe.

**Acceptance Criteria**:
- GIVEN a `TableConfig<T, ID>` with valid parameters
  WHEN `toTableDefinition()` is called
  THEN it returns a schema-ready definition

- GIVEN a `TableConfig` with field mapping
  WHEN serialization occurs
  THEN Dart field names are mapped to database column names

- GIVEN a `TableConfig` without required parameters
  WHEN the config is instantiated
  THEN a compile-time error occurs (via required parameters)

**Priority**: Must Have

---

### REQ-003: Factory Methods on Backends

**User Story**:
As a developer
I want to create backends with a single factory method
So that I don't have to manually wire up database connections and lifecycle.

**Acceptance Criteria**:
- GIVEN valid configuration parameters
  WHEN `XXXBackend.withYYY(...)` factory is called
  THEN a fully configured backend is returned

- GIVEN factory-created backend
  WHEN `initialize()` is called
  THEN database connection is established and schema is ready

- GIVEN factory-created backend
  WHEN `dispose()` is called
  THEN all resources are released without memory leaks

**Priority**: Must Have

---

### REQ-004: Multi-Table Manager Classes

**User Story**:
As a developer building a multi-table app
I want to coordinate multiple backends with shared database connections
So that I avoid connection duplication and simplify lifecycle management.

**Acceptance Criteria**:
- GIVEN a manager with multiple table configs
  WHEN `initialize()` is called once
  THEN all backends share a single database connection

- GIVEN an initialized manager
  WHEN `getBackend<T, ID>(tableName)` is called
  THEN the correctly typed backend is returned

- GIVEN a manager
  WHEN `dispose()` is called
  THEN all backends are disposed in correct order

- GIVEN a table name that doesn't exist
  WHEN `getBackend(tableName)` is called
  THEN a `StateError` is thrown with available table names

**Priority**: Must Have

---

### REQ-005: Provider/Connector Abstraction Pattern

**User Story**:
As a developer
I want auth and data operations abstracted behind interfaces
So that I can mock them in tests and swap implementations.

**Acceptance Criteria**:
- GIVEN an abstract `AuthProvider` interface
  WHEN a custom implementation is provided
  THEN the adapter uses the custom auth logic

- GIVEN no custom provider
  WHEN factory method is used
  THEN a default implementation is created internally

- GIVEN a mock provider in tests
  WHEN adapter operations occur
  THEN the mock is called instead of real implementation

**Priority**: Should Have

---

### REQ-006: DSL for Complex Configuration

**User Story**:
As a developer
I want to define sync rules, merge strategies, and RLS policies using Dart DSL
So that I can version-control configuration and avoid YAML/SQL errors.

**Acceptance Criteria**:
- GIVEN a `CrdtMergeConfig` with per-field strategies
  WHEN conflicts occur
  THEN the correct strategy is applied per field

- GIVEN a `SupabaseRLSPolicy` definition
  WHEN `toSql()` is called
  THEN valid PostgreSQL RLS policy SQL is generated

- GIVEN a `CrdtSyncRules` definition
  WHEN serialized
  THEN it produces correct sync filter configuration

**Priority**: Should Have

---

### REQ-007: State Management Provider Bundles

**User Story**:
As a developer using Riverpod/Signals/Bloc
I want to create all providers/signals/blocs for a store with one factory call
So that I don't have to manually create and coordinate multiple providers.

**Acceptance Criteria**:
- GIVEN a `StoreProviderBundle.forStore()` call
  WHEN accessed
  THEN `storeProvider`, `allProvider`, `byIdProvider` are all available

- GIVEN a `SignalsStoreBundle.create()` call
  WHEN accessed
  THEN `listSignal`, `stateSignal`, and computed signals are configured

- GIVEN a `BlocStoreBundle.create()` call
  WHEN accessed
  THEN `listBloc` and `itemCubit(id)` factory are available

**Priority**: Must Have

---

### REQ-008: Cross-Store Computed/Combined State

**User Story**:
As a developer with multiple stores
I want to create computed values that depend on multiple stores
So that I can build derived state efficiently.

**Acceptance Criteria**:
- GIVEN a `SignalsManager` with multiple stores
  WHEN `createCrossStoreComputed()` is called
  THEN computed signal updates when any source store changes

- GIVEN a `RiverpodStoreManager` with dependencies
  WHEN stores are initialized
  THEN dependency order is respected

- GIVEN a `BlocManager`
  WHEN `isAnyLoading` is accessed
  THEN it reflects combined loading state of all blocs

**Priority**: Should Have

---

## Technical Constraints

### Auto-Detected from Existing Packages

```yaml
# Common constraints across packages
sdk: ">=3.0.0 <4.0.0"
flutter: ">=3.10.0"
platforms: [android, ios, web, macos, linux, windows]

# Package-specific dependencies
nexus_store_drift_adapter:
  - drift: ^2.0.0
  - sqlite3_flutter_libs: any

nexus_store_supabase_adapter:
  - supabase: ^2.0.0

nexus_store_crdt_adapter:
  - sqlite_crdt: ^1.0.0

nexus_store_brick_adapter:
  - brick_offline_first: ^3.0.0

nexus_store_riverpod_binding:
  - riverpod: ^2.0.0
  - flutter_riverpod: ^2.0.0

nexus_store_signals_binding:
  - signals: ^5.0.0
  - flutter_signals: ^5.0.0

nexus_store_bloc_binding:
  - flutter_bloc: ^8.0.0
  - bloc: ^8.0.0
```

### Explicit Constraints

1. **Backwards Compatibility**: Existing API must remain unchanged; new features are additive
2. **No Breaking Changes**: Current users should not need to modify code
3. **Testability**: All new classes must be mockable without complex setup
4. **Tree-Shaking**: Factory methods should not pull in unused dependencies

---

## Public API Contract

### Storage Adapters: Common Column Pattern

```dart
/// Abstract base for type-safe column definitions.
/// Each adapter implements concrete column types.
abstract class ColumnDefinition {
  const ColumnDefinition({
    required this.name,
    required this.type,
    this.nullable = true,
    this.defaultValue,
  });

  final String name;
  final String type;
  final bool nullable;
  final Object? defaultValue;

  /// Generate SQL column definition.
  String toSqlDefinition();
}
```

### Drift Adapter API

```dart
// lib/src/drift_column.dart
enum DriftColumnType { text, integer, real, blob, boolean, dateTime }

class DriftColumn extends ColumnDefinition {
  /// Create a TEXT column.
  factory DriftColumn.text(String name, {bool nullable = true, String? defaultValue});

  /// Create an INTEGER column.
  factory DriftColumn.integer(String name, {bool nullable = true, int? defaultValue});

  /// Create a REAL column.
  factory DriftColumn.real(String name, {bool nullable = true, double? defaultValue});

  /// Create a BOOLEAN column (stored as INTEGER 0/1).
  factory DriftColumn.boolean(String name, {bool nullable = true, bool? defaultValue});

  /// Create a DATETIME column (stored as INTEGER epoch ms).
  factory DriftColumn.dateTime(String name, {bool nullable = true});

  /// Create a BLOB column.
  factory DriftColumn.blob(String name, {bool nullable = true});

  @override
  String toSqlDefinition();
}
```

```dart
// lib/src/drift_table_config.dart
class DriftTableConfig<T, ID> {
  const DriftTableConfig({
    required this.tableName,
    required this.columns,
    required this.fromJson,
    required this.toJson,
    required this.getId,
    this.primaryKeyColumn = 'id',
    this.fieldMapping,
    this.indexes,
  });

  final String tableName;
  final List<DriftColumn> columns;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T item) toJson;
  final ID Function(T item) getId;
  final String primaryKeyColumn;
  final Map<String, String>? fieldMapping;
  final List<DriftIndex>? indexes;

  /// Convert to table definition for schema creation.
  DriftTableDefinition toTableDefinition();
}

class DriftIndex {
  const DriftIndex({
    required this.name,
    required this.columns,
    this.unique = false,
  });

  final String name;
  final List<String> columns;
  final bool unique;

  String toSql(String tableName);
}
```

```dart
// lib/src/drift_backend.dart - factory extension
extension DriftBackendFactory<T, ID> on DriftBackend<T, ID> {
  /// Create a DriftBackend with automatic database setup.
  ///
  /// Example:
  /// ```dart
  /// final backend = DriftBackend<User, String>.withDatabase(
  ///   tableName: 'users',
  ///   columns: [
  ///     DriftColumn.text('name'),
  ///     DriftColumn.text('email'),
  ///     DriftColumn.integer('age', nullable: true),
  ///   ],
  ///   getId: (u) => u.id,
  ///   fromJson: User.fromJson,
  ///   toJson: (u) => u.toJson(),
  /// );
  /// await backend.initialize();
  /// ```
  static DriftBackend<T, ID> withDatabase<T, ID>({
    required String tableName,
    required List<DriftColumn> columns,
    required ID Function(T item) getId,
    required T Function(Map<String, dynamic> json) fromJson,
    required Map<String, dynamic> Function(T item) toJson,
    String? dbPath,
    String primaryKeyColumn = 'id',
    Map<String, String>? fieldMapping,
    List<DriftIndex>? indexes,
  });
}
```

```dart
// lib/src/drift_manager.dart
class DriftManager {
  /// Create manager with automatic database setup.
  ///
  /// Example:
  /// ```dart
  /// final manager = DriftManager.withDatabase(
  ///   tables: [
  ///     DriftTableConfig<User, String>(...),
  ///     DriftTableConfig<Post, String>(...),
  ///   ],
  /// );
  /// await manager.initialize();
  ///
  /// final userBackend = manager.getBackend<User, String>('users');
  /// ```
  factory DriftManager.withDatabase({
    required List<DriftTableConfig<dynamic, dynamic>> tables,
    String? dbPath,
    QueryExecutor? executor, // For testing
  });

  /// Whether the manager has been initialized.
  bool get isInitialized;

  /// Initialize database and all backends.
  Future<void> initialize();

  /// Get a typed backend by table name.
  ///
  /// Throws [StateError] if table name not found.
  DriftBackend<T, ID> getBackend<T, ID>(String tableName);

  /// List of all table names.
  List<String> get tableNames;

  /// Dispose all resources.
  Future<void> dispose();
}
```

**Input/Output Contract for DriftManager**:

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| tables | `List<DriftTableConfig>` | Yes | Table configurations |
| dbPath | `String?` | No | Database file path; null = in-memory |
| executor | `QueryExecutor?` | No | Custom executor for testing |

**Error Handling**:

| Error | Condition | Recovery |
|-------|-----------|----------|
| `StateError` | `getBackend` before `initialize()` | Call `initialize()` first |
| `StateError` | Table name not found | Check `tableNames` for valid names |
| `ArgumentError` | Empty columns list | Provide at least one column |

---

### Supabase Adapter API

```dart
// lib/src/supabase_column.dart
enum SupabaseColumnType { text, integer, float8, boolean, timestamptz, uuid, jsonb }

class SupabaseColumn extends ColumnDefinition {
  factory SupabaseColumn.text(String name, {bool nullable = true});
  factory SupabaseColumn.integer(String name, {bool nullable = true});
  factory SupabaseColumn.float8(String name, {bool nullable = true});
  factory SupabaseColumn.boolean(String name, {bool nullable = true});
  factory SupabaseColumn.timestamptz(String name, {bool nullable = true});
  factory SupabaseColumn.uuid(String name, {bool nullable = true});
  factory SupabaseColumn.jsonb(String name, {bool nullable = true});
}
```

```dart
// lib/src/supabase_auth_provider.dart
abstract class SupabaseAuthProvider {
  /// Get current access token.
  Future<String?> getAccessToken();

  /// Get current user ID.
  Future<String?> getUserId();

  /// Stream of auth state changes.
  Stream<SupabaseAuthState> get authStateStream;
}

class DefaultSupabaseAuthProvider implements SupabaseAuthProvider {
  DefaultSupabaseAuthProvider(SupabaseClient client);

  // Implementation uses client.auth
}

enum SupabaseAuthState { signedIn, signedOut, tokenRefreshed }
```

```dart
// lib/src/supabase_manager.dart
class SupabaseManager {
  factory SupabaseManager.withClient({
    required SupabaseClient client,
    required List<SupabaseTableConfig<dynamic, dynamic>> tables,
    SupabaseAuthProvider? authProvider,
  });

  SupabaseAuthProvider get authProvider;
  Future<void> initialize();
  SupabaseBackend<T, ID> getBackend<T, ID>(String tableName);
  Future<void> subscribeAll(); // Start all realtime subscriptions
  Future<void> unsubscribeAll();
  Future<void> dispose();
}
```

```dart
// lib/src/supabase_rls.dart
abstract class SupabaseRLSPolicy {
  const SupabaseRLSPolicy.select({required this.name, required this.using});
  const SupabaseRLSPolicy.insert({required this.name, required this.withCheck});
  const SupabaseRLSPolicy.update({required this.name, this.using, this.withCheck});
  const SupabaseRLSPolicy.delete({required this.name, required this.using});

  String toSql(String tableName);
}

class SupabaseRLSRules {
  const SupabaseRLSRules(this.policies);

  final List<SupabaseRLSPolicy> policies;

  /// Generate complete RLS setup SQL.
  String toSql(String tableName);
}
```

---

### CRDT Adapter API

```dart
// lib/src/crdt_merge_strategy.dart
enum CrdtMergeStrategy {
  /// Last-Writer-Wins based on HLC timestamps (default).
  lww,
  /// First-Writer-Wins (immutable after creation).
  fww,
  /// Custom merge function.
  custom,
}

class CrdtMergeConfig<T> {
  const CrdtMergeConfig({
    this.strategy = CrdtMergeStrategy.lww,
    this.fieldStrategies,
    this.customMerge,
  });

  final CrdtMergeStrategy strategy;
  final Map<String, CrdtMergeStrategy>? fieldStrategies;
  final T Function(T local, T remote)? customMerge;
}
```

```dart
// lib/src/crdt_peer_connector.dart
abstract class CrdtPeerConnector {
  /// Connect to peer network.
  Future<void> connect();

  /// Disconnect from peer network.
  Future<void> disconnect();

  /// Stream of incoming changesets from peers.
  Stream<CrdtChangeset> get incomingChangesets;

  /// Send changeset to peers.
  Future<void> sendChangeset(CrdtChangeset changeset);

  /// Current connection status.
  bool get isConnected;
}

class CrdtWebSocketConnector implements CrdtPeerConnector {
  CrdtWebSocketConnector({
    required this.url,
    this.authToken,
    this.reconnectInterval = const Duration(seconds: 5),
  });

  final String url;
  final String? authToken;
  final Duration reconnectInterval;

  // Implementation
}

class CrdtHttpConnector implements CrdtPeerConnector {
  CrdtHttpConnector({
    required this.url,
    this.pollInterval = const Duration(seconds: 30),
    this.authToken,
  });

  // Implementation uses HTTP polling
}

class CrdtMemoryConnector implements CrdtPeerConnector {
  /// For testing - connects two CRDT instances in memory.
  CrdtMemoryConnector();

  void link(CrdtMemoryConnector other);
}
```

```dart
// lib/src/crdt_manager.dart
class CrdtManager {
  factory CrdtManager.withDatabase({
    required List<CrdtTableConfig<dynamic, dynamic>> tables,
    String? dbPath,
    String? nodeId, // Auto-generated UUID if null
    CrdtDatabaseWrapper? wrapper, // For testing
  });

  /// This node's unique ID.
  String get nodeId;

  Future<void> initialize();
  CrdtBackend<T, ID> getBackend<T, ID>(String tableName);

  /// Get combined changeset from all tables since given HLC.
  Future<CrdtChangeset> getChangesetForAll({Hlc? since});

  /// Apply changeset to all tables atomically.
  Future<void> applyChangesetToAll(CrdtChangeset changeset);

  /// Connect a peer connector for sync.
  void attachConnector(CrdtPeerConnector connector);

  Future<void> dispose();
}
```

---

### Riverpod Binding API

```dart
// lib/src/providers/store_provider_bundle.dart
class StoreProviderBundle<T, ID> {
  /// Create all providers for a NexusStore.
  ///
  /// Example:
  /// ```dart
  /// final userBundle = StoreProviderBundle.forStore<User, String>(
  ///   create: (ref) => NexusStore<User, String>(backend: createBackend()),
  ///   name: 'user',
  /// );
  ///
  /// // In widget
  /// final users = ref.watch(userBundle.allProvider);
  /// ```
  factory StoreProviderBundle.forStore({
    required NexusStore<T, ID> Function(Ref ref) create,
    String? name,
    bool keepAlive = false,
  });

  /// The store provider.
  ProviderListenable<NexusStore<T, ID>> get storeProvider;

  /// StreamProvider for all items.
  StreamProvider<List<T>> get allProvider;

  /// StreamProvider.family for item by ID.
  StreamProviderFamily<T?, ID> get byIdProvider;

  /// StreamProvider for all with StoreResult status.
  StreamProvider<StoreResult<List<T>>> get statusProvider;

  /// StreamProvider.family for item with status.
  StreamProviderFamily<StoreResult<T?>, ID> get byIdStatusProvider;
}
```

```dart
// lib/src/manager/riverpod_store_manager.dart
class RiverpodStoreConfig<T, ID> {
  const RiverpodStoreConfig({
    required this.name,
    required this.create,
    this.keepAlive = false,
    this.dependencies = const [],
  });

  final String name;
  final NexusStore<T, ID> Function(Ref ref) create;
  final bool keepAlive;
  final List<String> dependencies;
}

class RiverpodStoreManager {
  RiverpodStoreManager(List<RiverpodStoreConfig<dynamic, dynamic>> configs);

  /// Get bundle by store name.
  StoreProviderBundle<T, ID> getBundle<T, ID>(String name);

  /// All store providers in dependency order.
  List<ProviderListenable<NexusStore<dynamic, dynamic>>> get allStoreProviders;

  /// Create test overrides for all stores.
  List<Override> createOverrides(Map<String, NexusStore<dynamic, dynamic>> mocks);
}
```

```dart
// lib/src/notifiers/nexus_notifier.dart
abstract class NexusAsyncNotifier<T, ID> extends AsyncNotifier<List<T>> {
  /// Override to provide the store.
  NexusStore<T, ID> get store;

  /// Override to provide optional query filter.
  Query<T>? get query => null;

  @override
  Future<List<T>> build();

  /// Add item to store.
  Future<T> add(T item);

  /// Update item in store.
  Future<T> update(T item);

  /// Remove item by ID.
  Future<bool> remove(ID id);

  /// Refresh data from backend.
  Future<void> refresh();
}
```

---

### Signals Binding API

```dart
// lib/src/factory/signals_store_factory.dart
class SignalsStoreConfig<T, ID> {
  const SignalsStoreConfig({
    required this.name,
    required this.store,
    this.initialQuery,
    this.autoLoad = true,
    this.computedSignals = const {},
  });

  final String name;
  final NexusStore<T, ID> store;
  final Query<T>? initialQuery;
  final bool autoLoad;
  final Map<String, Computed<dynamic> Function(Signal<List<T>>)> computedSignals;
}

class SignalsStoreBundle<T, ID> {
  factory SignalsStoreBundle.create({
    required SignalsStoreConfig<T, ID> config,
  });

  NexusListSignal<T, ID> get listSignal;
  Signal<NexusSignalState<T>> get stateSignal;
  Computed<R> computed<R>(String name);
  void dispose();
}
```

```dart
// lib/src/manager/signals_manager.dart
class SignalsManager {
  SignalsManager(List<SignalsStoreConfig<dynamic, dynamic>> configs);

  Future<void> initialize();
  NexusListSignal<T, ID> getListSignal<T, ID>(String name);
  Signal<NexusSignalState<T>> getStateSignal<T>(String name);

  /// Create computed signal spanning multiple stores.
  Computed<R> createCrossStoreComputed<R>(
    String name,
    R Function(Map<String, Signal<List<dynamic>>>) compute,
  );

  void dispose();
}
```

```dart
// lib/src/widgets/flutter_signal_scope.dart
class FlutterSignalScope extends InheritedWidget {
  const FlutterSignalScope({
    required this.stores,
    required super.child,
    super.key,
  });

  final List<SignalsStoreConfig<dynamic, dynamic>> stores;

  static SignalsManager of(BuildContext context);
  static SignalsManager? maybeOf(BuildContext context);
}
```

---

### Bloc Binding API

```dart
// lib/src/factory/bloc_store_factory.dart
class BlocStoreConfig<T, ID> {
  const BlocStoreConfig({
    required this.name,
    required this.store,
    this.initialQuery,
    this.useBloc = false,
    this.autoLoad = true,
    this.loadingStateConfig = const LoadingStateConfig(),
  });

  final String name;
  final NexusStore<T, ID> store;
  final Query<T>? initialQuery;
  final bool useBloc; // false = Cubit
  final bool autoLoad;
  final LoadingStateConfig loadingStateConfig;
}

class LoadingStateConfig {
  const LoadingStateConfig({
    this.showPreviousDataWhileLoading = true,
    this.debounceMs = 300,
    this.retryCount = 3,
  });

  final bool showPreviousDataWhileLoading;
  final int debounceMs;
  final int retryCount;
}

class BlocStoreBundle<T, ID> {
  factory BlocStoreBundle.create({
    required BlocStoreConfig<T, ID> config,
  });

  BlocBase<NexusStoreState<T>> get listBloc;
  NexusItemCubit<T, ID> itemCubit(ID id);
  Future<void> close();
}
```

```dart
// lib/src/manager/bloc_manager.dart
class BlocManager {
  BlocManager(List<BlocStoreConfig<dynamic, dynamic>> configs);

  Future<void> initialize();
  BlocBase<NexusStoreState<T>> getListBloc<T>(String name);
  NexusItemCubit<T, ID> getItemCubit<T, ID>(String name, ID id);

  Future<void> refreshAll();
  bool get isAnyLoading;
  Stream<bool> get isAnyLoadingStream;
  Object? get firstError;
  Stream<Object?> get errorStream;

  Future<void> dispose();
}
```

```dart
// lib/src/widgets/multi_bloc_provider.dart
class NexusMultiBlocProvider extends StatelessWidget {
  const NexusMultiBlocProvider({
    required this.manager,
    required this.child,
    super.key,
  });

  final BlocManager manager;
  final Widget child;

  static BlocManager of(BuildContext context);
}
```

---

## Testing Requirements

### Unit Test Scenarios

**Column Definitions**:
| Scenario | Input | Expected Output |
|----------|-------|-----------------|
| Text column | `DriftColumn.text('name')` | `"name" TEXT NOT NULL` |
| Nullable column | `DriftColumn.integer('age', nullable: true)` | `"age" INTEGER` |
| With default | `DriftColumn.text('status', defaultValue: 'active')` | `"status" TEXT NOT NULL DEFAULT 'active'` |
| Empty name | `DriftColumn.text('')` | `ArgumentError` |

**Table Config**:
| Scenario | Input | Expected |
|----------|-------|----------|
| Valid config | Complete config | `toTableDefinition()` succeeds |
| Field mapping | `fieldMapping: {'firstName': 'first_name'}` | JSON uses mapped names |

**Manager Lifecycle**:
| Scenario | Action | Expected |
|----------|--------|----------|
| Initialize | `manager.initialize()` | All backends ready |
| Get backend | `manager.getBackend<User>('users')` | Returns typed backend |
| Invalid table | `manager.getBackend('invalid')` | Throws `StateError` |
| Dispose | `manager.dispose()` | All resources released |

### Integration Test Scenarios

1. **Multi-table CRUD**:
   - Create manager with 3 table configs
   - Initialize and get backends
   - Perform CRUD on each table
   - Verify data isolation
   - Dispose and verify cleanup

2. **State Binding Lifecycle**:
   - Create `StoreProviderBundle`
   - Watch providers in widget test
   - Verify updates propagate
   - Dispose and verify no leaks

---

## Implementation Tasks

### Task 1: Drift Column & Config [P]
**Files**:
- `packages/nexus_store_drift_adapter/lib/src/drift_column.dart`
- `packages/nexus_store_drift_adapter/lib/src/drift_table_config.dart`
**Implements**: REQ-001, REQ-002
**Complexity**: Low

**Deliverables**:
- [ ] Create `DriftColumn` class with factory methods
- [ ] Create `DriftTableConfig` class
- [ ] Create `DriftTableDefinition` class
- [ ] Create `DriftIndex` class
- [ ] Add unit tests

### Task 2: Drift Factory & Manager [Depends: Task 1]
**Files**:
- `packages/nexus_store_drift_adapter/lib/src/drift_backend.dart` (modify)
- `packages/nexus_store_drift_adapter/lib/src/drift_manager.dart`
**Implements**: REQ-003, REQ-004
**Complexity**: Medium

**Deliverables**:
- [ ] Add `DriftBackend.withDatabase()` factory
- [ ] Create `DriftManager` class
- [ ] Add integration tests

### Task 3: Supabase Column & Config [P]
**Files**:
- `packages/nexus_store_supabase_adapter/lib/src/supabase_column.dart`
- `packages/nexus_store_supabase_adapter/lib/src/supabase_table_config.dart`
**Implements**: REQ-001, REQ-002
**Complexity**: Low

### Task 4: Supabase Auth Provider [P]
**Files**:
- `packages/nexus_store_supabase_adapter/lib/src/supabase_auth_provider.dart`
**Implements**: REQ-005
**Complexity**: Low

### Task 5: Supabase Factory & Manager [Depends: Task 3, 4]
**Files**:
- `packages/nexus_store_supabase_adapter/lib/src/supabase_backend.dart` (modify)
- `packages/nexus_store_supabase_adapter/lib/src/supabase_manager.dart`
**Implements**: REQ-003, REQ-004
**Complexity**: Medium

### Task 6: Supabase RLS DSL [P]
**Files**:
- `packages/nexus_store_supabase_adapter/lib/src/supabase_rls.dart`
**Implements**: REQ-006
**Complexity**: Low

### Task 7: CRDT Column & Config [P]
**Files**:
- `packages/nexus_store_crdt_adapter/lib/src/crdt_column.dart`
- `packages/nexus_store_crdt_adapter/lib/src/crdt_table_config.dart`
**Implements**: REQ-001, REQ-002
**Complexity**: Low

### Task 8: CRDT Merge Strategy [P]
**Files**:
- `packages/nexus_store_crdt_adapter/lib/src/crdt_merge_strategy.dart`
**Implements**: REQ-006
**Complexity**: Medium

### Task 9: CRDT Peer Connector [P]
**Files**:
- `packages/nexus_store_crdt_adapter/lib/src/crdt_peer_connector.dart`
**Implements**: REQ-005
**Complexity**: High

### Task 10: CRDT Factory & Manager [Depends: Task 7, 8, 9]
**Files**:
- `packages/nexus_store_crdt_adapter/lib/src/crdt_backend.dart` (modify)
- `packages/nexus_store_crdt_adapter/lib/src/crdt_manager.dart`
**Implements**: REQ-003, REQ-004
**Complexity**: High

### Task 11: Brick Config & Manager [P]
**Files**:
- `packages/nexus_store_brick_adapter/lib/src/brick_table_config.dart`
- `packages/nexus_store_brick_adapter/lib/src/brick_manager.dart`
**Implements**: REQ-002, REQ-003, REQ-004
**Complexity**: Medium

### Task 12: Riverpod Provider Bundle [P]
**Files**:
- `packages/nexus_store_riverpod_binding/lib/src/providers/store_provider_bundle.dart`
**Implements**: REQ-007
**Complexity**: Medium

### Task 13: Riverpod Manager & Notifier [Depends: Task 12]
**Files**:
- `packages/nexus_store_riverpod_binding/lib/src/manager/riverpod_store_manager.dart`
- `packages/nexus_store_riverpod_binding/lib/src/notifiers/nexus_notifier.dart`
**Implements**: REQ-007, REQ-008
**Complexity**: Medium

### Task 14: Signals Bundle & Manager [P]
**Files**:
- `packages/nexus_store_signals_binding/lib/src/factory/signals_store_factory.dart`
- `packages/nexus_store_signals_binding/lib/src/manager/signals_manager.dart`
- `packages/nexus_store_signals_binding/lib/src/widgets/flutter_signal_scope.dart`
**Implements**: REQ-007, REQ-008
**Complexity**: Medium

### Task 15: Bloc Bundle & Manager [P]
**Files**:
- `packages/nexus_store_bloc_binding/lib/src/factory/bloc_store_factory.dart`
- `packages/nexus_store_bloc_binding/lib/src/manager/bloc_manager.dart`
- `packages/nexus_store_bloc_binding/lib/src/widgets/multi_bloc_provider.dart`
**Implements**: REQ-007, REQ-008
**Complexity**: Medium

### Task 16: Update Barrel Exports [Depends: All]
**Files**: All package `lib/*.dart` barrel files
**Complexity**: Low

### Task 17: Update READMEs [Depends: All]
**Files**: All package README.md files
**Complexity**: Low

---

## Open Questions

All questions resolved during planning phase:

1. **Q: Are existing packages stubs?** A: No, all 13 packages are fully implemented.
2. **Q: Can batteries-included apply to all?** A: Yes to 7 packages (4 adapters, 3 bindings).
3. **Q: What's the priority order?** A: Drift > Supabase > CRDT > Brick > Riverpod > Signals > Bloc.
4. **Q: Should we use code generation?** A: Only for Riverpod (already has generator package).
