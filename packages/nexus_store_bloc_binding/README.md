# nexus_store_bloc_binding

[![Pub Version](https://img.shields.io/pub/v/nexus_store_bloc_binding)](https://pub.dev/packages/nexus_store_bloc_binding)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

Bloc/Cubit bindings for NexusStore, enabling familiar Bloc patterns with NexusStore data.

## Features

- **NexusStoreCubit** - Cubit for reactive list-based state management
- **NexusItemCubit** - Cubit for single item state management
- **NexusStoreBloc** - Bloc with events for list-based state management
- **NexusItemBloc** - Bloc with events for single item state management
- **Pattern Matching** - Sealed state classes with `when`/`maybeWhen` for exhaustive handling
- **Optimistic UI** - Previous data preserved during loading/error states
- **BlocObserver** - Configurable logging for debugging

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  nexus_store_bloc_binding:
    path: ../nexus_store_bloc_binding
```

## Usage

### State Classes

Both `NexusStoreState<T>` and `NexusItemState<T>` are sealed classes with pattern matching:

```dart
// List state (NexusStoreState)
state.when(
  initial: () => Text('Press load'),
  loading: (previousData) => CircularProgressIndicator(),
  loaded: (data) => UserList(users: data),
  error: (error, stackTrace, previousData) => ErrorWidget(error),
);

// Item state (NexusItemState)
state.when(
  initial: () => Text('Press load'),
  loading: (previousData) => CircularProgressIndicator(),
  loaded: (data) => UserDetails(user: data),
  notFound: () => Text('User not found'),
  error: (error, stackTrace, previousData) => ErrorWidget(error),
);
```

Convenience getters are available:

```dart
state.dataOrNull   // T? or List<T>?
state.isLoading    // bool
state.hasData      // bool
state.hasError     // bool
state.error        // Object?
```

### Cubits

#### NexusStoreCubit

For managing a collection of items with reactive updates:

```dart
class UsersCubit extends NexusStoreCubit<User, String> {
  UsersCubit(NexusStore<User, String> store) : super(store);

  // Optional: override lifecycle hooks
  @override
  void onSave(User item) {
    // Called before save
  }

  @override
  void onDelete(String id) {
    // Called before delete
  }
}

// Usage
final cubit = UsersCubit(userStore);

// Load all items (subscribes to watchAll)
await cubit.load();

// Load with query
await cubit.load(query: Query<User>((u) => u.age > 18));

// CRUD operations
await cubit.save(user);
await cubit.saveAll([user1, user2]);
await cubit.delete('user-id');
await cubit.deleteAll(['id1', 'id2']);

// Refresh data
await cubit.refresh();
```

#### NexusItemCubit

For managing a single item with reactive updates:

```dart
class UserCubit extends NexusItemCubit<User, String> {
  UserCubit(NexusStore<User, String> store, String id) : super(store, id);
}

// Usage
final cubit = UserCubit(userStore, 'user-123');

// Load item (subscribes to watch(id))
await cubit.load();

// Access the ID
print(cubit.id); // 'user-123'

// Save with options
await cubit.save(user, policy: WritePolicy.cacheOnly, tags: {'profile'});

// Delete
await cubit.delete(policy: WritePolicy.networkFirst);

// Refresh
await cubit.refresh();
```

### Blocs

#### NexusStoreBloc

Event-driven state management for collections:

```dart
class UsersBloc extends NexusStoreBloc<User, String> {
  UsersBloc(NexusStore<User, String> store) : super(store);
}

// Usage
final bloc = UsersBloc(userStore);

// Add events
bloc.add(const LoadAll());
bloc.add(LoadAll(query: Query<User>((u) => u.active)));
bloc.add(Save(user, policy: WritePolicy.cacheAndNetwork));
bloc.add(SaveAll([user1, user2]));
bloc.add(Delete('user-id'));
bloc.add(DeleteAll(['id1', 'id2']));
bloc.add(const Refresh());

// Listen to state
bloc.stream.listen((state) {
  state.when(
    initial: () => print('Initial'),
    loading: (_) => print('Loading...'),
    loaded: (users) => print('Loaded ${users.length} users'),
    error: (e, _, __) => print('Error: $e'),
  );
});
```

#### NexusItemBloc

Event-driven state management for single items:

```dart
class UserBloc extends NexusItemBloc<User, String> {
  UserBloc(NexusStore<User, String> store, String id) : super(store, id);
}

// Usage
final bloc = UserBloc(userStore, 'user-123');

// Add events
bloc.add(const LoadItem());
bloc.add(SaveItem(user, policy: WritePolicy.cacheOnly));
bloc.add(const DeleteItem());
bloc.add(const RefreshItem());
```

### BlocObserver

Configure logging for all NexusStore blocs/cubits:

```dart
// Set up globally
Bloc.observer = NexusStoreBlocObserver(
  logTransitions: true,
  logEvents: true,
  logErrors: true,
  onLog: (message) => debugPrint(message),
);

// Or with a custom logger
Bloc.observer = NexusStoreBlocObserver(
  onLog: (message) => myLogger.info(message),
);
```

### Flutter Integration

Use with `flutter_bloc` widgets:

```dart
// Provide the cubit/bloc
BlocProvider(
  create: (context) => UsersCubit(userStore)..load(),
  child: UsersPage(),
)

// Build UI based on state
BlocBuilder<UsersCubit, NexusStoreState<User>>(
  builder: (context, state) {
    return state.when(
      initial: () => const Text('Press load'),
      loading: (prev) => prev != null
          ? Stack(
              children: [
                UserList(users: prev),
                const LoadingOverlay(),
              ],
            )
          : const CircularProgressIndicator(),
      loaded: (users) => UserList(users: users),
      error: (error, _, prev) => Column(
        children: [
          Text('Error: $error'),
          if (prev != null) UserList(users: prev),
        ],
      ),
    );
  },
)

// Listen for specific states
BlocListener<UsersCubit, NexusStoreState<User>>(
  listenWhen: (prev, curr) => curr.hasError,
  listener: (context, state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${state.error}')),
    );
  },
  child: UserList(),
)
```

## API Reference

### State Classes

| Class | Description |
|-------|-------------|
| `NexusStoreState<T>` | Sealed class for list state (Initial, Loading, Loaded, Error) |
| `NexusItemState<T>` | Sealed class for item state (Initial, Loading, Loaded, NotFound, Error) |

### Cubits

| Class | Description |
|-------|-------------|
| `NexusStoreCubit<T, ID>` | Cubit for list-based reactive state |
| `NexusItemCubit<T, ID>` | Cubit for single item reactive state |

### Blocs

| Class | Description |
|-------|-------------|
| `NexusStoreBloc<T, ID>` | Bloc for list-based event-driven state |
| `NexusItemBloc<T, ID>` | Bloc for single item event-driven state |

### Events

| Store Events | Description |
|--------------|-------------|
| `LoadAll` | Load all items, optionally with query |
| `Save` | Save a single item |
| `SaveAll` | Save multiple items |
| `Delete` | Delete by ID |
| `DeleteAll` | Delete multiple by IDs |
| `Refresh` | Reload current query |

| Item Events | Description |
|-------------|-------------|
| `LoadItem` | Load the item |
| `SaveItem` | Save the item |
| `DeleteItem` | Delete the item |
| `RefreshItem` | Reload the item |

### Utilities

| Class | Description |
|-------|-------------|
| `NexusStoreBlocObserver` | Configurable BlocObserver for debugging |

## Testing

The package includes comprehensive tests. Run them with:

```bash
cd packages/nexus_store_bloc_binding
dart test
```

Use `bloc_test` for testing your cubits/blocs:

```dart
blocTest<UsersCubit, NexusStoreState<User>>(
  'emits loaded when load succeeds',
  build: () => UsersCubit(mockStore),
  act: (cubit) async {
    await cubit.load();
    streamController.add([testUser]);
  },
  expect: () => [
    isA<NexusStoreLoading<User>>(),
    isA<NexusStoreLoaded<User>>(),
  ],
);
```

## License

MIT License
