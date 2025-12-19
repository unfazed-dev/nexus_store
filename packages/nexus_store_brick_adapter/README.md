# nexus_store_brick_adapter

[![Pub Version](https://img.shields.io/pub/v/nexus_store_brick_adapter)](https://pub.dev/packages/nexus_store_brick_adapter)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Brick adapter for nexus_store with offline-first capabilities.

## Features

- **Offline-First** - Local caching with automatic sync via Brick
- **Code Generation** - Works with Brick's annotation-based code generation
- **Multiple Remotes** - Supports Supabase, REST, and GraphQL remotes
- **Query Translation** - Automatic translation to Brick queries
- **Model Annotations** - Leverage Brick's model annotations

## Prerequisites

1. Brick package configured in your project
2. Brick models defined with annotations
3. Brick repository set up
4. Build runner configured for code generation

## Installation

```yaml
dependencies:
  nexus_store: ^0.1.0
  nexus_store_brick_adapter: ^0.1.0
  brick_offline_first: ^4.0.0
  brick_offline_first_with_supabase: ^2.1.0  # Or your preferred remote

dev_dependencies:
  brick_offline_first_build: ^4.0.0
  build_runner: ^2.4.0
```

## Basic Usage

```dart
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_brick_adapter/nexus_store_brick_adapter.dart';

// Create the backend with your Brick repository
final backend = BrickBackend<User, String>(
  repository: myBrickRepository,
  getId: (user) => user.id,
  primaryKeyField: 'id',
);

await backend.initialize();

// Create the store
final userStore = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig.offlineFirst,
);

await userStore.initialize();
```

## Model Requirements

Your models must extend `OfflineFirstModel` from Brick:

```dart
import 'package:brick_offline_first/brick_offline_first.dart';

@ConnectOfflineFirstWithSupabase()
class User extends OfflineFirstModel {
  @Supabase(unique: true)
  final String id;

  final String name;
  final String email;
  final bool isActive;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.isActive = true,
  });
}
```

## Configuration Options

```dart
final backend = BrickBackend<User, String>(
  repository: myBrickRepository,
  getId: (user) => user.id,
  primaryKeyField: 'id',
  fieldMapping: {                // Optional: model to query field mapping
    'firstName': 'first_name',
    'lastName': 'last_name',
  },
);
```

## Offline-First Patterns

### Automatic Sync

Brick handles sync automatically:

```dart
// Save locally first, sync in background
await userStore.save(user);

// Data is available offline immediately
final users = await userStore.getAll();
```

### Check Sync Status

```dart
// Monitor sync status
backend.syncStatusStream.listen((status) {
  switch (status) {
    case SyncStatus.synced:
      print('All data synced');
    case SyncStatus.pending:
      print('Changes waiting to sync');
    case SyncStatus.syncing:
      print('Syncing...');
    case SyncStatus.error:
      print('Sync error');
  }
});

// Check pending changes
final pending = await backend.pendingChangesCount;
print('$pending changes pending');
```

### Manual Sync

```dart
// Force sync
await backend.sync();
```

## Query Translation

Queries are translated to Brick queries:

```dart
final query = Query<User>()
  .where('isActive', isEqualTo: true)
  .where('role', whereIn: ['admin', 'editor'])
  .orderBy('name')
  .limit(20);

final users = await userStore.getAll(query: query);
```

## Reactive Streams

Watch for real-time local and remote updates:

```dart
// Watch all users
userStore.watchAll().listen((users) {
  print('Users updated: ${users.length}');
});

// Watch with query
userStore.watchAll(
  query: Query<User>().where('isActive', isEqualTo: true),
).listen((activeUsers) {
  print('Active users: ${activeUsers.length}');
});
```

## Backend Capabilities

```dart
backend.supportsOffline      // true - offline-first
backend.supportsRealtime     // true - real-time updates
backend.supportsTransactions // true - transaction support
```

## Working with Brick Repository

### Repository Setup

```dart
// Your Brick repository
class MyRepository extends OfflineFirstWithSupabaseRepository {
  MyRepository({
    required super.supabaseProvider,
    required super.sqliteProvider,
    required super.migrations,
    required super.offlineRequestQueue,
  });
}

// Create repository
final repository = MyRepository(
  supabaseProvider: SupabaseProvider(supabaseClient),
  sqliteProvider: SqliteProvider('app.db'),
  migrations: migrations,
  offlineRequestQueue: OfflineRequestQueue(),
);

await repository.initialize();

// Use with nexus_store
final backend = BrickBackend<User, String>(
  repository: repository,
  getId: (user) => user.id,
  primaryKeyField: 'id',
);
```

### Access Underlying Repository

```dart
// For advanced Brick operations
final brickRepository = backend.repository;
await brickRepository.get<User>(query: BrickQuery(...));
```

## Error Handling

```dart
try {
  await userStore.save(user);
} on SyncError catch (e) {
  print('Sync failed: ${e.message}');
  // Data is still saved locally
} on ValidationError catch (e) {
  print('Validation error: ${e.message}');
}
```

## Additional Resources

- [Brick Documentation](https://getdutchie.github.io/brick/)
- [Core Package](../nexus_store/)

## License

MIT License - see [LICENSE](../../LICENSE) for details.
