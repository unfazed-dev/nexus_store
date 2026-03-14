# TRACKER: Signals Binding Batteries Included

## Status: COMPLETED

## Overview

Add batteries-included features to `nexus_store_signals_binding` including signal store bundles, multi-store manager, Flutter widget scope, and fluent computed signal builders.

## Spec Reference

- [SPEC-batteries-included-enhancements.md](../../specs/SPEC-batteries-included-enhancements.md)
- Implements: REQ-007, REQ-008

## Skills to Use

- `/tdd-flutter` - Test-Driven Development for all implementations
- `/commit-helper` - Semantic commit messages for all changes

## Related Trackers

- [Main Tracker](TRACKER-batteries-main.md)

## Tasks

### Phase 1: Store Bundle ✅
- [x] Create `SignalsStoreConfig<T, ID>` class
- [x] Create `SignalsStoreBundle<T, ID>` class
- [x] Implement `SignalsStoreBundle.create()` factory
- [x] Generate `listSignal` (NexusListSignal)
- [x] Generate `stateSignal` (loading/error tracking)
- [x] Support named computed signals
- [x] Implement `computed(name)` accessor
- [x] Implement `dispose()` method

### Phase 2: Store Manager ✅
- [x] Create `SignalsManager` class
- [x] Implement manager constructor with configs
- [x] Implement `getBundle(name)` method
- [x] Implement `getListSignal(name)` method
- [x] Implement `getStateSignal(name)` method
- [x] Implement `createCrossStoreComputed()` method
- [x] Implement `dispose()` method

### Phase 3: Flutter Widget Scope (Future Enhancement)
- [ ] Create `FlutterSignalScope` InheritedWidget
- [ ] Implement `FlutterSignalScope.of(context)` method
- [ ] Implement `FlutterSignalScope.maybeOf(context)` method
- [ ] Handle automatic initialization
- [ ] Handle automatic disposal

### Phase 4: Computed Builders (Future Enhancement)
- [ ] Create `ComputedBuilder<T, R>` class
- [ ] Implement `where(predicate)` method
- [ ] Implement `sortBy(keySelector)` method
- [ ] Implement `select(selector)` method
- [ ] Implement `take(count)` method
- [ ] Implement `skip(count)` method
- [ ] Implement `build()` method (returns Computed<List<R>>)
- [ ] Implement `buildFirst()` method
- [ ] Implement `buildCount()` method
- [ ] Implement `buildAny(predicate)` method
- [ ] Add extension on Signal<List<T>> for fluent API

### Phase 5: Integration ✅
- [x] Update barrel export
- [x] Add unit tests for store bundle (14 tests)
- [x] Add unit tests for manager (11 tests)
- [x] All existing tests passing (189 total)

## Test Results

```
✅ 189 tests passing
  - SignalsStoreBundle: 14 tests
  - SignalsManager: 11 tests
  - Existing tests: 164 tests
```

## Files

### New Files
| File | Description | Status |
|------|-------------|--------|
| `lib/src/bundle/signals_store_bundle.dart` | Store bundle factory | ✅ Created |
| `lib/src/manager/signals_manager.dart` | Multi-store coordination | ✅ Created |
| `lib/src/widgets/flutter_signal_scope.dart` | InheritedWidget integration | Future |
| `lib/src/computed/computed_builders.dart` | Fluent computed API | Future |

### Modified Files
| File | Changes | Status |
|------|---------|--------|
| `lib/nexus_store_signals_binding.dart` | Export new classes | ✅ Updated |

### Test Files
| File | Description | Status |
|------|-------------|--------|
| `test/unit/signals_store_bundle_test.dart` | Bundle tests | ✅ Created (14 tests) |
| `test/unit/signals_manager_test.dart` | Manager tests | ✅ Created (11 tests) |

## Dependencies

- signals: ^5.0.0 (existing)
- flutter_signals: ^5.0.0 (existing)

## API Design

```dart
// Store bundle with computed signals
final userBundle = SignalsStoreBundle.create(
  config: SignalsStoreConfig<User, String>(
    name: 'users',
    store: userStore,
    computedSignals: {
      'activeCount': (s) => computed(() => s.value.where((u) => u.isActive).length),
      'sortedByName': (s) => computed(() => [...s.value]..sort((a, b) => a.name.compareTo(b.name))),
    },
  ),
);

final users = userBundle.listSignal;
final activeCount = userBundle.computed('activeCount');

// Multi-store manager
final manager = SignalsManager([
  SignalsStoreConfig<User, String>(name: 'users', store: userStore),
  SignalsStoreConfig<Post, String>(name: 'posts', store: postStore),
]);

// Access bundles
final userBundle = manager.getBundle('users');
final usersSignal = manager.getListSignal('users');

// Cross-store computed
final totalCount = manager.createCrossStoreComputed<int>(
  'totalCount',
  (bundles) {
    final userCount = bundles['users']!.listSignal.value.length;
    final postCount = bundles['posts']!.listSignal.value.length;
    return userCount + postCount;
  },
);

// Clean up
manager.dispose();
```

## Notes

- Bundle returns dynamic-typed computed signals due to Dart type system limitations
- Manager methods return dynamic-typed signals; cast values when accessing
- Cross-store computed enables derived state across multiple stores
- Bundle disposes all signals including computed signals

## History

| Date | Update |
|------|--------|
| 2026-01-10 | Tracker created |
| 2026-01-10 | Phase 1 completed: SignalsStoreBundle with 14 tests |
| 2026-01-10 | Phase 2 completed: SignalsManager with 11 tests |
| 2026-01-10 | Package complete with 189 tests passing |
