# Migration Guide: From Raw Supabase

This guide helps you migrate from direct Supabase usage to nexus_store with the Supabase adapter.

## Why Migrate?

Using nexus_store provides:
- Unified API across backends (swap to PowerSync for offline later)
- Policy-based fetching (cacheFirst reduces API calls)
- Built-in GDPR and audit logging
- Flutter widgets for reactive UI
- Type-safe query builder

## Before: Direct Supabase

```dart
import 'package:supabase/supabase.dart';

final supabase = SupabaseClient('url', 'key');

// Read single
final response = await supabase
  .from('users')
  .select()
  .eq('id', userId)
  .single();
final user = User.fromJson(response);

// Read all with filters
final response = await supabase
  .from('users')
  .select()
  .eq('status', 'active')
  .order('name', ascending: true)
  .limit(10);
final users = (response as List).map((j) => User.fromJson(j)).toList();

// Insert
await supabase.from('users').insert(user.toJson());

// Update
await supabase.from('users').update({'name': user.name}).eq('id', user.id);

// Delete
await supabase.from('users').delete().eq('id', userId);

// Realtime subscription
final channel = supabase.channel('users');
channel
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'users',
    callback: (payload) {
      print('Change: ${payload.newRecord}');
    },
  )
  .subscribe();
```

## After: nexus_store with Supabase Adapter

```dart
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_supabase_adapter/nexus_store_supabase_adapter.dart';

// Create backend
final backend = SupabaseBackend<User, String>(
  client: supabase,
  tableName: 'users',
  getId: (user) => user.id,
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  primaryKeyColumn: 'id',
);

await backend.initialize();

// Create store
final userStore = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig.realtime,
);

await userStore.initialize();

// Read single
final user = await userStore.get(userId);

// Read all with filters
final users = await userStore.getAll(
  query: Query<User>()
    .where('status', isEqualTo: 'active')
    .orderBy('name')
    .limit(10),
);

// Insert/Update (unified save)
await userStore.save(user);

// Delete
await userStore.delete(userId);

// Watch (includes realtime updates)
userStore.watchAll().listen((users) {
  print('Users updated: ${users.length}');
});
```

## Step-by-Step Migration

### Step 1: Add Dependencies

```yaml
dependencies:
  nexus_store: ^0.1.0
  nexus_store_supabase_adapter: ^0.1.0
  supabase: ^2.8.0  # Keep existing
```

### Step 2: Create the Backend

```dart
final backend = SupabaseBackend<User, String>(
  client: existingSupabaseClient,  // Reuse existing client
  tableName: 'users',
  getId: (user) => user.id,
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  primaryKeyColumn: 'id',
);

await backend.initialize();
```

### Step 3: Create the Store

```dart
final userStore = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(
    fetchPolicy: FetchPolicy.networkFirst,  // Supabase is online-only
    writePolicy: WritePolicy.cacheAndNetwork,
    syncMode: SyncMode.realtime,
  ),
);

await userStore.initialize();
```

### Step 4: Migrate Queries

| Supabase | nexus_store |
|----------|-------------|
| `from('users').select().eq('id', id).single()` | `store.get(id)` |
| `from('users').select()` | `store.getAll()` |
| `from('users').select().eq('status', 'active')` | `store.getAll(query: Query<User>().where('status', isEqualTo: 'active'))` |
| `from('users').select().order('name')` | `store.getAll(query: Query<User>().orderBy('name'))` |
| `from('users').select().limit(10).range(20, 29)` | `store.getAll(query: Query<User>().limit(10).offset(20))` |

### Step 5: Migrate Writes

```dart
// Before: Different methods for insert/update
await supabase.from('users').insert(user.toJson());
await supabase.from('users').update({'name': name}).eq('id', id);

// After: Single save method (upsert behavior)
await userStore.save(user);
```

### Step 6: Migrate Realtime

```dart
// Before: Manual channel subscription
final channel = supabase.channel('users');
channel.onPostgresChanges(
  event: PostgresChangeEvent.all,
  table: 'users',
  callback: (payload) => handleChange(payload),
).subscribe();

// After: Automatic via watchAll
userStore.watchAll().listen((users) {
  // Automatically receives realtime updates
  updateUI(users);
});
```

## Query Translation Reference

| Supabase Method | Query Builder |
|-----------------|---------------|
| `.eq('status', 'active')` | `.where('status', isEqualTo: 'active')` |
| `.neq('status', 'deleted')` | `.where('status', isNotEqualTo: 'deleted')` |
| `.gt('age', 18)` | `.where('age', isGreaterThan: 18)` |
| `.lt('age', 65)` | `.where('age', isLessThan: 65)` |
| `.in_('role', ['admin', 'mod'])` | `.where('role', whereIn: ['admin', 'mod'])` |
| `.order('name', ascending: true)` | `.orderBy('name')` |
| `.order('createdAt', ascending: false)` | `.orderBy('createdAt', descending: true)` |
| `.limit(10)` | `.limit(10)` |
| `.range(20, 29)` | `.offset(20).limit(10)` |

## RLS Compatibility

Row-Level Security works automatically. The adapter uses the authenticated client:

```dart
// RLS policies apply automatically
final backend = SupabaseBackend<User, String>(
  client: supabase,  // Uses current auth session
  tableName: 'users',
  // ...
);

// After sign-in, RLS policies filter results
final myUsers = await userStore.getAll();  // Only sees allowed rows
```

## Schema Configuration

For non-public schemas:

```dart
final backend = SupabaseBackend<User, String>(
  client: supabase,
  tableName: 'users',
  schema: 'custom_schema',  // Default is 'public'
  // ...
);
```

## Column Mapping

If your model field names differ from Supabase columns:

```dart
final backend = SupabaseBackend<User, String>(
  // ...
  fieldMapping: {
    'firstName': 'first_name',
    'lastName': 'last_name',
    'createdAt': 'created_at',
  },
);
```

## Authentication Handling

Handle auth state changes:

```dart
supabase.auth.onAuthStateChange.listen((event) {
  if (event.event == AuthChangeEvent.signedOut) {
    // Invalidate cached data
    userStore.invalidateAll();
  }
});
```

## Error Handling

```dart
try {
  await userStore.save(user);
} on NetworkError catch (e) {
  print('Network error: ${e.message}');
  print('Status: ${e.statusCode}');
} on AuthenticationError catch (e) {
  // Redirect to login
  navigateToLogin();
} on AuthorizationError catch (e) {
  // RLS policy blocked
  showError('Permission denied');
}
```

## Flutter Widgets

Replace manual StreamBuilders:

```dart
// Before: Manual realtime handling
StreamBuilder<List<Map<String, dynamic>>>(
  stream: supabase.from('users').stream(primaryKey: ['id']),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    final users = snapshot.data!.map((j) => User.fromJson(j)).toList();
    return ListView.builder(...);
  },
)

// After: NexusStoreBuilder
NexusStoreBuilder<User, String>(
  store: userStore,
  builder: (context, users) => ListView.builder(...),
  loading: CircularProgressIndicator(),
)
```

## Gradual Migration

1. **Keep existing Supabase code** - Don't remove yet
2. **Add nexus_store alongside** - Run both in parallel
3. **Migrate one table at a time** - Start with read-heavy tables
4. **Verify RLS works** - Test with different users
5. **Remove old code** - After thorough testing

## Troubleshooting

### 401 Unauthorized

Ensure user is authenticated:

```dart
final session = supabase.auth.currentSession;
if (session == null) {
  // User not logged in
  await supabase.auth.signIn(email: email, password: password);
}
```

### RLS blocking operations

Check your RLS policies allow the operation:

```sql
-- Example: Allow users to read their own data
CREATE POLICY "Users read own data" ON users
  FOR SELECT USING (auth.uid() = user_id);
```

### Realtime not working

Ensure realtime is enabled for the table in Supabase dashboard.

## See Also

- [Supabase Adapter README](../../packages/nexus_store_supabase_adapter/README.md)
- [Core Package README](../../packages/nexus_store/README.md)
