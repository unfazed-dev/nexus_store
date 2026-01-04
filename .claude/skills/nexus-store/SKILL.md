---
name: nexus-store
description: Unified reactive data store for Flutter/Dart with 13 packages covering storage adapters (PowerSync, Supabase, Drift, Brick, CRDT), state management bindings (Riverpod, Bloc, Signals), code generators, and Flutter widgets. Use when building data layers, choosing storage backends, implementing offline-first patterns, or integrating state management with persistent storage.
---

# nexus_store Development Skill

A unified reactive data store abstraction providing a single consistent API across multiple storage backends with policy-based fetching, RxDart streams, encryption, and compliance features.

## Quick Start

```dart
import 'package:nexus_store/nexus_store.dart';

// Create a store with your chosen backend
final userStore = NexusStore<User, String>(
  backend: yourBackend,  // PowerSyncBackend, SupabaseBackend, DriftBackend, etc.
  config: StoreConfig.defaults,
);

await userStore.initialize();

// CRUD operations
await userStore.save(User(id: '1', name: 'Alice', email: 'alice@example.com'));
final user = await userStore.get('1');
final users = await userStore.getAll();
await userStore.delete('1');

// Reactive streams
userStore.watchAll().listen((users) => print('Users: ${users.length}'));
userStore.watch('1').listen((user) => print('User: $user'));

await userStore.dispose();
```

## Package Selection Matrix

Choose packages based on your requirements:

| Use Case | Required Packages | Optional |
|----------|-------------------|----------|
| **Basic Flutter app** | nexus_store, flutter_widgets, 1 adapter | 1 state binding |
| **Offline-first mobile** | nexus_store, flutter_widgets, powersync_adapter | riverpod_binding |
| **Real-time web app** | nexus_store, flutter_widgets, supabase_adapter | signals_binding |
| **Local-only with encryption** | nexus_store, flutter_widgets, drift_adapter | - |
| **P2P collaborative** | nexus_store, flutter_widgets, crdt_adapter | - |
| **HIPAA/GDPR compliance** | nexus_store (core has compliance built-in) | Any adapter |

## Installation

### Git Installation (Development)

```yaml
dependencies:
  # Core (always required)
  nexus_store:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store

  # Flutter widgets (for Flutter apps)
  nexus_store_flutter_widgets:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_flutter_widgets

  # Choose ONE adapter
  nexus_store_powersync_adapter:  # Offline-first sync
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_powersync_adapter

  # Choose ONE state management binding (optional)
  nexus_store_riverpod_binding:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_riverpod_binding

dev_dependencies:
  # Generators (optional)
  nexus_store_generator:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_generator
  build_runner: ^2.4.0
```

### Pub.dev Installation (When Published)

```yaml
dependencies:
  nexus_store: ^0.1.0
  nexus_store_flutter_widgets: ^0.1.0
  nexus_store_powersync_adapter: ^0.1.0  # Or other adapter
  nexus_store_riverpod_binding: ^0.1.0   # Or other binding

dev_dependencies:
  nexus_store_generator: ^0.1.0
  nexus_store_entity_generator: ^0.1.0
  build_runner: ^2.4.0
```

See [references/installation.md](references/installation.md) for complete installation patterns.

## Adapter Selection Guide

| Adapter | Offline | Real-time | Transactions | Best For |
|---------|---------|-----------|--------------|----------|
| **PowerSync** | Yes | Yes | Yes | Mobile apps needing offline-first with PostgreSQL sync |
| **Supabase** | No | Yes | No | Real-time apps with Supabase backend |
| **Drift** | Local | No | No | Local-only SQLite with type-safe queries |
| **Brick** | Yes | Yes | Yes | Apps using Brick ORM annotations |
| **CRDT** | Yes | Custom | No | P2P sync, collaborative editing |

### Quick Decision Tree

1. **Need offline support?**
   - Yes, with server sync → **PowerSync** or **Brick**
   - Yes, P2P/edge → **CRDT**
   - No → **Supabase** or **Drift**

2. **Using Supabase already?**
   - Yes → **Supabase** adapter
   - No → Choose based on offline needs

3. **Local-only storage?**
   - Yes → **Drift** adapter

See [references/adapters.md](references/adapters.md) for detailed adapter documentation.

## Core Concepts

### FetchPolicy (Read Operations)

```dart
// Control how data is read
final user = await store.get('1', policy: FetchPolicy.networkFirst);
```

| Policy | Behavior | Use When |
|--------|----------|----------|
| `cacheFirst` | Cache if available, else network | Read-heavy, infrequent updates |
| `networkFirst` | Always fetch network, update cache | Fresh data critical (balance) |
| `cacheAndNetwork` | Return cache, then emit network | Instant UI + background refresh |
| `cacheOnly` | Only cached data | Offline-only scenarios |
| `networkOnly` | Always network, ignore cache | Never cache (OTP) |
| `staleWhileRevalidate` | Return stale, revalidate background | Eventual consistency OK |

### WritePolicy (Write Operations)

```dart
// Control how data is written
await store.save(user, policy: WritePolicy.networkFirst);
```

| Policy | Behavior | Use When |
|--------|----------|----------|
| `cacheAndNetwork` | Cache then sync (optimistic) | Standard online ops |
| `networkFirst` | Wait for network sync | Critical data consistency |
| `cacheFirst` | Local first, background sync | Offline-first apps |
| `cacheOnly` | Local only, never sync | Drafts, local settings |

### Query Builder

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

**Filter Operators:**
- `isEqualTo`, `isNotEqualTo`
- `isLessThan`, `isLessThanOrEqualTo`
- `isGreaterThan`, `isGreaterThanOrEqualTo`
- `whereIn`, `whereNotIn`
- `arrayContains`, `arrayContainsAny`
- `isNull`

### StoreConfig Presets

```dart
StoreConfig.defaults       // Sensible defaults
StoreConfig.offlineFirst   // Optimized for offline
StoreConfig.onlineOnly     // Network-dependent
StoreConfig.realtime       // Real-time subscriptions
```

## State Management Integration

### Riverpod

```dart
// Create providers
final userStoreProvider = createNexusStoreProvider<User, String>(
  (ref) => NexusStore(backend: backend, config: StoreConfig.defaults),
);

// Watch in widgets
final users = ref.watch(userStoreProvider).watchAll();

// Use consumer widgets
NexusStoreListConsumer<User, String>(
  store: ref.read(userStoreProvider),
  builder: (context, users, status) => ListView.builder(...),
);
```

### Bloc

```dart
// Use Cubit for reactive state
final userCubit = NexusStoreCubit<User, String>(store);
await userCubit.loadAll();

// Pattern match on state
BlocBuilder<NexusStoreCubit<User, String>, NexusStoreState<User>>(
  bloc: userCubit,
  builder: (context, state) => state.when(
    initial: () => Text('Initial'),
    loading: () => CircularProgressIndicator(),
    loaded: (users) => UserList(users),
    error: (e, prev) => Text('Error: $e'),
  ),
);
```

### Signals

```dart
// Convert to signals
final usersSignal = store.toSignal();

// Computed signals
final activeUsers = usersSignal.filtered((u) => u.isActive);
final userCount = usersSignal.count();

// Use in widgets with NexusSignalsMixin
SignalBuilder(
  signal: usersSignal.signal,
  builder: (context, users) => UserList(users),
);
```

See [references/state-management.md](references/state-management.md) for complete integration patterns.

## Code Generation

### Entity Generator (Type-safe Queries)

```dart
import 'package:nexus_store/nexus_store.dart';

part 'user.entity.dart';

@NexusEntity()
class User {
  final String id;
  final String name;
  final int age;
}

// Generated: UserFields class
final query = Query<User>()
  .whereExpression(UserFields.age.greaterThan(18));
```

### Lazy Field Generator

```dart
@NexusLazy()
class Post {
  final String id;

  @Lazy(placeholder: [])
  final List<Comment> comments;
}

// Generated: load methods
await post.loadComments();
```

### Riverpod Generator

```dart
@riverpodNexusStore
NexusStore<User, String> userStore(UserStoreRef ref) {
  return NexusStore(backend: backend, config: StoreConfig.defaults);
}

// Generated: userStoreProvider, userProvider, userByIdProvider, userStatusProvider
```

See [references/generators.md](references/generators.md) for build_runner configuration.

## Common Patterns

### Offline-First with Sync

```dart
final store = NexusStore<User, String>(
  backend: PowerSyncBackend(powerSync, 'users'),
  config: StoreConfig.offlineFirst,
);

// Monitor sync status
store.syncStatusStream.listen((status) {
  switch (status) {
    case SyncStatus.synced: print('Synced');
    case SyncStatus.syncing: print('Syncing...');
    case SyncStatus.pending: print('Changes pending');
    case SyncStatus.error: print('Sync error');
  }
});
```

### Encrypted Storage

```dart
final config = StoreConfig(
  encryption: EncryptionConfig.sqlCipher(
    keyProvider: () async => await secureStorage.read(key: 'db_key'),
    kdfIterations: 256000,
  ),
);

// Or field-level encryption
final config = StoreConfig(
  encryption: EncryptionConfig.fieldLevel(
    encryptedFields: {'ssn', 'email', 'phone'},
    keyProvider: () async => await secureStorage.read(key: 'field_key'),
    algorithm: EncryptionAlgorithm.aes256Gcm,
  ),
);
```

### HIPAA Audit Logging

```dart
final store = NexusStore<Patient, String>(
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
  entityType: 'Patient',
  action: AuditAction.update,
  startDate: DateTime.now().subtract(Duration(days: 7)),
);
```

### GDPR Compliance

```dart
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(enableGdpr: true),
  subjectIdField: 'userId',
);

// Data portability (Article 20)
final export = await store.gdpr!.exportSubjectData('user-123');

// Right to erasure (Article 17)
await store.gdpr!.eraseSubjectData('user-123');

// Right of access (Article 15)
final report = await store.gdpr!.accessSubjectData('user-123');
```

See [references/encryption-compliance.md](references/encryption-compliance.md) for security details.

## Flutter Widgets

```dart
// Result builder for single items
NexusStoreItemBuilder<User, String>(
  store: userStore,
  id: 'user-123',
  builder: (context, result) => result.when(
    idle: () => Text('Idle'),
    pending: () => CircularProgressIndicator(),
    success: (user) => Text(user.name),
    error: (e) => Text('Error: $e'),
  ),
);

// List builder with query
NexusStoreBuilder<User, String>(
  store: userStore,
  query: Query<User>().where('active', isEqualTo: true),
  builder: (context, result) => result.when(
    idle: () => Text('Idle'),
    pending: () => CircularProgressIndicator(),
    success: (users) => ListView.builder(
      itemCount: users.length,
      itemBuilder: (_, i) => Text(users[i].name),
    ),
    error: (e) => Text('Error: $e'),
  ),
);

// Provider for dependency injection
NexusStoreProvider<User, String>(
  store: userStore,
  child: MyApp(),
);

// Access via context
final store = context.nexusStore<User, String>();
```

## Error Handling

```dart
try {
  final user = await store.get('unknown');
} on NotFoundError catch (e) {
  print('Not found: ${e.id}');
} on NetworkError catch (e) {
  if (e.isRetryable) { /* retry */ }
  print('Network: ${e.statusCode}');
} on ValidationError catch (e) {
  print('Validation: ${e.field} - ${e.message}');
} on ConflictError catch (e) {
  print('Conflict detected');
} on AuthenticationError catch (e) {
  print('Auth required');
} on AuthorizationError catch (e) {
  print('Permission denied');
}
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Store not initialized | Call `await store.initialize()` before operations |
| Sync not working | Check backend `supportsRealtime` capability |
| Query returns empty | Verify filter operators match field types |
| Encryption key error | Ensure key provider returns consistent key |
| GDPR service null | Enable `enableGdpr: true` in StoreConfig |
| Audit service null | Enable `enableAuditLogging: true` in StoreConfig |
| Build runner fails | Run `dart run build_runner build --delete-conflicting-outputs` |

## References

- [Installation Guide](references/installation.md) - Complete installation patterns
- [Storage Adapters](references/adapters.md) - All 5 adapter details
- [State Management](references/state-management.md) - Riverpod/Bloc/Signals
- [Code Generators](references/generators.md) - Entity/Lazy/Riverpod generators
- [Encryption & Compliance](references/encryption-compliance.md) - Security features
- [API Quick Reference](references/api-quick-reference.md) - Condensed cheatsheet
