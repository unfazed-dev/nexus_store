# TRACKER: Signals Binding Package

## Status: PENDING

## Overview

Create `nexus_store_signals_binding` package that adapts NexusStore streams to Signals for fine-grained reactivity.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-048, Task 37
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Package Setup
- [ ] Create package skeleton
  - [ ] `pubspec.yaml` with dependencies
  - [ ] `analysis_options.yaml`
  - [ ] Basic library structure

- [ ] Add dependencies
  - [ ] `signals: ^5.0.0` (or latest)
  - [ ] `nexus_store: (path)`

### Core Extensions
- [ ] Create `NexusStoreSignalExtension<T, ID>`
  - [ ] `Signal<List<T>> toSignal()` - All items as signal
  - [ ] `Signal<T?> toSignal(ID id)` - Single item as signal
  - [ ] `Signal<StoreResult<List<T>>> toStatusSignal()` - With status

- [ ] Implement stream-to-signal adapter
  - [ ] Subscribe to store stream
  - [ ] Update signal on emission
  - [ ] Handle disposal

### Signal Types
- [ ] Create `NexusSignal<T>` wrapper (optional)
  - [ ] Extends Signal with store-specific methods
  - [ ] `refresh()` - Force store refresh
  - [ ] `save(T item)` - Delegate to store

- [ ] Create `NexusListSignal<T>` for collections
  - [ ] `add(T item)` - Save new item
  - [ ] `remove(ID id)` - Delete item
  - [ ] `update(ID id, T Function(T) transform)`

### Computed Signals
- [ ] Create `NexusComputed` utilities
  - [ ] Combine multiple store signals
  - [ ] Derived values

- [ ] Create common computed patterns
  - [ ] `filteredSignal(predicate)` - Filtered list
  - [ ] `sortedSignal(comparator)` - Sorted list
  - [ ] `countSignal` - Item count

### Lifecycle Management
- [ ] Implement disposal mechanism
  - [ ] Track stream subscriptions
  - [ ] Dispose signals properly
  - [ ] Prevent memory leaks

- [ ] Create `SignalScope` for scoped signals
  - [ ] Auto-dispose when scope ends
  - [ ] Widget lifecycle integration

### Flutter Integration
- [ ] Create `Watch` widget wrapper (if needed)
  - [ ] Rebuilds on signal change
  - [ ] Integrates with Flutter lifecycle

- [ ] Create `SignalBuilder` for NexusSignals
  - [ ] Loading/error handling

### Documentation & Examples
- [ ] Write README.md
  - [ ] Installation
  - [ ] Basic usage
  - [ ] Computed signals
  - [ ] Disposal patterns

- [ ] Create example app
  - [ ] CRUD with signals
  - [ ] Computed values
  - [ ] Multiple stores

### Unit Tests
- [ ] `test/signal_extension_test.dart`
  - [ ] toSignal() works
  - [ ] Updates on store changes
  - [ ] Disposal works

- [ ] `test/computed_test.dart`
  - [ ] Computed signals work
  - [ ] Dependencies tracked

## Files

**Package Structure:**
```
packages/nexus_store_signals_binding/
├── lib/
│   ├── nexus_store_signals_binding.dart  # Main export
│   └── src/
│       ├── extensions/
│       │   └── store_signal_extension.dart
│       ├── signals/
│       │   ├── nexus_signal.dart
│       │   └── nexus_list_signal.dart
│       ├── computed/
│       │   └── computed_utils.dart
│       └── lifecycle/
│           └── signal_scope.dart
├── test/
│   ├── signal_extension_test.dart
│   └── computed_test.dart
├── example/
│   └── lib/main.dart
├── pubspec.yaml
└── README.md
```

## Dependencies

- Core package (Task 1, complete)
- `signals: ^5.0.0` (or `signals_flutter` for Flutter)

## API Preview

```dart
// pubspec.yaml
dependencies:
  nexus_store: ^1.0.0
  nexus_store_signals_binding: ^1.0.0
  signals_flutter: ^5.0.0

// Basic usage - convert store to signal
final userStore = NexusStore<User, String>(backend: backend);
final usersSignal = userStore.toSignal();

// Signal updates automatically when store changes
print(usersSignal.value); // List<User>

// Watch in widget
Watch((context) {
  final users = usersSignal.value;
  return ListView(
    children: users.map((u) => UserTile(u)).toList(),
  );
});

// Single item signal
final currentUserSignal = userStore.toSignal(currentUserId);

Watch((context) {
  final user = currentUserSignal.value;
  return user != null ? UserCard(user) : NotFound();
});

// With status (loading/error)
final usersStatusSignal = userStore.toStatusSignal();

Watch((context) {
  final result = usersStatusSignal.value;
  return result.when(
    idle: () => Text('Ready'),
    pending: (prev) => Column(
      children: [
        if (prev != null) UserList(users: prev),
        LinearProgressIndicator(),
      ],
    ),
    success: (users) => UserList(users: users),
    error: (e, st, prev) => ErrorWidget(e),
  );
});

// Computed signals
final activeUsersSignal = computed(() {
  return usersSignal.value.where((u) => u.isActive).toList();
});

final userCountSignal = computed(() => usersSignal.value.length);

final dashboardSignal = computed(() {
  final users = usersSignal.value;
  final orders = ordersSignal.value;
  return DashboardState(
    userCount: users.length,
    orderCount: orders.length,
  );
});

// Helper methods
final filteredUsers = usersSignal.filtered((u) => u.age > 18);
final sortedUsers = usersSignal.sorted((a, b) => a.name.compareTo(b.name));

// NexusListSignal with CRUD helpers
final usersListSignal = userStore.toListSignal();

// These delegate to store
await usersListSignal.add(newUser);
await usersListSignal.remove(userId);
await usersListSignal.update(userId, (u) => u.copyWith(name: 'New Name'));

// Scoped signals (auto-dispose)
class UserScreen extends StatefulWidget {
  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> with SignalsMixin {
  late final usersSignal = createSignal(() => userStore.toSignal());

  @override
  void dispose() {
    disposeSignals(); // Auto-cleanup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      return UserList(users: usersSignal.value);
    });
  }
}

// Effect for side effects
effect(() {
  final users = usersSignal.value;
  analytics.trackUserCount(users.length);
});

// Batch updates
batch(() {
  usersSignal.value = [...usersSignal.value, newUser1];
  ordersSignal.value = [...ordersSignal.value, newOrder];
});
```

## Notes

- Signals provide fine-grained reactivity (only affected widgets rebuild)
- Simpler mental model than streams for some developers
- `signals` package is actively maintained and performant
- Consider supporting both `signals` and `flutter_signals` packages
- Disposal is critical - document clearly
- Computed signals automatically track dependencies
- Batch updates can improve performance for multiple changes
- Document that this is an alternative to built-in RxDart streams
