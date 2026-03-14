# Migration Guide: From Raw PowerSync

This guide helps you migrate from direct PowerSync usage to nexus_store with the PowerSync adapter.

## Why Migrate?

Using nexus_store provides:
- Unified API across backends (swap to Supabase, Drift later)
- Policy-based fetching (cacheFirst, networkFirst, etc.)
- Built-in GDPR and audit logging
- Flutter widgets for reactive UI
- Type-safe query builder

## Before: Direct PowerSync

```dart
import 'package:powersync/powersync.dart';

// Initialize
final db = PowerSyncDatabase(schema: schema, path: 'app.db');
await db.initialize();

// Read single
final row = await db.get('SELECT * FROM users WHERE id = ?', [userId]);
final user = User.fromJson(row);

// Read all
final rows = await db.getAll('SELECT * FROM users WHERE status = ?', ['active']);
final users = rows.map((r) => User.fromJson(r)).toList();

// Insert
await db.execute(
  'INSERT INTO users (id, name, email) VALUES (?, ?, ?)',
  [user.id, user.name, user.email],
);

// Update
await db.execute(
  'UPDATE users SET name = ? WHERE id = ?',
  [user.name, user.id],
);

// Delete
await db.execute('DELETE FROM users WHERE id = ?', [userId]);

// Watch
db.watch('SELECT * FROM users WHERE status = ?', ['active']).map(
  (rows) => rows.map((r) => User.fromJson(r)).toList(),
).listen((users) {
  print('Users: ${users.length}');
});

// Sync status
db.statusStream.listen((status) {
  print('Connected: ${status.connected}');
});
```

## After: nexus_store with PowerSync Adapter

```dart
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';

// Initialize
final db = PowerSyncDatabase(schema: schema, path: 'app.db');
await db.initialize();

final backend = PowerSyncBackend<User, String>(
  db: db,
  tableName: 'users',
  getId: (user) => user.id,
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  primaryKeyColumn: 'id',
);

final userStore = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig.offlineFirst,
);

await userStore.initialize();

// Read single
final user = await userStore.get(userId);

// Read all
final users = await userStore.getAll(
  query: Query<User>().where('status', isEqualTo: 'active'),
);

// Insert/Update (unified save)
await userStore.save(user);

// Delete
await userStore.delete(userId);

// Watch
userStore.watchAll(
  query: Query<User>().where('status', isEqualTo: 'active'),
).listen((users) {
  print('Users: ${users.length}');
});

// Sync status
userStore.syncStatusStream.listen((status) {
  print('Status: $status');
});
```

## Step-by-Step Migration

### Step 1: Add Dependencies

```yaml
dependencies:
  nexus_store: ^0.1.0
  nexus_store_powersync_adapter: ^0.1.0
  powersync: ^1.17.0  # Keep existing
```

### Step 2: Create the Backend

```dart
// Create backend alongside existing PowerSync database
final backend = PowerSyncBackend<User, String>(
  db: existingPowerSyncDb,  // Reuse existing database
  tableName: 'users',
  getId: (user) => user.id,
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  primaryKeyColumn: 'id',
);
```

### Step 3: Create the Store

```dart
final userStore = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(
    fetchPolicy: FetchPolicy.cacheFirst,
    writePolicy: WritePolicy.cacheAndNetwork,
    syncMode: SyncMode.realtime,
  ),
);

await userStore.initialize();
```

### Step 4: Migrate Queries

| PowerSync | nexus_store |
|-----------|-------------|
| `db.get('SELECT * FROM users WHERE id = ?', [id])` | `store.get(id)` |
| `db.getAll('SELECT * FROM users')` | `store.getAll()` |
| `db.getAll('SELECT * FROM users WHERE status = ?', ['active'])` | `store.getAll(query: Query<User>().where('status', isEqualTo: 'active'))` |
| `db.getAll('SELECT * FROM users ORDER BY name LIMIT 10')` | `store.getAll(query: Query<User>().orderBy('name').limit(10))` |

### Step 5: Migrate Writes

```dart
// Before: Different methods for insert/update
await db.execute('INSERT INTO users...', [user.id, user.name, user.email]);
await db.execute('UPDATE users SET name = ?...', [user.name, user.id]);

// After: Single save method
await userStore.save(user);  // Handles both insert and update
```

### Step 6: Migrate Watch Queries

```dart
// Before
db.watch('SELECT * FROM users WHERE status = ?', ['active'])
  .map((rows) => rows.map((r) => User.fromJson(r)).toList())
  .listen((users) => updateUI(users));

// After
userStore.watchAll(
  query: Query<User>().where('status', isEqualTo: 'active'),
).listen((users) => updateUI(users));
```

### Step 7: Add Flutter Widgets (Optional)

```dart
// Replace StreamBuilder with NexusStoreBuilder
NexusStoreBuilder<User, String>(
  store: userStore,
  query: Query<User>().where('status', isEqualTo: 'active'),
  builder: (context, users) => ListView.builder(
    itemCount: users.length,
    itemBuilder: (context, i) => Text(users[i].name),
  ),
)
```

## Query Translation Reference

| SQL | Query Builder |
|-----|---------------|
| `WHERE status = 'active'` | `.where('status', isEqualTo: 'active')` |
| `WHERE age > 18` | `.where('age', isGreaterThan: 18)` |
| `WHERE role IN ('admin', 'mod')` | `.where('role', whereIn: ['admin', 'mod'])` |
| `ORDER BY name ASC` | `.orderBy('name')` |
| `ORDER BY createdAt DESC` | `.orderBy('createdAt', descending: true)` |
| `LIMIT 10` | `.limit(10)` |
| `LIMIT 10 OFFSET 20` | `.limit(10).offset(20)` |

## Column Mapping

If your model field names differ from database columns:

```dart
final backend = PowerSyncBackend<User, String>(
  // ...
  fieldMapping: {
    'firstName': 'first_name',
    'lastName': 'last_name',
    'createdAt': 'created_at',
  },
);
```

## SQLCipher Migration

If using encrypted PowerSync:

```dart
// Before: powersync_sqlcipher directly

// After: PowerSyncEncryptedBackend
final backend = PowerSyncEncryptedBackend<User, String>(
  db: encryptedDb,
  tableName: 'users',
  getId: (user) => user.id,
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  primaryKeyColumn: 'id',
  keyProvider: InMemoryKeyProvider(encryptionKey),
);
```

## Gradual Migration

You can migrate incrementally:

1. **Keep existing PowerSync code** - Don't remove yet
2. **Add nexus_store alongside** - Run both in parallel
3. **Migrate one feature at a time** - Start with low-risk features
4. **Verify consistency** - Compare results between old and new
5. **Remove old code** - After thorough testing

## Troubleshooting

### Sync not working

Ensure you're using the same PowerSync database instance:

```dart
// WRONG: Creating new database
final backend = PowerSyncBackend(db: PowerSyncDatabase(...));

// RIGHT: Reusing existing database
final backend = PowerSyncBackend(db: existingDb);
```

### Query results differ

Check field mapping matches your model:

```dart
// Model uses camelCase
class User {
  final String firstName;  // camelCase
}

// Database uses snake_case
// first_name in SQL

// Add mapping
fieldMapping: {'firstName': 'first_name'}
```

### Watch not emitting

Ensure you're subscribing to the stream:

```dart
// This creates a stream but doesn't subscribe
userStore.watchAll();

// This subscribes and receives updates
userStore.watchAll().listen((users) => ...);
```

## See Also

- [PowerSync Adapter README](../../packages/nexus_store_powersync_adapter/README.md)
- [Core Package README](../../packages/nexus_store/README.md)
