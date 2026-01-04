# nexus_store_crdt_adapter

[![Pub Version](https://img.shields.io/pub/v/nexus_store_crdt_adapter)](https://pub.dev/packages/nexus_store_crdt_adapter)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

CRDT adapter for nexus_store with conflict-free replicated data types.

## Features

- **Conflict-Free Replication** - Automatic conflict resolution via CRDTs
- **Hybrid Logical Clocks** - HLC timestamps for causal ordering
- **Last-Writer-Wins** - LWW register semantics for field updates
- **Tombstone Deletes** - Soft deletes for CRDT correctness
- **Changeset Sync** - Efficient peer-to-peer synchronization

## What is CRDT?

CRDT (Conflict-free Replicated Data Types) are data structures that can be replicated across multiple nodes and modified concurrently without coordination. All replicas converge to the same state automatically.

This adapter uses **Last-Writer-Wins Register (LWW)** semantics with **Hybrid Logical Clocks (HLC)** for ordering.

## Prerequisites

1. sqlite_crdt package
2. Understanding of CRDT concepts (optional but helpful)

## Installation

```yaml
dependencies:
  nexus_store: ^0.1.0
  nexus_store_crdt_adapter: ^0.1.0
  sqlite_crdt: ^3.0.4
```

## Basic Usage

```dart
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_crdt_adapter/nexus_store_crdt_adapter.dart';

// Create the backend
final backend = CrdtBackend<User, String>(
  tableName: 'users',
  getId: (user) => user.id,
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  primaryKeyField: 'id',
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
final backend = CrdtBackend<User, String>(
  tableName: 'users',
  getId: (user) => user.id,
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  primaryKeyField: 'id',
  fieldMapping: {                // Optional: model to column mapping
    'firstName': 'first_name',
    'lastName': 'last_name',
  },
);
```

## Conflict Resolution (LWW)

The adapter uses Last-Writer-Wins (LWW) conflict resolution:

```dart
// Node A at T1
await nodeAStore.save(User(id: '1', name: 'Alice'));

// Node B at T2 (later)
await nodeBStore.save(User(id: '1', name: 'Alicia'));

// After sync, both nodes have: User(id: '1', name: 'Alicia')
// The write at T2 wins because it has a later timestamp
```

### How HLC Works

Hybrid Logical Clocks combine:
- Physical time (wall clock)
- Logical counter (for events in the same millisecond)

This ensures:
1. Causal ordering is preserved
2. No coordination needed between nodes
3. Eventual consistency guaranteed

## Tombstone Behavior

Deletes are soft-deletes (tombstones) for CRDT correctness:

```dart
// Delete a user
await userStore.delete('user-1');

// The record is marked as deleted, not removed
// This prevents "resurrection" during sync

// Tombstones are filtered from queries automatically
final users = await userStore.getAll(); // user-1 not included
```

Tombstones ensure that delete operations propagate correctly across all replicas during synchronization.

## Sync Transport Options

The adapter provides changeset-based sync. You provide the transport:

### Get Changes

```dart
// Get all changes since last sync
final changeset = await backend.getChangeset();

// The changeset contains:
// - Modified records with HLC timestamps
// - Tombstones for deleted records
// - Node ID for conflict resolution
```

### Apply Changes

```dart
// Receive changeset from peer
final remoteChangeset = await receiveFromPeer();

// Apply to local database
await backend.applyChangeset(remoteChangeset);

// Conflicts are resolved automatically via LWW
```

### Peer-to-Peer Sync Example

```dart
// Sync between two peers
class SyncService {
  final CrdtBackend<User, String> localBackend;
  final WebSocket peer;

  Future<void> syncWithPeer() async {
    // Get local changes
    final localChanges = await localBackend.getChangeset();

    // Send to peer and receive their changes
    peer.send(jsonEncode(localChanges));

    // Apply received changes
    peer.stream.listen((data) async {
      final remoteChanges = jsonDecode(data) as Map<String, dynamic>;
      await localBackend.applyChangeset(remoteChanges);
    });
  }
}
```

### Server-Based Sync Example

```dart
// Sync via a central server
class ServerSyncService {
  final CrdtBackend<User, String> backend;
  final HttpClient client;
  DateTime? lastSync;

  Future<void> syncWithServer() async {
    // Get local changes
    final localChanges = await backend.getChangeset();

    // Send to server
    final response = await client.post(
      '/sync',
      body: jsonEncode({
        'changes': localChanges,
        'lastSync': lastSync?.toIso8601String(),
      }),
    );

    // Apply server changes
    final serverChanges = jsonDecode(response.body) as Map<String, dynamic>;
    await backend.applyChangeset(serverChanges);

    lastSync = DateTime.now();
  }
}
```

## Reactive Streams

Watch for local changes:

```dart
// Watch all users
userStore.watchAll().listen((users) {
  print('Users: ${users.length}');
});

// Watch single user
userStore.watch('user-1').listen((user) {
  print('User: ${user?.name}');
});
```

## Backend Capabilities

```dart
backend.supportsOffline      // true - full offline support
backend.supportsRealtime     // false - no built-in realtime (provide your own transport)
backend.supportsTransactions // false - basic operation support
```

## When to Use CRDT

CRDT is ideal for:
- **Peer-to-peer applications** - No central server required
- **Collaborative editing** - Multiple users editing simultaneously
- **Offline-heavy apps** - Extended offline periods with later sync
- **Edge computing** - Distributed nodes with eventual consistency

Consider alternatives if:
- You need strong consistency
- You have a reliable central server
- Conflict resolution needs domain-specific logic

## Additional Resources

- [CRDT Primer](https://crdt.tech/)
- [sqlite_crdt Documentation](https://pub.dev/packages/sqlite_crdt)
- [Core Package](../nexus_store/)

## License

BSD 3-Clause License - see [LICENSE](../../LICENSE) for details.
