# nexus_store_powersync_adapter

[![Pub Version](https://img.shields.io/pub/v/nexus_store_powersync_adapter)](https://pub.dev/packages/nexus_store_powersync_adapter)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

PowerSync adapter for nexus_store with offline-first sync and SQLCipher support.

## Features

- **Offline-First** - Full offline support with automatic sync when online
- **Real-Time Sync** - Live updates from PostgreSQL via PowerSync service
- **SQLCipher Encryption** - Optional database-level encryption
- **Conflict Resolution** - Built-in conflict handling with server-wins default
- **Query Translation** - Automatic translation of nexus_store queries to SQL

## Prerequisites

1. A [PowerSync](https://www.powersync.com/) account
2. A PostgreSQL database connected to PowerSync
3. PowerSync sync rules configured for your tables

## Installation

```yaml
dependencies:
  nexus_store: ^0.1.0
  nexus_store_powersync_adapter: ^0.1.0
  powersync: ^1.17.0

  # Optional: for SQLCipher encryption
  # powersync_sqlcipher: ^1.0.0
```

## Basic Usage

```dart
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';
import 'package:powersync/powersync.dart';

// Initialize PowerSync database
final powerSyncDb = PowerSyncDatabase(
  schema: schema,
  path: 'app.db',
);
await powerSyncDb.initialize();

// Create the backend
final backend = PowerSyncBackend<User, String>(
  db: powerSyncDb,
  tableName: 'users',
  getId: (user) => user.id,
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  primaryKeyColumn: 'id',
);

await backend.initialize();

// Create the store
final userStore = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig.offlineFirst,
);

await userStore.initialize();
```

## Configuration Options

```dart
final backend = PowerSyncBackend<User, String>(
  db: powerSyncDb,
  tableName: 'users',
  getId: (user) => user.id,
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  primaryKeyColumn: 'id',          // Primary key column name
  fieldMapping: {                   // Optional: map model fields to DB columns
    'firstName': 'first_name',
    'lastName': 'last_name',
  },
  queryTranslator: customTranslator, // Optional: custom query translator
);
```

## SQLCipher Encryption

For encrypted databases, use the encrypted variant:

```dart
import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';

// Create encrypted backend
final backend = PowerSyncEncryptedBackend<User, String>(
  db: encryptedPowerSyncDb,
  tableName: 'users',
  getId: (user) => user.id,
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  primaryKeyColumn: 'id',
  keyProvider: InMemoryKeyProvider(encryptionKey),
);
```

### Key Provider

Implement `EncryptionKeyProvider` for secure key management:

```dart
class SecureKeyProvider implements EncryptionKeyProvider {
  @override
  Future<String> getKey() async {
    // Retrieve key from secure storage
    return await secureStorage.read(key: 'db_encryption_key');
  }
}

final backend = PowerSyncEncryptedBackend<User, String>(
  // ...
  keyProvider: SecureKeyProvider(),
);
```

## Sync Status Handling

Monitor synchronization status:

```dart
// Get current status
final status = backend.syncStatus;
print('Status: $status'); // synced, pending, syncing, error

// Watch status changes
backend.syncStatusStream.listen((status) {
  switch (status) {
    case SyncStatus.synced:
      print('All changes synced');
    case SyncStatus.pending:
      print('Changes waiting to sync');
    case SyncStatus.syncing:
      print('Syncing in progress...');
    case SyncStatus.error:
      print('Sync error occurred');
  }
});

// Get pending changes count
final pending = await backend.pendingChangesCount;
print('$pending changes pending');

// Manually trigger sync
await backend.sync();
```

## Query Translation

Queries are automatically translated to SQL:

```dart
// nexus_store query
final query = Query<User>()
  .where('status', isEqualTo: 'active')
  .where('age', isGreaterThan: 18)
  .orderBy('createdAt', descending: true)
  .limit(10);

// Automatically translated to SQL:
// SELECT * FROM users
// WHERE status = 'active' AND age > 18
// ORDER BY createdAt DESC
// LIMIT 10

final users = await userStore.getAll(query: query);
```

## Backend Capabilities

```dart
backend.supportsOffline      // true - full offline support
backend.supportsRealtime     // true - real-time sync
backend.supportsTransactions // true - atomic operations
```

## Migration from Raw PowerSync

If you're migrating from direct PowerSync usage:

```dart
// Before: Direct PowerSync usage
final results = await db.getAll('SELECT * FROM users WHERE status = ?', ['active']);
final users = results.map((row) => User.fromJson(row)).toList();

// After: nexus_store with PowerSync adapter
final users = await userStore.getAll(
  query: Query<User>().where('status', isEqualTo: 'active'),
);
```

See the [migration guide](../../docs/migration/from-raw-powersync.md) for detailed steps.

## Additional Resources

- [PowerSync Documentation](https://docs.powersync.com/)
- [Core Package](../nexus_store/)
- [Migration Guide](../../docs/migration/from-raw-powersync.md)

## License

MIT License - see [LICENSE](../../LICENSE) for details.
