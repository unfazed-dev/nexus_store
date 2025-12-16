# TRACKER: Built-in State Layer

## Status: PENDING

## Overview

Implement a lightweight built-in state management layer for nexus_store, making it self-sufficient for most applications without requiring external state management packages.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-042, REQ-043, REQ-044, REQ-045, Task 34
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Store Registry (REQ-042)

#### Implementation
- [ ] Create `NexusRegistry` singleton class
  - [ ] `static void register<T>(NexusStore<T, dynamic> store, {String? scope})`
  - [ ] `static NexusStore<T, ID> get<T, ID>({String? scope})`
  - [ ] `static void dispose<T>({String? scope})`
  - [ ] `static void reset()` - Clear all, for testing

- [ ] Implement scoped registration
  - [ ] Support multi-tenant scenarios
  - [ ] Scope-based isolation
  - [ ] Nested scopes (optional)

- [ ] Implement lifecycle management
  - [ ] Auto-dispose on unregister
  - [ ] Dispose callbacks
  - [ ] Leak detection (debug mode)

### Computed Stores (REQ-043)

#### Data Models
- [ ] Create `ComputedStore<T>` class
  - [ ] Generic over computed result type
  - [ ] Accepts list of source stores
  - [ ] Accepts compute function

#### Implementation
- [ ] Implement stream combination
  - [ ] Use `Rx.combineLatest` for multiple sources
  - [ ] Map through compute function
  - [ ] Apply `distinctUntilChanged`

- [ ] Implement BehaviorSubject backing
  - [ ] Immediate emission on subscribe
  - [ ] Cache last computed value

- [ ] Support various arities
  - [ ] `ComputedStore.from2(store1, store2, (a, b) => ...)`
  - [ ] `ComputedStore.from3(store1, store2, store3, (a, b, c) => ...)`
  - [ ] `ComputedStore.fromList(stores, (values) => ...)`

### UI State Containers (REQ-044)

#### Implementation
- [ ] Create `NexusState<T>` class
  - [ ] BehaviorSubject backing
  - [ ] `T get value` - Current value
  - [ ] `set value(T newValue)` - Update and emit
  - [ ] `Stream<T> get stream` - Observable stream

- [ ] Implement update methods
  - [ ] `void update(T Function(T current) transform)`
  - [ ] `void reset()` - Revert to initial value
  - [ ] `void emit(T value)` - Direct emit (alias for setter)

- [ ] Implement persistence (optional)
  - [ ] `NexusState.persisted(key, initial, serializer)`
  - [ ] Auto-save to SharedPreferences/Hive
  - [ ] Restore on creation

### Selectors (REQ-045)

#### Implementation
- [ ] Create `Selector<T, R>` class
  - [ ] Source stream
  - [ ] Select function
  - [ ] Equality function (optional)

- [ ] Add `select<R>()` to NexusStore
  - [ ] `Stream<R> select<R>(R Function(List<T>) selector, {bool Function(R, R)? equals})`
  - [ ] Apply distinctUntilChanged with custom equality

- [ ] Implement memoization
  - [ ] Cache last input and output
  - [ ] Skip computation if input unchanged

- [ ] Create common selector utilities
  - [ ] `selectById(ID id)` - Single item selector
  - [ ] `selectWhere(bool Function(T) predicate)` - Filtered list
  - [ ] `selectCount()` - Item count
  - [ ] `selectFirst()` / `selectLast()`

### Unit Tests
- [ ] `test/src/state/nexus_registry_test.dart`
  - [ ] Registration and retrieval
  - [ ] Scoped registration
  - [ ] Disposal works
  - [ ] Reset clears all

- [ ] `test/src/state/computed_store_test.dart`
  - [ ] Combines multiple stores
  - [ ] Recomputes on source change
  - [ ] distinctUntilChanged behavior
  - [ ] Immediate emission

- [ ] `test/src/state/nexus_state_test.dart`
  - [ ] Value updates emit
  - [ ] Update transform works
  - [ ] Reset reverts to initial
  - [ ] Stream provides current value

- [ ] `test/src/state/selector_test.dart`
  - [ ] Selects subset correctly
  - [ ] Custom equality works
  - [ ] Memoization prevents recomputation

## Files

**Source Files:**
```
packages/nexus_store/lib/src/state/
├── nexus_registry.dart      # NexusRegistry singleton
├── computed_store.dart      # ComputedStore<T>
├── nexus_state.dart         # NexusState<T>
├── selector.dart            # Selector<T, R>
└── state.dart               # Barrel export
```

**Test Files:**
```
packages/nexus_store/test/src/state/
├── nexus_registry_test.dart
├── computed_store_test.dart
├── nexus_state_test.dart
└── selector_test.dart
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
- Consider adding `NexusState.persisted` for settings that survive restart
- All state primitives use BehaviorSubject for immediate value on subscribe
