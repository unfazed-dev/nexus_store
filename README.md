# nexus_store

[![Pub Version](https://img.shields.io/pub/v/nexus_store)](https://pub.dev/packages/nexus_store)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![Dart](https://img.shields.io/badge/Dart-3.5+-blue.svg)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev)

A unified reactive data store abstraction for Dart and Flutter. Use a single consistent API across multiple storage backends with policy-based fetching, RxDart streams, and optional compliance features.

## Features

- **Unified Backend Interface** - Single API for PowerSync, Supabase, Drift, Brick, and CRDT backends
- **Reactive Streams** - RxDart BehaviorSubjects for immediate values and real-time updates
- **Policy-Based Operations** - Apollo-style fetch/write policies (cacheFirst, networkFirst, etc.)
- **Query Builder** - Fluent API for filtering, ordering, and pagination
- **Encryption Support** - SQLCipher database encryption and field-level AES-256-GCM
- **Compliance Ready** - HIPAA audit logging and GDPR data portability/erasure
- **Flutter Widgets** - Ready-to-use builders and providers for Flutter apps

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

### State Management Examples

**Riverpod:**
```dart
@riverpodNexusStore
NexusStore<User, String> userStore(Ref ref) {
  return NexusStore(backend: backend);
}

// Generated providers: userStoreProvider, usersProvider, userByIdProvider
class MyWidget extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);
    return users.when(
      data: (list) => ListView(children: list.map((u) => Text(u.name)).toList()),
      loading: () => CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
```

**Bloc:**
```dart
class UsersCubit extends NexusStoreCubit<User, String> {
  UsersCubit(NexusStore<User, String> store) : super(store);
}

// Use with BlocBuilder
BlocBuilder<UsersCubit, StoreState<List<User>>>(
  builder: (context, state) => state.when(
    loading: () => CircularProgressIndicator(),
    data: (users) => UserList(users),
    error: (e) => ErrorWidget(e),
  ),
)
```

**Signals:**
```dart
final usersSignal = userStore.toSignal();
final activeCount = computed(() =>
  usersSignal.value.where((u) => u.isActive).length
);
```

## Backend Selection Guide

Choose the right backend for your use case:

| Backend | Best For | Sync | Offline | Conflict Resolution |
|---------|----------|------|---------|---------------------|
| **PowerSync** | Offline-first apps with PostgreSQL | Bi-directional | Full | Server-authoritative |
| **Supabase** | Real-time apps, RLS security | Real-time | Limited | Last-write-wins |
| **Drift** | Local-only storage, no sync needed | None | Full | N/A |
| **Brick** | Multiple remotes (REST, GraphQL, Supabase) | Bi-directional | Full | Customizable |
| **CRDT** | P2P, multi-device, no central server | Peer-to-peer | Full | Automatic (LWW) |

### When to Use Each

- **PowerSync**: Enterprise apps needing PostgreSQL sync with offline support
- **Supabase**: Apps requiring real-time updates and Row Level Security
- **Drift**: Settings storage, local caching, or apps with no network requirements
- **Brick**: Complex apps with multiple data sources or migration between backends
- **CRDT**: Collaborative apps, P2P sync, or conflict-free distributed data

## Packages

| Package | Description | Pub |
|---------|-------------|-----|
| [nexus_store](packages/nexus_store/) | Core store abstraction | [![pub](https://img.shields.io/pub/v/nexus_store)](https://pub.dev/packages/nexus_store) |
| [nexus_store_flutter](packages/nexus_store_flutter/) | Flutter widgets and providers | [![pub](https://img.shields.io/pub/v/nexus_store_flutter)](https://pub.dev/packages/nexus_store_flutter) |
| [nexus_store_powersync_adapter](packages/nexus_store_powersync_adapter/) | PowerSync offline-first backend | [![pub](https://img.shields.io/pub/v/nexus_store_powersync_adapter)](https://pub.dev/packages/nexus_store_powersync_adapter) |
| [nexus_store_supabase_adapter](packages/nexus_store_supabase_adapter/) | Supabase realtime backend | [![pub](https://img.shields.io/pub/v/nexus_store_supabase_adapter)](https://pub.dev/packages/nexus_store_supabase_adapter) |
| [nexus_store_drift_adapter](packages/nexus_store_drift_adapter/) | Drift local SQLite backend | [![pub](https://img.shields.io/pub/v/nexus_store_drift_adapter)](https://pub.dev/packages/nexus_store_drift_adapter) |
| [nexus_store_brick_adapter](packages/nexus_store_brick_adapter/) | Brick offline-first backend | [![pub](https://img.shields.io/pub/v/nexus_store_brick_adapter)](https://pub.dev/packages/nexus_store_brick_adapter) |
| [nexus_store_crdt_adapter](packages/nexus_store_crdt_adapter/) | CRDT conflict-free backend | [![pub](https://img.shields.io/pub/v/nexus_store_crdt_adapter)](https://pub.dev/packages/nexus_store_crdt_adapter) |

### State Management Bindings

| Package | Description |
|---------|-------------|
| [nexus_store_riverpod_binding](packages/nexus_store_riverpod_binding/) | Riverpod providers and hooks |
| [nexus_store_bloc_binding](packages/nexus_store_bloc_binding/) | Bloc/Cubit integration |
| [nexus_store_signals_binding](packages/nexus_store_signals_binding/) | Signals fine-grained reactivity |

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
  nexus_store_flutter: ^0.1.0
```

## Requirements

- Dart SDK: ^3.5.0
- Flutter SDK: ^3.10.0 (for Flutter packages)

## Compliance Features

nexus_store includes enterprise-ready compliance features for HIPAA and GDPR requirements.

### HIPAA Audit Logging

```dart
final store = NexusStore<Patient, String>(
  backend: backend,
  config: StoreConfig(
    audit: AuditConfig.hipaaCompliant(
      backend: auditBackend,
      signLogs: true, // Cryptographic hash chain
    ),
  ),
);

// All operations are automatically logged with:
// - userId, timestamp, action, resourceType, resourceId
// - IP address and success/failure status
// - Hash-chained for tamper detection
```

### GDPR Data Erasure (Article 17)

```dart
// Process right to erasure requests
final result = await store.gdpr.processErasureRequest(
  userId: 'user_123',
  anonymize: true, // Anonymize instead of delete if required
);
print('Erased ${result.deletedCount} records');
```

### GDPR Data Portability (Article 20)

```dart
// Export all user data in machine-readable format
final export = await store.gdpr.exportUserData(
  userId: 'user_123',
  format: ExportFormat.json,
);
// Returns JSON with all user data and checksum
```

### Field-Level Encryption

```dart
final store = NexusStore<Patient, String>(
  backend: backend,
  config: StoreConfig(
    encryption: EncryptionConfig.fieldLevel(
      encryptedFields: {'ssn', 'diagnosis', 'medications'},
      keyProvider: () => secureStorage.getKey(),
    ),
  ),
);
// Specified fields are encrypted with AES-256-GCM before storage
```

## Documentation

### Package Documentation
- [Core Package](packages/nexus_store/README.md)
- [Flutter Extension](packages/nexus_store_flutter/README.md)

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

- [Basic Usage](example/basic_usage/) - Console app with CRUD and queries
- [Flutter Widgets](example/flutter_widgets/) - Flutter app with reactive widgets

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
