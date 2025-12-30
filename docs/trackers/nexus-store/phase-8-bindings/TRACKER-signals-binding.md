# TRACKER: Signals Binding Package

## Status: COMPLETE

## Overview

Create `nexus_store_signals_binding` package that adapts NexusStore streams to Signals for fine-grained reactivity.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-048, Task 37
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Implementation Summary

**Package Created**: `packages/nexus_store_signals_binding/`
**Tests**: 87 tests passing
**Methodology**: TDD (Test-Driven Development)

## Tasks

### Package Setup
- [x] Create package skeleton
  - [x] `pubspec.yaml` with dependencies
  - [x] `analysis_options.yaml`
  - [x] Basic library structure

- [x] Add dependencies
  - [x] `signals: ^6.3.0`
  - [x] `signals_flutter: ^6.3.0`
  - [x] `nexus_store: (path)`
  - [x] `collection: ^1.19.0`

### State Classes
- [x] Create `NexusSignalState<T>` sealed class (33 tests)
  - [x] `NexusSignalInitial<T>` - Before first load
  - [x] `NexusSignalLoading<T>` - Loading with optional previousData
  - [x] `NexusSignalData<T>` - Success with data
  - [x] `NexusSignalError<T>` - Error with optional previousData
  - [x] Pattern matching: `when()`, `maybeWhen()`
  - [x] Properties: `dataOrNull`, `isLoading`, `hasData`, `hasError`

- [x] Create `NexusItemSignalState<T>` sealed class
  - [x] `NexusItemSignalInitial<T>`
  - [x] `NexusItemSignalLoading<T>`
  - [x] `NexusItemSignalData<T>`
  - [x] `NexusItemSignalNotFound<T>`
  - [x] `NexusItemSignalError<T>`

### Core Extensions
- [x] Create `NexusStoreSignalExtension<T, ID>` (16 tests)
  - [x] `Signal<List<T>> toSignal({Query<T>? query})` - All items as signal
  - [x] `Signal<T?> toItemSignal(ID id)` - Single item as signal
  - [x] `Signal<NexusSignalState<T>> toStateSignal({Query<T>? query})` - With status
  - [x] `Signal<NexusItemSignalState<T>> toItemStateSignal(ID id)` - Single item with status

- [x] Implement stream-to-signal adapter
  - [x] Subscribe to store stream
  - [x] Update signal on emission
  - [x] Handle disposal

### Signal Types
- [x] Create `NexusSignal<T, ID>` wrapper (5 tests)
  - [x] Factory `fromStore(NexusStore<T, ID> store, {Query<T>? query})`
  - [x] `value` - Current list value
  - [x] `peek()` - Read without subscribing
  - [x] `refresh()` - Trigger store sync
  - [x] `dispose()` - Clean up resources
  - [x] `subscribe(callback)` - Listen to changes

- [x] Create `NexusListSignal<T, ID>` for collections (9 tests)
  - [x] `add(T item)` - Delegate to store.save()
  - [x] `remove(ID id)` - Delegate to store.delete()
  - [x] `update(ID id, T Function(T) transform)` - Get, transform, save
  - [x] `length`, `isEmpty`, `isNotEmpty`, `[index]` accessors

### Computed Signals
- [x] Create computed utilities via extension methods (17 tests)
  - [x] `filtered(predicate)` - Filtered list
  - [x] `sorted(comparator)` - Sorted list
  - [x] `count()` - Item count
  - [x] `firstWhereOrNull(predicate)` - First match
  - [x] `mapped(transform)` - Map to new type
  - [x] `any(predicate)` - Any match
  - [x] `every(predicate)` - All match

### Lifecycle Management
- [x] Create `SignalScope` (7 tests)
  - [x] `createSignal<T>(initialValue)` - Track signal
  - [x] `createComputed<T>(compute)` - Track computed
  - [x] `createFromStore(store, {query})` - Track store signal
  - [x] `createItemFromStore(store, id)` - Track item signal
  - [x] `disposeAll()` - Dispose all tracked signals
  - [x] `isDisposed`, `signalCount` properties

- [x] Create `NexusSignalsMixin<T>`
  - [x] `createSignal<V>(initialValue)`
  - [x] `createComputed<V>(compute)`
  - [x] `createFromStore<E, ID>(store, {query})`
  - [x] `createItemFromStore<E, ID>(store, id)`
  - [x] `disposeSignals()`

### Documentation & Examples
- [x] Write README.md
  - [x] Installation
  - [x] Basic usage
  - [x] State signals
  - [x] NexusSignal wrapper
  - [x] NexusListSignal CRUD
  - [x] Computed signals
  - [x] Lifecycle management
  - [x] API reference

### Unit Tests
- [x] `test/state_test.dart` - 33 tests
- [x] `test/signal_extension_test.dart` - 16 tests
- [x] `test/nexus_signal_test.dart` - 5 tests
- [x] `test/nexus_list_signal_test.dart` - 9 tests
- [x] `test/computed_test.dart` - 17 tests
- [x] `test/lifecycle_test.dart` - 7 tests

## Files

**Package Structure (Implemented):**
```
packages/nexus_store_signals_binding/
├── lib/
│   ├── nexus_store_signals_binding.dart  # Main export
│   └── src/
│       ├── state/
│       │   ├── nexus_signal_state.dart         # Sealed state classes
│       │   └── nexus_item_signal_state.dart    # Single item states
│       ├── extensions/
│       │   └── store_signal_extension.dart     # NexusStore.toSignal() etc.
│       ├── signals/
│       │   ├── nexus_signal.dart               # NexusSignal<T, ID> wrapper
│       │   └── nexus_list_signal.dart          # NexusListSignal<T, ID>
│       ├── computed/
│       │   └── computed_utils.dart             # Extension methods
│       └── lifecycle/
│           └── signal_scope.dart               # SignalScope + NexusSignalsMixin
├── test/
│   ├── fixtures/
│   │   ├── mock_store.dart
│   │   └── test_entities.dart
│   ├── state_test.dart
│   ├── signal_extension_test.dart
│   ├── nexus_signal_test.dart
│   ├── nexus_list_signal_test.dart
│   ├── computed_test.dart
│   └── lifecycle_test.dart
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

## Dependencies

- Core package (complete)
- `signals: ^6.3.0`
- `signals_flutter: ^6.3.0`
- `collection: ^1.19.0`

## API Summary

```dart
// pubspec.yaml
dependencies:
  nexus_store: ^1.0.0
  nexus_store_signals_binding: ^1.0.0
  signals_flutter: ^6.3.0

// Basic usage - convert store to signal
final userStore = NexusStore<User, String>(backend: backend);
final usersSignal = userStore.toSignal();

// Watch in widget
Watch((context) {
  return ListView(
    children: usersSignal.value.map((u) => UserTile(u)).toList(),
  );
});

// Single item signal
final currentUserSignal = userStore.toItemSignal(currentUserId);

// With state (loading/error)
final usersState = userStore.toStateSignal();
Watch((context) {
  return usersState.value.when(
    initial: () => Text('Ready'),
    loading: (prev) => CircularProgressIndicator(),
    data: (users) => UserList(users: users),
    error: (e, st, prev) => Text('Error: $e'),
  );
});

// NexusSignal wrapper with refresh
final usersNexusSignal = NexusSignal.fromStore(userStore);
await usersNexusSignal.refresh();
usersNexusSignal.dispose();

// NexusListSignal with CRUD
final usersListSignal = NexusListSignal.fromStore(userStore);
await usersListSignal.add(newUser);
await usersListSignal.remove(userId);
await usersListSignal.update(userId, (u) => u.copyWith(name: 'New'));

// Computed signals
final activeUsers = usersSignal.filtered((u) => u.isActive);
final sortedUsers = usersSignal.sorted((a, b) => a.name.compareTo(b.name));
final userCount = usersSignal.count();

// Scoped signals with auto-dispose
class _MyState extends State<MyWidget> with NexusSignalsMixin {
  late final usersSignal = createFromStore(userStore);

  @override
  void dispose() {
    disposeSignals();
    super.dispose();
  }
}
```

## Notes

- Signals provide fine-grained reactivity (only affected widgets rebuild)
- 87 tests ensure comprehensive coverage
- Sealed state classes with pattern matching for type-safe handling
- Computed signals via extension methods (filtered, sorted, count, etc.)
- SignalScope and NexusSignalsMixin for lifecycle management
- Follows TDD methodology throughout implementation
