# Authentication Reference

Authentication integration patterns for nexus_store adapters.

## Architecture Overview

nexus_store follows a **separation of concerns** design for authentication:

- **Adapters don't implement authentication** - they use already-authenticated clients
- **Auth is handled externally** - Supabase Auth SDK, PowerSync connector, etc.
- **Adapters detect auth errors** - and map them to typed exceptions
- **RLS policies work automatically** - when using authenticated clients

```
┌─────────────────────────────────────────────────────────────────┐
│                        Your Application                         │
├─────────────────────────────────────────────────────────────────┤
│  Auth Layer          │  Data Layer                              │
│  ─────────────────   │  ─────────────────────────────────────   │
│  Supabase Auth SDK   │  NexusStore<T, ID>                       │
│  ↓                   │      ↓                                   │
│  JWT Token           │  SupabaseBackend / PowerSyncBackend      │
│  ↓                   │      ↓ (uses authenticated client)       │
│  Session             │  SupabaseClient / PowerSyncDatabase      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Supabase Auth + PowerSync Integration

The most common pattern for offline-first apps with Supabase authentication.

### Complete Setup Pattern

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:powersync/powersync.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';

// 1. Initialize Supabase with auth
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_ANON_KEY',
  authOptions: const FlutterAuthClientOptions(
    autoRefreshToken: true,  // Important: auto-refresh JWT
  ),
);
final supabase = Supabase.instance.client;

// 2. Create PowerSync connector with Supabase auth
class SupabaseConnector extends PowerSyncBackendConnector {
  final SupabaseClient _supabase;

  SupabaseConnector(this._supabase);

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    // Get PowerSync token from your backend or Supabase Edge Function
    final response = await _supabase.functions.invoke('powersync-token');
    final token = response.data['token'] as String;

    return PowerSyncCredentials(
      endpoint: 'YOUR_POWERSYNC_URL',
      token: token,
      expiresAt: session.expiresAt != null
          ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
          : null,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    // Upload local changes to Supabase
    final tx = await database.getNextCrudTransaction();
    if (tx == null) return;

    for (final op in tx.crud) {
      switch (op.op) {
        case UpdateType.put:
          await _supabase.from(op.table).upsert(op.opData!);
        case UpdateType.patch:
          await _supabase.from(op.table).update(op.opData!).eq('id', op.id);
        case UpdateType.delete:
          await _supabase.from(op.table).delete().eq('id', op.id);
      }
    }
    await tx.complete();
  }
}

// 3. Initialize PowerSync with connector
final schema = Schema([
  Table('users', [
    Column.text('name'),
    Column.text('email'),
    Column.integer('age'),
  ]),
]);

final powerSync = PowerSyncDatabase(schema: schema, path: 'app.db');
await powerSync.initialize();

final connector = SupabaseConnector(supabase);
await powerSync.connect(connector: connector);

// 4. Create nexus_store with PowerSync backend
final backend = PowerSyncBackend<User, String>(
  powerSync,
  'users',
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  getId: (user) => user.id,
);

final userStore = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig.offlineFirst,
);
await userStore.initialize();

// 5. Handle auth state changes
supabase.auth.onAuthStateChange.listen((data) {
  final event = data.event;

  switch (event) {
    case AuthChangeEvent.signedIn:
      // Reconnect PowerSync with new credentials
      powerSync.connect(connector: connector);

    case AuthChangeEvent.signedOut:
      // Disconnect and clear local data
      powerSync.disconnect();
      userStore.invalidateAll();

    case AuthChangeEvent.tokenRefreshed:
      // PowerSync connector will fetch new credentials automatically
      break;

    default:
      break;
  }
});
```

### Token Flow

```
User Login
    │
    ▼
Supabase Auth ──► JWT Token (access_token)
    │
    ▼
PowerSync Connector.fetchCredentials()
    │
    ▼
Edge Function (optional) ──► PowerSync Token
    │
    ▼
PowerSync Sync Service ──► PostgreSQL (with RLS)
    │
    ▼
Local SQLite Cache
    │
    ▼
nexus_store (reads from local cache)
```

---

## Supabase Adapter Authentication

For online-only apps using Supabase directly (without PowerSync).

### Session Integration

The Supabase adapter automatically uses the authenticated session:

```dart
import 'package:nexus_store_supabase_adapter/nexus_store_supabase_adapter.dart';

// Sign in user
await supabase.auth.signInWithPassword(
  email: 'user@example.com',
  password: 'password',
);

// Create backend - automatically uses current session
final backend = SupabaseBackend<User, String>(
  client: supabase,  // JWT included in all requests
  tableName: 'users',
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  getId: (user) => user.id,
);

final userStore = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig.realtime,
);
await userStore.initialize();

// All operations respect RLS policies
final users = await userStore.getAll();  // Only sees allowed rows
```

### Auth State Changes

Handle sign-out and session changes:

```dart
supabase.auth.onAuthStateChange.listen((data) {
  switch (data.event) {
    case AuthChangeEvent.signedOut:
      // Clear cached data - user no longer authorized
      userStore.invalidateAll();

    case AuthChangeEvent.signedIn:
      // Refresh data with new user context
      userStore.invalidateAll();

    case AuthChangeEvent.tokenRefreshed:
      // No action needed - client handles automatically
      break;

    case AuthChangeEvent.userUpdated:
      // Optionally refresh if user metadata affects queries
      break;

    default:
      break;
  }
});
```

### RLS (Row-Level Security)

RLS policies are enforced automatically. Example policies:

```sql
-- Users can only read their own data
CREATE POLICY "Users read own data" ON users
  FOR SELECT USING (auth.uid() = id);

-- Users can only update their own data
CREATE POLICY "Users update own data" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Users can insert their own record
CREATE POLICY "Users insert own data" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Users can delete their own record
CREATE POLICY "Users delete own data" ON users
  FOR DELETE USING (auth.uid() = id);
```

No changes needed in Dart code - RLS is transparent:

```dart
// This automatically filters to current user's data
final myData = await userStore.getAll();

// This throws AuthorizationError if RLS blocks it
await userStore.save(User(id: 'other-user-id', ...));
```

### Real-time Subscriptions with Auth

Real-time updates also respect RLS:

```dart
// Only receives updates for rows the user can access
userStore.watchAll().listen((users) {
  print('Authorized users: ${users.length}');
});
```

---

## PowerSync Adapter Authentication

For offline-first apps using PowerSync.

### Connector Pattern

PowerSync requires a connector to handle authentication:

```dart
class SupabaseConnector extends PowerSyncBackendConnector {
  final SupabaseClient _supabase;

  SupabaseConnector(this._supabase);

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      // Not authenticated - return null to pause sync
      return null;
    }

    // Option 1: Use Supabase JWT directly (if PowerSync configured for it)
    return PowerSyncCredentials(
      endpoint: 'YOUR_POWERSYNC_URL',
      token: session.accessToken,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000),
    );

    // Option 2: Exchange for PowerSync-specific token via Edge Function
    // final response = await _supabase.functions.invoke('powersync-auth');
    // return PowerSyncCredentials(
    //   endpoint: response.data['endpoint'],
    //   token: response.data['token'],
    // );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    // Handle uploads to Supabase
    // ...
  }
}
```

### Offline Token Handling

PowerSync caches credentials for offline operation:

```dart
// Token is cached locally
// When offline, local operations continue
// When back online, connector.fetchCredentials() is called
// If token expired, user may need to re-authenticate

// Check sync status
powerSync.statusStream.listen((status) {
  if (status.connected) {
    print('Connected and syncing');
  } else if (status.downloading || status.uploading) {
    print('Sync in progress');
  } else {
    print('Offline - using cached data');
  }
});
```

---

## Error Types

### AuthenticationError

Thrown when authentication fails.

```dart
class AuthenticationError extends StoreError {
  // Properties
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  // Error code: 'AUTHENTICATION_ERROR'
}
```

**Triggers**:
- Expired JWT token
- Invalid or malformed token
- Session not found
- `AuthException` from Supabase
- HTTP 401 responses

### AuthorizationError

Thrown when the user lacks permission.

```dart
class AuthorizationError extends StoreError {
  // Properties
  final String message;
  final String? requiredPermission;  // Optional: which permission was needed
  final Object? cause;
  final StackTrace? stackTrace;

  // Error code: 'AUTHORIZATION_ERROR'
}
```

**Triggers**:
- RLS policy blocked the operation
- PostgreSQL permission denied (code 42501)
- PostgREST RLS error (code PGRST301)
- HTTP 403 responses

---

## Error Mapping Reference

### Supabase Adapter

| Error Source | Detection | Maps To |
|-------------|-----------|---------|
| `AuthException` | Type check | `AuthenticationError` |
| PostgreSQL code `42501` | Error code | `AuthorizationError` |
| PostgREST code `PGRST301` | Error code | `AuthorizationError` |
| Message contains `jwt` | Pattern match | `AuthenticationError` |
| Message contains `row-level security` | Pattern match | `AuthorizationError` |
| Message contains `permission denied` | Pattern match | `AuthorizationError` |

### PowerSync Adapter

| Error Source | Detection | Maps To |
|-------------|-----------|---------|
| Message contains `401` or `unauthorized` | Pattern match | `AuthenticationError` |
| Message contains `403` or `forbidden` | Pattern match | `AuthorizationError` |

---

## Error Handling

### Basic Pattern

```dart
try {
  final user = await userStore.get('user-123');
  await userStore.save(updatedUser);
} on AuthenticationError catch (e) {
  // Session expired or invalid token
  print('Authentication failed: ${e.message}');

  // Redirect to login
  Navigator.of(context).pushReplacementNamed('/login');

} on AuthorizationError catch (e) {
  // RLS policy blocked or permission denied
  print('Authorization denied: ${e.message}');
  if (e.requiredPermission != null) {
    print('Required: ${e.requiredPermission}');
  }

  // Show error to user
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('You do not have permission for this action')),
  );
}
```

### Recovery Patterns

```dart
Future<T?> withAuthRecovery<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } on AuthenticationError {
    // Try to refresh the session
    final response = await supabase.auth.refreshSession();
    if (response.session != null) {
      // Retry the operation
      return await operation();
    }
    // Session refresh failed - need to re-login
    throw AuthenticationError(message: 'Please log in again');
  }
}

// Usage
final user = await withAuthRecovery(() => userStore.get('user-123'));
```

---

## Common Patterns

### Multi-tenant with RLS

```sql
-- SQL: Each user belongs to an organization
CREATE POLICY "Users see org data" ON documents
  FOR SELECT USING (
    org_id IN (
      SELECT org_id FROM org_members WHERE user_id = auth.uid()
    )
  );
```

```dart
// Dart: No special handling needed
final documents = await documentStore.getAll();  // Auto-filtered by org
```

### Secure User Data

```sql
-- SQL: Users can only access their own records
CREATE POLICY "Own records only" ON user_settings
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
```

```dart
// Dart: Automatically enforced
final settings = await settingsStore.get(currentUserId);
```

### Admin Override

```sql
-- SQL: Admins can see all, users see their own
CREATE POLICY "Admin or own" ON users
  FOR SELECT USING (
    auth.uid() = id
    OR
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );
```

### Service Role Bypass

For server-side operations that need to bypass RLS:

```dart
// Use service role key (server-side only!)
final adminClient = SupabaseClient(
  supabaseUrl,
  serviceRoleKey,  // Never expose in client code
);

final adminBackend = SupabaseBackend<User, String>(
  client: adminClient,
  tableName: 'users',
  // ...
);
```

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| JWT expired | Token not refreshed | Enable `autoRefreshToken: true` in Supabase init |
| 401 Unauthorized | Not logged in | Check `supabase.auth.currentSession` before operations |
| RLS blocking reads | SELECT policy missing/wrong | Add SELECT policy with correct `auth.uid()` check |
| RLS blocking writes | INSERT/UPDATE policy missing | Add appropriate write policies |
| PGRST301 error | JWT missing or RLS violation | Re-authenticate and check RLS policies |
| Sync auth failed | PowerSync connector issue | Check `fetchCredentials()` returns valid token |
| Token not refreshing | `autoRefreshToken` disabled | Enable auto-refresh or manually refresh |

### Debug Checklist

1. **Verify authentication**:
   ```dart
   final session = supabase.auth.currentSession;
   print('Session: ${session != null}');
   print('User ID: ${session?.user.id}');
   print('Expires: ${session?.expiresAt}');
   ```

2. **Check JWT expiration**:
   ```dart
   final expiresAt = session?.expiresAt;
   final isExpired = expiresAt != null &&
       DateTime.now().millisecondsSinceEpoch > expiresAt * 1000;
   print('Token expired: $isExpired');
   ```

3. **Test RLS in Supabase dashboard**:
   - Go to SQL Editor
   - Run: `SELECT * FROM your_table;` as authenticated user
   - Check if expected rows are returned

4. **View RLS policies**:
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'your_table';
   ```

5. **Check PowerSync sync status**:
   ```dart
   powerSync.statusStream.listen((status) {
     print('Connected: ${status.connected}');
     print('Last synced: ${status.lastSyncedAt}');
     print('Has credentials: ${status.hasSyncCredentials}');
   });
   ```

### Common Error Messages

| Message | Meaning | Fix |
|---------|---------|-----|
| `new row violates row-level security policy` | INSERT/UPDATE blocked by RLS | Check WITH CHECK clause in policy |
| `permission denied for table X` | No policy allows this operation | Add appropriate RLS policy |
| `JWT expired` | Access token expired | Refresh session or re-login |
| `invalid claim: missing sub claim` | Malformed JWT | Re-authenticate |
| `Could not verify JWT` | Invalid or tampered token | Re-authenticate |
