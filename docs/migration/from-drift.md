# Migration Guide: From Raw Drift

This guide helps you migrate from direct Drift usage to nexus_store with the Drift adapter.

## Why Migrate?

Using nexus_store provides:
- Unified API across backends (swap to PowerSync, Supabase later)
- Policy-based fetching (useful if you add sync later)
- Built-in GDPR and audit logging
- Flutter widgets for reactive UI
- Consistent query API across backends

## Before: Direct Drift

```dart
import 'package:drift/drift.dart';

// Table definition
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get status => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// Database
@DriftDatabase(tables: [Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}

// Usage
final db = AppDatabase();

// Read single
final user = await (db.select(db.users)
  ..where((u) => u.id.equals(userId)))
  .getSingleOrNull();

// Read all
final users = await (db.select(db.users)
  ..where((u) => u.status.equals('active')))
  .get();

// Insert
await db.into(db.users).insert(UsersCompanion.insert(
  id: user.id,
  name: user.name,
  email: user.email,
  status: user.status,
));

// Update
await (db.update(db.users)
  ..where((u) => u.id.equals(user.id)))
  .write(UsersCompanion(name: Value(user.name)));

// Delete
await (db.delete(db.users)
  ..where((u) => u.id.equals(userId)))
  .go();

// Watch
(db.select(db.users)
  ..where((u) => u.status.equals('active')))
  .watch()
  .listen((users) {
    print('Users: ${users.length}');
  });
```

## After: nexus_store with Drift Adapter

```dart
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_drift_adapter/nexus_store_drift_adapter.dart';

// Create backend
final backend = DriftBackend<User, String>(
  tableName: 'users',
  getId: (user) => user.id,
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  primaryKeyField: 'id',
);

await backend.initializeWithExecutor(db);

// Create store
final userStore = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig.defaults,
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
```

## Step-by-Step Migration

### Step 1: Add Dependencies

```yaml
dependencies:
  nexus_store: ^0.1.0
  nexus_store_drift_adapter: ^0.1.0
  drift: ^2.22.0  # Keep existing
```

### Step 2: Create a Model Class

If you're using Drift's generated companion classes, create a plain model:

```dart
// Plain Dart model (used with nexus_store)
class User {
  final String id;
  final String name;
  final String email;
  final String status;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
  });

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
```

### Step 3: Create the Backend

```dart
final backend = DriftBackend<User, String>(
  tableName: 'users',
  getId: (user) => user.id,
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  primaryKeyField: 'id',
);

// Initialize with existing Drift database
await backend.initializeWithExecutor(existingDb);
```

### Step 4: Create the Store

```dart
final userStore = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig.defaults,
);

await userStore.initialize();
```

### Step 5: Migrate Queries

| Drift | nexus_store |
|-------|-------------|
| `(select(users)..where((u) => u.id.equals(id))).getSingleOrNull()` | `store.get(id)` |
| `select(users).get()` | `store.getAll()` |
| `(select(users)..where((u) => u.status.equals('active'))).get()` | `store.getAll(query: Query<User>().where('status', isEqualTo: 'active'))` |
| `(select(users)..orderBy([(u) => OrderingTerm.asc(u.name)])).get()` | `store.getAll(query: Query<User>().orderBy('name'))` |

### Step 6: Migrate Writes

```dart
// Before: Different methods for insert/update
await db.into(db.users).insert(UsersCompanion.insert(...));
await (db.update(db.users)..where((u) => u.id.equals(id))).write(...);

// After: Single save method
await userStore.save(user);
```

### Step 7: Migrate Watch Queries

```dart
// Before
(db.select(db.users)
  ..where((u) => u.status.equals('active')))
  .watch()
  .listen((users) => updateUI(users));

// After
userStore.watchAll(
  query: Query<User>().where('status', isEqualTo: 'active'),
).listen((users) => updateUI(users));
```

## Query Translation Reference

| Drift Expression | Query Builder |
|------------------|---------------|
| `where((u) => u.status.equals('active'))` | `.where('status', isEqualTo: 'active')` |
| `where((u) => u.age.isBiggerThan(18))` | `.where('age', isGreaterThan: 18)` |
| `where((u) => u.role.isIn(['admin', 'mod']))` | `.where('role', whereIn: ['admin', 'mod'])` |
| `orderBy([(u) => OrderingTerm.asc(u.name)])` | `.orderBy('name')` |
| `orderBy([(u) => OrderingTerm.desc(u.createdAt)])` | `.orderBy('createdAt', descending: true)` |
| `limit(10)` | `.limit(10)` |
| `limit(10, offset: 20)` | `.limit(10).offset(20)` |

## Column Mapping

If your model field names differ from Drift columns:

```dart
final backend = DriftBackend<User, String>(
  // ...
  fieldMapping: {
    'firstName': 'first_name',
    'lastName': 'last_name',
    'createdAt': 'created_at',
  },
);
```

## Keeping Drift for Advanced Queries

You can use nexus_store for standard operations and Drift for complex queries:

```dart
// Standard operations via nexus_store
final user = await userStore.get(id);
await userStore.save(user);

// Complex queries still use Drift directly
final report = await db.customSelect('''
  SELECT u.name, COUNT(p.id) as post_count
  FROM users u
  LEFT JOIN posts p ON p.user_id = u.id
  GROUP BY u.id
''').get();
```

## Flutter Widgets

Replace Drift stream builders:

```dart
// Before: StreamBuilder with Drift
StreamBuilder<List<User>>(
  stream: (db.select(db.users)..where((u) => u.status.equals('active'))).watch(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    return ListView.builder(...);
  },
)

// After: NexusStoreBuilder
NexusStoreBuilder<User, String>(
  store: userStore,
  query: Query<User>().where('status', isEqualTo: 'active'),
  builder: (context, users) => ListView.builder(...),
  loading: CircularProgressIndicator(),
)
```

## Local-Only Behavior

Since Drift is local-only:
- Sync operations are no-ops
- `syncStatus` is always `synced`
- `pendingChangesCount` is always 0

This is intentional - you can later swap to PowerSync or add sync without changing your application code.

## Gradual Migration

1. **Keep existing Drift code** - Don't remove yet
2. **Add nexus_store alongside** - Run both in parallel
3. **Migrate one table at a time** - Start with simple tables
4. **Verify consistency** - Compare results between old and new
5. **Remove old code** - After thorough testing

## Troubleshooting

### Type mismatches

Ensure your `fromJson`/`toJson` match Drift's column types:

```dart
// Drift stores DateTime as int (milliseconds)
// Your fromJson should handle this
factory User.fromJson(Map<String, dynamic> json) => User(
  createdAt: json['createdAt'] is int
    ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
    : DateTime.parse(json['createdAt']),
);
```

### Watch not updating

Make sure you're using the same database instance:

```dart
// Use existing database
await backend.initializeWithExecutor(existingDb);
```

## See Also

- [Drift Adapter README](../../packages/nexus_store_drift_adapter/README.md)
- [Core Package README](../../packages/nexus_store/README.md)
