# nexus_store_signals_binding

[![Pub Version](https://img.shields.io/pub/v/nexus_store_signals_binding)](https://pub.dev/packages/nexus_store_signals_binding)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

Signals integration for NexusStore - provides fine-grained reactive signals for efficient UI updates.

## Features

- **Store to Signal Adapters** - Convert NexusStore streams to signals
- **State Management** - Sealed state classes with pattern matching
- **Computed Signals** - Filter, sort, count, and transform utilities
- **Lifecycle Management** - SignalScope and disposal helpers

## Installation

```yaml
dependencies:
  nexus_store_signals_binding:
    path: ../nexus_store_signals_binding
```

## Basic Usage

### Convert Store to Signal

```dart
import 'package:nexus_store_signals_binding/nexus_store_signals_binding.dart';
import 'package:signals_flutter/signals_flutter.dart';

final userStore = NexusStore<User, String>(backend: backend);

// All items as signal
final usersSignal = userStore.toSignal();

// Single item as signal
final currentUserSignal = userStore.toItemSignal(currentUserId);

// Use in widget
Watch((context) {
  return ListView(
    children: usersSignal.value.map((u) => UserTile(u)).toList(),
  );
});
```

### State Signals with Loading/Error

```dart
// Get signal with state (initial, loading, data, error)
final usersState = userStore.toStateSignal();

Watch((context) {
  return usersState.value.when(
    initial: () => const Text('Ready to load'),
    loading: (previousData) => Column(
      children: [
        if (previousData != null) UserList(users: previousData),
        const CircularProgressIndicator(),
      ],
    ),
    data: (users) => UserList(users: users),
    error: (error, stackTrace, previousData) => Column(
      children: [
        Text('Error: $error'),
        if (previousData != null) UserList(users: previousData),
      ],
    ),
  );
});
```

### Single Item State Signals

```dart
final userState = userStore.toItemStateSignal(userId);

Watch((context) {
  return userState.value.when(
    initial: () => const Text('Loading...'),
    loading: (prev) => const CircularProgressIndicator(),
    data: (user) => UserDetails(user: user),
    notFound: () => const Text('User not found'),
    error: (e, st, prev) => Text('Error: $e'),
  );
});
```

### NexusSignal Wrapper

```dart
// Create store-aware signal with refresh and dispose
final usersSignal = NexusSignal.fromStore(userStore);

// Trigger store sync
await usersSignal.refresh();

// Access value
print(usersSignal.value); // List<User>

// Clean up
usersSignal.dispose();
```

### NexusListSignal with CRUD

```dart
final usersListSignal = NexusListSignal.fromStore(userStore);

// Add item
await usersListSignal.add(newUser);

// Remove item
await usersListSignal.remove(userId);

// Update item
await usersListSignal.update(userId, (user) => user.copyWith(name: 'New Name'));

// Access list operations
print(usersListSignal.length);
print(usersListSignal.isEmpty);
final firstUser = usersListSignal[0];
```

## Computed Signals

Extension methods on `Signal<List<T>>` for common patterns:

```dart
final usersSignal = userStore.toSignal();

// Filter
final activeUsers = usersSignal.filtered((u) => u.isActive);

// Sort
final sortedByName = usersSignal.sorted((a, b) => a.name.compareTo(b.name));

// Count
final userCount = usersSignal.count();

// First match
final firstAdmin = usersSignal.firstWhereOrNull((u) => u.isAdmin);

// Map
final userNames = usersSignal.mapped((u) => u.name);

// Predicates
final hasAdmin = usersSignal.any((u) => u.isAdmin);
final allActive = usersSignal.every((u) => u.isActive);
```

## Lifecycle Management

### SignalScope

```dart
final scope = SignalScope();

// Create signals through the scope
final counter = scope.createSignal(0);
final name = scope.createSignal('');
final users = scope.createFromStore(userStore);

// Dispose all at once
scope.disposeAll();
```

### NexusSignalsMixin for Widgets

```dart
class _MyWidgetState extends State<MyWidget> with NexusSignalsMixin {
  late final counter = createSignal(0);
  late final users = createFromStore(userStore);

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      return Column(
        children: [
          Text('Count: ${counter.value}'),
          ...users.value.map((u) => UserTile(u)),
        ],
      );
    });
  }

  @override
  void dispose() {
    disposeSignals(); // Clean up all signals
    super.dispose();
  }
}
```

## State Classes

### NexusSignalState (for lists)

```dart
sealed class NexusSignalState<T> {
  // Pattern matching
  R when<R>({
    required R Function() initial,
    required R Function(List<T>? previousData) loading,
    required R Function(List<T> data) data,
    required R Function(Object error, StackTrace? stackTrace, List<T>? previousData) error,
  });

  // Optional handlers with fallback
  R maybeWhen<R>({...required R Function() orElse});

  // Properties
  List<T>? get dataOrNull;
  bool get isLoading;
  bool get hasData;
  bool get hasError;
}
```

### NexusItemSignalState (for single items)

```dart
sealed class NexusItemSignalState<T> {
  // Pattern matching
  R when<R>({
    required R Function() initial,
    required R Function(T? previousData) loading,
    required R Function(T data) data,
    required R Function() notFound,
    required R Function(Object error, StackTrace? stackTrace, T? previousData) error,
  });
}
```

## API Reference

### Extensions on NexusStore

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toSignal()` | `Signal<List<T>>` | All items as signal |
| `toItemSignal(id)` | `Signal<T?>` | Single item as signal |
| `toStateSignal()` | `Signal<NexusSignalState<T>>` | With loading/error states |
| `toItemStateSignal(id)` | `Signal<NexusItemSignalState<T>>` | Single item with states |

### NexusSignal Methods

| Method | Description |
|--------|-------------|
| `value` | Current list value |
| `peek()` | Read value without subscribing |
| `refresh()` | Trigger store sync |
| `dispose()` | Clean up subscriptions |
| `subscribe(callback)` | Listen to changes |

### NexusListSignal Methods

| Method | Description |
|--------|-------------|
| `add(item)` | Save item to store |
| `remove(id)` | Delete item from store |
| `update(id, transform)` | Transform and save item |
| `length` | Number of items |
| `isEmpty` | Whether list is empty |
| `[index]` | Access item by index |

## Batteries-Included Usage

For reduced boilerplate, use signal bundles and the manager.

### Store Bundle

Create bundled signals with computed signals support:

```dart
final userBundle = SignalsStoreBundle.create(
  config: SignalsStoreConfig<User, String>(
    name: 'users',
    store: userStore,
    computedSignals: {
      'activeCount': (s) => computed(() =>
        s.value.where((u) => u.isActive).length
      ),
      'sortedByName': (s) => computed(() =>
        [...s.value]..sort((a, b) => a.name.compareTo(b.name))
      ),
    },
  ),
);

// Access signals
final users = userBundle.listSignal;
final state = userBundle.stateSignal;

// Access named computed signals
final activeCount = userBundle.computed('activeCount');
final sortedUsers = userBundle.computed('sortedByName');

// Use in widget
Watch((context) {
  return Column(
    children: [
      Text('Active: ${activeCount.value}'),
      ...users.value.map((u) => UserTile(u)),
    ],
  );
});

// Clean up
userBundle.dispose();
```

### Multi-Store Manager

Coordinate multiple stores:

```dart
final manager = SignalsManager([
  SignalsStoreConfig<User, String>(name: 'users', store: userStore),
  SignalsStoreConfig<Post, String>(name: 'posts', store: postStore),
]);

// Access bundles
final userBundle = manager.getBundle('users');
final postBundle = manager.getBundle('posts');

// Direct signal access
final usersSignal = manager.getListSignal('users');
final usersState = manager.getStateSignal('users');
```

### Cross-Store Computed Signals

Create derived state across multiple stores:

```dart
final totalCount = manager.createCrossStoreComputed<int>(
  'totalCount',
  (bundles) {
    final userCount = bundles['users']!.listSignal.value.length;
    final postCount = bundles['posts']!.listSignal.value.length;
    return userCount + postCount;
  },
);

Watch((context) {
  return Text('Total items: ${totalCount.value}');
});

// Clean up all signals
manager.dispose();
```

## Dependencies

- `signals` ^6.3.0
- `signals_flutter` ^6.3.0
- `nexus_store`
- `collection` ^1.19.0
