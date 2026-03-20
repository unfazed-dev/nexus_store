# nexus_store

[![Pub Version](https://img.shields.io/pub/v/nexus_store)](https://pub.dev/packages/nexus_store)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

A unified reactive data store abstraction providing a single consistent API across multiple storage backends with policy-based fetching, RxDart streams, and optional compliance features.

## Features

- **Unified API** — Single interface for PowerSync, Drift, Supabase, Brick, CRDT, and custom backends
- **Policy-based fetching** — Apollo GraphQL-style fetch policies (cacheFirst, networkFirst, etc.)
- **Reactive streams** — RxDart BehaviorSubject for immediate value on subscribe
- **Query builder** — Fluent API with filtering, ordering, text search, cursor pagination, field selection
- **Transactions** — Single-store ACID transactions and multi-store saga coordination
- **Mutations** — TanStack Query-style lifecycle hooks with optimistic updates
- **Pagination** — Offset, cursor, and infinite-scroll with sealed state management
- **Interceptors** — Pluggable request/response/error pipeline
- **Lazy loading** — On-demand field loading with batching
- **Scoped stores** — Auto-filtered views with composable query scopes
- **Cross-store joins** — Reactive stream composition across stores
- **Cache management** — Tag-based invalidation, LRU eviction, memory pressure handling
- **Diagnostics** — Operation metrics, cache stats, memory monitoring, health checks
- **Encryption** — SQLCipher database encryption and field-level AES-256-GCM
- **Compliance** — GDPR erasure/portability/consent, HIPAA audit logging

## Installation

```yaml
dependencies:
  nexus_store: ^0.1.0
```

Then add a backend adapter package for your storage solution.

## Basic Usage

```dart
import 'package:nexus_store/nexus_store.dart';

// Define your model
class User {
  final String id;
  final String name;
  final String email;
  final String status;

  User({required this.id, required this.name, required this.email, required this.status});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    status: json['status'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'status': status,
  };
}

// Create a store
final userStore = NexusStore<User, String>(
  backend: yourBackend,  // PowerSyncBackend, DriftBackend, etc.
  config: StoreConfig.defaults,
);

// Initialize before use
await userStore.initialize();

// CRUD operations
await userStore.save(User(id: '1', name: 'Alice', email: 'alice@example.com', status: 'active'));
final user = await userStore.get('1');
final users = await userStore.getAll();
await userStore.delete('1');

// Clean up when done
await userStore.dispose();
```

## Core Operations

### CRUD

```dart
// Save (create or update)
final saved = await store.save(user);
final savedAll = await store.saveAll([user1, user2]);

// Read
final user = await store.get('user-1');                         // By ID (throws NotFoundError if missing)
final users = await store.getAll(query: query);                 // With optional query
final one = await store.getOne(query: query);                   // First match or null

// Delete
await store.delete('user-1');                                   // By ID
final count = await store.deleteWhere(                          // By query
  Query<User>().where('status', isEqualTo: 'inactive'),
);

// Soft delete (sets deleted_at to current timestamp)
await store.softDelete('user-1');
await store.softDelete('user-1', field: 'removed_at');          // Custom field
```

### Lookup Helpers

```dart
// Single-field lookup (returns null if not found)
final user = await store.findBy('email', 'alice@example.com');

// Batch ID lookup
final users = await store.getByIds(['id-1', 'id-2', 'id-3']);

// Existence checks
final exists = await store.exists('user-1');
final anyAdmin = await store.existsWhere(
  Query<User>().where('role', isEqualTo: 'admin'),
);
```

### Upsert Operations

Insert or update with configurable conflict handling:

```dart
final upserted = await store.upsert(
  user,
  onConflict: ConflictStrategy.update,  // Default
);

final bulk = await store.upsertAll(
  users,
  onConflict: ConflictStrategy.ignore,  // Skip existing
);
```

| ConflictStrategy | Behavior |
|------------------|----------|
| `update` | Merge new values into existing entity (default) |
| `ignore` | Keep existing entity unchanged |
| `replace` | Replace entire entity with new one |
| `error` | Throw if entity already exists |

### Partial Updates

```dart
// Update specific fields without loading the full entity
await store.patch('user-1', {'name': 'Bob', 'age': 30});

// Update all matching entities
await store.updateWhere(
  Query<User>().where('status', isEqualTo: 'trial'),
  {'status': 'expired'},
);
```

### Aggregate Operations

```dart
// Generic aggregate
final total = await store.aggregate('amount', AggregateType.sum,
  query: Query<Order>().where('status', isEqualTo: 'completed'),
);

// Convenience methods (all accept optional query parameter)
final revenue = await store.sum('amount');
final avgRating = await store.avg('rating');
final cheapest = await store.min('price');
final priciest = await store.max('price');

// Count (more efficient than getAll().length)
final total = await store.count();
final activeCount = await store.count(
  query: Query<User>().where('status', isEqualTo: 'active'),
);
```

**AggregateType** enum: `sum`, `avg`, `min`, `max`

### Policy Overrides

All read operations accept a `FetchPolicy` override, all write operations accept a `WritePolicy` override:

```dart
// Override per operation
final user = await store.get('1', policy: FetchPolicy.networkFirst);
await store.save(user, policy: WritePolicy.networkFirst);
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
  transactionTimeout: Duration(seconds: 30),       // Default transaction deadline

  // --- Retry ---
  retryConfig: RetryConfig.defaults,

  // --- Encryption ---
  encryption: EncryptionConfig.none(),

  // --- Compliance ---
  enableAuditLogging: false,
  enableGdpr: false,
  gdpr: GdprConfig(...),                           // Enhanced GDPR (consent, breach, minimization)

  // --- Interceptors ---
  interceptors: [                                  // Request/response pipeline
    LoggingInterceptor(),
    TimingInterceptor(),
  ],

  // --- Lazy Loading ---
  lazyLoad: LazyLoadConfig(
    lazyFields: {'thumbnail', 'video'},
    batchSize: 10,
    batchDelay: Duration(milliseconds: 50),
    preloadOnWatch: false,
    placeholders: {'thumbnail': null},
  ),

  // --- Memory Management ---
  memory: MemoryConfig(
    maxCacheBytes: 50 * 1024 * 1024,               // 50MB
    moderateThreshold: 0.7,
    criticalThreshold: 0.9,
    strategy: EvictionStrategy.lru,
  ),

  // --- Reliability ---
  circuitBreaker: CircuitBreakerConfig(
    failureThreshold: 5,
    successThreshold: 2,
    openDuration: Duration(seconds: 30),
  ),
  healthCheck: HealthCheckConfig(
    checkInterval: Duration(seconds: 30),
    timeout: Duration(seconds: 10),
    failureThreshold: 3,
  ),

  // --- Validation & Sync ---
  schemaValidation: SchemaValidationConfig(...),
  deltaSync: DeltaSyncConfig(...),                 // Field-level change tracking

  // --- Telemetry ---
  metricsConfig: MetricsConfig.defaults,
  metricsReporter: NoOpMetricsReporter(),

  // --- Misc ---
  tableName: 'users',
);
```

### Preset Configurations

```dart
// Sensible defaults: cacheFirst reads, cacheAndNetwork writes, realtime sync
StoreConfig.defaults

// Offline-first: cacheFirst reads and writes, periodic sync
StoreConfig.offlineFirst

// Online-only: networkOnly reads, networkFirst writes, sync disabled
StoreConfig.onlineOnly

// Realtime: cacheAndNetwork reads, realtime sync
StoreConfig.realtime
```

## Fetch Policies

Control how data is read from cache and network:

| Policy | Behavior | Use Case |
|--------|----------|----------|
| `cacheFirst` | Return cache if available, otherwise fetch network | Read-heavy, less frequent updates |
| `networkFirst` | Always fetch network, update cache | Fresh data (account balance) |
| `cacheAndNetwork` | Return cache immediately, then emit network result | Instant UI with background refresh |
| `cacheOnly` | Return only cached data | Offline-only scenarios |
| `networkOnly` | Always fetch network, ignore cache | Data that shouldn't be cached (OTP) |
| `staleWhileRevalidate` | Return stale cache, revalidate in background | Content with eventual consistency |

```dart
final user = await store.get('1', policy: FetchPolicy.networkFirst);
```

## Write Policies

Control how data is written to cache and network:

| Policy | Behavior | Use Case |
|--------|----------|----------|
| `cacheAndNetwork` | Save to cache, then sync (optimistic) | Standard online operations |
| `networkFirst` | Wait for network sync before returning | Critical data requiring consistency |
| `cacheFirst` | Save locally, sync in background | Offline-first apps |
| `cacheOnly` | Save only to cache, never sync | Local-only data (drafts, settings) |
| `networkOnly` | Network only, bypass cache | Direct remote writes |

```dart
await store.save(user, policy: WritePolicy.networkFirst);
```

## Sync Modes

| Mode | Behavior |
|------|----------|
| `realtime` | Continuous bidirectional sync |
| `periodic` | Sync at configured `syncInterval` |
| `manual` | Only sync when `store.sync()` is called |
| `eventDriven` | Sync triggered by events |
| `disabled` | No synchronization |

## Query Builder

Build queries with a fluent API:

```dart
final query = Query<User>()
  .where('status', isEqualTo: 'active')
  .where('age', isGreaterThan: 18)
  .where('role', whereIn: ['admin', 'moderator'])
  .orderBy('createdAt', descending: true)
  .limit(10)
  .offset(20);

final users = await store.getAll(query: query);
```

### Filter Operators

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
.where('field', isNull: true)               // IS NULL
.where('field', isNull: false)              // IS NOT NULL
```

### Text Search

```dart
.where('name', contains: 'ali')             // LIKE %ali%
.where('name', startsWith: 'A')             // LIKE A%
.where('name', endsWith: 'ce')              // LIKE %ce
.where('name', iContains: 'ALI')            // Case-insensitive LIKE
.where('name', iStartsWith: 'a')            // Case-insensitive prefix
.where('name', iEndsWith: 'CE')             // Case-insensitive suffix
.where('bio', textSearch: TextSearchConfig('flutter dart'))  // Full-text search
```

### OR Groups

Conditions inside `.or()` are OR-ed together and AND-ed with the rest of the query:

```dart
Query<User>()
  .where('status', isEqualTo: 'active')
  .or((q) => q
    .where('role', isEqualTo: 'admin')
    .where('role', isEqualTo: 'superadmin')
  );
// WHERE status = 'active' AND (role = 'admin' OR role = 'superadmin')
```

### Range Filters

```dart
.whereBetween('age', start: 18, end: 65)    // 18 <= age <= 65
```

### Field Selection & Preloading

```dart
// Load only specific fields (reduces data transfer)
final query = Query<User>().select({'id', 'name', 'email'});

// Eager-load related/lazy fields
final query = Query<User>().preload({'avatar', 'address'});
final query = Query<User>().preloadField('avatar');

// Unique results only
final query = Query<User>().distinct();
```

### Cursor Pagination

For efficient large-dataset pagination:

```dart
// Forward pagination
final page1 = await store.getAll(
  query: Query<User>()
    .orderBy('createdAt', descending: true)
    .first(20),
);

// Next page
final page2 = await store.getAll(
  query: Query<User>()
    .orderBy('createdAt', descending: true)
    .after(page1.endCursor)
    .first(20),
);

// Backward pagination
final prevPage = await store.getAll(
  query: Query<User>()
    .orderBy('createdAt', descending: true)
    .before(page2.startCursor)
    .last(20),
);
```

## Reactive Streams

Watch for real-time updates using RxDart BehaviorSubjects:

```dart
// Watch a single entity by ID
userStore.watch('user-123').listen((user) {
  if (user != null) print('User updated: ${user.name}');
});

// Watch all entities (with optional query)
userStore.watchAll(
  query: Query<User>().where('status', isEqualTo: 'active'),
).listen((users) {
  print('Active users: ${users.length}');
});

// Watch reactive count
userStore.watchCount(
  query: Query<User>().where('status', isEqualTo: 'active'),
).listen((count) {
  print('Active count: $count');
});

// Watch single query result (first match)
userStore.watchOne(
  Query<User>().where('email', isEqualTo: 'alice@example.com'),
).listen((user) {
  print('Alice: $user');
});

// Watch multiple IDs
userStore.watchByIds(['id-1', 'id-2', 'id-3']).listen((users) {
  print('Watched users: ${users.length}');
});
```

### Paged Reactive Streams

```dart
// Watch paged results
userStore.watchAllPaged(query: query).listen((pagedResult) {
  print('Items: ${pagedResult.items.length}');
  print('Has next: ${pagedResult.pageInfo.hasNextPage}');
  print('End cursor: ${pagedResult.pageInfo.endCursor}');
});

// Watch with explicit page size
userStore.watchPaged(query: query, pageSize: 20).listen((pagedResult) {
  print(pagedResult.items);
});

// Full pagination state stream (sealed class)
userStore.watchAllPaginated(query: query, pageSize: 20).listen((state) {
  state.when(
    initial: () => print('Ready to load'),
    loading: (previousItems) => print('Loading first page...'),
    loadingMore: (items, pageInfo) => print('Loading more...'),
    data: (items, pageInfo) => print('Got ${items.length} items'),
    error: (error, items, pageInfo) => print('Error: $error'),
  );
});
```

### Pagination Types

**PaginationState<T>** — Sealed class with five variants:

| Variant | Properties | Description |
|---------|------------|-------------|
| `PaginationInitial` | — | Before any loading |
| `PaginationLoading` | `previousItems` | Loading first page or refreshing |
| `PaginationLoadingMore` | `items`, `pageInfo` | Loading additional pages |
| `PaginationData` | `items`, `pageInfo` | Data loaded successfully |
| `PaginationError` | `error`, `items`, `pageInfo` | Error during loading |

All variants support `when()` and `maybeWhen()` pattern matching, plus common properties: `items`, `isLoading`, `isLoadingMore`, `hasMore`, `error`, `pageInfo`.

**PagedResult<T>** — `items`, `pageInfo`

**PageInfo** — `hasNextPage`, `hasPreviousPage`, `startCursor`, `endCursor`

### Sync Streams

```dart
// Sync status
userStore.syncStatusStream.listen((status) {
  switch (status) {
    case SyncStatus.synced: print('All synced');
    case SyncStatus.syncing: print('Syncing...');
    case SyncStatus.pending: print('Changes pending');
    case SyncStatus.error: print('Sync error');
  }
});

// Pending changes stream
userStore.pendingChanges.listen((changes) {
  for (final change in changes) {
    print('${change.type}: ${change.id} (status: ${change.status})');
  }
});

// Conflict stream
userStore.conflicts.listen((conflict) {
  print('Conflict on ${conflict.entityId}');
  print('Local: ${conflict.localVersion}');
  print('Remote: ${conflict.remoteVersion}');
});
```

## Transactions

### Single-Store Transactions

All operations within the callback are atomic. If the callback throws, all changes are rolled back.

```dart
final result = await store.transaction((tx) async {
  final user = await tx.get('user-1');
  final updated = user.copyWith(balance: user.balance - 100);
  await tx.save(updated);

  final receipt = Receipt(userId: user.id, amount: 100);
  await tx.save(receipt);

  return updated;
}, timeout: Duration(seconds: 10));
```

Configure default timeout via `StoreConfig.transactionTimeout` (default: 30 seconds).

### Cross-Store Transactions

Atomic operations across multiple stores with automatic rollback:

```dart
await NexusStore.crossTransaction(
  stores: [userStore, orderStore, inventoryStore],
  action: (ctx) async {
    // ctx.save() and ctx.delete() track operations for rollback
    final user = await userStore.get('user-1');
    await ctx.save(userStore, user.copyWith(balance: user.balance - total));
    await ctx.save(orderStore, newOrder);
    await ctx.delete(inventoryStore, 'item-1');
  },
  timeout: Duration(seconds: 30),
);
```

If any operation fails, `CrossTransactionContext` compensates all previous operations (inserts are deleted, updates are reverted, deletes are restored). Throws `TransactionError` on failure.

### TransactionCoordinator

Low-level API for saga-style coordination:

```dart
await TransactionCoordinator.run(
  stores: [storeA, storeB],
  action: (ctx) async {
    await ctx.save(storeA, itemA);
    await ctx.save(storeB, itemB);
  },
  timeout: Duration(seconds: 30),
);
```

## Mutations with Lifecycle Hooks

TanStack Query-inspired mutation lifecycle for optimistic updates and rollback:

```dart
final updated = await store.mutate(
  updatedUser,
  options: MutationOptions<User>(
    onMutate: () async {
      // Called BEFORE mutation — return rollback context
      final previous = await store.get(updatedUser.id);
      return previous;
    },
    onSuccess: (result, context) async {
      // Called on SUCCESS — result is the saved entity
      print('Updated: ${result.name}');
    },
    onError: (error, context) async {
      // Called on ERROR — context is from onMutate
      if (context != null) {
        await store.save(context as User);  // Rollback
      }
    },
    onSettled: (context) async {
      // ALWAYS called after success or error
    },
    invalidateTags: {'users', 'user-list'},  // Invalidated on success only
  ),
);
```

### Delete with Hooks

```dart
await store.mutateDelete('user-1', options: MutationOptions<User>(
  onMutate: () async => await store.get('user-1'),
  onError: (error, previous) async {
    if (previous != null) await store.save(previous as User);
  },
));
```

### Transform Mutation

Atomic get-transform-save:

```dart
final updated = await store.mutateTransform(
  'user-1',
  transform: (user) => user.copyWith(loginCount: user.loginCount + 1),
);
```

## Cache Management

### Invalidation

```dart
// Mark single entity as stale
store.invalidate('user-1');

// Mark all entities as stale
store.invalidateAll();

// Invalidate by IDs
store.invalidateByIds(['user-1', 'user-2']);

// Tag-based invalidation
store.addTags('user-1', {'team-alpha', 'department-eng'});
store.invalidateByTags({'team-alpha'});

// Remove tags
store.removeTags('user-1', {'department-eng'});

// Get tags for an entity
final tags = store.getTags('user-1');

// Check staleness
final isStale = store.isStale('user-1');
```

### Eviction

```dart
// Evict entire cache
store.evictCache();
```

### Cache Statistics

```dart
final stats = store.getCacheStats();
print('Entries: ${stats.entryCount}');
print('Hit rate: ${stats.hitRate}');
print('Hits: ${stats.hits}');
print('Misses: ${stats.misses}');
```

## Interceptor Pipeline

Interceptors observe and modify store operations at three lifecycle points.

### Execution Order

For a chain `[A, B, C]`:
- **Request phase**: A.onRequest -> B.onRequest -> C.onRequest -> operation
- **Response phase**: C.onResponse -> B.onResponse -> A.onResponse
- **Error phase**: C.onError -> B.onError -> A.onError

### Configuration

```dart
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(
    interceptors: [
      LoggingInterceptor(),       // Built-in: logs all operations
      TimingInterceptor(),        // Built-in: tracks operation duration
      CachingInterceptor(cache),  // Built-in: cache management
      ValidationInterceptor(),    // Built-in: data validation
    ],
  ),
);
```

### Custom Interceptor

```dart
class AuthInterceptor extends StoreInterceptor {
  final AuthService _auth;
  AuthInterceptor(this._auth);

  // Only intercept write operations
  @override
  Set<StoreOperation> get operations => {
    StoreOperation.save,
    StoreOperation.saveAll,
    StoreOperation.delete,
    StoreOperation.deleteAll,
  };

  @override
  Future<InterceptorResult<R>> onRequest<T, R>(
    InterceptorContext<T, R> ctx,
  ) async {
    final user = await _auth.currentUser;
    if (user == null) {
      return InterceptorResult.error(
        AuthenticationError(message: 'Not authenticated'),
      );
    }
    ctx.metadata['userId'] = user.id;
    return const InterceptorResult.continue_();
  }

  @override
  Future<void> onResponse<T, R>(InterceptorContext<T, R> ctx) async {
    // Log successful operations
    final userId = ctx.metadata['userId'];
    await _auditLog.record('${ctx.operation} by $userId');
  }

  @override
  Future<InterceptorResult<R>> onError<T, R>(
    InterceptorContext<T, R> ctx,
    Object error,
  ) async {
    // Transform or handle errors
    return InterceptorResult.error(error);
  }
}
```

### InterceptorResult

Sealed class controlling flow:

| Variant | Effect |
|---------|--------|
| `InterceptorResult.continue_()` | Proceed to next interceptor |
| `InterceptorResult.error(e)` | Short-circuit with error |
| `InterceptorResult.modify(response)` | Replace the response |

### InterceptorContext

| Property | Type | Description |
|----------|------|-------------|
| `operation` | `StoreOperation` | Which operation is executing |
| `request` | `T` | The request data |
| `response` | `R?` | The response (available in onResponse) |
| `metadata` | `Map<String, dynamic>` | Mutable metadata shared across interceptors |
| `timestamp` | `DateTime` | When the operation started |

Call `ctx.stopPropagation()` to prevent remaining interceptors from processing the request.

### StoreOperation Enum

All interceptable operations:

| Category | Operations |
|----------|-----------|
| **Read** | `get`, `getAll`, `getByIds`, `getOne`, `count`, `aggregate`, `exists`, `existsWhere` |
| **Write** | `save`, `saveAll`, `updateWhere`, `patch`, `upsert`, `upsertAll` |
| **Delete** | `delete`, `deleteAll`, `deleteWhere` |
| **Stream** | `watch`, `watchAll` |
| **Sync** | `sync` |

Extension methods: `.isRead`, `.isWrite`, `.isDelete`, `.isStream`, `.isSync`, `.modifiesData`.

## Lazy Loading

On-demand loading for heavy fields (images, blobs, large text).

### Configuration

```dart
final store = NexusStore<MediaPost, String>(
  backend: backend,
  config: StoreConfig(
    lazyLoad: LazyLoadConfig(
      lazyFields: {'thumbnail', 'fullImage', 'video'},
      batchSize: 10,                               // Max batch size
      batchDelay: Duration(milliseconds: 50),       // Batch window
      preloadOnWatch: false,                        // Auto-load on watch?
      placeholders: {'thumbnail': null},            // Default values
    ),
  ),
);
```

Presets: `LazyLoadConfig.off` (disabled), `LazyLoadConfig.media` (pre-configured for media fields).

### Store-Level API

```dart
// Load a single field for an entity
await store.loadField('post-1', 'thumbnail');

// Batch load a field for multiple entities
final thumbnails = await store.loadFieldBatch(['post-1', 'post-2'], 'thumbnail');
// Returns Map<ID, dynamic>

// Check field load state
final state = store.getFieldState('post-1', 'thumbnail');
// LazyFieldState: notLoaded, loading, loaded, error
```

### LazyEntity Wrapper

```dart
final lazy = LazyEntity<MediaPost, String>(
  post,
  idExtractor: (p) => p.id,
  fieldLoader: fieldLoader,
  config: LazyLoadConfig(lazyFields: {'avatar', 'fullBio'}),
);

// Check load state
print(lazy.isFieldLoaded('avatar'));  // false

// Load on demand
await lazy.loadField('avatar');
print(lazy.isFieldLoaded('avatar'));  // true

// Load multiple fields
await lazy.loadFields({'avatar', 'fullBio'});

// Get field value (returns placeholder if not loaded)
final avatar = lazy.getField('avatar');

// Stream of loaded field names
lazy.fieldLoadedStream.listen((fieldName) {
  print('$fieldName loaded');
});
```

### FieldLoader

The engine behind lazy loading:

```dart
final loader = FieldLoader<User, String>(
  backend: backend,
  config: LazyLoadConfig(
    lazyFields: {'avatar', 'fullBio'},
    batchSize: 10,
  ),
);

final avatar = await loader.loadField('user-1', 'avatar');
final avatars = await loader.loadFieldBatch(['user-1', 'user-2'], 'avatar');
final state = loader.getFieldState('user-1', 'avatar');
```

## Scoped Stores

Auto-apply filters to all read operations without modifying queries:

```dart
final scopedStore = store.scoped([
  SoftDeleteScope(),                         // WHERE deleted_at IS NULL
  OwnerScope(ownerId: 'user-123'),           // WHERE owner_id = 'user-123'
]);

// All reads are automatically filtered
final users = await scopedStore.getAll();    // Both scopes applied
final count = await scopedStore.count();     // Scoped count
final stream = scopedStore.watchAll();       // Scoped stream

// Write operations pass through unmodified
await scopedStore.save(user);               // No scope applied
```

### Built-in Scopes

```dart
SoftDeleteScope()                            // Filters deleted_at IS NULL
SoftDeleteScope(field: 'removed_at')         // Custom field name

OwnerScope(ownerId: 'user-123')              // Filters owner_id = value
OwnerScope(ownerId: 'user-123', field: 'created_by')  // Custom field
```

### Custom Scopes

```dart
class ActiveOnlyScope<T> extends QueryScope<T> {
  const ActiveOnlyScope();

  @override
  Query<T> apply(Query<T> query) {
    return query.where('active', isEqualTo: true);
  }
}

// Compose multiple scopes
final scopedStore = store.scoped([
  SoftDeleteScope(),
  OwnerScope(ownerId: currentUserId),
  ActiveOnlyScope(),
]);
```

## Cross-Store Joins

Combine reactive streams from multiple stores:

```dart
// Combine two stores — re-emits when either changes
StoreJoin.combine2(
  storeA: userStore,
  storeB: orderStore,
  queryA: Query<User>().where('active', isEqualTo: true),
  queryB: Query<Order>().where('status', isEqualTo: 'pending'),
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

// Available variants:
// combine2, combine3, combine4 — emit when any store changes
// withLatest2, withLatest3, withLatest4 — emit only on primary change
```

## Composite Backend

Combine multiple backends for fallback and caching:

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

| CompositeReadStrategy | Behavior |
|-----------------------|----------|
| `primaryFirst` | Try primary, fallback, then cache |
| `cacheFirst` | Check cache first, then primary |
| `fastest` | Race all backends, return first result |

| CompositeWriteStrategy | Behavior |
|------------------------|----------|
| `primaryOnly` | Write to primary only |
| `all` | Write to all backends |
| `primaryAndCache` | Write to primary and cache |

## Sync Management

```dart
// Manual sync trigger
await store.sync();

// Pending changes count
final count = await store.pendingChangesCount;

// Cancel a pending change
await store.cancelPendingChange('change-id');

// Retry failed changes
await store.retryPendingChange('change-id');
await store.retryAllPending();
```

See [Reactive Streams > Sync Streams](#sync-streams) for pending changes and conflict streams.

## Diagnostics & Observability

### Store Statistics

```dart
final stats = store.getStats();
print('Operation counts: ${stats.operationCounts}');
print('Total durations: ${stats.totalDurations}');
print('Cache hits: ${stats.cacheHits}');
print('Cache misses: ${stats.cacheMisses}');
print('Sync successes: ${stats.syncSuccessCount}');
print('Sync failures: ${stats.syncFailureCount}');
```

### Comprehensive Diagnostics

```dart
final diagnostics = await store.getDiagnostics();
print('Health: ${diagnostics.healthStatus}');
print('Entities: ${diagnostics.entityCount}');
print('Pending changes: ${diagnostics.pendingCount}');
print('Cache hit rate: ${diagnostics.cacheHitPercentage}%');
print('Slow operations: ${diagnostics.slowOperations.length}');
```

### Memory Monitoring

```dart
store.memoryMetricsStream.listen((metrics) {
  print('Cache size: ${metrics.cacheSizeBytes}');
  print('Entry count: ${metrics.entryCount}');
});

store.memoryPressureStream.listen((level) {
  // MemoryPressureLevel: normal, moderate, critical
  if (level == MemoryPressureLevel.critical) {
    store.evictCache();
  }
});
```

### Backend Capabilities

```dart
final caps = store.capabilities;
print('Offline: ${caps.supportsOffline}');
print('Realtime: ${caps.supportsRealtime}');
print('Transactions: ${caps.supportsTransactions}');
```

## Encryption

### Database-Level Encryption (SQLCipher)

```dart
final config = StoreConfig(
  encryption: EncryptionConfig.sqlCipher(
    keyProvider: () async => await secureStorage.read(key: 'db_key'),
    kdfIterations: 256000,
  ),
);
```

### Field-Level Encryption (AES-256-GCM)

```dart
final config = StoreConfig(
  encryption: EncryptionConfig.fieldLevel(
    encryptedFields: {'ssn', 'email', 'phone'},
    keyProvider: () async => await secureStorage.read(key: 'field_key'),
    algorithm: EncryptionAlgorithm.aes256Gcm,
  ),
);
```

## Audit Logging (HIPAA)

```dart
final auditStorage = InMemoryAuditStorage();

final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(enableAuditLogging: true),
  auditService: AuditService(
    storage: auditStorage,
    actorProvider: () async => currentUser.id,
    hashChainEnabled: true,
  ),
);

// Query audit logs
final logs = await store.audit!.query(
  entityType: 'User',
  action: AuditAction.update,
  startDate: DateTime.now().subtract(Duration(days: 7)),
);

// Verify log integrity (hash chain)
final isValid = await store.audit!.verifyIntegrity();

// Export for compliance
final export = await store.audit!.export(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 12, 31),
);
```

## GDPR Compliance

```dart
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(enableGdpr: true),
  subjectIdField: 'userId',
);

// Article 20 — Data Portability
final export = await store.gdpr!.exportSubjectData('user-123');
print(export.toJson());

// Article 17 — Right to Erasure
final summary = await store.gdpr!.eraseSubjectData('user-123');
print('Deleted ${summary.deletedCount} records');

// Article 15 — Right of Access
final report = await store.gdpr!.accessSubjectData('user-123');
print('Categories: ${report.categories}');
```

## Error Handling

```dart
try {
  final user = await store.get('unknown-id');
} on NotFoundError catch (e) {
  print('User not found: ${e.id}');
} on NetworkError catch (e) {
  if (e.isRetryable) { /* retry */ }
  print('Network error: ${e.statusCode}');
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

`StoreError` (sealed base class):

| Error | Purpose | Retryable |
|-------|---------|-----------|
| `NotFoundError` | Entity not found (includes `id`, `entityType`) | No |
| `NetworkError` | Network failure (includes `statusCode`, `url`) | Yes (5xx, 408, 429) |
| `TimeoutError` | Operation timed out (includes `duration`, `operation`) | Yes |
| `ValidationError` | Validation failed (includes `violations: List<ValidationViolation>`) | No |
| `ConflictError` | Sync conflict (includes `localVersion`, `remoteVersion`, `conflictedFields`) | No |
| `SyncError` | Sync failed (includes `pendingChanges` count) | Yes |
| `AuthenticationError` | Authentication required | No |
| `AuthorizationError` | Permission denied (includes `requiredPermission`) | No |
| `TransactionError` | Transaction failed (includes `wasRolledBack`) | No |
| `StateError` | Invalid store state (includes `currentState`, `expectedState`) | No |
| `CancellationError` | Operation cancelled | No |
| `QuotaExceededError` | Quota exceeded (includes `limit`, `current`, `quotaType`) | No |
| `CircuitBreakerOpenException` | Circuit breaker open (includes `retryAfter`) | Yes |
| `SagaError` | Saga failed (includes `failedStep`, `compensatedSteps`, `failedCompensations`) | No |

**Pool Errors** (`PoolError` sealed base):

| Error | Purpose | Retryable |
|-------|---------|-----------|
| `PoolNotInitializedError` | Pool not yet initialized | No |
| `PoolClosedError` | Pool already disposed | No |
| `PoolConnectionError` | Connection creation/validation failed | Yes |
| `PoolConnectionTimeoutError` | Connection timed out | Yes |
| `PoolExhaustedError` | All pool connections in use | Yes |

All errors have: `message`, `code`, `cause`, `stackTrace`, `isRetryable`, `errorName`.

## Backend Interface

Implement `StoreBackend<T, ID>` to create custom backends:

```dart
class MyCustomBackend<T, ID> implements StoreBackend<T, ID> {
  @override
  String get name => 'MyCustomBackend';

  @override
  bool get supportsOffline => true;

  @override
  bool get supportsRealtime => false;

  @override
  bool get supportsTransactions => false;

  // Implement read/write/sync/stream methods...
}
```

See the [Backend Interface documentation](../../docs/architecture/backend-interface.md) for the full interface contract.

## Additional Resources

- [Flutter Widgets](../nexus_store_flutter_widgets/) — Builders, providers, and utilities
- [PowerSync Adapter](../nexus_store_powersync_adapter/) — Offline-first sync
- [Supabase Adapter](../nexus_store_supabase_adapter/) — Realtime backend with RLS
- [Drift Adapter](../nexus_store_drift_adapter/) — Local SQLite
- [Brick Adapter](../nexus_store_brick_adapter/) — Code-gen offline-first
- [CRDT Adapter](../nexus_store_crdt_adapter/) — Conflict-free replication
- [Architecture Overview](../../docs/architecture/overview.md)

## License

BSD 3-Clause License — see [LICENSE](../../LICENSE) for details.
