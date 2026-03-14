# TRACKER: Riverpod Binding Batteries Included

## Status: COMPLETED

## Overview

Add batteries-included features to `nexus_store_riverpod_binding` including provider bundles, multi-store manager, base notifier classes, and mutation providers for streamlined Riverpod integration.

## Spec Reference

- [SPEC-batteries-included-enhancements.md](../../specs/SPEC-batteries-included-enhancements.md)
- Implements: REQ-007, REQ-008

## Skills to Use

- `/tdd-flutter` - Test-Driven Development for all implementations
- `/commit-helper` - Semantic commit messages for all changes

## Related Trackers

- [Main Tracker](TRACKER-batteries-main.md)

## Tasks

### Phase 1: Provider Bundle ✅
- [x] Create `StoreProviderBundle<T, ID>` class
- [x] Implement `StoreProviderBundle.forStore()` factory
- [x] Generate `storeProvider` (base store)
- [x] Generate `allProvider` (StreamProvider for all items)
- [x] Generate `byIdProvider` (StreamProviderFamily for item by ID)
- [x] Generate `statusProvider` (StreamProvider with StoreResult)
- [x] Generate `byIdStatusProvider` (StreamProviderFamily with status)
- [x] Support `keepAlive` option

### Phase 2: Store Manager ✅
- [x] Create `RiverpodStoreConfig<T, ID>` class
- [x] Create `RiverpodStoreManager` class
- [x] Implement `getBundle(name)` method
- [x] Implement `allStoreProviders` getter
- [x] Implement `createOverrides(mocks)` method for testing
- [x] Support store dependencies configuration

### Phase 3: Base Notifier Classes (Future Enhancement)
- [ ] Create `NexusAsyncNotifier<T, ID>` base class
- [ ] Implement automatic stream subscription
- [ ] Implement `add(item)` method
- [ ] Implement `update(item)` method
- [ ] Implement `remove(id)` method
- [ ] Implement `refresh()` method
- [ ] Create `NexusItemAsyncNotifier<T, ID>` for single items

### Phase 4: Mutation Providers (Future Enhancement)
- [ ] Create `StoreMutationProviders<T, ID>` class
- [ ] Implement `createMutationProviders()` factory
- [ ] Generate `save` provider
- [ ] Generate `saveAll` provider
- [ ] Generate `delete` provider
- [ ] Generate `deleteAll` provider
- [ ] Generate `refresh` provider

### Phase 5: Integration ✅
- [x] Update barrel export
- [x] Add unit tests for provider bundle (16 tests)
- [x] Add unit tests for store manager (13 tests)
- [x] All existing tests passing (103 total)

## Test Results

```
✅ 103 tests passing
  - StoreProviderBundle: 16 tests
  - RiverpodStoreManager: 13 tests
  - Extensions: 12 tests
  - Providers: 11 tests
  - Auto-dispose providers: 9 tests
  - Widgets: 42 tests
```

## Files

### New Files
| File | Description | Status |
|------|-------------|--------|
| `lib/src/providers/store_provider_bundle.dart` | All-in-one provider factory | ✅ Created |
| `lib/src/manager/riverpod_store_manager.dart` | Multi-store coordination | ✅ Created |
| `lib/src/notifiers/nexus_notifier.dart` | Base notifier classes | Future |
| `lib/src/providers/mutation_providers.dart` | Action providers | Future |

### Modified Files
| File | Changes | Status |
|------|---------|--------|
| `lib/nexus_store_riverpod_binding.dart` | Export new classes | ✅ Updated |

### Test Files
| File | Description | Status |
|------|-------------|--------|
| `test/unit/store_provider_bundle_test.dart` | Bundle tests | ✅ Created (16 tests) |
| `test/unit/riverpod_store_manager_test.dart` | Manager tests | ✅ Created (13 tests) |

## Dependencies

- riverpod: ^2.0.0 (existing)
- flutter_riverpod: ^2.0.0 (existing)

## API Design

```dart
// Provider bundle - all providers in one call
final userBundle = StoreProviderBundle.forStore<User, String>(
  create: (ref) => NexusStore<User, String>(backend: createBackend()),
  name: 'user',
  keepAlive: true,
);

// In widget
final users = ref.watch(userBundle.allProvider);
final user = ref.watch(userBundle.byIdProvider('user-123'));

// Multi-store manager
final storeManager = RiverpodStoreManager([
  RiverpodStoreConfig<User, String>(
    name: 'users',
    create: (ref) => NexusStore(backend: userBackend),
  ),
  RiverpodStoreConfig<Post, String>(
    name: 'posts',
    create: (ref) => NexusStore(backend: postBackend),
    dependencies: ['users'],
  ),
]);

final userBundle = storeManager.getBundle('users');

// Test overrides
testWidgets('my test', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: storeManager.createOverrides({
        'users': mockUserStore,
        'posts': mockPostStore,
      }),
      child: MyApp(),
    ),
  );
});
```

## Notes

- Provider bundle reduces boilerplate from 5+ providers to 1 call
- Manager enables coordinated multi-store apps with test override support
- Bundle returns dynamic types due to Dart type system limitations
- Cast providers when accessing specific types: `container.read(bundle.storeProvider) as NexusStore<User, String>`

## History

| Date | Update |
|------|--------|
| 2026-01-10 | Tracker created |
| 2026-01-10 | Phase 1 completed: StoreProviderBundle with 16 tests |
| 2026-01-10 | Phase 2 completed: RiverpodStoreManager with 13 tests |
| 2026-01-10 | Package complete with 103 tests passing |
