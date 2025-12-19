# nexus_store

[![Pub Version](https://img.shields.io/pub/v/nexus_store)](https://pub.dev/packages/nexus_store)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart](https://img.shields.io/badge/Dart-3.5+-blue.svg)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev)

A unified reactive data store abstraction for Dart and Flutter. Use a single consistent API across multiple storage backends with policy-based fetching, RxDart streams, and optional compliance features.

## Features

- **Unified Backend Interface** - Single API for PowerSync, Supabase, Drift, Brick, and CRDT backends
- **Reactive Streams** - RxDart BehaviorSubjects for immediate values and real-time updates
- **Policy-Based Operations** - Apollo-style fetch/write policies (cacheFirst, networkFirst, etc.)
- **Query Builder** - Fluent API for filtering, ordering, and pagination
- **Encryption Support** - SQLCipher database encryption and field-level AES-256-GCM
- **Compliance Ready** - HIPAA audit logging and GDPR data portability/erasure
- **Flutter Widgets** - Ready-to-use builders and providers for Flutter apps

## Quick Start

```dart
import 'package:nexus_store/nexus_store.dart';

// Create a store with any backend
final userStore = NexusStore<User, String>(
  backend: InMemoryBackend<User, String>(
    getId: (user) => user.id,
  ),
  config: StoreConfig.defaults,
);

await userStore.initialize();

// CRUD operations
await userStore.save(User(id: '1', name: 'Alice'));
final user = await userStore.get('1');
final users = await userStore.getAll();
await userStore.delete('1');

// Reactive streams
userStore.watch('1').listen((user) => print(user));
userStore.watchAll().listen((users) => print(users));

// Query builder
final activeUsers = await userStore.getAll(
  query: Query<User>()
    .where('status', isEqualTo: 'active')
    .orderBy('createdAt', descending: true)
    .limit(10),
);
```

## Packages

| Package | Description | Pub |
|---------|-------------|-----|
| [nexus_store](packages/nexus_store/) | Core store abstraction | [![pub](https://img.shields.io/pub/v/nexus_store)](https://pub.dev/packages/nexus_store) |
| [nexus_store_flutter](packages/nexus_store_flutter/) | Flutter widgets and providers | [![pub](https://img.shields.io/pub/v/nexus_store_flutter)](https://pub.dev/packages/nexus_store_flutter) |
| [nexus_store_powersync_adapter](packages/nexus_store_powersync_adapter/) | PowerSync offline-first backend | [![pub](https://img.shields.io/pub/v/nexus_store_powersync_adapter)](https://pub.dev/packages/nexus_store_powersync_adapter) |
| [nexus_store_supabase_adapter](packages/nexus_store_supabase_adapter/) | Supabase realtime backend | [![pub](https://img.shields.io/pub/v/nexus_store_supabase_adapter)](https://pub.dev/packages/nexus_store_supabase_adapter) |
| [nexus_store_drift_adapter](packages/nexus_store_drift_adapter/) | Drift local SQLite backend | [![pub](https://img.shields.io/pub/v/nexus_store_drift_adapter)](https://pub.dev/packages/nexus_store_drift_adapter) |
| [nexus_store_brick_adapter](packages/nexus_store_brick_adapter/) | Brick offline-first backend | [![pub](https://img.shields.io/pub/v/nexus_store_brick_adapter)](https://pub.dev/packages/nexus_store_brick_adapter) |
| [nexus_store_crdt_adapter](packages/nexus_store_crdt_adapter/) | CRDT conflict-free backend | [![pub](https://img.shields.io/pub/v/nexus_store_crdt_adapter)](https://pub.dev/packages/nexus_store_crdt_adapter) |

## Installation

Add the core package and your preferred backend adapter:

```yaml
dependencies:
  nexus_store: ^0.1.0
  nexus_store_powersync_adapter: ^0.1.0  # Or your preferred backend

  # For Flutter apps
  nexus_store_flutter: ^0.1.0
```

## Requirements

- Dart SDK: ^3.5.0
- Flutter SDK: ^3.10.0 (for Flutter packages)

## Documentation

- [Core Package Documentation](packages/nexus_store/README.md)
- [Flutter Extension Documentation](packages/nexus_store_flutter/README.md)
- [Architecture Overview](docs/architecture/overview.md)
- [Migration Guides](docs/migration/)

## Examples

See the [example](example/) directory for complete working examples:

- [Basic Usage](example/basic_usage/) - Console app with CRUD and queries
- [Flutter Widgets](example/flutter_widgets/) - Flutter app with reactive widgets

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
