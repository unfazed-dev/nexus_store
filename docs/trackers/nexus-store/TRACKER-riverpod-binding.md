# TRACKER: Riverpod Binding Package

## Status: PENDING

## Overview

Create `nexus_store_riverpod_binding` package that provides first-class Riverpod integration with code generation for auto-generated providers.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-046, Task 35
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Package Setup
- [ ] Create package skeleton
  - [ ] `pubspec.yaml` with dependencies
  - [ ] `analysis_options.yaml`
  - [ ] Basic library structure

- [ ] Add dependencies
  - [ ] `riverpod: ^2.0.0`
  - [ ] `riverpod_annotation: ^2.0.0`
  - [ ] `nexus_store: (path)`
  - [ ] `build_runner` (dev)
  - [ ] `riverpod_generator` (dev)

### Manual Providers (No Code Gen)
- [ ] Create `NexusStoreProvider<T, ID>` helper
  - [ ] Wraps store in Provider
  - [ ] Handles disposal

- [ ] Create extension methods
  - [ ] `store.watchAllProvider` → `StreamProvider<List<T>>`
  - [ ] `store.watchProvider(id)` → `StreamProvider.family<T?, ID>`
  - [ ] `store.watchWithStatusProvider` → `StreamProvider<StoreResult<List<T>>>`

### Code Generation (Optional)
- [ ] Create `@riverpodNexusStore` annotation
  - [ ] Marks store factory for generation
  - [ ] Options: scope, keepAlive, etc.

- [ ] Create `nexus_store_riverpod_generator` package
  - [ ] Implements `Generator` from build_runner
  - [ ] Parses annotations
  - [ ] Generates provider code

- [ ] Generate providers
  - [ ] `{name}StoreProvider` - The store itself
  - [ ] `{name}Provider` - watchAll() as AsyncValue
  - [ ] `{name}ByIdProvider` - watch(id) family
  - [ ] `{name}StatusProvider` - watchWithStatus()

### Disposal Integration
- [ ] Implement `ref.onDispose` integration
  - [ ] Close store subscriptions
  - [ ] Optionally dispose store

- [ ] Handle keepAlive stores
  - [ ] Don't auto-dispose
  - [ ] Manual invalidation

### Utilities
- [ ] Create `NexusStoreConsumer` widget (optional)
  - [ ] Shorthand for common patterns
  - [ ] Error/loading handling

- [ ] Create `useNexusStore` hook (flutter_hooks)
  - [ ] For hooks users

### Documentation & Examples
- [ ] Write README.md
  - [ ] Installation
  - [ ] Basic usage
  - [ ] Code generation setup
  - [ ] Migration from manual providers

- [ ] Create example app
  - [ ] Demonstrates all features

### Unit Tests
- [ ] `test/providers_test.dart`
  - [ ] Providers emit correctly
  - [ ] Disposal works
  - [ ] Family providers work

- [ ] `test/generator_test.dart` (if code gen)
  - [ ] Generates correct code
  - [ ] Handles edge cases

## Files

**Package Structure:**
```
packages/nexus_store_riverpod_binding/
├── lib/
│   ├── nexus_store_riverpod_binding.dart  # Main export
│   └── src/
│       ├── providers.dart                  # Provider helpers
│       ├── extensions.dart                 # Store extensions
│       ├── annotations.dart                # @riverpodNexusStore
│       └── widgets.dart                    # Optional widgets
├── test/
│   ├── providers_test.dart
│   └── extensions_test.dart
├── example/
│   └── lib/main.dart
├── pubspec.yaml
└── README.md

packages/nexus_store_riverpod_generator/ (optional)
├── lib/
│   └── builder.dart
├── pubspec.yaml
└── build.yaml
```

## Dependencies

- Core package (Task 1, complete)
- `riverpod: ^2.0.0`
- `riverpod_annotation: ^2.0.0`
- `flutter_riverpod: ^2.0.0` (for Flutter widgets)

## API Preview

```dart
// pubspec.yaml
dependencies:
  nexus_store: ^1.0.0
  nexus_store_riverpod_binding: ^1.0.0
  flutter_riverpod: ^2.0.0

// Manual usage (no code gen)
final userStoreProvider = Provider<NexusStore<User, String>>((ref) {
  final store = NexusStore<User, String>(backend: createBackend());
  ref.onDispose(() => store.dispose());
  return store;
});

final usersProvider = StreamProvider<List<User>>((ref) {
  return ref.watch(userStoreProvider).watchAll();
});

final userProvider = StreamProvider.family<User?, String>((ref, id) {
  return ref.watch(userStoreProvider).watch(id);
});

// With extensions (cleaner)
final userStoreProvider = Provider<NexusStore<User, String>>((ref) {
  return NexusStore<User, String>(backend: createBackend())
    ..bindToRef(ref); // Auto-dispose on ref disposal
});

// Extension creates providers automatically
final usersProvider = userStoreProvider.watchAll();
final userByIdProvider = userStoreProvider.watchFamily();

// With code generation (cleanest)
@riverpodNexusStore
NexusStore<User, String> userStore(UserStoreRef ref) {
  return NexusStore<User, String>(
    backend: ref.watch(backendProvider),
  );
}

// Generated:
// - userStoreProvider: Provider<NexusStore<User, String>>
// - usersProvider: StreamProvider<List<User>>
// - userProvider: StreamProvider.family<User?, String>
// - usersStatusProvider: StreamProvider<StoreResult<List<User>>>

// Usage in widget
class UserListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return usersAsync.when(
      data: (users) => ListView(
        children: users.map((u) => UserTile(u)).toList(),
      ),
      loading: () => CircularProgressIndicator(),
      error: (e, st) => ErrorWidget(e),
    );
  }
}

// Single user with family
class UserDetailScreen extends ConsumerWidget {
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider(userId));

    return userAsync.when(
      data: (user) => user != null
        ? UserDetail(user)
        : Text('User not found'),
      loading: () => CircularProgressIndicator(),
      error: (e, st) => ErrorWidget(e),
    );
  }
}

// With status (loading states, sync status)
class UserListWithStatus extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(usersStatusProvider);

    return statusAsync.when(
      data: (result) => result.when(
        idle: () => Text('Idle'),
        pending: (prev) => Stack(
          children: [
            UserList(users: prev ?? []),
            LinearProgressIndicator(),
          ],
        ),
        success: (users) => UserList(users: users),
        error: (e, st, prev) => ErrorWithRetry(
          error: e,
          previousData: prev,
        ),
      ),
      loading: () => CircularProgressIndicator(),
      error: (e, st) => ErrorWidget(e),
    );
  }
}
```

## Notes

- Code generation is optional but recommended for large apps
- Manual providers work fine for small apps
- `bindToRef` extension handles disposal automatically
- Consider supporting Riverpod 3.0 when released
- Family providers essential for detail screens
- Status providers give more control than basic AsyncValue
- Document migration path from bare Riverpod to this package
