# Policy Engine

The policy engine controls how data is fetched from and written to backends.

## Overview

nexus_store uses an Apollo GraphQL-inspired policy system that separates the "what" (operations) from the "how" (caching strategy). This allows the same code to work differently based on network conditions, user preferences, or app requirements.

## Fetch Policies

Fetch policies control how read operations retrieve data.

### Available Policies

| Policy | Cache | Network | Use Case |
|--------|-------|---------|----------|
| `cacheFirst` | Read first | Fallback | Read-heavy, tolerant of stale data |
| `networkFirst` | Fallback | Read first | Fresh data critical (balance, inventory) |
| `cacheAndNetwork` | Emit first | Then emit | Instant UI with background refresh |
| `cacheOnly` | Read only | Never | Offline-only scenarios |
| `networkOnly` | Never | Always | Uncacheable data (OTP, live prices) |
| `staleWhileRevalidate` | Emit stale | Revalidate | Content with eventual consistency |

### Policy Behavior

#### cacheFirst (Default)

```
1. Check cache
   ├── Cache hit → Return cached data
   └── Cache miss → Fetch from network
                    ├── Success → Cache and return
                    └── Failure → Return error
```

Best for: User profiles, settings, historical data.

#### networkFirst

```
1. Fetch from network
   ├── Success → Cache and return
   └── Failure → Check cache
                 ├── Cache hit → Return cached data
                 └── Cache miss → Return error
```

Best for: Account balances, inventory counts, real-time data.

#### cacheAndNetwork

```
1. Check cache
   ├── Cache hit → Emit cached data
   └── Cache miss → (continue to step 2)
2. Fetch from network (parallel)
   ├── Success → Cache and emit updated data
   └── Failure → (already emitted cache, or emit error)
```

Best for: Feed content, news, social posts.

#### staleWhileRevalidate

```
1. Check cache
   ├── Fresh → Return cached data
   └── Stale → Return cached data AND trigger background revalidation
2. Background revalidation
   └── Success → Update cache (next read gets fresh data)
```

Best for: Blog posts, documentation, product descriptions.

### Using Fetch Policies

```dart
// Default policy from config
final user = await store.get('user-1');

// Override per-operation
final freshUser = await store.get(
  'user-1',
  policy: FetchPolicy.networkFirst,
);

// Configure default in StoreConfig
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(
    fetchPolicy: FetchPolicy.cacheFirst,
    staleDuration: Duration(minutes: 5),
  ),
);
```

## Write Policies

Write policies control how write operations persist data.

### Available Policies

| Policy | Behavior | Use Case |
|--------|----------|----------|
| `cacheAndNetwork` | Write cache, then sync | Optimistic updates |
| `networkFirst` | Wait for network, then cache | Critical data |
| `cacheFirst` | Write cache, background sync | Offline-first |
| `cacheOnly` | Write cache only, no sync | Local-only data |

### Policy Behavior

#### cacheAndNetwork (Default)

```
1. Write to cache (optimistic)
2. Sync to network
   ├── Success → Done
   └── Failure → Mark as pending, retry later
```

Best for: Most write operations, optimistic UI.

#### networkFirst

```
1. Write to network
   ├── Success → Update cache → Return success
   └── Failure → Return error (no local write)
```

Best for: Financial transactions, critical data.

#### cacheFirst

```
1. Write to cache
2. Queue for background sync
3. Return success immediately
```

Best for: Offline-first apps, draft saving.

#### cacheOnly

```
1. Write to cache only
2. Never sync to network
```

Best for: Local preferences, drafts, temporary data.

### Using Write Policies

```dart
// Default policy from config
await store.save(user);

// Override per-operation
await store.save(
  transaction,
  policy: WritePolicy.networkFirst,
);

// Configure default in StoreConfig
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(
    writePolicy: WritePolicy.cacheAndNetwork,
  ),
);
```

## Sync Modes

Sync modes control when synchronization happens.

| Mode | Behavior |
|------|----------|
| `realtime` | Sync immediately on changes |
| `periodic` | Sync at regular intervals |
| `manual` | Sync only when explicitly called |
| `eventDriven` | Sync on app lifecycle events |
| `disabled` | No automatic sync |

### Configuring Sync Mode

```dart
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(
    syncMode: SyncMode.realtime,
    syncInterval: Duration(minutes: 30),  // For periodic mode
  ),
);

// Manual sync
await store.sync();

// Watch sync status
store.syncStatusStream.listen((status) {
  print('Sync status: $status');
});
```

## Conflict Resolution

When offline changes conflict with server data:

| Strategy | Behavior |
|----------|----------|
| `serverWins` | Server data overwrites local changes |
| `clientWins` | Local changes overwrite server data |
| `latestWins` | Most recent timestamp wins |
| `merge` | Attempt to merge changes |
| `crdt` | Use CRDT algorithms (with CRDT backend) |
| `custom` | Use custom resolution callback |

### Configuring Conflict Resolution

```dart
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(
    conflictResolution: ConflictResolution.serverWins,
  ),
);
```

## Retry Configuration

Failed operations can be retried with exponential backoff:

```dart
final config = StoreConfig(
  retryConfig: RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 30),
    backoffMultiplier: 2.0,
    jitterFactor: 0.1,
  ),
);

// Preset configurations
RetryConfig.defaults    // 3 attempts, 2x backoff
RetryConfig.noRetry     // 1 attempt (disabled)
RetryConfig.aggressive  // 5 attempts, faster backoff
```

## Custom Policy Implementation

The policy handlers are designed to be extensible:

```dart
class CustomFetchPolicyHandler extends FetchPolicyHandler {
  @override
  Future<T?> handle<T, ID>({
    required StoreBackend<T, ID> backend,
    required ID id,
    required FetchPolicy policy,
  }) async {
    // Custom logic here
    return await backend.get(id);
  }
}
```

## Best Practices

1. **Use cacheFirst for stable data** - Reduces network calls for data that rarely changes
2. **Use networkFirst for critical data** - Ensures freshness for important information
3. **Configure staleDuration** - Define when cached data becomes stale
4. **Handle offline gracefully** - Use cacheFirst/cacheOnly when offline
5. **Use cacheAndNetwork for UX** - Provides instant response with eventual consistency

## See Also

- [Architecture Overview](overview.md)
- [Reactive Layer](reactive-layer.md)
