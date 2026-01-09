# nexus_store_powersync_adapter

[![Pub Version](https://img.shields.io/pub/v/nexus_store_powersync_adapter)](https://pub.dev/packages/nexus_store_powersync_adapter)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

PowerSync adapter for nexus_store with offline-first sync and SQLCipher support. Batteries included.

## Features

- **Batteries Included** - Single factory handles schema, database, and connector setup
- **Offline-First** - Full offline support with automatic sync when online
- **Real-Time Sync** - Live updates from PostgreSQL via PowerSync service
- **Multi-Table Support** - Share a single database across multiple backends
- **Sync Rules Generation** - Generate PowerSync sync rules YAML from Dart code
- **SQLCipher Encryption** - Optional database-level encryption
- **Query Translation** - Automatic translation of nexus_store queries to SQL

## Prerequisites

1. A [PowerSync](https://www.powersync.com/) account
2. A [Supabase](https://supabase.com/) project (or other PostgreSQL database)
3. PowerSync connected to your database

## Installation

```yaml
dependencies:
  nexus_store: ^0.1.0
  nexus_store_powersync_adapter: ^0.1.0
  supabase: ^2.8.0
```

## Quick Start

The simplest way to get started - everything is handled for you:

```dart
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';
import 'package:supabase/supabase.dart';

// Create the backend with Supabase integration
final backend = PowerSyncBackend<User, String>.withSupabase(
  supabase: Supabase.instance.client,
  powerSyncUrl: 'https://your-instance.powersync.co',
  tableName: 'users',
  columns: [
    PSColumn.text('name'),
    PSColumn.text('email'),
    PSColumn.integer('age', nullable: true),
  ],
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,
);

// Initialize - handles database creation and connection
await backend.initialize();

// Create the store
final userStore = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig.offlineFirst,
);

await userStore.initialize();

// Use the store
final users = await userStore.getAll();
await userStore.save(User(id: '1', name: 'Alice', email: 'alice@example.com'));

// Clean up
await backend.dispose();
```

## Column Definitions

Define your table schema using type-safe column definitions:

```dart
final columns = [
  PSColumn.text('name'),                    // TEXT NOT NULL
  PSColumn.text('email'),                   // TEXT NOT NULL
  PSColumn.integer('age', nullable: true),  // INTEGER (nullable)
  PSColumn.real('rating'),                  // REAL NOT NULL
];
```

### Column Types

| Factory | SQL Type | Description |
|---------|----------|-------------|
| `PSColumn.text(name)` | TEXT | String values |
| `PSColumn.integer(name)` | INTEGER | Whole numbers |
| `PSColumn.real(name)` | REAL | Floating-point numbers |

All columns default to `NOT NULL`. Use `nullable: true` for optional fields.

## Multi-Table Apps

For apps with multiple tables, use `PowerSyncManager` to share a single database:

```dart
final manager = PowerSyncManager.withSupabase(
  supabase: Supabase.instance.client,
  powerSyncUrl: 'https://your-instance.powersync.co',
  tables: [
    PSTableConfig<User, String>(
      tableName: 'users',
      columns: [
        PSColumn.text('name'),
        PSColumn.text('email'),
      ],
      fromJson: User.fromJson,
      toJson: (u) => u.toJson(),
      getId: (u) => u.id,
    ),
    PSTableConfig<Post, String>(
      tableName: 'posts',
      columns: [
        PSColumn.text('title'),
        PSColumn.text('content'),
        PSColumn.text('author_id'),
      ],
      fromJson: Post.fromJson,
      toJson: (p) => p.toJson(),
      getId: (p) => p.id,
    ),
  ],
);

await manager.initialize();

// Get individual backends
final userBackend = manager.getBackend<User, String>('users');
final postBackend = manager.getBackend<Post, String>('posts');

// Create stores
final userStore = NexusStore<User, String>(backend: userBackend);
final postStore = NexusStore<Post, String>(backend: postBackend);

// Clean up
await manager.dispose();
```

## Sync Rules Generation

Generate PowerSync sync rules YAML programmatically:

```dart
final syncRules = PSSyncRules([
  // Public data - synced to all users
  PSBucket.global(
    name: 'public_data',
    queries: [
      PSQuery.select(table: 'settings'),
    ],
  ),

  // User-specific data - filtered by user_id
  PSBucket.userScoped(
    name: 'user_data',
    queries: [
      PSQuery.select(
        table: 'users',
        columns: ['id', 'name', 'email'],
        filter: 'id = bucket.user_id',
      ),
      PSQuery.select(
        table: 'posts',
        filter: 'author_id = bucket.user_id',
      ),
    ],
  ),

  // Parameterized - custom bucket parameters
  PSBucket.parameterized(
    name: 'team_data',
    parameters: 'SELECT team_id FROM team_members WHERE user_id = token_parameters.user_id',
    queries: [
      PSQuery.select(table: 'teams', filter: 'id = bucket.team_id'),
    ],
  ),
]);

// Generate YAML
print(syncRules.toYaml());

// Or save to file
await syncRules.saveToFile('sync-rules.yaml');
```

### Generated Output

```yaml
bucket_definitions:
  - name: public_data
    data:
      - SELECT * FROM settings
  - name: user_data
    parameters: SELECT request.user_id() as user_id
    data:
      - SELECT id, name, email FROM users WHERE id = bucket.user_id
      - SELECT * FROM posts WHERE author_id = bucket.user_id
  - name: team_data
    parameters: SELECT team_id FROM team_members WHERE user_id = token_parameters.user_id
    data:
      - SELECT * FROM teams WHERE id = bucket.team_id
```

## Configuration Options

```dart
final backend = PowerSyncBackend<User, String>.withSupabase(
  supabase: supabaseClient,
  powerSyncUrl: 'https://...',
  tableName: 'users',
  columns: [...],
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,

  // Optional configuration
  dbPath: '/custom/path/app.db',  // Custom database path
  primaryKeyColumn: 'user_id',     // Custom primary key (default: 'id')
  fieldMapping: {                  // Map model fields to DB columns
    'firstName': 'first_name',
    'lastName': 'last_name',
  },
);
```

## SQLCipher Encryption

For encrypted databases:

```dart
final backend = PowerSyncEncryptedBackend<User, String>(
  db: encryptedPowerSyncDb,
  tableName: 'users',
  getId: (user) => user.id,
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  keyProvider: InMemoryKeyProvider(encryptionKey),
);
```

### Custom Key Provider

```dart
class SecureKeyProvider implements EncryptionKeyProvider {
  @override
  Future<String> getKey() async {
    return await secureStorage.read(key: 'db_encryption_key');
  }

  @override
  Future<String> rotateKey(String newKey) async {
    await secureStorage.write(key: 'db_encryption_key', value: newKey);
    return newKey;
  }

  @override
  Future<void> dispose() async {
    // Clean up resources
  }
}
```

## Sync Status

Monitor synchronization status:

```dart
// Current status
final status = backend.syncStatus; // synced, pending, syncing, error

// Watch changes
backend.syncStatusStream.listen((status) {
  switch (status) {
    case SyncStatus.synced:
      print('All changes synced');
    case SyncStatus.pending:
      print('Changes waiting to sync');
    case SyncStatus.syncing:
      print('Syncing...');
    case SyncStatus.error:
      print('Sync error');
  }
});

// Pending changes count
final pending = await backend.pendingChangesCount;

// Manual sync trigger
await backend.sync();
```

## Query Translation

Queries are automatically translated to SQL:

```dart
final query = Query<User>()
  .where('status', isEqualTo: 'active')
  .where('age', isGreaterThan: 18)
  .orderBy('createdAt', descending: true)
  .limit(10);

// Translates to:
// SELECT * FROM users
// WHERE status = 'active' AND age > 18
// ORDER BY createdAt DESC
// LIMIT 10

final users = await userStore.getAll(query: query);
```

## Advanced: Manual Setup

For advanced use cases, you can configure PowerSync manually:

```dart
import 'package:powersync/powersync.dart';

// Manual PowerSync database setup
final powerSyncDb = PowerSyncDatabase(
  schema: schema,
  path: 'app.db',
);
await powerSyncDb.initialize();

// Manual backend creation
final backend = PowerSyncBackend<User, String>(
  db: powerSyncDb,
  tableName: 'users',
  getId: (user) => user.id,
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
);

await backend.initialize();
```

## Testing

```bash
# Unit tests
dart test test/unit/

# All tests
dart test
```

### Integration Tests

Integration tests require PowerSync native library. See test utilities in `test/test_utils/powersync_test_utils.dart`.

## API Reference

### Core Classes

| Class | Description |
|-------|-------------|
| `PowerSyncBackend<T, ID>` | Backend for single-table apps |
| `PowerSyncManager` | Manager for multi-table apps |
| `PSTableConfig<T, ID>` | Table configuration for manager |
| `PSColumn` | Column definition with type-safe factories |

### Sync Rules Classes

| Class | Description |
|-------|-------------|
| `PSSyncRules` | Container for sync rules |
| `PSBucket` | Bucket definition (global, userScoped, parameterized) |
| `PSQuery` | SELECT query for bucket data |

### Encryption Classes

| Class | Description |
|-------|-------------|
| `PowerSyncEncryptedBackend<T, ID>` | Encrypted database backend |
| `EncryptionKeyProvider` | Abstract key provider interface |
| `InMemoryKeyProvider` | Simple in-memory key storage |

## Additional Resources

- [PowerSync Documentation](https://docs.powersync.com/)
- [Supabase Documentation](https://supabase.com/docs)
- [Core Package](../nexus_store/)

## License

BSD 3-Clause License - see [LICENSE](../../LICENSE) for details.
