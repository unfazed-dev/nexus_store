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

## Supabase Connector

The adapter includes a ready-to-use connector for Supabase integration:

### Default Usage

```dart
final connector = SupabasePowerSyncConnector.withClient(
  supabase: Supabase.instance.client,
  powerSyncUrl: 'https://your-instance.powersync.co',
);
```

### Custom Auth Provider

Implement `SupabaseAuthProvider` for custom authentication:

```dart
class CustomAuthProvider implements SupabaseAuthProvider {
  @override
  Future<String?> getAccessToken() async {
    // Return your custom token
    return myCustomAuth.token;
  }

  @override
  Future<String?> getUserId() async {
    return myCustomAuth.userId;
  }

  @override
  Future<DateTime?> getTokenExpiresAt() async {
    return myCustomAuth.expiresAt;
  }
}
```

### Custom Data Provider

Implement `SupabaseDataProvider` for custom CRUD operations:

```dart
class CustomDataProvider implements SupabaseDataProvider {
  @override
  Future<void> upsert(String table, Map<String, dynamic> data) async {
    // Custom upsert logic
  }

  @override
  Future<void> update(String table, String id, Map<String, dynamic> data) async {
    // Custom update logic
  }

  @override
  Future<void> delete(String table, String id) async {
    // Custom delete logic
  }
}

// Use with custom providers
final connector = SupabasePowerSyncConnector(
  authProvider: CustomAuthProvider(),
  dataProvider: CustomDataProvider(),
  powerSyncUrl: 'https://your-instance.powersync.co',
);
```

### Error Handling

The connector distinguishes between fatal and transient errors:
- **Fatal errors** (HTTP 4xx except 429): Marked complete to prevent infinite retries
- **Transient errors** (network issues, rate limits): Automatically retried by PowerSync

## Lifecycle Management

Proper cleanup prevents resource leaks:

### Single Backend

```dart
final backend = PowerSyncBackend<User, String>.withSupabase(...);
await backend.initialize();

// Use the backend...

// Clean up when done
await backend.dispose();
```

### Multi-Table Manager

```dart
final manager = PowerSyncManager.withSupabase(...);
await manager.initialize();

// Get backends and use them...

// Clean up all resources at once
await manager.dispose();
```

The `dispose()` method:
- Closes all database connections
- Disconnects from PowerSync service
- Releases all allocated resources

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

Integration tests require the PowerSync native library.

#### Prerequisites

Check if the library is available:

```dart
import 'package:nexus_store_powersync_adapter/test_utils.dart';

void main() {
  if (!checkPowerSyncLibraryAvailable()) {
    print('PowerSync library not available');
    return;
  }

  // Run integration tests...
}
```

#### Download Native Binaries

For macOS/Linux, download the PowerSync binary:

```bash
./scripts/download_powersync_binary.sh
```

#### Test Database Factory

Use the test utilities for creating test databases:

```dart
import 'package:nexus_store_powersync_adapter/test_utils.dart';

void main() {
  late PowerSyncDatabase db;

  setUp(() async {
    db = await createTestPowerSyncDatabase(schema);
  });

  tearDown(() async {
    await db.close();
  });

  test('my integration test', () async {
    // Use db for testing...
  });
}
```

#### Test Factory for Desktop

For desktop platforms, use `TestPowerSyncOpenFactory`:

```dart
final factory = TestPowerSyncOpenFactory(path: ':memory:');
final db = PowerSyncDatabase.withFactory(factory, schema: schema);
await db.initialize();
```

See `test/test_utils/powersync_test_utils.dart` for more utilities.

## API Reference

### Core Classes

| Class | Description |
|-------|-------------|
| `PowerSyncBackend<T, ID>` | Backend for single-table apps |
| `PowerSyncBackend.withSupabase()` | Factory with batteries-included Supabase setup |
| `PowerSyncManager` | Manager for multi-table apps |
| `PowerSyncManager.withSupabase()` | Factory with batteries-included multi-table setup |
| `PSTableConfig<T, ID>` | Table configuration for manager |
| `PSColumn` | Column definition with type-safe factories |
| `PSTableDefinition` | Table schema definition |
| `PowerSyncBackendConfig<T, ID>` | Backend configuration container |

### Database Adapter Classes

| Class | Description |
|-------|-------------|
| `PowerSyncDatabaseAdapter` | Abstract interface for database lifecycle |
| `DefaultPowerSyncDatabaseAdapter` | Production implementation |
| `PowerSyncDatabaseWrapper` | Wrapper for testing abstraction |
| `PowerSyncDatabaseAdapterFactory` | Factory function type for DI |

### Supabase Classes

| Class | Description |
|-------|-------------|
| `SupabasePowerSyncConnector` | Connector for auth and data sync |
| `SupabaseAuthProvider` | Interface for authentication data |
| `DefaultSupabaseAuthProvider` | Default Supabase auth implementation |
| `SupabaseDataProvider` | Interface for CRUD operations |
| `DefaultSupabaseDataProvider` | Default Supabase REST implementation |

### Sync Rules Classes

| Class | Description |
|-------|-------------|
| `PSSyncRules` | Container for sync rules |
| `PSBucket` | Bucket definition (global, userScoped, parameterized) |
| `PSBucketType` | Enum: Global, UserScoped, Parameterized |
| `PSQuery` | SELECT query for bucket data |

### Encryption Classes

| Class | Description |
|-------|-------------|
| `PowerSyncEncryptedBackend<T, ID>` | Encrypted database backend |
| `EncryptionKeyProvider` | Abstract key provider interface |
| `InMemoryKeyProvider` | Simple in-memory key storage |
| `EncryptionAlgorithm` | Enum: AES-256-GCM, ChaCha20-Poly1305 |

### Type Definitions

| Type | Description |
|------|-------------|
| `ConnectorFactory` | Factory for creating connectors |
| `BackendFactory` | Factory for creating backends |
| `PowerSyncDatabaseAdapterFactory` | Factory for creating database adapters |

## Troubleshooting

### OFFSET without LIMIT Error

**Symptom:** SQL error when using `offsetBy()` without `limitTo()`.

**Cause:** SQLite requires LIMIT before OFFSET.

**Solution:** The adapter automatically handles this by generating `LIMIT -1 OFFSET n` when only offset is specified.

### PowerSync Library Not Found

**Symptom:** Tests fail with "PowerSync library not available" or similar errors.

**Solution:**
1. Run the download script: `./scripts/download_powersync_binary.sh`
2. Or check if Homebrew SQLite is available: `isHomebrewSqliteAvailable()`
3. Use `checkPowerSyncLibraryAvailable()` to skip tests when library is missing

### Type Issues with getBackend

**Symptom:** `getBackend<User, String>()` returns `PowerSyncBackend<dynamic, dynamic>`.

**Cause:** Dart's generic invariance prevents casting stored backends to typed versions.

**Solution:** The returned backend works correctly at runtime. Use it directly or create a typed wrapper:

```dart
final dynamicBackend = manager.getBackend<User, String>('users');
// Operations work correctly despite dynamic types
await dynamicBackend.save(User(...));  // Works!
```

### Authentication Token Expiration

**Symptom:** Sync fails after token expires.

**Solution:** The connector automatically fetches fresh credentials via `fetchCredentials()`. Ensure your `SupabaseAuthProvider` returns current token data:

```dart
@override
Future<DateTime?> getTokenExpiresAt() async {
  final expiresIn = client.auth.currentSession?.expiresIn;
  if (expiresIn == null) return null;
  return DateTime.now().add(Duration(seconds: expiresIn));
}
```

## Additional Resources

- [PowerSync Documentation](https://docs.powersync.com/)
- [Supabase Documentation](https://supabase.com/docs)
- [Core Package](../nexus_store/)

## License

BSD 3-Clause License - see [LICENSE](../../LICENSE) for details.
