# nexus_store

[![Pub Version](https://img.shields.io/pub/v/nexus_store)](https://pub.dev/packages/nexus_store)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

A unified reactive data store abstraction providing a single consistent API across multiple storage backends with policy-based fetching, RxDart streams, and optional compliance features.

## Features

- **Unified API** - Single interface for PowerSync, Drift, Supabase, Brick, CRDT, and custom backends
- **Policy-based fetching** - Apollo GraphQL-style fetch policies (cacheFirst, networkFirst, etc.)
- **Reactive streams** - RxDart BehaviorSubject for immediate value on subscribe
- **Query builder** - Fluent API with filtering, ordering, and pagination
- **Encryption** - SQLCipher database encryption and field-level AES-256-GCM
- **Compliance** - GDPR erasure/portability, HIPAA audit logging

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
    'id': id,
    'name': name,
    'email': email,
    'status': status,
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

## Configuration

### StoreConfig

```dart
final config = StoreConfig(
  fetchPolicy: FetchPolicy.cacheFirst,       // Default read policy
  writePolicy: WritePolicy.cacheAndNetwork,  // Default write policy
  syncMode: SyncMode.realtime,               // Sync strategy
  conflictResolution: ConflictResolution.serverWins,
  staleDuration: Duration(minutes: 5),       // Cache staleness threshold
  syncInterval: Duration(minutes: 30),       // Background sync interval
  enableAuditLogging: false,                 // HIPAA audit logging
  enableGdpr: false,                         // GDPR compliance features
  encryption: EncryptionConfig.none(),       // Encryption configuration
  retryConfig: RetryConfig.defaults,         // Retry configuration
);
```

### Preset Configurations

```dart
// Sensible defaults for most apps
StoreConfig.defaults

// Optimized for offline-first apps
StoreConfig.offlineFirst

// Optimized for online-only apps
StoreConfig.onlineOnly

// Optimized for real-time data
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
// Override default policy per operation
final user = await userStore.get('1', policy: FetchPolicy.networkFirst);
```

## Write Policies

Control how data is written to cache and network:

| Policy | Behavior | Use Case |
|--------|----------|----------|
| `cacheAndNetwork` | Save to cache, then sync (optimistic) | Standard online operations |
| `networkFirst` | Wait for network sync before returning | Critical data requiring consistency |
| `cacheFirst` | Save locally, sync in background | Offline-first apps |
| `cacheOnly` | Save only to cache, never sync | Local-only data (drafts, settings) |

```dart
// Override default policy per operation
await userStore.save(user, policy: WritePolicy.networkFirst);
```

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

final users = await userStore.getAll(query: query);
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
.where('field', isNull: true)
```

## Reactive Streams

Watch for real-time updates using RxDart BehaviorSubjects:

```dart
// Watch a single entity
userStore.watch('user-123').listen((user) {
  if (user != null) {
    print('User updated: ${user.name}');
  }
});

// Watch all entities (with optional query)
userStore.watchAll(
  query: Query<User>().where('status', isEqualTo: 'active'),
).listen((users) {
  print('Active users: ${users.length}');
});

// Sync status stream
userStore.syncStatusStream.listen((status) {
  switch (status) {
    case SyncStatus.synced:
      print('All changes synced');
    case SyncStatus.syncing:
      print('Syncing...');
    case SyncStatus.pending:
      print('Changes pending');
    case SyncStatus.error:
      print('Sync error');
  }
});
```

## Encryption

### Database-Level Encryption (SQLCipher)

```dart
final config = StoreConfig(
  encryption: EncryptionConfig.sqlCipher(
    keyProvider: () async => await secureStorage.read(key: 'db_key'),
    kdfIterations: 256000,  // PBKDF2 iterations
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

Enable audit logging to track all data access and modifications:

```dart
final auditStorage = InMemoryAuditStorage();

final store = NexusStore<User, String>(
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

// Verify log integrity
final isValid = await store.audit!.verifyIntegrity();

// Export for compliance
final export = await store.audit!.export(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 12, 31),
);
```

## GDPR Compliance

Enable GDPR features for data portability and erasure:

```dart
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(enableGdpr: true),
  subjectIdField: 'userId',  // Field containing data subject ID
);

// Article 20 - Data Portability
final export = await store.gdpr!.exportSubjectData('user-123');
print(export.toJson());

// Article 17 - Right to Erasure
final summary = await store.gdpr!.eraseSubjectData('user-123');
print('Deleted ${summary.deletedCount} records');

// Article 15 - Right of Access
final report = await store.gdpr!.accessSubjectData('user-123');
print('Categories: ${report.categories}');
```

## Error Handling

The package provides typed errors for different failure scenarios:

```dart
try {
  final user = await userStore.get('unknown-id');
} on NotFoundError catch (e) {
  print('User not found: ${e.id}');
} on NetworkError catch (e) {
  if (e.isRetryable) {
    // Retry the operation
  }
  print('Network error: ${e.statusCode}');
} on ValidationError catch (e) {
  print('Validation failed: ${e.field} - ${e.message}');
} on StoreError catch (e) {
  // Catch-all for store errors
  print('Store error: ${e.message}');
}
```

### Error Types

- `NotFoundError` - Entity not found
- `NetworkError` - Network operation failed
- `TimeoutError` - Operation timed out
- `ValidationError` - Field validation failed
- `ConflictError` - Sync conflict detected
- `SyncError` - Synchronization failed
- `AuthenticationError` - Authentication required
- `AuthorizationError` - Permission denied
- `TransactionError` - Transaction failed
- `StateError` - Invalid store state

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

  // Implement read/write/sync methods...
}
```

See the [Backend Interface documentation](../../docs/architecture/backend-interface.md) for details.

## Additional Resources

- [Flutter Extension](../nexus_store_flutter/) - Widgets and providers
- [PowerSync Adapter](../nexus_store_powersync_adapter/) - Offline-first sync
- [Supabase Adapter](../nexus_store_supabase_adapter/) - Realtime backend
- [Drift Adapter](../nexus_store_drift_adapter/) - Local SQLite
- [Brick Adapter](../nexus_store_brick_adapter/) - Code-gen offline-first
- [CRDT Adapter](../nexus_store_crdt_adapter/) - Conflict-free replication
- [Architecture Overview](../../docs/architecture/overview.md)

## License

MIT License - see [LICENSE](../../LICENSE) for details.
