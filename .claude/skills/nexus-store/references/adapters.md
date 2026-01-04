# Storage Adapters Reference

Detailed documentation for all 5 nexus_store storage adapters.

## Adapter Capabilities Matrix

| Adapter | Offline | Real-time | Transactions | SQLCipher | Best For |
|---------|---------|-----------|--------------|-----------|----------|
| PowerSync | Yes | Yes | Yes | Yes | Mobile offline-first with PostgreSQL |
| Supabase | No | Yes | No | No | Real-time web apps with RLS |
| Drift | Local | No | No | No | Local SQLite with type-safety |
| Brick | Yes | Yes | Yes | No | Brick ORM projects |
| CRDT | Yes | Custom | No | No | P2P, collaborative editing |

## PowerSync Adapter

Offline-first sync with PostgreSQL via PowerSync service.

### Installation

```yaml
dependencies:
  nexus_store_powersync_adapter:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_powersync_adapter
```

### Setup

```dart
import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';

// Initialize PowerSync
final powerSync = PowerSyncDatabase(schema: schema);
await powerSync.initialize();

// Create backend
final backend = PowerSyncBackend<User, String>(
  powerSync,
  'users',  // Table name
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  getId: (user) => user.id,
);

// Create store
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig.offlineFirst,
);
```

### With SQLCipher Encryption

```dart
import 'package:powersync_sqlcipher/powersync_sqlcipher.dart';

final powerSync = PowerSyncDatabase.withFactory(
  SqlCipherOpenFactory(
    path: dbPath,
    key: encryptionKey,
  ),
  schema: schema,
);
```

### Capabilities

- `supportsOffline: true` - Full offline operation
- `supportsRealtime: true` - Real-time sync from PostgreSQL
- `supportsTransactions: true` - Transaction support

### When to Use

- Mobile apps requiring offline-first architecture
- Apps syncing with PostgreSQL databases
- Need for SQLCipher database encryption

---

## Supabase Adapter

Real-time backend with PostgreSQL and Row-Level Security.

### Installation

```yaml
dependencies:
  nexus_store_supabase_adapter:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_supabase_adapter
```

### Setup

```dart
import 'package:nexus_store_supabase_adapter/nexus_store_supabase_adapter.dart';

// Initialize Supabase
final supabase = Supabase.instance.client;

// Create backend
final backend = SupabaseBackend<User, String>(
  supabase,
  'users',  // Table name
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  getId: (user) => user.id,
);

// Create store with real-time config
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig.realtime,
);
```

### Field Mapping

```dart
final backend = SupabaseBackend<User, String>(
  supabase,
  'users',
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  getId: (user) => user.id,
  fieldMapping: {
    'firstName': 'first_name',  // Dart field -> DB column
    'lastName': 'last_name',
    'createdAt': 'created_at',
  },
);
```

### Real-time Subscriptions

```dart
// Automatic real-time updates via watchAll/watch
store.watchAll().listen((users) {
  print('Users updated: ${users.length}');
});
```

### Capabilities

- `supportsOffline: false` - Requires network
- `supportsRealtime: true` - Real-time subscriptions
- `supportsTransactions: false` - No transaction support

### When to Use

- Web/mobile apps with Supabase backend
- Apps requiring real-time collaboration
- Projects using Supabase Auth and RLS

---

## Drift Adapter

Local SQLite storage with type-safe queries.

### Installation

```yaml
dependencies:
  nexus_store_drift_adapter:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_drift_adapter
  drift: ^2.0.0

dev_dependencies:
  drift_dev: ^2.0.0
  build_runner: ^2.4.0
```

### Setup

```dart
import 'package:nexus_store_drift_adapter/nexus_store_drift_adapter.dart';

// Define Drift database
@DriftDatabase(tables: [Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  @override
  int get schemaVersion => 1;
}

// Create backend
final backend = DriftBackend<User, String>(
  database.users,
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  getId: (user) => user.id,
);

// Create store
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig.defaults,
);
```

### Column Mapping

```dart
final backend = DriftBackend<User, String>(
  database.users,
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  getId: (user) => user.id,
  columnMapping: {
    'firstName': 'first_name',
    'lastName': 'last_name',
  },
);
```

### Capabilities

- `supportsOffline: false` - Local-only (no sync concept)
- `supportsRealtime: false` - No real-time
- `supportsTransactions: false` - Drift handles transactions

### When to Use

- Local-only data storage
- Apps not requiring server sync
- Projects already using Drift

---

## Brick Adapter

Offline-first ORM with multiple remote support.

### Installation

```yaml
dependencies:
  nexus_store_brick_adapter:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_brick_adapter
  brick_offline_first: ^3.0.0
  brick_offline_first_with_supabase: ^1.0.0  # Or other remote
```

### Setup

```dart
import 'package:nexus_store_brick_adapter/nexus_store_brick_adapter.dart';

// Models must extend OfflineFirstModel
@ConnectOfflineFirstWithSupabase()
class User extends OfflineFirstModel {
  final String id;
  final String name;
  // ...
}

// Create backend
final backend = BrickBackend<User, String>(
  repository,  // Your Brick repository
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  getId: (user) => user.id,
);

// Create store
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig.offlineFirst,
);
```

### Capabilities

- `supportsOffline: true` - Full offline via Brick
- `supportsRealtime: true` - Sync via Brick's remotes
- `supportsTransactions: true` - Transaction support

### When to Use

- Projects using Brick ORM annotations
- Apps with multiple remote backends (REST, GraphQL, Supabase)
- Complex offline-first requirements

---

## CRDT Adapter

Conflict-free replicated data types for P2P sync.

### Installation

```yaml
dependencies:
  nexus_store_crdt_adapter:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_crdt_adapter
```

### Setup

```dart
import 'package:nexus_store_crdt_adapter/nexus_store_crdt_adapter.dart';

// Create CRDT backend
final backend = CrdtBackend<User, String>(
  nodeId: 'device-uuid',  // Unique per device
  tableName: 'users',
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  getId: (user) => user.id,
);

// Create store
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig.offlineFirst,
);
```

### Sync via Changesets

```dart
// Get changes since last sync
final changeset = await backend.getChangeset(sinceHlc: lastSyncHlc);

// Send to peer via your transport (WebSocket, HTTP, etc.)
await sendToPeer(changeset);

// Apply received changes
await backend.applyChangeset(receivedChangeset);
```

### Conflict Resolution

- **Last-Writer-Wins (LWW)**: Automatic based on Hybrid Logical Clocks
- **Tombstones**: Soft-deletes preserved for CRDT correctness
- **Causal Ordering**: HLC ensures proper ordering across peers

### Capabilities

- `supportsOffline: true` - Full offline operation
- `supportsRealtime: false` - Custom transport required
- `supportsTransactions: false` - CRDT semantics differ

### When to Use

- Peer-to-peer applications
- Collaborative editing (documents, whiteboards)
- Edge computing without central server
- Apps requiring conflict-free merging

---

## Composite Backend

Combine multiple backends for fallback and caching.

```dart
final store = NexusStore<User, String>(
  backend: CompositeBackend(
    primary: supabaseBackend,
    fallback: driftBackend,
    cache: inMemoryBackend,
    readStrategy: CompositeReadStrategy.cacheFirst,
    writeStrategy: CompositeWriteStrategy.primaryAndCache,
  ),
);
```

### Read Strategies

- `cacheFirst` - Check cache, then primary, then fallback
- `primaryFirst` - Try primary, fallback on error
- `fallbackFirst` - Try fallback, primary on error

### Write Strategies

- `primaryAndCache` - Write to both primary and cache
- `primaryOnly` - Write only to primary
- `allBackends` - Write to all (primary, fallback, cache)
