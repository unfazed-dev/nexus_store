# nexus_store_riverpod_generator

[![Pub Version](https://img.shields.io/pub/v/nexus_store_riverpod_generator)](https://pub.dev/packages/nexus_store_riverpod_generator)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

Code generator for Riverpod providers from NexusStore. Automatically generates stream providers for entities with reactive watchAll and watch-by-ID patterns.

## Features

- Generates `{name}StoreProvider` for direct store access
- Generates `{name}Provider` as `StreamProvider<List<T>>` for reactive lists
- Generates `{name}ByIdProvider` as `StreamProvider.family` for single entity access
- Generates `{name}StatusProvider` with `StoreResult` wrapper for loading states
- Supports keepAlive option to prevent auto-dispose
- Custom provider name prefixes
- Integrates with build_runner

## Installation

Add this package as a dev dependency:

```yaml
dependencies:
  nexus_store: ^0.1.0
  nexus_store_riverpod_binding: ^0.1.0
  flutter_riverpod: ^2.0.0

dev_dependencies:
  nexus_store_riverpod_generator: ^0.1.0
  build_runner: ^2.4.0
```

## Usage

### 1. Create a store function with annotation

Mark your store factory function with `@riverpodNexusStore`:

```dart
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_riverpod_binding/nexus_store_riverpod_binding.dart';

part 'user_store.g.dart';

@riverpodNexusStore
NexusStore<User, String> userStore(Ref ref) {
  return NexusStore<User, String>(
    backend: ref.watch(backendProvider),
    config: StoreConfig.defaults,
  );
}
```

### 2. Run the generator

```bash
dart run build_runner build
```

Or for watch mode during development:

```bash
dart run build_runner watch
```

### 3. Use the generated providers

The generator creates a `.g.dart` file with:

```dart
// user_store.g.dart (generated)

/// Provider for the User store.
final userStoreProvider = Provider.autoDispose<NexusStore<User, String>>((ref) {
  final store = userStore(ref);
  ref.onDispose(() => store.dispose());
  return store;
});

/// StreamProvider for all users.
final usersProvider = StreamProvider.autoDispose<List<User>>((ref) {
  final store = ref.watch(userStoreProvider);
  return store.watchAll();
});

/// StreamProvider.family for a single user by ID.
final userByIdProvider = StreamProvider.autoDispose.family<User?, String>((ref, id) {
  final store = ref.watch(userStoreProvider);
  return store.watch(id);
});

/// StreamProvider for all users with StoreResult status.
final usersStatusProvider = StreamProvider.autoDispose<StoreResult<List<User>>>((ref) {
  final store = ref.watch(userStoreProvider);
  return store.watchAll().map(StoreResult.success);
});
```

### 4. Use in widgets

```dart
class UserListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return usersAsync.when(
      data: (users) => ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) => UserTile(user: users[index]),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}

class UserDetailPage extends ConsumerWidget {
  final String userId;

  const UserDetailPage({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(userId));

    return userAsync.when(
      data: (user) => user != null
          ? UserDetails(user: user)
          : const Text('User not found'),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

## Annotation Options

### @riverpodNexusStore

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `keepAlive` | `bool` | `false` | Prevent auto-dispose when all listeners are removed |
| `name` | `String?` | `null` | Custom provider name prefix (derived from function name if not specified) |

### Examples

#### Default (auto-dispose enabled)

```dart
@riverpodNexusStore
NexusStore<User, String> userStore(Ref ref) => ...;
// Generates: userStoreProvider, usersProvider, userByIdProvider
```

#### Keep alive (no auto-dispose)

```dart
@RiverpodNexusStore(keepAlive: true)
NexusStore<Product, String> productStore(Ref ref) => ...;
// Generates providers without .autoDispose modifier
```

#### Custom name prefix

```dart
@RiverpodNexusStore(name: 'employee')
NexusStore<Person, String> personStore(Ref ref) => ...;
// Generates: employeeStoreProvider, employeesProvider, employeeByIdProvider
```

## Generated Providers

For a function `userStore` returning `NexusStore<User, String>`:

| Provider | Type | Description |
|----------|------|-------------|
| `userStoreProvider` | `Provider<NexusStore<User, String>>` | Direct store access |
| `usersProvider` | `StreamProvider<List<User>>` | Reactive list from `watchAll()` |
| `userByIdProvider` | `StreamProvider.family<User?, String>` | Single entity from `watch(id)` |
| `usersStatusProvider` | `StreamProvider<StoreResult<List<User>>>` | List with loading state |

## Integration with nexus_store_riverpod_binding

This generator is designed to work alongside `nexus_store_riverpod_binding`, which provides:

- `StoreResult<T>` sealed class for async states
- Additional widgets and hooks for Riverpod integration
- Ref extensions for store management

## Build Configuration

The generator automatically applies to dependents. The default configuration in `build.yaml`:

```yaml
builders:
  nexus_store_riverpod:
    import: "package:nexus_store_riverpod_generator/builder.dart"
    builder_factories: ["nexusStoreRiverpodBuilder"]
    build_extensions: {".dart": [".nexus_store.g.dart"]}
    auto_apply: dependents
    build_to: source
    applies_builders: ["source_gen|combining_builder"]
```

## License

See repository license.
