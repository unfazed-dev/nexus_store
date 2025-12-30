# TRACKER: Built-in State Layer

## Status: COMPLETE (117 tests)

## Overview

Implement a lightweight built-in state management layer for nexus_store, making it self-sufficient for most applications without requiring external state management packages.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-042, REQ-043, REQ-044, REQ-045, Task 34
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Store Registry (REQ-042)

#### Implementation
- [x] Create `NexusRegistry` singleton class
  - [x] `static void register<T>(NexusStore<T, dynamic> store, {String? scope})`
  - [x] `static NexusStore<T, ID> get<T, ID>({String? scope})`
  - [x] `static void dispose<T>({String? scope})`
  - [x] `static void reset()` - Clear all, for testing

- [x] Implement scoped registration
  - [x] Support multi-tenant scenarios
  - [x] Scope-based isolation
  - [x] Nested scopes (optional)

- [x] Implement lifecycle management
  - [x] Auto-dispose on unregister
  - [x] Dispose callbacks
  - [x] Leak detection (debug mode)

### Computed Stores (REQ-043)

#### Data Models
- [x] Create `ComputedStore<T>` class
  - [x] Generic over computed result type
  - [x] Accepts list of source stores
  - [x] Accepts compute function

#### Implementation
- [x] Implement stream combination
  - [x] Use `Rx.combineLatest` for multiple sources
  - [x] Map through compute function
  - [x] Apply `distinctUntilChanged`

- [x] Implement BehaviorSubject backing
  - [x] Immediate emission on subscribe
  - [x] Cache last computed value

- [x] Support various arities
  - [x] `ComputedStore.from2(store1, store2, (a, b) => ...)`
  - [x] `ComputedStore.from3(store1, store2, store3, (a, b, c) => ...)`
  - [x] `ComputedStore.fromList(stores, (values) => ...)`

### UI State Containers (REQ-044)

#### Implementation
- [x] Create `NexusState<T>` class
  - [x] BehaviorSubject backing
  - [x] `T get value` - Current value
  - [x] `set value(T newValue)` - Update and emit
  - [x] `Stream<T> get stream` - Observable stream

- [x] Implement update methods
  - [x] `void update(T Function(T current) transform)`
  - [x] `void reset()` - Revert to initial value
  - [x] `void emit(T value)` - Direct emit (alias for setter)

- [x] Implement persistence
  - [x] `StateStorage` abstract interface (user provides SharedPreferences/Hive impl)
  - [x] `PersistedState<T>` with async factory and auto-save
  - [x] `NexusState.persisted()` static factory method
  - [x] Auto-save on value change via stream subscription
  - [x] Restore from storage on creation
  - [x] Error handling (fallback to initial value)

### Selectors (REQ-045)

#### Implementation
- [x] Create `Selector<T, R>` class
  - [x] Source stream
  - [x] Select function
  - [x] Equality function (optional)

- [x] Add `select<R>()` to NexusStore
  - [x] `Stream<R> select<R>(R Function(List<T>) selector, {bool Function(R, R)? equals})`
  - [x] Apply distinctUntilChanged with custom equality

- [x] Implement memoization
  - [x] Cache last input and output
  - [x] Skip computation if input unchanged

- [x] Create common selector utilities
  - [x] `selectById(ID id)` - Single item selector
  - [x] `selectWhere(bool Function(T) predicate)` - Filtered list
  - [x] `selectCount()` - Item count
  - [x] `selectFirst()` / `selectLast()`

### Unit Tests
- [x] `test/src/state/nexus_registry_test.dart` (29 tests)
  - [x] Registration and retrieval
  - [x] Scoped registration
  - [x] Disposal works
  - [x] Reset clears all

- [x] `test/src/state/computed_store_test.dart` (17 tests)
  - [x] Combines multiple stores
  - [x] Recomputes on source change
  - [x] distinctUntilChanged behavior
  - [x] Immediate emission

- [x] `test/src/state/nexus_state_test.dart` (27 tests)
  - [x] Value updates emit
  - [x] Update transform works
  - [x] Reset reverts to initial
  - [x] Stream provides current value

- [x] `test/src/state/selector_test.dart` (17 tests)
  - [x] Selects subset correctly
  - [x] Custom equality works
  - [x] Memoization prevents recomputation

- [x] `test/src/state/persisted_state_test.dart` (27 tests)
  - [x] Create with initial/restored value
  - [x] Auto-save on value change, emit(), update(), reset()
  - [x] Error handling for storage failures
  - [x] Stream behavior and multiple subscribers
  - [x] Complex types (List, Map, JSON)
  - [x] NexusState.persisted() factory

## Files

**Source Files:**
```
packages/nexus_store/lib/src/state/
├── nexus_registry.dart      # NexusRegistry singleton
├── computed_store.dart      # ComputedStore<T>
├── nexus_state.dart         # NexusState<T> + persisted() factory
├── persisted_state.dart     # PersistedState<T> with auto-save
├── selector.dart            # Selector<T, R>
├── state_storage.dart       # StateStorage abstract interface
└── state.dart               # Barrel export
```

**Test Files:**
```
packages/nexus_store/test/src/state/
├── nexus_registry_test.dart
├── computed_store_test.dart
├── nexus_state_test.dart
├── persisted_state_test.dart
└── selector_test.dart
```

**Test Fixtures:**
```
packages/nexus_store/test/fixtures/
└── fake_state_storage.dart   # FakeStateStorage + FailingStateStorage
```

## Dependencies

- Core package (Task 1, complete)
- RxDart (already in core)

## API Preview

```dart
// Store Registry
void main() {
  // Register stores
  NexusRegistry.register<User>(
    NexusStore<User, String>(backend: userBackend),
  );
  NexusRegistry.register<Order>(
    NexusStore<Order, String>(backend: orderBackend),
  );

  runApp(MyApp());
}

// Access anywhere
class UserService {
  final userStore = NexusRegistry.get<User, String>();

  Future<void> updateUser(User user) => userStore.save(user);
}

// Scoped registration (multi-tenant)
NexusRegistry.register<User>(
  tenantAStore,
  scope: 'tenant-a',
);
NexusRegistry.register<User>(
  tenantBStore,
  scope: 'tenant-b',
);

final storeA = NexusRegistry.get<User, String>(scope: 'tenant-a');

// Computed Store
final dashboardStore = ComputedStore.from2(
  NexusRegistry.get<User, String>(),
  NexusRegistry.get<Order, String>(),
  (users, orders) => DashboardState(
    userCount: users.length,
    orderCount: orders.length,
    revenue: orders.fold(0, (sum, o) => sum + o.total),
  ),
);

// Watch computed state
dashboardStore.stream.listen((dashboard) {
  print('Users: ${dashboard.userCount}, Orders: ${dashboard.orderCount}');
});

// UI State Container
final uiState = NexusState<AppUIState>(
  AppUIState(selectedTab: 0, searchQuery: '', isDarkMode: false),
);

// Update UI state
uiState.update((s) => s.copyWith(selectedTab: 1));
uiState.update((s) => s.copyWith(searchQuery: 'flutter'));

// Watch UI state
StreamBuilder<AppUIState>(
  stream: uiState.stream,
  builder: (context, snapshot) {
    final state = snapshot.data ?? uiState.value;
    return TabBar(currentIndex: state.selectedTab);
  },
);

// Reset to initial
uiState.reset();

// Selectors
final userStore = NexusRegistry.get<User, String>();

// Select active users only
final activeUsers = userStore.select(
  (users) => users.where((u) => u.isActive).toList(),
  equals: listEquals,
);

// Select single user
final currentUser = userStore.select(
  (users) => users.firstWhereOrNull((u) => u.id == currentUserId),
);

// Select count
final userCount = userStore.select((users) => users.length);

// Use in widget
StreamBuilder<List<User>>(
  stream: activeUsers,
  builder: (context, snapshot) {
    // Only rebuilds when active users change
    return UserList(users: snapshot.data ?? []);
  },
);
```

## Notes

- NexusRegistry is intentionally simple (not a full DI container)
- For complex DI needs, use with GetIt or similar
- ComputedStore uses RxDart's combineLatest internally
- NexusState is similar to BehaviorSubject but with nicer API
- Selectors are key for performance (avoid unnecessary rebuilds)
- `NexusState.persisted()` enables settings that survive restart via abstract storage
- All state primitives use BehaviorSubject for immediate value on subscribe
- PersistedState uses async factory pattern since Dart constructors can't be async
