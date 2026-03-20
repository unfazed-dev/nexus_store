# nexus_store

[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![Dart](https://img.shields.io/badge/Dart-3.5+-blue.svg)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev)

A unified reactive data store abstraction for Dart and Flutter. Use a single consistent API across multiple storage backends with policy-based fetching, RxDart streams, and optional compliance features.

## Features

- **Unified Backend Interface** — Single API for PowerSync, Supabase, Drift, Brick, and CRDT backends
- **Reactive Streams** — RxDart BehaviorSubjects for immediate values and real-time updates
- **Policy-Based Operations** — Apollo-style fetch/write policies (cacheFirst, networkFirst, etc.)
- **Query Builder** — Fluent API with filtering, ordering, text search, cursor pagination, and field selection
- **Transactions** — Single-store ACID transactions and multi-store saga coordination
- **Mutations** — TanStack Query-style lifecycle hooks with optimistic updates and rollback
- **Pagination** — Offset, cursor, and infinite-scroll pagination with sealed state management
- **Interceptors** — Pluggable request/response pipeline for logging, caching, timing, and validation
- **Lazy Loading** — On-demand field loading with batching for media-heavy entities
- **Scoped Stores** — Auto-filtered store views with composable query scopes
- **Cross-Store Joins** — Reactive stream composition across multiple stores
- **Cache Management** — Tag-based invalidation, eviction strategies, and memory pressure handling
- **Diagnostics** — Operation metrics, cache stats, memory monitoring, and health checks
- **Encryption** — SQLCipher database encryption and field-level AES-256-GCM
- **Compliance** — HIPAA audit logging and GDPR data portability/erasure
- **Flutter Widgets** — Ready-to-use builders, providers, and pagination widgets
- **Code Generation** — Entity field accessors, lazy field wrappers, and Riverpod providers

## Quick Start

```dart
import 'package:nexus_store/nexus_store.dart';

// Create a store with any backend
final userStore = NexusStore<User, String>(
  backend: InMemoryBackend<User, String>(
    getId: (user) => user.id,
  ),
  config: StoreConfig.defaults,
);

await userStore.initialize();

// CRUD operations
await userStore.save(User(id: '1', name: 'Alice'));
final user = await userStore.get('1');
final users = await userStore.getAll();
await userStore.delete('1');

// Reactive streams
userStore.watch('1').listen((user) => print(user));
userStore.watchAll().listen((users) => print(users));

// Query builder
final activeUsers = await userStore.getAll(
  query: Query<User>()
    .where('status', isEqualTo: 'active')
    .orderBy('createdAt', descending: true)
    .limit(10),
);
```

## API Reference

### Core CRUD Operations

```dart
// Save (create or update)
final saved = await store.save(user);
final savedAll = await store.saveAll([user1, user2]);

// Read
final user = await store.get('user-1');
final users = await store.getAll(query: query);
final one = await store.getOne(query: query);  // First match or null

// Lookup helpers
final user = await store.findBy('email', 'alice@example.com');
final batch = await store.getByIds(['id-1', 'id-2', 'id-3']);
final exists = await store.exists('user-1');
final any = await store.existsWhere(
  Query<User>().where('role', isEqualTo: 'admin'),
);

// Delete
await store.delete('user-1');
final count = await store.deleteWhere(
  Query<User>().where('status', isEqualTo: 'inactive'),
);

// Soft delete (patches deletion timestamp)
await store.softDelete('user-1');

// Upsert with conflict handling
final upserted = await store.upsert(user, onConflict: ConflictStrategy.update);
final bulk = await store.upsertAll(users, onConflict: ConflictStrategy.ignore);

// Partial update
await store.patch('user-1', {'name': 'Bob', 'age': 30});

// Count
final total = await store.count();
final active = await store.count(
  query: Query<User>().where('status', isEqualTo: 'active'),
);
```

**ConflictStrategy** — Controls upsert behavior when an entity already exists:

| Value | Behavior |
|-------|----------|
| `update` | Merge new values into existing entity (default) |
| `ignore` | Keep existing entity unchanged |
| `replace` | Replace entire entity |
| `error` | Throw if entity exists |

All write operations accept an optional `WritePolicy` override. All read operations accept an optional `FetchPolicy` override.

### Aggregate Operations

```dart
final total = await store.aggregate('amount', AggregateType.sum,
  query: Query<Order>().where('status', isEqualTo: 'completed'),
);

// Convenience methods
final totalRevenue = await store.sum('amount');
final avgRating = await store.avg('rating');
final minPrice = await store.min('price');
final maxPrice = await store.max('price');
```

### Query Builder

#### Basic Filters

```dart
final query = Query<User>()
  .where('status', isEqualTo: 'active')
  .where('age', isGreaterThan: 18)
  .where('role', whereIn: ['admin', 'moderator'])
  .orderBy('createdAt', descending: true)
  .limit(10)
  .offset(20);
```

#### Filter Operators

```dart
.where('field', isEqualTo: value)
.where('field', isNotEqualTo: value)
.where('field', isLessThan: value)
.where('field', isLessThanOrEqualTo: value)
.where('field', isGreaterThan: value)
.where('field', isGreaterThanOrEqualTo: value)
.where('field', whereIn: [value1, value2])
.where('field', whereNotIn: [value1, value2])
.where('field', arrayContains: value)
.where('field', arrayContainsAny: [value1, value2])
.where('field', isNull: true)           // NULL check
.where('field', isNull: false)          // NOT NULL check
```

#### Text Search

```dart
.where('name', contains: 'ali')         // Substring match
.where('name', startsWith: 'A')         // Prefix match
.where('name', endsWith: 'ce')          // Suffix match
.where('name', iContains: 'ALI')        // Case-insensitive contains
.where('name', iStartsWith: 'a')        // Case-insensitive prefix
.where('name', iEndsWith: 'CE')         // Case-insensitive suffix
.where('bio', textSearch: TextSearchConfig('flutter dart'))  // Full-text search
```

#### OR Groups

```dart
Query<User>()
  .where('status', isEqualTo: 'active')
  .or((q) => q
    .where('role', isEqualTo: 'admin')
    .where('role', isEqualTo: 'superadmin')
  );
// status = 'active' AND (role = 'admin' OR role = 'superadmin')
```

#### Range Filters

```dart
.whereBetween('age', start: 18, end: 65)  // 18 <= age <= 65
```

#### Field Selection & Preloading

```dart
// Load only specific fields (partial entity)
Query<User>().select({'id', 'name', 'email'})

// Eager-load related fields
Query<User>().preload({'avatar', 'address'})

// Unique results only
Query<User>().distinct()
```

#### Cursor Pagination

```dart
// Forward pagination
final page1 = await store.getAll(
  query: Query<User>().orderBy('createdAt').first(20),
);

// Next page using cursor
final page2 = await store.getAll(
  query: Query<User>()
    .orderBy('createdAt')
    .after(page1.endCursor)
    .first(20),
);

// Backward pagination
final prevPage = await store.getAll(
  query: Query<User>()
    .orderBy('createdAt')
    .before(page2.startCursor)
    .last(20),
);
```

### Reactive Streams

```dart
// Watch a single entity
store.watch('user-1').listen((user) => print(user));

// Watch all (with optional query)
store.watchAll(query: query).listen((users) => print(users));

// Watch count
store.watchCount(query: query).listen((count) => print('Count: $count'));

// Watch single query result
store.watchOne(Query<User>().where('email', isEqualTo: 'alice@example.com'))
  .listen((user) => print(user));

// Watch multiple IDs
store.watchByIds(['id-1', 'id-2']).listen((users) => print(users));

// Watch paged results
store.watchAllPaged(query: query).listen((pagedResult) {
  print('Items: ${pagedResult.items.length}');
  print('Has next: ${pagedResult.pageInfo.hasNextPage}');
});

// Watch with page size control
store.watchPaged(query: query, pageSize: 20).listen((pagedResult) {
  print(pagedResult.items);
});

// Full pagination state stream (sealed class)
store.watchAllPaginated(query: query, pageSize: 20).listen((state) {
  state.when(
    initial: () => print('Ready'),
    loading: (_) => print('Loading...'),
    loadingMore: (items, _) => print('Loading more...'),
    data: (items, pageInfo) => print('Got ${items.length} items'),
    error: (error, items, _) => print('Error: $error'),
  );
});

// Sync status
store.syncStatusStream.listen((status) {
  switch (status) {
    case SyncStatus.synced: print('All synced');
    case SyncStatus.syncing: print('Syncing...');
    case SyncStatus.pending: print('Changes pending');
    case SyncStatus.error: print('Sync error');
  }
});
```

**PaginationState** — Sealed class with variants: `initial`, `loading`, `loadingMore`, `data`, `error`. Supports `when()` and `maybeWhen()` pattern matching.

**PagedResult<T>** — Contains `.items`, `.pageInfo` (`PageInfo` with `.hasNextPage`, `.hasPreviousPage`, `.startCursor`, `.endCursor`).

**StreamingConfig** — Configure pagination behavior: `pageSize`, `prefetchDistance`, `shouldPrefetch`.

### Transactions

#### Single-Store Transactions

```dart
final result = await store.transaction((tx) async {
  final user = await tx.get('user-1');
  await tx.save(user.copyWith(balance: user.balance - 100));
  await tx.save(receipt);
  return user;
}, timeout: Duration(seconds: 10));
```

If the callback throws, all operations are rolled back and a `TransactionError` is thrown.

#### Cross-Store Transactions

```dart
await NexusStore.crossTransaction(
  stores: [userStore, orderStore],
  action: (ctx) async {
    await ctx.save(userStore, updatedUser);
    await ctx.save(orderStore, newOrder);
    await ctx.delete(orderStore, 'old-order-id');
  },
  timeout: Duration(seconds: 30),
);
```

Cross-store transactions use `CrossTransactionContext` which tracks all operations and compensates (rollback) on failure via `TransactionCoordinator`.

### Mutations with Lifecycle Hooks

```dart
final updated = await store.mutate(
  updatedUser,
  options: MutationOptions(
    onMutate: () async {
      // Save rollback data before mutation
      return await store.get(updatedUser.id);
    },
    onSuccess: (result, context) async {
      print('Updated: ${result.name}');
    },
    onError: (error, context) async {
      if (context != null) await store.save(context as User); // rollback
    },
    onSettled: (context) async {
      // Always runs after success or error
    },
    invalidateTags: {'users', 'user-list'},  // Cache tags to invalidate on success
  ),
);

// Delete with lifecycle hooks
await store.mutateDelete('user-1', options: MutationOptions(
  onMutate: () async => await store.get('user-1'),
  onError: (error, previous) async {
    if (previous != null) await store.save(previous as User);
  },
));
```

### Cache Management

```dart
// Mark specific entity as stale
store.invalidate('user-1');

// Mark all entities as stale
store.invalidateAll();

// Tag-based invalidation
store.addTags('user-1', {'team-alpha', 'department-eng'});
store.invalidateByTags({'team-alpha'});  // Invalidate all tagged items
store.invalidateByIds(['user-1', 'user-2']);

// Evict cache
store.evictCache();

// Cache statistics
final stats = store.getCacheStats();
print('Entries: ${stats.entryCount}');
print('Hit rate: ${stats.hitRate}');
```

### Interceptor Pipeline

Interceptors observe and modify store operations at three points: before execution (`onRequest`), after success (`onResponse`), and on error (`onError`).

```dart
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(
    interceptors: [
      LoggingInterceptor(),       // Built-in: logs operations
      TimingInterceptor(),        // Built-in: tracks duration
      CachingInterceptor(cache),  // Built-in: cache layer
      ValidationInterceptor(),    // Built-in: data validation
      MyCustomInterceptor(),      // Your own
    ],
  ),
);
```

#### Custom Interceptor

```dart
class AuthInterceptor extends StoreInterceptor {
  final AuthService _auth;
  AuthInterceptor(this._auth);

  @override
  Set<StoreOperation> get operations => {
    StoreOperation.save,
    StoreOperation.delete,
  };

  @override
  Future<InterceptorResult<R>> onRequest<T, R>(
    InterceptorContext<T, R> ctx,
  ) async {
    final user = await _auth.currentUser;
    if (user == null) {
      return InterceptorResult.error(AuthenticationError(message: 'Not authenticated'));
    }
    ctx.metadata['userId'] = user.id;
    return const InterceptorResult.continue_();
  }

  @override
  Future<void> onResponse<T, R>(InterceptorContext<T, R> ctx) async {
    final userId = ctx.metadata['userId'];
    await _auditLog.record('${ctx.operation} by $userId');
  }
}
```

**StoreOperation** enum values: `get`, `getAll`, `save`, `saveAll`, `delete`, `deleteAll`, `watch`, `watchAll`, `sync`, `count`, `deleteWhere`, `aggregate`, `exists`, `existsWhere`, `updateWhere`, `patch`, `upsert`, `upsertAll`, `getByIds`, `getOne`.

**InterceptorResult** — Sealed: `continue_()`, `error(e)`, `modify(response)`.

### Lazy Loading

```dart
// Configure lazy fields
final store = NexusStore<MediaPost, String>(
  backend: backend,
  config: StoreConfig(
    lazyLoad: LazyLoadConfig(
      lazyFields: {'thumbnail', 'fullImage', 'video'},
      batchSize: 10,
      batchDelay: Duration(milliseconds: 50),
      preloadOnWatch: false,
    ),
  ),
);

// Load fields on demand
await store.loadField('post-1', 'thumbnail');
final thumbnails = await store.loadFieldBatch(['post-1', 'post-2'], 'thumbnail');

// Check field state
final state = store.getFieldState('post-1', 'thumbnail');
// LazyFieldState: notLoaded, loading, loaded, error

// LazyEntity wrapper (uses FieldLoader engine internally)
final lazy = LazyEntity<MediaPost, String>(
  post,
  idExtractor: (p) => p.id,
  fieldLoader: FieldLoader<MediaPost, String>(backend: backend),
  config: LazyLoadConfig(lazyFields: {'avatar'}),
);
print(lazy.isFieldLoaded('avatar')); // false
await lazy.loadField('avatar');
print(lazy.isFieldLoaded('avatar')); // true
```

### Scoped Stores

Create a `ScopedStore` that auto-applies filters to all read operations:

```dart
final scopedStore = store.scoped([
  SoftDeleteScope(),                         // Excludes deleted_at IS NOT NULL
  OwnerScope(ownerId: 'user-123'),           // Filters by owner_id
]);

// All reads automatically apply scopes
final users = await scopedStore.getAll();  // Filtered by both scopes
final count = await scopedStore.count();   // Scoped count
```

Built-in scopes: `SoftDeleteScope(field:)`, `OwnerScope(ownerId:, field:)`. Implement `QueryScope<T>` for custom scopes.

### Cross-Store Joins

```dart
// Combine two stores — re-emits when either changes
StoreJoin.combine2(
  storeA: userStore,
  storeB: orderStore,
  queryA: Query<User>().where('active', isEqualTo: true),
).listen((record) {
  final (users, orders) = record;
  print('Users: ${users.length}, Orders: ${orders.length}');
});

// Primary-driven — only emits when primary changes
StoreJoin.withLatest2(
  primary: userStore,
  secondary: settingsStore,
).listen((record) {
  final (users, settings) = record;
  // Only fires when userStore changes
});

// Also available: combine3, combine4, withLatest3, withLatest4
```

### Composite Backend

```dart
final store = NexusStore<User, String>(
  backend: CompositeBackend(
    primary: supabaseBackend,
    fallback: driftBackend,
    cache: inMemoryBackend,
    readStrategy: CompositeReadStrategy.cacheFirst,
    writeStrategy: CompositeWriteStrategy.primaryAndCache,
  ),
);
```

| Read Strategy | Behavior |
|---------------|----------|
| `primaryFirst` | Try primary, fall back to fallback, then cache |
| `cacheFirst` | Check cache first, then primary |
| `fastest` | Race all backends, return first result |

| Write Strategy | Behavior |
|----------------|----------|
| `primaryOnly` | Write to primary only |
| `all` | Write to all backends |
| `primaryAndCache` | Write to primary and cache |

### Diagnostics & Observability

```dart
// StoreStats — operation counts, durations, cache performance
final stats = store.getStats();
print('Operations: ${stats.operationCounts}');
print('Cache hits: ${stats.cacheHits}');

// StoreDiagnostics — comprehensive health snapshot
final diagnostics = await store.getDiagnostics();
print('Health: ${diagnostics.healthStatus}');
print('Entities: ${diagnostics.entityCount}');
print('Cache hit rate: ${diagnostics.cacheHitPercentage}%');
print('Slow operations: ${diagnostics.slowOperations.length}');

// MemoryMetrics — memory monitoring stream
store.memoryMetricsStream.listen((metrics) {
  print('Cache size: ${metrics.cacheSizeBytes}');
});

store.memoryPressureStream.listen((level) {
  // MemoryPressureLevel: normal, moderate, critical
  if (level == MemoryPressureLevel.critical) {
    store.evictCache();
  }
});

// BackendCapabilities — feature detection
final caps = store.capabilities;
print('Supports transactions: ${caps.supportsTransactions}');
print('Supports realtime: ${caps.supportsRealtime}');
```

### Sync Management

```dart
// Manual sync trigger
await store.sync();

// Pending changes count
final count = await store.pendingChangesCount;

// Stream of pending changes
store.pendingChanges.listen((changes) {
  for (final change in changes) {
    print('${change.type}: ${change.id} (${change.status})');
  }
});

// Conflict detection (ConflictDetails stream)
store.conflicts.listen((conflict) {
  print('Conflict on ${conflict.entityId}');
  print('Local: ${conflict.localVersion}');
  print('Remote: ${conflict.remoteVersion}');
});

// Cancel specific pending change
await store.cancelPendingChange('change-id');

// Retry failed changes
await store.retryPendingChange('change-id');
await store.retryAllPending();
```

## Configuration

### StoreConfig

```dart
final config = StoreConfig(
  // --- Policies ---
  fetchPolicy: FetchPolicy.cacheFirst,            // Default read policy
  writePolicy: WritePolicy.cacheAndNetwork,        // Default write policy
  syncMode: SyncMode.realtime,                     // Sync strategy
  conflictResolution: ConflictResolution.serverWins,

  // --- Timing ---
  staleDuration: Duration(minutes: 5),             // Cache staleness threshold
  syncInterval: Duration(minutes: 30),             // Periodic sync interval
  transactionTimeout: Duration(seconds: 30),       // Transaction deadline

  // --- Retry ---
  retryConfig: RetryConfig.defaults,               // Retry configuration

  // --- Encryption ---
  encryption: EncryptionConfig.none(),             // Encryption configuration

  // --- Compliance ---
  enableAuditLogging: false,                       // HIPAA audit logging
  enableGdpr: false,                               // GDPR compliance
  gdpr: GdprConfig(...),                           // Enhanced GDPR config

  // --- Interceptors ---
  interceptors: [LoggingInterceptor()],            // Interceptor pipeline

  // --- Lazy Loading ---
  lazyLoad: LazyLoadConfig(                        // On-demand field loading
    lazyFields: {'thumbnail', 'video'},
    batchSize: 10,
  ),

  // --- Memory Management ---
  memory: MemoryConfig(                            // Cache eviction
    maxCacheBytes: 50 * 1024 * 1024,               // 50MB
    moderateThreshold: 0.7,
    criticalThreshold: 0.9,
    strategy: EvictionStrategy.lru,
  ),

  // --- Reliability ---
  circuitBreaker: CircuitBreakerConfig(            // Cascade failure protection
    failureThreshold: 5,
    successThreshold: 2,
    openDuration: Duration(seconds: 30),
  ),
  healthCheck: HealthCheckConfig(                  // Health monitoring
    checkInterval: Duration(seconds: 30),
    timeout: Duration(seconds: 10),
    failureThreshold: 3,
  ),

  // --- Validation ---
  schemaValidation: SchemaValidationConfig(...),   // Entity schema enforcement

  // --- Sync ---
  deltaSync: DeltaSyncConfig(...),                 // Field-level change tracking

  // --- Telemetry ---
  metricsConfig: MetricsConfig.defaults,           // Sampling and buffering
  metricsReporter: NoOpMetricsReporter(),          // Telemetry reporter

  // --- Misc ---
  tableName: 'users',                             // Custom table name override
);
```

### Preset Configurations

```dart
StoreConfig.defaults     // Sensible defaults (cacheFirst, cacheAndNetwork, realtime)
StoreConfig.offlineFirst // cacheFirst reads, cacheFirst writes, periodic sync
StoreConfig.onlineOnly   // networkOnly reads, networkFirst writes, sync disabled
StoreConfig.realtime     // cacheAndNetwork reads, realtime sync
```

### Fetch Policies

| Policy | Behavior | Use Case |
|--------|----------|----------|
| `cacheFirst` | Return cache if available, else fetch | Read-heavy, infrequent updates |
| `networkFirst` | Always fetch, update cache | Fresh data (account balance) |
| `cacheAndNetwork` | Return cache, then emit network | Instant UI + background refresh |
| `cacheOnly` | Cache only, no network | Offline-only |
| `networkOnly` | Network only, no cache | Uncacheable data (OTP) |
| `staleWhileRevalidate` | Return stale cache, revalidate | Eventual consistency |

### Write Policies

| Policy | Behavior | Use Case |
|--------|----------|----------|
| `cacheAndNetwork` | Save cache, then sync (optimistic) | Standard operations |
| `networkFirst` | Wait for network before returning | Critical consistency |
| `cacheFirst` | Save locally, sync in background | Offline-first apps |
| `cacheOnly` | Cache only, never sync | Local-only data |
| `networkOnly` | Network only, bypass cache | Direct remote writes |

### Sync Modes

| Mode | Behavior |
|------|----------|
| `realtime` | Continuous bidirectional sync |
| `periodic` | Sync at configured intervals |
| `manual` | Only sync when `store.sync()` is called |
| `eventDriven` | Sync triggered by events |
| `disabled` | No sync |

## Error Handling

```dart
try {
  final user = await store.get('unknown-id');
} on NotFoundError catch (e) {
  print('Not found: ${e.id}');
} on NetworkError catch (e) {
  if (e.isRetryable) { /* retry */ }
  print('Status: ${e.statusCode}');
} on ValidationError catch (e) {
  for (final v in e.violations) {
    print('${v.field}: ${v.message}');
  }
} on TransactionError catch (e) {
  print('Rolled back: ${e.wasRolledBack}');
} on CircuitBreakerOpenException catch (e) {
  print('Retry after: ${e.retryAfter}');
} on StoreError catch (e) {
  print('Store error: ${e.message}');
}
```

### Error Hierarchy

`StoreError` (sealed base class) with typed subclasses:

| Error | Purpose | Retryable |
|-------|---------|-----------|
| `NotFoundError` | Entity not found | No |
| `NetworkError` | Network operation failed | Yes (5xx, 408, 429) |
| `TimeoutError` | Operation timed out | Yes |
| `ValidationError` | Field validation failed | No |
| `ConflictError` | Sync conflict detected | No |
| `SyncError` | Synchronization failed | Yes |
| `AuthenticationError` | Authentication required | No |
| `AuthorizationError` | Permission denied | No |
| `TransactionError` | Transaction failed/rolled back | No |
| `StateError` | Invalid store state | No |
| `CancellationError` | Operation was cancelled | No |
| `QuotaExceededError` | Storage/rate quota hit | No |
| `CircuitBreakerOpenException` | Circuit breaker tripped | Yes (after `retryAfter`) |
| `SagaError` | Cross-store saga failure | No |

**Pool Errors** (`PoolError` sealed base):

| Error | Purpose | Retryable |
|-------|---------|-----------|
| `PoolNotInitializedError` | Pool not initialized | No |
| `PoolClosedError` | Pool already disposed | No |
| `PoolConnectionError` | Connection failure | Yes |
| `PoolConnectionTimeoutError` | Connection timed out | Yes |
| `PoolExhaustedError` | All connections in use | Yes |

## Backend Selection Guide

| Backend | Best For | Sync | Offline | Conflict Resolution |
|---------|----------|------|---------|---------------------|
| **PowerSync** | Offline-first apps with PostgreSQL | Bi-directional | Full | Server-authoritative |
| **Supabase** | Real-time apps, RLS security | Real-time | Limited | Last-write-wins |
| **Drift** | Local-only storage, no sync needed | None | Full | N/A |
| **Brick** | Multiple remotes (REST, GraphQL, Supabase) | Bi-directional | Full | Customizable |
| **CRDT** | P2P, multi-device, no central server | Peer-to-peer | Full | Automatic (LWW) |

### Detailed Feature Matrix

| Feature | PowerSync | Supabase | Drift | Brick | CRDT |
|---------|:---------:|:--------:|:-----:|:-----:|:----:|
| **Sync & Connectivity** |
| Offline Support | Full | Limited | Full | Full | Full |
| Real-time Updates | Yes | Yes | No | Yes | Yes |
| Bi-directional Sync | Yes | No | No | Yes | Yes |
| P2P Support | No | No | No | No | Yes |
| **Security** |
| Database Encryption | SQLCipher | No | SQLCipher | No | No |
| Field-level Encryption | Yes | Yes | Yes | Yes | Yes |
| Row Level Security | No | Yes | No | No | No |
| **Query Capabilities** |
| Full SQL Support | Yes | No | Yes | No | No |
| Complex Filters | Yes | Yes | Yes | Partial | Partial |
| Transactions | Yes | No | Yes | Yes | No |
| **Architecture** |
| Requires Server | PostgreSQL | Supabase | No | Optional | No |
| Local-only Mode | No | No | Yes | Yes | Yes |

### Adapter Highlights

All adapters implement the `StoreBackend<T, ID>` interface and support the **batteries-included pattern** with a `Manager` class for multi-table coordination and `TableConfig` for declarative table setup:

```dart
// Drift example
final manager = DriftManager(database);
manager.register<User, String>(DriftTableConfig(
  tableName: 'users',
  columns: [
    DriftColumn.text('name'),
    DriftColumn.text('email'),
    DriftColumn.integer('age', nullable: true),
    DriftColumn.boolean('active', defaultValue: true),
    DriftColumn.dateTime('created_at'),
  ],
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,
));
```

- **Drift** — Column DSL: `.text()`, `.integer()`, `.real()`, `.boolean()`, `.dateTime()`, `.blob()`
- **Supabase** — Column DSL: `.uuid()`, `.text()`, `.integer()`, `.float8()`, `.boolean()`, `.timestamptz()`, `.jsonb()`. Plus: RLS policy DSL, auth providers, storage backend, realtime manager
- **PowerSync** — Column DSL: `.text()`, `.integer()`, `.real()`. Plus: SQLCipher encryption, sync rules DSL, Supabase connector
- **Brick** — Sync policies: `BrickSyncPolicy`, `BrickConflictResolution`, `BrickRetryPolicy`
- **CRDT** — Merge strategies, peer connectors, sync rules DSL, P2P messaging protocol

## State Management Bindings

### Bloc Binding

```dart
// Cubit (simplified)
class UsersCubit extends NexusStoreCubit<User, String> {
  UsersCubit(NexusStore<User, String> store) : super(store);
}

final cubit = UsersCubit(userStore);
await cubit.load();                      // Subscribe to watchAll
await cubit.save(user);                  // CRUD through cubit

// Bloc (with events)
class UsersBloc extends NexusStoreBloc<User, String> {
  UsersBloc(NexusStore<User, String> store) : super(store);
}

// Item-level cubits
class UserCubit extends NexusItemCubit<User, String> {
  UserCubit(NexusStore<User, String> store) : super(store);
}

// State hierarchy (sealed)
// NexusStoreState: Initial, Loading, Loaded, Error
// NexusItemState: Initial, Loading, Loaded, NotFound, Error
// Both support when() and maybeWhen() pattern matching

BlocBuilder<UsersCubit, NexusStoreState<User>>(
  builder: (context, state) => state.when(
    initial: () => const Text('Ready'),
    loading: (_) => const CircularProgressIndicator(),
    loaded: (users) => UserList(users),
    error: (e, _) => ErrorWidget(e),
  ),
)
```

### Riverpod Binding

```dart
// Code generation (recommended)
@riverpodNexusStore
NexusStore<User, String> userStore(Ref ref) {
  return NexusStore(backend: ref.watch(backendProvider));
}
// Generated: userStoreProvider, usersProvider, userByIdProvider

// Manual setup
class MyWidget extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);
    return users.when(
      data: (list) => ListView(children: list.map((u) => Text(u.name)).toList()),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

// Extensions
final signal = userStore.bindToRef(ref);  // Ref binding

// Widget helpers
NexusStoreConsumer<User, String>(
  store: userStore,
  builder: (context, users) => UserList(users),
)
```

### Signals Binding

```dart
// Stream to signal conversion
final usersSignal = userStore.toSignal();
final currentUser = userStore.toItemSignal('user-1');

// State signals with loading/error
final usersState = userStore.toStateSignal();
Watch((context) {
  return usersState.value.when(
    initial: () => const Text('Ready'),
    loading: (previous) => const CircularProgressIndicator(),
    data: (users) => UserList(users: users),
    error: (error, _, previous) => Text('Error: $error'),
  );
});

// NexusSignal wrapper with refresh
final usersSignal = NexusSignal.fromStore(userStore);
await usersSignal.refresh();

// Computed signals
final activeCount = computed(() =>
  usersSignal.value.where((u) => u.isActive).length
);

// State hierarchy (sealed)
// NexusSignalState: Initial, Loading, Data, Error
// NexusItemSignalState: Initial, Loading, Data, NotFound, Error
```

## Flutter Widgets

### Providers

```dart
// Single store
NexusStoreProvider<User, String>(
  store: userStore,
  child: MyApp(),
)

// Multiple stores
MultiNexusStoreProvider(
  providers: [
    NexusStoreProvider<User, String>(store: userStore),
    NexusStoreProvider<Order, String>(store: orderStore),
  ],
  child: MyApp(),
)

// Access via BuildContext
final store = context.nexusStore<User, String>();
```

### Builder Widgets

```dart
// Reactive list builder
NexusStoreBuilder<User, String>(
  store: userStore,
  query: Query<User>().where('active', isEqualTo: true),
  builder: (context, users) => ListView(
    children: users.map((u) => Text(u.name)).toList(),
  ),
)

// Reactive item builder
NexusStoreItemBuilder<User, String>(
  store: userStore,
  id: 'user-1',
  builder: (context, user) => user != null
    ? Text(user.name)
    : const Text('Not found'),
)
```

### StoreResult

A sealed class for representing async states:

```dart
// Variants: Idle, Pending, Success, Error
final result = StoreResult<User>.idle();
final result = StoreResult<User>.pending(previousData);
final result = StoreResult<User>.success(user);
final result = StoreResult<User>.error(exception, previousData);

// Pattern matching
result.when(
  idle: () => const Text('Ready'),
  pending: (previous) => const CircularProgressIndicator(),
  success: (data) => Text(data.name),
  error: (e, previous) => Text('Error: $e'),
);

// Builder widgets
StoreResultBuilder<User>(
  result: userResult,
  idle: () => const Text('Tap to load'),
  pending: (previous) => const CircularProgressIndicator(),
  success: (user) => Text(user.name),
  error: (e, previous) => Text('Error: $e'),
)

StoreResultStreamBuilder<User>(
  stream: userResultStream,
  builder: (context, result) => result.when(...),
)

// Pagination state builder
PaginationStateBuilder<User>(
  stream: store.watchAllPaginated(query: query, pageSize: 20),
  builder: (context, state) => state.when(
    initial: () => const Text('Pull to refresh'),
    loading: (_) => const CircularProgressIndicator(),
    loadingMore: (items, _) => UserList(items, isLoadingMore: true),
    data: (items, _) => UserList(items),
    error: (e, items, _) => ErrorWidget(e),
  ),
)
```

### Utilities

```dart
// Virtualized lazy loading list
LazyListView<User>(...)

// Viewport-based loading
VisibilityLoader(...)

// App lifecycle integration
StoreLifecycleObserver(stores: [userStore, orderStore])

// Memory pressure handling
FlutterMemoryPressureHandler(stores: [userStore])

// Background sync
BackgroundSyncService(config: BackgroundSyncConfig(...))

// Secure key storage
SecureSaltStorage(...)
```

## Code Generation

### Entity Generator (`@NexusEntity`)

Generates type-safe field accessors and query builder methods:

```dart
@NexusEntity()
class User {
  final String id;
  final String name;
  final int age;
  // ...
}

// Generated: UserFields.name, UserFields.age
// With query methods: .greaterThan(), .startsWith(), etc.
final query = Query<User>()
  .where(UserFields.age.greaterThan(18))
  .where(UserFields.name.startsWith('A'));
```

### Lazy Field Generator (`@NexusLazy`)

Generates typed accessor mixins and wrapper classes for lazy-loaded fields:

```dart
@NexusLazy(
  fields: {'avatar', 'fullBio'},
  placeholders: {'avatar': null},
)
class UserProfile { ... }

// Generated: UserProfileLazyMixin, LazyUserProfile
```

### Riverpod Generator (`@riverpodNexusStore`)

Generates Riverpod providers from store factory functions:

```dart
@riverpodNexusStore
NexusStore<User, String> userStore(Ref ref) {
  return NexusStore(backend: ref.watch(backendProvider));
}

// Generated: userStoreProvider, usersProvider, userByIdProvider(id)
```

## Compliance Features

### HIPAA Audit Logging

```dart
final auditStorage = InMemoryAuditStorage();

final store = NexusStore<Patient, String>(
  backend: backend,
  config: StoreConfig(enableAuditLogging: true),
  auditService: AuditService(
    storage: auditStorage,
    actorProvider: () async => currentUser.id,
    hashChainEnabled: true,  // Tamper-evident logging
  ),
);

// Query audit logs
final logs = await store.audit!.query(
  entityType: 'User',
  action: AuditAction.update,
  startDate: DateTime.now().subtract(Duration(days: 7)),
);

// Verify integrity
final isValid = await store.audit!.verifyIntegrity();
```

### GDPR Data Erasure & Portability

```dart
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(enableGdpr: true),
  subjectIdField: 'userId',
);

// Article 17 — Right to Erasure
final summary = await store.gdpr!.eraseSubjectData('user-123');
print('Deleted ${summary.deletedCount} records');

// Article 20 — Data Portability
final export = await store.gdpr!.exportSubjectData('user-123');
print(export.toJson());

// Article 15 — Right of Access
final report = await store.gdpr!.accessSubjectData('user-123');
```

### Field-Level Encryption

```dart
final store = NexusStore<Patient, String>(
  backend: backend,
  config: StoreConfig(
    encryption: EncryptionConfig.fieldLevel(
      encryptedFields: {'ssn', 'diagnosis', 'medications'},
      keyProvider: () => secureStorage.getKey(),
      algorithm: EncryptionAlgorithm.aes256Gcm,
    ),
  ),
);
```

## Packages

| Package | Description | Pub |
|---------|-------------|-----|
| [nexus_store](packages/nexus_store/) | Core store abstraction | [![pub](https://img.shields.io/pub/v/nexus_store)](https://pub.dev/packages/nexus_store) |
| [nexus_store_flutter_widgets](packages/nexus_store_flutter_widgets/) | Flutter widgets and providers | [![pub](https://img.shields.io/pub/v/nexus_store_flutter_widgets)](https://pub.dev/packages/nexus_store_flutter_widgets) |
| [nexus_store_powersync_adapter](packages/nexus_store_powersync_adapter/) | PowerSync offline-first backend | [![pub](https://img.shields.io/pub/v/nexus_store_powersync_adapter)](https://pub.dev/packages/nexus_store_powersync_adapter) |
| [nexus_store_supabase_adapter](packages/nexus_store_supabase_adapter/) | Supabase realtime backend with RLS and auth | [![pub](https://img.shields.io/pub/v/nexus_store_supabase_adapter)](https://pub.dev/packages/nexus_store_supabase_adapter) |
| [nexus_store_drift_adapter](packages/nexus_store_drift_adapter/) | Drift SQLite backend with column DSL | [![pub](https://img.shields.io/pub/v/nexus_store_drift_adapter)](https://pub.dev/packages/nexus_store_drift_adapter) |
| [nexus_store_brick_adapter](packages/nexus_store_brick_adapter/) | Brick offline-first backend with sync policies | [![pub](https://img.shields.io/pub/v/nexus_store_brick_adapter)](https://pub.dev/packages/nexus_store_brick_adapter) |
| [nexus_store_crdt_adapter](packages/nexus_store_crdt_adapter/) | CRDT backend with merge strategies and sync rules | [![pub](https://img.shields.io/pub/v/nexus_store_crdt_adapter)](https://pub.dev/packages/nexus_store_crdt_adapter) |

### State Management Bindings

| Package | Description |
|---------|-------------|
| [nexus_store_riverpod_binding](packages/nexus_store_riverpod_binding/) | Riverpod provider bundles, store manager, and hooks |
| [nexus_store_bloc_binding](packages/nexus_store_bloc_binding/) | Bloc/Cubit bundles with state helpers and event sequences |
| [nexus_store_signals_binding](packages/nexus_store_signals_binding/) | Signal bundles with cross-store computed signals |

### Code Generation

| Package | Description |
|---------|-------------|
| [nexus_store_generator](packages/nexus_store_generator/) | Lazy field accessor generator |
| [nexus_store_entity_generator](packages/nexus_store_entity_generator/) | Type-safe entity field generator |
| [nexus_store_riverpod_generator](packages/nexus_store_riverpod_generator/) | Riverpod provider generator |

## Installation

Add the core package and your preferred backend adapter:

```yaml
dependencies:
  nexus_store: ^0.1.0
  nexus_store_powersync_adapter: ^0.1.0  # Or your preferred backend

  # For Flutter apps
  nexus_store_flutter_widgets: ^0.1.0
```

## Requirements

- Dart SDK: ^3.5.0
- Flutter SDK: ^3.10.0 (for Flutter packages)

## Documentation

### Package Documentation
- [Core Package](packages/nexus_store/README.md)
- [Flutter Widgets](packages/nexus_store_flutter_widgets/README.md)

### Architecture
- [Architecture Overview](docs/architecture/overview.md)
- [Policy Engine](docs/architecture/policy-engine.md)
- [Reactive Layer](docs/architecture/reactive-layer.md)
- [Backend Interface](docs/architecture/backend-interface.md)

### Security & Compliance
- [Encryption Guide](docs/architecture/encryption.md)
- [Compliance Guide](docs/architecture/compliance.md)

### Migration Guides
- [From Raw PowerSync](docs/migration/from-raw-powersync.md)
- [From Drift](docs/migration/from-drift.md)
- [From Supabase](docs/migration/from-supabase.md)
- [Version Upgrades](docs/migration/version-upgrades.md)

### Code Generation
- [Entity Generator](packages/nexus_store_entity_generator/README.md)
- [Lazy Field Generator](packages/nexus_store_generator/README.md)
- [Riverpod Generator](packages/nexus_store_riverpod_generator/README.md)

## Examples

See the [example](example/) directory for complete working examples:

- [Basic Usage](example/basic_usage/) — Console app with CRUD and queries
- [Flutter Widgets](example/flutter_widgets/) — Flutter app with reactive widgets
- [Complete Integration](example/complete_integration/) — Full Flutter app with Riverpod state management

## License

BSD 3 License — see [LICENSE](LICENSE) file for details.

## Links

- **Repository**: https://github.com/unfazed-dev/nexus_store
- **Issues**: https://github.com/unfazed-dev/nexus_store/issues
- **Pub.dev**: https://pub.dev/packages/nexus_store

## Support

For bugs, feature requests, or questions:
1. Check existing [issues](https://github.com/unfazed-dev/nexus_store/issues)
2. Create a new issue with detailed information

---
