# TRACKER: Bloc Binding Batteries Included

## Status: COMPLETED

## Overview

Add batteries-included features to `nexus_store_bloc_binding` including bloc store bundles, multi-store manager, enhanced state helpers, and event builder utilities.

## Spec Reference

- [SPEC-batteries-included-enhancements.md](../../specs/SPEC-batteries-included-enhancements.md)
- Implements: REQ-007, REQ-008

## Skills to Use

- `/tdd-flutter` - Test-Driven Development for all implementations
- `/commit-helper` - Semantic commit messages for all changes

## Related Trackers

- [Main Tracker](TRACKER-batteries-main.md)

## Tasks

### Phase 1: Store Configuration
- [x] Create `BlocStoreConfig<T, ID>` class
- [x] Create `LoadingStateConfig` class
- [x] Support useBloc flag (Cubit vs Bloc)
- [x] Support autoLoad option
- [x] Support loading state customization

### Phase 2: Store Bundle
- [x] Create `BlocStoreBundle<T, ID>` class
- [x] Implement `BlocStoreBundle.create()` factory
- [x] Generate `listBloc` (Cubit or Bloc based on config)
- [x] Implement `itemCubit(id)` factory method
- [x] Implement `close()` method

### Phase 3: Store Manager
- [x] Create `BlocManager` class
- [x] Implement manager constructor with configs
- [x] Implement `getBundle(name)` method
- [x] Implement `getListCubit(name)` method
- [x] Implement `getListBloc(name)` method
- [x] Implement `refreshAll()` method
- [x] Implement `isAnyLoading` getter
- [x] Implement `isAnyLoadingStream` getter
- [x] Implement `firstError` getter
- [x] Implement `errorStream` getter
- [x] Implement `dispose()` method

### Phase 4: Enhanced State Helpers
- [x] Create `NexusStoreStateX` extension
- [x] Implement `mapData<R>(transform)` method
- [x] Implement `where(predicate)` method
- [x] Implement `firstOrNull` getter
- [x] Implement `findById<ID>(id, getId)` method
- [x] Implement `combineWith<R>(other)` method
- [x] Create `CombinedState<T, R>` class
- [x] Implement `isEmpty`, `isNotEmpty`, `length` getters

### Phase 5: Multi-Provider Widget
- [x] Skipped - Package is pure Dart (no Flutter dependency)

### Phase 6: Event Builders
- [x] Create `NexusStoreCubitX` extension
- [x] Create `NexusStoreBlocX` extension
- [x] Implement `loadDebounced()` method
- [x] Implement `loadWithRetry()` method
- [x] Implement `addDebounced()` method
- [x] Create `EventSequences` class with pre-built patterns

### Phase 7: Integration
- [x] Update barrel export
- [x] Add unit tests for store bundle (18 tests)
- [x] Add unit tests for manager (14 tests)
- [x] Add unit tests for state helpers (25 tests)
- [x] Add unit tests for event builders (8 tests)

## Files

### New Files
| File | Description |
|------|-------------|
| `lib/src/bundle/bloc_store_bundle.dart` | BlocStoreConfig, LoadingStateConfig, BlocStoreBundle |
| `lib/src/manager/bloc_manager.dart` | Multi-store coordination |
| `lib/src/extensions/enhanced_state.dart` | State helper extensions |
| `lib/src/extensions/event_builders.dart` | Event helper utilities |

### Modified Files
| File | Changes |
|------|---------|
| `lib/nexus_store_bloc_binding.dart` | Export new classes |

### Test Files
| File | Description |
|------|-------------|
| `test/unit/bloc_store_bundle_test.dart` | Bundle tests (18 tests) |
| `test/unit/bloc_manager_test.dart` | Manager tests (14 tests) |
| `test/unit/enhanced_state_test.dart` | State helper tests (25 tests) |
| `test/unit/event_builders_test.dart` | Event builder tests (8 tests) |

## Dependencies

- bloc: ^8.1.4 (existing)

## API Design

```dart
// Store configuration
final userConfig = BlocStoreConfig<User, String>(
  name: 'users',
  store: userStore,
  useBloc: true, // Use Bloc instead of Cubit
  loadingStateConfig: LoadingStateConfig(
    showPreviousDataWhileLoading: true,
    debounceMs: 300,
    retryCount: 3,
  ),
);

// Store bundle
final userBlocs = BlocStoreBundle.create(config: userConfig);
final usersBloc = userBlocs.listBloc;
final userCubit = userBlocs.itemCubit('user-123');

// Multi-store manager
final manager = BlocManager([
  BlocStoreConfig<User, String>(name: 'users', store: userStore),
  BlocStoreConfig<Post, String>(name: 'posts', store: postStore),
]);

// Coordinated operations
await manager.refreshAll();
final anyLoading = manager.isAnyLoading;

// Enhanced state helpers
final state = NexusStoreLoaded([user1, user2]);
final filtered = state.where((u) => u.isActive);
final mapped = state.mapData((users) => users.map((u) => u.name).toList());
final combined = usersState.combineWith(postsState);

// Event helpers
cubit.loadDebounced(delay: Duration(milliseconds: 500));
await cubit.loadWithRetry(maxRetries: 3);
bloc.addDebounced(LoadAll(), delay: Duration(milliseconds: 300));

// Event sequences
final sequences = EventSequences<User, String>();
for (final event in sequences.saveAndRefresh(user)) {
  bloc.add(event);
}
```

## Notes

- Supports both Cubit (simpler) and Bloc (event-driven) patterns
- Enhanced state helpers reduce boilerplate in UI layer
- Event builders provide common patterns out-of-box
- Manager enables coordinated state across blocs
- Widget integration skipped (no Flutter dependency in package)

## History

| Date | Update |
|------|--------|
| 2026-01-10 | Tracker created |
| 2026-01-10 | Completed all phases: bundle (18 tests), manager (14 tests), state helpers (25 tests), event builders (8 tests) |
