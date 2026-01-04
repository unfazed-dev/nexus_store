# State Management Reference

Detailed documentation for all 3 nexus_store state management bindings.

## Binding Comparison

| Binding | Pattern | Reactivity | Boilerplate | Best For |
|---------|---------|------------|-------------|----------|
| Riverpod | Provider | Coarse | Low | Most Flutter apps |
| Bloc | Event/State | Coarse | Medium | Complex business logic |
| Signals | Fine-grained | Fine | Low | Performance-critical UIs |

---

## Riverpod Binding

Provider-based state management with hooks support.

### Installation

```yaml
dependencies:
  nexus_store_riverpod_binding:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_riverpod_binding
  flutter_riverpod: ^2.0.0
  hooks_riverpod: ^2.0.0  # For hooks

dev_dependencies:
  nexus_store_riverpod_generator:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_riverpod_generator
  riverpod_generator: ^2.0.0
  build_runner: ^2.4.0
```

### Create Providers Manually

```dart
import 'package:nexus_store_riverpod_binding/nexus_store_riverpod_binding.dart';

// Store provider
final userStoreProvider = createNexusStoreProvider<User, String>(
  (ref) => NexusStore(backend: backend, config: StoreConfig.defaults),
);

// Auto-dispose variant
final userStoreProvider = createAutoDisposeNexusStoreProvider<User, String>(
  (ref) => NexusStore(backend: backend, config: StoreConfig.defaults),
);

// Stream providers
final usersProvider = createWatchAllProvider<User, String>(userStoreProvider);
final userByIdProvider = createWatchByIdProvider<User, String>(userStoreProvider);
final usersWithStatusProvider = createWatchWithStatusProvider<User, String>(userStoreProvider);
```

### Generate Providers (Recommended)

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:nexus_store_riverpod_binding/nexus_store_riverpod_binding.dart';

part 'user_store.g.dart';
part 'user_store.nexus_store.g.dart';

@riverpodNexusStore
NexusStore<User, String> userStore(UserStoreRef ref) {
  return NexusStore(backend: backend, config: StoreConfig.defaults);
}

// Generated providers:
// - userStoreProvider (Provider<NexusStore<User, String>>)
// - userProvider (StreamProvider<List<User>>)
// - userByIdProvider (StreamProvider.family<User?, String>)
// - userStatusProvider (StreamProvider<StoreResult<List<User>>>)
```

### Watch in Widgets

```dart
class UserListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all users
    final usersAsync = ref.watch(userProvider);

    return usersAsync.when(
      data: (users) => ListView.builder(
        itemCount: users.length,
        itemBuilder: (_, i) => Text(users[i].name),
      ),
      loading: () => CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
```

### Watch with Status

```dart
final statusAsync = ref.watch(userStatusProvider);

return statusAsync.when(
  data: (result) => result.when(
    idle: () => Text('Idle'),
    pending: () => CircularProgressIndicator(),
    success: (users) => UserList(users),
    error: (e) => Text('Error: $e'),
  ),
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);
```

### Consumer Widgets

```dart
NexusStoreListConsumer<User, String>(
  store: ref.read(userStoreProvider),
  query: Query<User>().where('active', isEqualTo: true),
  builder: (context, users, status) {
    if (status == StoreResultStatus.pending) {
      return CircularProgressIndicator();
    }
    return UserList(users);
  },
);

NexusStoreItemConsumer<User, String>(
  store: ref.read(userStoreProvider),
  id: userId,
  builder: (context, user, status) {
    if (user == null) return Text('Not found');
    return UserCard(user);
  },
);
```

### Hooks

```dart
class UserListPage extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch users with hooks
    final users = ref.watchStoreList<User, String>(userStoreProvider);

    // Debounced search
    final searchResults = useStoreDebouncedSearch<User, String>(
      ref.read(userStoreProvider),
      searchTerm,
      searchField: 'name',
      debounceMs: 300,
    );

    // Store operations
    final saveOperation = useStoreOperation<User, String>(
      ref.read(userStoreProvider),
      (store, user) => store.save(user),
    );

    return Column(
      children: [
        ElevatedButton(
          onPressed: () => saveOperation.execute(newUser),
          child: Text('Save'),
        ),
        if (saveOperation.isLoading) CircularProgressIndicator(),
      ],
    );
  }
}
```

### Ref Extensions

```dart
// In any ConsumerWidget or provider
final users = ref.watchStoreAll<User, String>(userStoreProvider);
final user = ref.watchStoreItem<User, String>(userStoreProvider, 'user-123');
final store = ref.readStore<User, String>(userStoreProvider);
ref.refreshStoreList<User, String>(userStoreProvider);
```

---

## Bloc Binding

Event-driven state management with sealed classes.

### Installation

```yaml
dependencies:
  nexus_store_bloc_binding:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_bloc_binding
  flutter_bloc: ^8.0.0
```

### Using Cubit (Simpler)

```dart
import 'package:nexus_store_bloc_binding/nexus_store_bloc_binding.dart';

// Create cubit
final userCubit = NexusStoreCubit<User, String>(store);

// Load data
await userCubit.loadAll();
await userCubit.loadAll(query: Query<User>().where('active', isEqualTo: true));

// CRUD operations
await userCubit.save(user);
await userCubit.delete('user-123');
await userCubit.refresh();
```

### Cubit State

```dart
BlocBuilder<NexusStoreCubit<User, String>, NexusStoreState<User>>(
  bloc: userCubit,
  builder: (context, state) {
    return state.when(
      initial: () => Text('Initial'),
      loading: (previousData) => Stack(
        children: [
          if (previousData != null) UserList(previousData),  // Optimistic UI
          CircularProgressIndicator(),
        ],
      ),
      loaded: (users) => UserList(users),
      error: (error, previousData) => Column(
        children: [
          Text('Error: $error'),
          if (previousData != null) UserList(previousData),  // Show stale data
        ],
      ),
    );
  },
);
```

### Single Item Cubit

```dart
final userItemCubit = NexusItemCubit<User, String>(store, 'user-123');
await userItemCubit.load();

BlocBuilder<NexusItemCubit<User, String>, NexusItemState<User>>(
  bloc: userItemCubit,
  builder: (context, state) {
    return state.when(
      initial: () => Text('Initial'),
      loading: (previous) => CircularProgressIndicator(),
      loaded: (user) => UserCard(user),
      notFound: () => Text('User not found'),
      error: (error, previous) => Text('Error: $error'),
    );
  },
);
```

### Using Bloc (Event-Driven)

```dart
// Create bloc
final userBloc = NexusStoreBloc<User, String>(store);

// Dispatch events
userBloc.add(LoadAll());
userBloc.add(LoadAll(query: Query<User>().where('active', isEqualTo: true)));
userBloc.add(Save(user));
userBloc.add(SaveAll([user1, user2]));
userBloc.add(Delete('user-123'));
userBloc.add(DeleteAll(['id1', 'id2']));
userBloc.add(Refresh());
```

### Item Bloc

```dart
final userItemBloc = NexusItemBloc<User, String>(store, 'user-123');

userItemBloc.add(LoadItem());
userItemBloc.add(SaveItem(updatedUser));
userItemBloc.add(DeleteItem());
userItemBloc.add(RefreshItem());
```

### Bloc Observer

```dart
// Enable logging
Bloc.observer = NexusStoreBlocObserver(
  logEvents: true,
  logTransitions: true,
  logErrors: true,
);
```

---

## Signals Binding

Fine-grained reactive signals for efficient UI updates.

### Installation

```yaml
dependencies:
  nexus_store_signals_binding:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_signals_binding
  signals: ^5.0.0
  signals_flutter: ^5.0.0
```

### Basic Usage

```dart
import 'package:nexus_store_signals_binding/nexus_store_signals_binding.dart';

// Convert store to signal
final usersSignal = store.toSignal();

// Access current value
final users = usersSignal.value;

// React to changes
effect(() {
  print('Users changed: ${usersSignal.value.length}');
});
```

### List Signal with CRUD

```dart
final usersSignal = store.toSignal();

// Add item
await usersSignal.add(newUser);

// Update item
await usersSignal.update(userId, (user) => user.copyWith(name: 'New Name'));

// Remove item
await usersSignal.remove(userId);

// Refresh from store
await usersSignal.refresh();
```

### Single Item Signal

```dart
final userSignal = store.toItemSignal('user-123');

// Access value
final user = userSignal.value;  // User?

// Watch for changes
effect(() {
  if (userSignal.value != null) {
    print('User: ${userSignal.value!.name}');
  }
});
```

### State Signals (with Status)

```dart
// List with status
final usersStateSignal = store.toStateSignal();

effect(() {
  usersStateSignal.value.when(
    idle: () => print('Idle'),
    pending: () => print('Loading...'),
    success: (users) => print('Loaded ${users.length} users'),
    error: (e) => print('Error: $e'),
  );
});

// Item with status
final userStateSignal = store.toItemStateSignal('user-123');

effect(() {
  userStateSignal.value.when(
    idle: () => print('Idle'),
    pending: () => print('Loading...'),
    success: (user) => print('User: ${user?.name}'),
    error: (e) => print('Error: $e'),
  );
});
```

### Computed Signals

```dart
final usersSignal = store.toSignal();

// Filter
final activeUsers = usersSignal.filtered((u) => u.isActive);
final admins = usersSignal.filtered((u) => u.role == 'admin');

// Sort
final sortedByName = usersSignal.sorted((a, b) => a.name.compareTo(b.name));

// Count
final userCount = usersSignal.count();
final activeCount = activeUsers.count();

// First match
final firstAdmin = usersSignal.firstWhereOrNull((u) => u.role == 'admin');

// Map/transform
final userNames = usersSignal.mapped((u) => u.name);

// Predicates
final hasAdmins = usersSignal.any((u) => u.role == 'admin');
final allActive = usersSignal.every((u) => u.isActive);
```

### Signal Scope

```dart
// Manage multiple signals with automatic disposal
final scope = SignalScope();

final usersSignal = scope.createSignal(store.toSignal);
final ordersSignal = scope.createSignal(orderStore.toSignal);

// Dispose all at once
scope.dispose();
```

### Widget Integration

```dart
class UserListPage extends StatefulWidget with NexusSignalsMixin {
  @override
  void initSignals() {
    usersSignal = registerSignal(store.toSignal());
    activeUsers = registerComputed(() =>
      usersSignal.value.where((u) => u.isActive).toList()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final users = activeUsers.value;
      return ListView.builder(
        itemCount: users.length,
        itemBuilder: (_, i) => Text(users[i].name),
      );
    });
  }
}
```

### SignalBuilder Widget

```dart
SignalBuilder(
  signal: usersSignal.signal,
  builder: (context, users) => UserList(users),
);
```
