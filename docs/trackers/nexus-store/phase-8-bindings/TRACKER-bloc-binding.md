# TRACKER: Bloc Binding Package

## Status: COMPLETE

## Overview

Create `nexus_store_bloc_binding` package that provides Bloc/Cubit wrappers for NexusStore, enabling familiar Bloc patterns with NexusStore data.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-047, Task 36
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Completion Summary

**Tests**: 183 tests
**Files**: 15 source files, 9 test files

## Tasks

### Package Setup
- [x] Create package skeleton
  - [x] `pubspec.yaml` with dependencies
  - [x] `analysis_options.yaml`
  - [x] Basic library structure

- [x] Add dependencies
  - [x] `bloc: ^8.1.4`
  - [x] `flutter_bloc: ^8.1.6`
  - [x] `nexus_store: (path)`

### State Models
- [x] Create `NexusStoreState<T>` sealed class
  - [x] `NexusStoreInitial<T>` - Before first load
  - [x] `NexusStoreLoading<T>` - Loading (with optional previous data)
  - [x] `NexusStoreLoaded<T>` - Success with data
  - [x] `NexusStoreError<T>` - Error (with optional previous data)

- [x] Create `NexusItemState<T>` for single items
  - [x] `NexusItemInitial<T>` - Before first load
  - [x] `NexusItemLoading<T>` - Loading (with optional previous data)
  - [x] `NexusItemLoaded<T>` - Success with data
  - [x] `NexusItemNotFound<T>` - Item not found
  - [x] `NexusItemError<T>` - Error (with optional previous data)

### Cubit Implementation
- [x] Create `NexusStoreCubit<T, ID>` base class
  - [x] Accepts `NexusStore<T, ID>` in constructor
  - [x] Auto-subscribes to `watchAll()`
  - [x] Emits state changes

- [x] Implement CRUD method delegates
  - [x] `Future<void> load()` - Trigger refresh
  - [x] `Future<void> save(T item)` - Save and emit
  - [x] `Future<void> delete(ID id)` - Delete and emit

- [x] Implement subscription management
  - [x] Subscribe on creation or first load
  - [x] Cancel subscription on close
  - [x] Handle stream errors

### Bloc Implementation (Event-Driven)
- [x] Create `NexusStoreEvent` sealed class
  - [x] `LoadAll` - Load all items
  - [x] `Save(T item)` - Save item
  - [x] `SaveAll(List<T> items)` - Save multiple items
  - [x] `Delete(ID id)` - Delete item
  - [x] `DeleteAll(List<ID> ids)` - Delete multiple items
  - [x] `Refresh` - Force refresh

- [x] Create `NexusStoreBloc<T, ID>` base class
  - [x] Event handlers for each event
  - [x] Maps store stream to state

- [x] Implement event handlers
  - [x] `on<LoadAll>` - Subscribe to watchAll()
  - [x] `on<Save>` - Call store.save()
  - [x] `on<Delete>` - Call store.delete()

### Single Item Cubit/Bloc
- [x] Create `NexusItemCubit<T, ID>` for single items
  - [x] Watches single item by ID
  - [x] Save/delete operations

- [x] Create `NexusItemBloc<T, ID>` (event-driven)
  - [x] Same functionality, event-driven

### Utilities
- [x] Create `NexusStoreBlocObserver` (optional)
  - [x] Configurable logging for debugging
  - [x] Error tracking

### Documentation & Examples
- [x] Write README.md
  - [x] Installation
  - [x] Cubit vs Bloc usage
  - [x] Custom state handling
  - [x] Testing patterns

### Unit Tests
- [x] `test/state/nexus_store_state_test.dart` (58 tests)
- [x] `test/state/nexus_item_state_test.dart` (75 tests)
- [x] `test/cubit/nexus_store_cubit_test.dart` (14 tests)
- [x] `test/cubit/nexus_item_cubit_test.dart` (26 tests)
- [x] `test/bloc/nexus_store_event_test.dart` (24 tests)
- [x] `test/bloc/nexus_store_bloc_test.dart` (18 tests)
- [x] `test/bloc/nexus_item_bloc_test.dart` (19 tests)
- [x] `test/utils/bloc_observer_test.dart` (12 tests)

## Files

**Package Structure:**
```
packages/nexus_store_bloc_binding/
├── lib/
│   ├── nexus_store_bloc_binding.dart   # Main export
│   └── src/
│       ├── state/
│       │   ├── nexus_store_state.dart  # State classes
│       │   └── nexus_item_state.dart
│       ├── cubit/
│       │   ├── nexus_store_cubit.dart  # Cubit base
│       │   └── nexus_item_cubit.dart
│       ├── bloc/
│       │   ├── nexus_store_bloc.dart   # Bloc base
│       │   ├── nexus_store_event.dart  # Events
│       │   ├── nexus_item_bloc.dart
│       │   └── nexus_item_event.dart
│       └── utils/
│           └── bloc_observer.dart
├── test/
│   ├── fixtures/
│   │   ├── test_entities.dart
│   │   └── mock_store.dart
│   ├── state/
│   │   ├── nexus_store_state_test.dart
│   │   └── nexus_item_state_test.dart
│   ├── cubit/
│   │   ├── nexus_store_cubit_test.dart
│   │   └── nexus_item_cubit_test.dart
│   ├── bloc/
│   │   ├── nexus_store_event_test.dart
│   │   ├── nexus_store_bloc_test.dart
│   │   └── nexus_item_bloc_test.dart
│   └── utils/
│       └── bloc_observer_test.dart
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

## Dependencies

- Core package (Task 1, complete)
- `bloc: ^8.1.4`
- `flutter_bloc: ^8.1.6`
- `bloc_test: ^9.1.7` (dev)
- `mocktail: ^1.0.4` (dev)

## API Summary

```dart
// State classes with pattern matching
state.when(
  initial: () => Text('Press load'),
  loading: (prev) => CircularProgressIndicator(),
  loaded: (users) => UserList(users: users),
  error: (error, _, prev) => ErrorWidget(error),
);

// Cubit (simpler)
class UsersCubit extends NexusStoreCubit<User, String> {
  UsersCubit(NexusStore<User, String> store) : super(store);
}
cubit.load();
cubit.save(user);
cubit.delete(userId);

// Bloc (event-driven)
class UsersBloc extends NexusStoreBloc<User, String> {
  UsersBloc(NexusStore<User, String> store) : super(store);
}
bloc.add(const LoadAll());
bloc.add(Save(user));
bloc.add(Delete(userId));

// Single item
class UserCubit extends NexusItemCubit<User, String> {
  UserCubit(NexusStore<User, String> store, String id) : super(store, id);
}

// Observer
Bloc.observer = NexusStoreBlocObserver(
  logTransitions: true,
  logEvents: true,
  onLog: (message) => debugPrint(message),
);
```

## Notes

- Cubit is simpler, recommended for most use cases
- Bloc is better for complex event handling requirements
- State preserves previous data during loading/error (optimistic UI)
- Test with `bloc_test` package for easy verification
- Bloc layer is optional - can use store directly
