# API Quick Reference

Condensed cheatsheet for nexus_store APIs.

## NexusStore<T, ID>

```dart
// Lifecycle
await store.initialize();
await store.dispose();

// Read
final item = await store.get(id);
final item = await store.get(id, policy: FetchPolicy.networkFirst);
final items = await store.getAll();
final items = await store.getAll(query: query, policy: policy);

// Write
await store.save(item);
await store.save(item, policy: WritePolicy.networkFirst);
await store.saveAll([item1, item2]);
await store.delete(id);
await store.deleteAll([id1, id2]);

// Watch (RxDart BehaviorSubject)
store.watch(id).listen((item) => ...);
store.watchAll().listen((items) => ...);
store.watchAll(query: query, policy: policy).listen(...);

// Sync
store.syncStatusStream.listen((status) => ...);
await store.sync();
await store.invalidateAll();

// Compliance (when enabled)
store.audit?.query(...);
store.gdpr?.exportSubjectData(...);
```

## Query<T>

```dart
Query<User>()
  // Filters
  .where('field', isEqualTo: value)
  .where('field', isNotEqualTo: value)
  .where('field', isLessThan: value)
  .where('field', isLessThanOrEqualTo: value)
  .where('field', isGreaterThan: value)
  .where('field', isGreaterThanOrEqualTo: value)
  .where('field', whereIn: [v1, v2])
  .where('field', whereNotIn: [v1, v2])
  .where('field', arrayContains: value)
  .where('field', arrayContainsAny: [v1, v2])
  .where('field', isNull: true)

  // Type-safe expressions (with generator)
  .whereExpression(UserFields.age.greaterThan(18))
  .whereExpression(UserFields.name.contains('John'))

  // Ordering
  .orderBy('field')
  .orderBy('field', descending: true)

  // Pagination
  .limit(10)
  .offset(20)
```

## FetchPolicy

| Policy | Behavior |
|--------|----------|
| `cacheFirst` | Cache → Network (if miss) |
| `networkFirst` | Network → Cache (on error) |
| `cacheAndNetwork` | Cache immediately, then Network |
| `cacheOnly` | Cache only |
| `networkOnly` | Network only |
| `staleWhileRevalidate` | Stale cache, background revalidate |

## WritePolicy

| Policy | Behavior |
|--------|----------|
| `cacheAndNetwork` | Cache + sync (optimistic) |
| `networkFirst` | Wait for network sync |
| `cacheFirst` | Local first, background sync |
| `cacheOnly` | Local only, never sync |

## StoreConfig

```dart
StoreConfig(
  fetchPolicy: FetchPolicy.cacheFirst,
  writePolicy: WritePolicy.cacheAndNetwork,
  syncMode: SyncMode.realtime,           // realtime | scheduled | manual
  conflictResolution: ConflictResolution.serverWins,
  staleDuration: Duration(minutes: 5),
  syncInterval: Duration(minutes: 30),
  enableAuditLogging: false,
  enableGdpr: false,
  encryption: EncryptionConfig.none(),
  retryConfig: RetryConfig.defaults,
)

// Presets
StoreConfig.defaults      // Sensible defaults
StoreConfig.offlineFirst  // Offline-first optimized
StoreConfig.onlineOnly    // Network-dependent
StoreConfig.realtime      // Real-time subscriptions
```

## EncryptionConfig

```dart
// No encryption
EncryptionConfig.none()

// SQLCipher database encryption
EncryptionConfig.sqlCipher(
  keyProvider: () async => key,
  kdfIterations: 256000,
)

// Field-level encryption
EncryptionConfig.fieldLevel(
  encryptedFields: {'ssn', 'email'},
  keyProvider: () async => key,
  algorithm: EncryptionAlgorithm.aes256Gcm,
)
```

## Error Types

```dart
try {
  await store.get(id);
} on NotFoundError catch (e) {
  // e.id, e.entityType
} on NetworkError catch (e) {
  // e.statusCode, e.isRetryable, e.message
} on TimeoutError catch (e) {
  // e.duration, e.message
} on ValidationError catch (e) {
  // e.field, e.message, e.value
} on ConflictError catch (e) {
  // e.localVersion, e.serverVersion
} on SyncError catch (e) {
  // e.operation, e.message
} on AuthenticationError catch (e) {
  // e.message
} on AuthorizationError catch (e) {
  // e.requiredPermission, e.message
} on TransactionError catch (e) {
  // e.operations, e.failedIndex
} on StoreError catch (e) {
  // Base class for all store errors
}
```

## SyncStatus

```dart
store.syncStatusStream.listen((status) {
  switch (status) {
    case SyncStatus.synced:    // All changes synced
    case SyncStatus.syncing:   // Sync in progress
    case SyncStatus.pending:   // Changes waiting to sync
    case SyncStatus.error:     // Sync failed
  }
});
```

## StoreResult<T>

```dart
result.when(
  idle: () => ...,
  pending: () => ...,
  success: (data) => ...,
  error: (error) => ...,
);

// Properties
result.isIdle
result.isPending
result.isSuccess
result.isError
result.data      // T? - data if success
result.error     // Object? - error if error
```

## Flutter Widgets

```dart
// Single item
NexusStoreItemBuilder<T, ID>(
  store: store,
  id: itemId,
  builder: (context, result) => result.when(...),
)

// List
NexusStoreBuilder<T, ID>(
  store: store,
  query: query,  // Optional
  builder: (context, result) => result.when(...),
)

// Provider
NexusStoreProvider<T, ID>(store: store, child: child)
MultiNexusStoreProvider(stores: [store1, store2], child: child)

// Context access
context.nexusStore<T, ID>()
context.maybeNexusStore<T, ID>()
```

## Riverpod

```dart
// Create providers
createNexusStoreProvider<T, ID>((ref) => store)
createAutoDisposeNexusStoreProvider<T, ID>((ref) => store)
createWatchAllProvider<T, ID>(storeProvider)
createWatchByIdProvider<T, ID>(storeProvider)

// Ref extensions
ref.watchStoreAll<T, ID>(provider)
ref.watchStoreItem<T, ID>(provider, id)
ref.readStore<T, ID>(provider)
ref.refreshStoreList<T, ID>(provider)

// Generator: @riverpodNexusStore
// Generates: {name}StoreProvider, {name}Provider, {name}ByIdProvider, {name}StatusProvider
```

## Bloc

```dart
// Cubit
NexusStoreCubit<T, ID>(store)
  .loadAll(query?)
  .save(item)
  .delete(id)
  .refresh()

NexusItemCubit<T, ID>(store, id)
  .load()
  .save(item)
  .delete()
  .refresh()

// States
NexusStoreState<T>.initial()
NexusStoreState<T>.loading(previousData?)
NexusStoreState<T>.loaded(data)
NexusStoreState<T>.error(error, previousData?)

NexusItemState<T>.initial()
NexusItemState<T>.loading(previous?)
NexusItemState<T>.loaded(item)
NexusItemState<T>.notFound()
NexusItemState<T>.error(error, previous?)
```

## Signals

```dart
// Convert to signals
store.toSignal()           // NexusListSignal<T>
store.toItemSignal(id)     // NexusSignal<T?>
store.toStateSignal()      // Signal<NexusSignalState<List<T>>>
store.toItemStateSignal(id) // Signal<NexusItemSignalState<T>>

// List signal methods
signal.add(item)
signal.update(id, updater)
signal.remove(id)
signal.refresh()

// Computed signals
signal.filtered(predicate)
signal.sorted(comparator)
signal.count()
signal.firstWhereOrNull(predicate)
signal.mapped(transform)
signal.any(predicate)
signal.every(predicate)
```

## Adapters

| Adapter | Package | Backend Constructor |
|---------|---------|-------------------|
| PowerSync | `nexus_store_powersync_adapter` | `PowerSyncBackend<T, ID>(powerSync, table, ...)` |
| Supabase | `nexus_store_supabase_adapter` | `SupabaseBackend<T, ID>(client, table, ...)` |
| Drift | `nexus_store_drift_adapter` | `DriftBackend<T, ID>(tableRef, ...)` |
| Brick | `nexus_store_brick_adapter` | `BrickBackend<T, ID>(repository, ...)` |
| CRDT | `nexus_store_crdt_adapter` | `CrdtBackend<T, ID>(nodeId, table, ...)` |
| Composite | Core | `CompositeBackend(primary, fallback?, cache?)` |
