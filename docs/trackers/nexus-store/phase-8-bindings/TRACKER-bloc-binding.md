# TRACKER: Bloc Binding Package

## Status: PENDING

## Overview

Create `nexus_store_bloc_binding` package that provides Bloc/Cubit wrappers for NexusStore, enabling familiar Bloc patterns with NexusStore data.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-047, Task 36
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Package Setup
- [ ] Create package skeleton
  - [ ] `pubspec.yaml` with dependencies
  - [ ] `analysis_options.yaml`
  - [ ] Basic library structure

- [ ] Add dependencies
  - [ ] `bloc: ^8.0.0`
  - [ ] `flutter_bloc: ^8.0.0`
  - [ ] `nexus_store: (path)`

### State Models
- [ ] Create `NexusStoreState<T>` sealed class
  - [ ] `NexusStoreInitial<T>` - Before first load
  - [ ] `NexusStoreLoading<T>` - Loading (with optional previous data)
  - [ ] `NexusStoreLoaded<T>` - Success with data
  - [ ] `NexusStoreError<T>` - Error (with optional previous data)

- [ ] Create `NexusItemState<T>` for single items
  - [ ] Similar states for single item operations

### Cubit Implementation
- [ ] Create `NexusStoreCubit<T, ID>` base class
  - [ ] Accepts `NexusStore<T, ID>` in constructor
  - [ ] Auto-subscribes to `watchAll()`
  - [ ] Emits state changes

- [ ] Implement CRUD method delegates
  - [ ] `Future<void> load()` - Trigger refresh
  - [ ] `Future<void> save(T item)` - Save and emit
  - [ ] `Future<void> delete(ID id)` - Delete and emit

- [ ] Implement subscription management
  - [ ] Subscribe on creation or first load
  - [ ] Cancel subscription on close
  - [ ] Handle stream errors

### Bloc Implementation (Event-Driven)
- [ ] Create `NexusStoreEvent` sealed class
  - [ ] `LoadAll` - Load all items
  - [ ] `LoadOne(ID id)` - Load single item
  - [ ] `Save(T item)` - Save item
  - [ ] `Delete(ID id)` - Delete item
  - [ ] `Refresh` - Force refresh

- [ ] Create `NexusStoreBloc<T, ID>` base class
  - [ ] Event handlers for each event
  - [ ] Maps store stream to state

- [ ] Implement event handlers
  - [ ] `on<LoadAll>` - Subscribe to watchAll()
  - [ ] `on<Save>` - Call store.save()
  - [ ] `on<Delete>` - Call store.delete()

### Single Item Cubit/Bloc
- [ ] Create `NexusItemCubit<T, ID>` for single items
  - [ ] Watches single item by ID
  - [ ] Save/delete operations

- [ ] Create `NexusItemBloc<T, ID>` (event-driven)
  - [ ] Same functionality, event-driven

### Utilities
- [ ] Create `NexusStoreBlocObserver` (optional)
  - [ ] Logging for debugging
  - [ ] Error tracking

- [ ] Create mixin `NexusStoreBlocMixin`
  - [ ] For adding to existing Blocs

### Documentation & Examples
- [ ] Write README.md
  - [ ] Installation
  - [ ] Cubit vs Bloc usage
  - [ ] Custom state handling
  - [ ] Testing patterns

- [ ] Create example app
  - [ ] CRUD operations
  - [ ] Error handling
  - [ ] Optimistic updates

### Unit Tests
- [ ] `test/cubit_test.dart`
  - [ ] State transitions
  - [ ] CRUD operations
  - [ ] Error handling
  - [ ] Disposal

- [ ] `test/bloc_test.dart`
  - [ ] Event handling
  - [ ] State emissions

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
│       │   └── nexus_item_bloc.dart
│       └── utils/
│           └── bloc_observer.dart
├── test/
│   ├── cubit_test.dart
│   └── bloc_test.dart
├── example/
│   └── lib/main.dart
├── pubspec.yaml
└── README.md
```

## Dependencies

- Core package (Task 1, complete)
- `bloc: ^8.0.0`
- `flutter_bloc: ^8.0.0`

## API Preview

```dart
// pubspec.yaml
dependencies:
  nexus_store: ^1.0.0
  nexus_store_bloc_binding: ^1.0.0
  flutter_bloc: ^8.0.0

// Using Cubit (simpler)
class UsersCubit extends NexusStoreCubit<User, String> {
  UsersCubit(NexusStore<User, String> store) : super(store);

  // Optionally override for custom behavior
  @override
  Future<void> onSave(User user) async {
    // Custom logic before save
    await super.onSave(user);
    // Custom logic after save
  }
}

// Usage
final cubit = UsersCubit(userStore);

// In widget
BlocBuilder<UsersCubit, NexusStoreState<User>>(
  builder: (context, state) {
    return state.when(
      initial: () => Text('Press load'),
      loading: (prev) => Stack(
        children: [
          if (prev != null) UserList(users: prev),
          CircularProgressIndicator(),
        ],
      ),
      loaded: (users) => UserList(users: users),
      error: (error, prev) => ErrorWidget(error, retry: cubit.load),
    );
  },
);

// CRUD operations
await cubit.save(newUser);
await cubit.delete(userId);
await cubit.load(); // Force refresh

// Using Bloc (event-driven)
class UsersBloc extends NexusStoreBloc<User, String> {
  UsersBloc(NexusStore<User, String> store) : super(store) {
    // Custom event handlers
    on<CustomUserEvent>(_onCustomEvent);
  }

  Future<void> _onCustomEvent(
    CustomUserEvent event,
    Emitter<NexusStoreState<User>> emit,
  ) async {
    // Custom handling
  }
}

// Dispatch events
bloc.add(LoadAll());
bloc.add(Save(newUser));
bloc.add(Delete(userId));

// Single item Cubit
class UserDetailCubit extends NexusItemCubit<User, String> {
  UserDetailCubit(NexusStore<User, String> store, String userId)
    : super(store, userId);
}

// Usage
BlocBuilder<UserDetailCubit, NexusItemState<User>>(
  builder: (context, state) {
    return state.when(
      initial: () => Loading(),
      loading: (prev) => Loading(showPrevious: prev),
      loaded: (user) => user != null
        ? UserDetail(user)
        : NotFound(),
      error: (e, prev) => Error(e),
    );
  },
);

// Provider setup
MultiBlocProvider(
  providers: [
    BlocProvider(
      create: (context) => UsersCubit(
        context.read<NexusStore<User, String>>(),
      )..load(),
    ),
  ],
  child: MyApp(),
);

// State convenience methods
state.maybeWhen(
  loaded: (users) => print('Got ${users.length} users'),
  orElse: () => print('Not loaded yet'),
);

state.dataOrNull; // List<User>? - Returns data from any state
state.isLoading; // bool
state.hasError; // bool
state.error; // Object?
```

## Notes

- Cubit is simpler, recommended for most use cases
- Bloc is better for complex event handling requirements
- NexusStoreCubit auto-subscribes; call `load()` to start or let stream auto-load
- State preserves previous data during loading/error (optimistic UI)
- Consider adding `NexusMultiStoreCubit` for combining multiple stores
- Test with `bloc_test` package for easy verification
- Document that Bloc layer is optional - can use store directly
