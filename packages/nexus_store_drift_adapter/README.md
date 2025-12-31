# nexus_store_drift_adapter

[![Pub Version](https://img.shields.io/pub/v/nexus_store_drift_adapter)](https://pub.dev/packages/nexus_store_drift_adapter)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

Drift adapter for nexus_store for local-only SQLite storage.

## Features

- **Local-Only Storage** - SQLite database with no sync overhead
- **Type-Safe SQL** - Leverage Drift's compile-time SQL verification
- **Query Translation** - Automatic translation of nexus_store queries to Drift
- **Reactive Streams** - Real-time updates via Drift's stream queries
- **Code Generation** - Works with Drift's code generation system

## Prerequisites

1. Drift package configured in your project
2. Drift tables defined for your models
3. Build runner configured for code generation

## Installation

```yaml
dependencies:
  nexus_store: ^0.1.0
  nexus_store_drift_adapter: ^0.1.0
  drift: ^2.22.0

dev_dependencies:
  drift_dev: ^2.22.0
  build_runner: ^2.4.0
```

## Basic Usage

```dart
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_drift_adapter/nexus_store_drift_adapter.dart';
import 'package:drift/drift.dart';

// Create the backend
final backend = DriftBackend<User, String>(
  tableName: 'users',
  getId: (user) => user.id,
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  primaryKeyField: 'id',
);

// Initialize with your Drift database
await backend.initializeWithExecutor(myDriftDatabase);

// Create the store
final userStore = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig.defaults,
);

await userStore.initialize();
```

## Configuration Options

```dart
final backend = DriftBackend<User, String>(
  tableName: 'users',             // Database table name
  getId: (user) => user.id,       // ID extraction function
  fromJson: User.fromJson,        // JSON deserialization
  toJson: (user) => user.toJson(), // JSON serialization
  primaryKeyField: 'id',          // Primary key field name
  fieldMapping: {                  // Optional: model to column mapping
    'firstName': 'first_name',
    'lastName': 'last_name',
  },
);
```

## Table Mapping Patterns

### Simple Table

```dart
// Drift table definition
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// nexus_store model
class User {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  User({required this.id, required this.name, required this.email, required this.createdAt});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
  };
}
```

### Column Name Mapping

When your model field names differ from database columns:

```dart
final backend = DriftBackend<User, String>(
  tableName: 'users',
  getId: (user) => user.id,
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  primaryKeyField: 'id',
  fieldMapping: {
    'firstName': 'first_name',     // Model 'firstName' -> DB 'first_name'
    'lastName': 'last_name',
    'createdAt': 'created_at',
  },
);
```

## Local-Only Usage Patterns

Since Drift is local-only, sync operations are no-ops:

```dart
// Sync status is always 'synced' for local-only backends
print(backend.syncStatus); // SyncStatus.synced

// Sync is a no-op
await backend.sync(); // Does nothing

// Pending changes count is always 0
final pending = await backend.pendingChangesCount; // 0
```

## Query Translation

Queries are translated to Drift SQL:

```dart
final query = Query<User>()
  .where('status', isEqualTo: 'active')
  .where('age', isGreaterThanOrEqualTo: 18)
  .orderBy('name')
  .limit(50);

final users = await userStore.getAll(query: query);
```

## Reactive Streams

Watch for real-time updates:

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

// Watch single user
userStore.watch('user-123').listen((user) {
  if (user != null) {
    print('User updated: ${user.name}');
  }
});
```

## Backend Capabilities

```dart
backend.supportsOffline      // false - local-only, not "offline-first"
backend.supportsRealtime     // false - no remote sync
backend.supportsTransactions // false - basic transaction support only
```

## Migration from Raw Drift

If you're migrating from direct Drift usage:

```dart
// Before: Direct Drift usage
final users = await db.select(db.users).get();

// After: nexus_store with Drift adapter
final users = await userStore.getAll();

// Before: Drift query with filters
final activeUsers = await (db.select(db.users)
  ..where((u) => u.status.equals('active'))
  ..orderBy([(u) => OrderingTerm.desc(u.createdAt)])
  ..limit(10))
  .get();

// After: nexus_store query
final activeUsers = await userStore.getAll(
  query: Query<User>()
    .where('status', isEqualTo: 'active')
    .orderBy('createdAt', descending: true)
    .limit(10),
);
```

See the [migration guide](../../docs/migration/from-drift.md) for detailed steps.

## Additional Resources

- [Drift Documentation](https://drift.simonbinder.eu/)
- [Core Package](../nexus_store/)
- [Migration Guide](../../docs/migration/from-drift.md)

## License

MIT License - see [LICENSE](../../LICENSE) for details.
