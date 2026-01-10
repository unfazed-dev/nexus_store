# nexus_store_supabase_adapter

[![Pub Version](https://img.shields.io/pub/v/nexus_store_supabase_adapter)](https://pub.dev/packages/nexus_store_supabase_adapter)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

Supabase adapter for nexus_store with real-time subscriptions.

## Features

- **Real-Time Subscriptions** - Live updates via Supabase Realtime
- **PostgreSQL Backend** - Full PostgreSQL power through Supabase
- **Row-Level Security** - Works with Supabase RLS policies
- **Query Translation** - Automatic translation to PostgREST queries
- **Authentication** - Seamless integration with Supabase Auth

## Prerequisites

1. A [Supabase](https://supabase.com/) project
2. Database tables configured
3. Row-Level Security (RLS) policies if needed
4. Realtime enabled for tables requiring live updates

## Installation

```yaml
dependencies:
  nexus_store: ^0.1.0
  nexus_store_supabase_adapter: ^0.1.0
  supabase: ^2.8.0
```

## Basic Usage

```dart
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_supabase_adapter/nexus_store_supabase_adapter.dart';
import 'package:supabase/supabase.dart';

// Initialize Supabase client
final supabase = SupabaseClient(
  'https://your-project.supabase.co',
  'your-anon-key',
);

// Create the backend
final backend = SupabaseBackend<User, String>(
  client: supabase,
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
  config: StoreConfig.realtime,
);

await userStore.initialize();
```

## Configuration Options

```dart
final backend = SupabaseBackend<User, String>(
  client: supabase,
  tableName: 'users',
  getId: (user) => user.id,
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  primaryKeyColumn: 'id',        // Primary key column name
  schema: 'public',               // Database schema (default: 'public')
  fieldMapping: {                 // Optional: model to column mapping
    'firstName': 'first_name',
    'lastName': 'last_name',
  },
);
```

## Batteries-Included Usage

For reduced boilerplate, use the type-safe configuration classes and factory methods.

### Column Definitions

Define table schemas using type-safe factory methods:

```dart
final columns = [
  SupabaseColumn.uuid('id'),
  SupabaseColumn.text('name'),
  SupabaseColumn.text('email'),
  SupabaseColumn.integer('age', nullable: true),
  SupabaseColumn.boolean('is_active', defaultValue: true),
  SupabaseColumn.timestamptz('created_at'),
  SupabaseColumn.jsonb('metadata', nullable: true),
];
```

Available column types:
- `SupabaseColumn.text()` - TEXT column
- `SupabaseColumn.integer()` - INTEGER column
- `SupabaseColumn.float8()` - DOUBLE PRECISION column
- `SupabaseColumn.boolean()` - BOOLEAN column
- `SupabaseColumn.timestamptz()` - TIMESTAMP WITH TIME ZONE column
- `SupabaseColumn.uuid()` - UUID column
- `SupabaseColumn.jsonb()` - JSONB column

### Factory Method

Create a fully configured backend with a single call:

```dart
final backend = SupabaseBackend<User, String>.withClient(
  client: Supabase.instance.client,
  tableName: 'users',
  columns: columns,
  getId: (u) => u.id,
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  enableRealtime: true,
);
await backend.initialize();
```

### Multi-Table Manager

Coordinate multiple backends with a shared client:

```dart
final manager = SupabaseManager.withClient(
  client: Supabase.instance.client,
  tables: [
    SupabaseTableConfig<User, String>(
      tableName: 'users',
      columns: userColumns,
      fromJson: User.fromJson,
      toJson: (u) => u.toJson(),
      getId: (u) => u.id,
      enableRealtime: true,
    ),
    SupabaseTableConfig<Post, String>(
      tableName: 'posts',
      columns: postColumns,
      fromJson: Post.fromJson,
      toJson: (p) => p.toJson(),
      getId: (p) => p.id,
    ),
  ],
);

await manager.initialize();

// Get typed backends
final userBackend = manager.getBackend('users');
final postBackend = manager.getBackend('posts');

// Subscribe/unsubscribe realtime for all tables
await manager.subscribeAll();
await manager.unsubscribeAll();

// Cleanup
await manager.dispose();
```

### Auth Provider Abstraction

Use custom auth implementations:

```dart
// Default: Uses Supabase Auth
final backend = SupabaseBackend<User, String>.withClient(
  client: supabase,
  // ...
);

// Custom: Implement your own auth provider
class CustomAuthProvider implements SupabaseAuthProvider {
  @override
  SupabaseAuthState get state => _state;

  @override
  Stream<SupabaseAuthState> get stateStream => _stateController.stream;

  @override
  String? get currentUserId => _userId;
}

final backend = SupabaseBackend<User, String>.withClient(
  client: supabase,
  authProvider: CustomAuthProvider(),
  // ...
);
```

### RLS Policy DSL

Generate PostgreSQL RLS policies from Dart:

```dart
final rlsRules = SupabaseRLSRules([
  SupabaseRLSPolicy.select(
    name: 'users_select_own',
    using: 'auth.uid() = id',
  ),
  SupabaseRLSPolicy.insert(
    name: 'users_insert_own',
    withCheck: 'auth.uid() = id',
  ),
  SupabaseRLSPolicy.update(
    name: 'users_update_own',
    using: 'auth.uid() = id',
    withCheck: 'auth.uid() = id',
  ),
  SupabaseRLSPolicy.delete(
    name: 'users_delete_own',
    using: 'auth.uid() = id',
  ),
]);

// Generate SQL
print(rlsRules.toSql('users'));
// Output:
// CREATE POLICY "users_select_own" ON "users" FOR SELECT USING (auth.uid() = id);
// CREATE POLICY "users_insert_own" ON "users" FOR INSERT WITH CHECK (auth.uid() = id);
// ...
```

## Real-Time Setup

### Enable Realtime on Table

In Supabase Dashboard:
1. Go to Database > Tables
2. Select your table
3. Click "Enable Realtime"

Or via SQL:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE users;
```

### Subscribe to Changes

```dart
// Watch all users - receives real-time updates
userStore.watchAll().listen((users) {
  print('Users changed: ${users.length}');
});

// Watch single user
userStore.watch('user-123').listen((user) {
  print('User updated: ${user?.name}');
});
```

## Row-Level Security (RLS)

The adapter works seamlessly with Supabase RLS policies:

```sql
-- Example RLS policy
CREATE POLICY "Users can only see their own data"
ON users
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own data"
ON users
FOR UPDATE
USING (auth.uid() = user_id);
```

The adapter respects these policies automatically based on the authenticated user.

## Authentication Handling

### Set Auth Token

```dart
// After user signs in
await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);

// The backend automatically uses the authenticated session
final users = await userStore.getAll(); // RLS policies apply
```

### Handle Auth State Changes

```dart
supabase.auth.onAuthStateChange.listen((event) {
  if (event.event == AuthChangeEvent.signedOut) {
    // Clear stores or handle logout
    userStore.invalidateAll();
  }
});
```

## Query Translation

Queries are translated to PostgREST format:

```dart
final query = Query<User>()
  .where('status', isEqualTo: 'active')
  .where('age', isGreaterThan: 18)
  .where('role', whereIn: ['admin', 'moderator'])
  .orderBy('createdAt', descending: true)
  .limit(10)
  .offset(20);

// Translated to:
// GET /users?status=eq.active&age=gt.18&role=in.(admin,moderator)&order=created_at.desc&limit=10&offset=20

final users = await userStore.getAll(query: query);
```

## Backend Capabilities

```dart
backend.supportsOffline      // false - online-only
backend.supportsRealtime     // true - real-time subscriptions
backend.supportsTransactions // false - no transaction support
```

## Error Handling

```dart
try {
  await userStore.save(user);
} on NetworkError catch (e) {
  print('Network error: ${e.message}');
  print('Status code: ${e.statusCode}');
} on AuthenticationError catch (e) {
  print('Auth required: ${e.message}');
  // Redirect to login
} on AuthorizationError catch (e) {
  print('Permission denied: ${e.message}');
  // RLS policy blocked the operation
}
```

## Migration from Raw Supabase

If you're migrating from direct Supabase usage:

```dart
// Before: Direct Supabase usage
final response = await supabase
  .from('users')
  .select()
  .eq('status', 'active')
  .order('created_at', ascending: false)
  .limit(10);
final users = (response as List).map((json) => User.fromJson(json)).toList();

// After: nexus_store with Supabase adapter
final users = await userStore.getAll(
  query: Query<User>()
    .where('status', isEqualTo: 'active')
    .orderBy('createdAt', descending: true)
    .limit(10),
);
```

See the [migration guide](../../docs/migration/from-supabase.md) for detailed steps.

## Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Core Package](../nexus_store/)
- [Migration Guide](../../docs/migration/from-supabase.md)

## License

BSD 3-Clause License - see [LICENSE](../../LICENSE) for details.
