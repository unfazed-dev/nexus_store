# nexus_store_riverpod_binding

[![Pub Version](https://img.shields.io/pub/v/nexus_store_riverpod_binding)](https://pub.dev/packages/nexus_store_riverpod_binding)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

Riverpod integration for NexusStore - provides first-class Riverpod support with providers, extensions, widgets, and hooks for reactive data management.

## Features

- **Provider Helpers**: Factory functions for creating NexusStore providers with automatic disposal
- **Stream Providers**: Pre-built StreamProviders for `watchAll()` and `watch()` operations
- **Extensions**: Convenient extension methods on NexusStore and Ref for cleaner code
- **Widget Utilities**: ConsumerWidget wrappers for common NexusStore patterns
- **Flutter Hooks**: Hooks for use with `hooks_riverpod`
- **Code Generation**: Optional `@riverpodNexusStore` annotation for auto-generating providers

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  nexus_store: ^1.0.0
  nexus_store_riverpod_binding: ^0.1.0
  flutter_riverpod: ^2.6.1

# Optional: For hooks support
  flutter_hooks: ^0.20.5
  hooks_riverpod: ^2.6.1

# Optional: For code generation
dev_dependencies:
  nexus_store_riverpod_generator: ^0.1.0
  build_runner: ^2.4.0
```

## Quick Start

### Basic Usage

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_riverpod_binding/nexus_store_riverpod_binding.dart';

// 1. Create a store provider with auto-disposal
final userStoreProvider = createNexusStoreProvider<User, String>(
  (ref) => NexusStore<User, String>(backend: createBackend()),
);

// 2. Create stream providers for reactive data
final usersProvider = createWatchAllProvider<User, String>(userStoreProvider);
final userByIdProvider = createWatchByIdProvider<User, String>(userStoreProvider);

// 3. Use in widgets
class UserListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);

    return users.when(
      data: (data) => ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) => UserTile(data[index]),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => ErrorWidget(e),
    );
  }
}
```

### With Extensions (Cleaner Syntax)

```dart
// Use bindToRef for automatic disposal
final userStoreProvider = Provider<NexusStore<User, String>>((ref) {
  return NexusStore<User, String>(backend: createBackend())
    ..bindToRef(ref);
});

// Use ref extensions for cleaner stream access
final usersProvider = StreamProvider<List<User>>((ref) {
  return ref.watchStoreAll(userStoreProvider);
});
```

### Widget Utilities

```dart
// Use pre-built consumer widgets
NexusStoreListConsumer<User>(
  provider: usersProvider,
  builder: (context, users) => ListView.builder(
    itemCount: users.length,
    itemBuilder: (context, index) => UserTile(users[index]),
  ),
  loading: (context) => const CircularProgressIndicator(),
  error: (context, error, stackTrace) => ErrorView(error),
)

// For single items
NexusStoreItemConsumer<User, String>(
  provider: userByIdProvider,
  id: userId,
  builder: (context, user) => user != null
    ? UserDetail(user)
    : const Text('User not found'),
  notFound: (context) => const Text('User not found'),
)
```

### With Flutter Hooks

```dart
class UserListScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use WidgetRef extension methods
    final users = ref.watchStoreList(usersProvider);

    // Track loading state for operations
    final (isLoading, execute) = useStoreOperation();

    return Column(
      children: [
        if (isLoading) const LinearProgressIndicator(),
        Expanded(
          child: users.when(
            data: (data) => ListView.builder(...),
            loading: () => const CircularProgressIndicator(),
            error: (e, st) => ErrorWidget(e),
          ),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : () => execute(
            () => ref.readStore(userStoreProvider).save(newUser),
          ),
          child: const Text('Add User'),
        ),
      ],
    );
  }
}
```

## API Reference

### Provider Factory Functions

| Function | Description |
|----------|-------------|
| `createNexusStoreProvider<T, ID>()` | Creates a Provider with optional auto-disposal |
| `createAutoDisposeNexusStoreProvider<T, ID>()` | Creates an auto-dispose Provider |
| `createWatchAllProvider<T, ID>()` | Creates a StreamProvider for `watchAll()` |
| `createWatchByIdProvider<T, ID>()` | Creates a family StreamProvider for `watch(id)` |
| `createWatchWithStatusProvider<T, ID>()` | Creates a StreamProvider with `StoreResult` status |

### Extension Methods

#### NexusStore Extensions

```dart
extension NexusStoreRiverpodX<T, ID> on NexusStore<T, ID> {
  void bindToRef(Ref ref);           // Auto-dispose on ref disposal
  void bindToAutoDisposeRef(AutoDisposeRef ref);
  NexusStoreKeepAlive<T, ID> withKeepAlive(Ref ref); // Manual invalidation
}
```

#### Ref Extensions

```dart
extension NexusStoreRefX on Ref {
  Stream<List<T>> watchStoreAll<T, ID>(provider, {Query<T>? query});
  Stream<T?> watchStoreItem<T, ID>(provider, ID id);
  Stream<StoreResult<List<T>>> watchStoreAllWithStatus<T, ID>(provider);
}
```

#### WidgetRef Extensions

```dart
extension NexusStoreWidgetRefHooksX on WidgetRef {
  AsyncValue<List<T>> watchStoreList<T>(provider);
  AsyncValue<T?> watchStoreItem<T, ID>(provider, id);
  NexusStore<T, ID> readStore<T, ID>(provider);
  Future<List<T>> refreshStoreList<T>(provider);
  Future<T?> refreshStoreItem<T, ID>(provider, id);
}
```

### Widgets

| Widget | Description |
|--------|-------------|
| `NexusStoreListConsumer<T>` | Consumer for list data with loading/error handling |
| `NexusStoreItemConsumer<T, ID>` | Consumer for single item by ID |
| `NexusStoreRefreshableConsumer<T>` | Consumer with pull-to-refresh support |
| `NexusStoreHookWidget` | Base class for hook-based widgets |

### Hooks

| Hook | Description |
|------|-------------|
| `useStoreCallback<T, ID, A, R>()` | Memoized callback for store operations |
| `useStoreOperation()` | Tracks loading state for async operations |
| `useStoreDebouncedSearch()` | Debounced search term state |
| `useStoreDataWithPrevious<T>()` | Retains previous data while loading |

## Code Generation (Optional)

For the cleanest syntax, use the `@riverpodNexusStore` annotation:

### Setup

Add the generator to your dev dependencies:

```yaml
dev_dependencies:
  nexus_store_riverpod_generator: ^0.1.0
  build_runner: ^2.4.0
```

### Usage

```dart
import 'package:nexus_store_riverpod_binding/nexus_store_riverpod_binding.dart';

part 'user_store.g.dart';

@riverpodNexusStore
NexusStore<User, String> userStore(UserStoreRef ref) {
  return NexusStore<User, String>(
    backend: ref.watch(backendProvider),
  );
}
```

Run the generator:

```bash
dart run build_runner build
```

This generates:
- `userStoreProvider` - Provider<NexusStore<User, String>>
- `usersProvider` - StreamProvider<List<User>>
- `userByIdProvider` - StreamProvider.family<User?, String>
- `usersStatusProvider` - StreamProvider<StoreResult<List<User>>>

### Annotation Options

```dart
@RiverpodNexusStore(
  keepAlive: true,  // Prevent auto-dispose
  name: 'product',  // Custom name prefix
)
NexusStore<Product, int> productStore(ProductStoreRef ref) { ... }
```

## Disposal Patterns

### Auto-Dispose (Default)

```dart
// Store is disposed when provider is invalidated
final storeProvider = createNexusStoreProvider<User, String>(
  (ref) => NexusStore(...),
  autoDispose: true, // default
);
```

### Keep-Alive (Long-Lived)

```dart
// Store persists until manually invalidated
final storeProvider = Provider<NexusStoreKeepAlive<User, String>>((ref) {
  return NexusStore<User, String>(backend: createBackend())
    .withKeepAlive(ref);
});

// Later, to dispose:
ref.read(storeProvider).invalidate();
```

### Multiple Stores

```dart
final storesProvider = Provider<StoreDisposalManager>((ref) {
  final manager = StoreDisposalManager.forRef(ref);
  manager.register(userStore);
  manager.register(productStore);
  return manager;
});
```

## Best Practices

1. **Use auto-dispose for scoped data**: Data that's only needed in specific screens
2. **Use keepAlive for global data**: User session, app configuration, etc.
3. **Prefer extensions over manual providers**: Cleaner, less boilerplate
4. **Use family providers for detail screens**: `watchByIdProvider(userId)`
5. **Handle all AsyncValue states**: Don't ignore loading and error states

## Migration from Manual Providers

Before:
```dart
final usersProvider = StreamProvider<List<User>>((ref) {
  final store = ref.watch(userStoreProvider);
  return store.watchAll();
});
```

After:
```dart
final usersProvider = createWatchAllProvider<User, String>(userStoreProvider);
```

## Related Packages

- [nexus_store](../nexus_store) - Core package
- [nexus_store_flutter_widgets](../nexus_store_flutter_widgets) - Flutter widgets
- [nexus_store_bloc_binding](../nexus_store_bloc_binding) - Bloc integration
