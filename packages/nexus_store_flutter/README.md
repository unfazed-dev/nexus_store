# nexus_store_flutter

[![Pub Version](https://img.shields.io/pub/v/nexus_store_flutter)](https://pub.dev/packages/nexus_store_flutter)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

Flutter extension for nexus_store with StreamBuilder widgets and providers.

## Features

- **StoreResult** - Sealed class for representing async states (idle, pending, success, error)
- **Widgets** - StreamBuilder-style widgets for reactive UI
- **Providers** - InheritedWidget-based dependency injection
- **Extensions** - BuildContext extensions for convenient store access
- **Utilities** - Lifecycle observers for background sync management

## Installation

```yaml
dependencies:
  nexus_store: ^0.1.0
  nexus_store_flutter: ^0.1.0
```

## StoreResult

A sealed class representing async operation states, similar to Riverpod's AsyncValue:

```dart
import 'package:nexus_store_flutter/nexus_store_flutter.dart';

// Create results
final idle = StoreResult<User>.idle();
final loading = StoreResult<User>.pending();
final loadingWithData = StoreResult<User>.pending(previousUser);
final success = StoreResult<User>.success(user);
final error = StoreResult<User>.error(exception);
final errorWithData = StoreResult<User>.error(exception, previousUser);
```

### Pattern Matching

```dart
// Using when() - all cases required
Widget build(BuildContext context) {
  return result.when(
    idle: () => const Text('Tap to load'),
    pending: (previous) => previous != null
      ? _buildUserCard(previous, loading: true)
      : const CircularProgressIndicator(),
    success: (user) => _buildUserCard(user),
    error: (error, previous) => Column(
      children: [
        Text('Error: $error'),
        if (previous != null) _buildUserCard(previous, stale: true),
      ],
    ),
  );
}

// Using maybeWhen() - partial matching
Widget buildOptimistic(BuildContext context) {
  return result.maybeWhen(
    success: (user) => Text(user.name),
    error: (e, prev) => Text('Error: $e'),
    orElse: () => const CircularProgressIndicator(),
  );
}
```

### Properties

```dart
result.hasData     // true if data is available
result.data        // the data or null
result.isLoading   // true if pending
result.hasError    // true if error
result.error       // the error or null
result.isIdle      // true if idle
result.isSuccess   // true if success
result.isRefreshing // true if loading with previous data
```

### Extensions

```dart
result.dataOr(defaultUser)  // data or default value
result.requireData()        // data or throws error
result.toNullable()         // data or null
```

## Widgets

### StoreResultBuilder

Build UI based on a StoreResult:

```dart
StoreResultBuilder<User>(
  result: userResult,
  idle: () => const Text('Tap to load user'),
  pending: () => const CircularProgressIndicator(),
  success: (user) => Text('Hello, ${user.name}'),
  error: (error) => Text('Error: $error'),
)
```

### StoreResultStreamBuilder

Build UI from a stream of StoreResults:

```dart
StoreResultStreamBuilder<List<User>>(
  stream: userStore.watchAll().map((users) => StoreResult.success(users)),
  idle: () => const Text('Loading...'),
  pending: () => const CircularProgressIndicator(),
  success: (users) => ListView.builder(
    itemCount: users.length,
    itemBuilder: (context, i) => ListTile(title: Text(users[i].name)),
  ),
  error: (error) => Text('Error: $error'),
)
```

### NexusStoreBuilder

Build UI from a NexusStore's watchAll stream:

```dart
NexusStoreBuilder<User, String>(
  store: userStore,
  query: Query<User>().where('isActive', isEqualTo: true),
  builder: (context, users) => ListView.builder(
    itemCount: users.length,
    itemBuilder: (context, i) => ListTile(title: Text(users[i].name)),
  ),
  loading: const CircularProgressIndicator(),
  error: (error) => Text('Error: $error'),
)
```

### NexusStoreItemBuilder

Build UI from a NexusStore's watch stream (single item):

```dart
NexusStoreItemBuilder<User, String>(
  store: userStore,
  id: userId,
  builder: (context, user) {
    if (user == null) {
      return const Text('User not found');
    }
    return Text('Hello, ${user.name}');
  },
  loading: const CircularProgressIndicator(),
  error: (error) => Text('Error: $error'),
)
```

## Providers

### NexusStoreProvider

Provide a single store to the widget tree:

```dart
// Provide the store
NexusStoreProvider<User, String>(
  store: userStore,
  child: MyApp(),
)

// Access in child widgets
final store = context.nexusStore<User, String>();
```

### MultiNexusStoreProvider

Provide multiple stores to the widget tree:

```dart
MultiNexusStoreProvider(
  providers: [
    NexusStoreProvider<User, String>(store: userStore),
    NexusStoreProvider<Post, String>(store: postStore),
    NexusStoreProvider<Comment, String>(store: commentStore),
  ],
  child: MyApp(),
)

// Access each store
final userStore = context.nexusStore<User, String>();
final postStore = context.nexusStore<Post, String>();
```

## BuildContext Extensions

```dart
// Get store from provider
final store = context.nexusStore<User, String>();

// Optional - returns null if not found
final store = context.maybeNexusStore<User, String>();
```

## Lifecycle Observer

Manage store lifecycle with app state changes:

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StoreLifecycleObserver _observer;

  @override
  void initState() {
    super.initState();
    _observer = StoreLifecycleObserver(
      stores: [userStore, postStore],
      onResume: () {
        // App resumed from background - sync data
        userStore.sync();
        postStore.sync();
      },
      onPause: () {
        // App going to background
      },
    );
  }

  @override
  void dispose() {
    _observer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MyAppContent();
}
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_flutter/nexus_store_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final userStore = NexusStore<User, String>(
    backend: InMemoryBackend<User, String>(getId: (u) => u.id),
  );
  await userStore.initialize();

  runApp(
    NexusStoreProvider<User, String>(
      store: userStore,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Users')),
        body: NexusStoreBuilder<User, String>(
          store: context.nexusStore<User, String>(),
          builder: (context, users) {
            if (users.isEmpty) {
              return const Center(child: Text('No users'));
            }
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(users[i].name),
                subtitle: Text(users[i].email),
              ),
            );
          },
          loading: const Center(child: CircularProgressIndicator()),
          error: (e) => Center(child: Text('Error: $e')),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final store = context.nexusStore<User, String>();
            await store.save(User(
              id: DateTime.now().toIso8601String(),
              name: 'New User',
              email: 'new@example.com',
            ));
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});
}
```

## Additional Resources

- [Core Package](../nexus_store/) - Main store abstraction
- [Examples](../../example/) - Complete working examples

## License

MIT License - see [LICENSE](../../LICENSE) for details.
