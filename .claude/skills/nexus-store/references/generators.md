# Code Generators Reference

Documentation for all 3 nexus_store code generators.

## Generator Overview

| Generator | Annotation | Output | Purpose |
|-----------|------------|--------|---------|
| Entity Generator | `@NexusEntity()` | `.entity.dart` | Type-safe query field accessors |
| Lazy Generator | `@NexusLazy()` | `.lazy.dart` | Lazy-loaded field accessors |
| Riverpod Generator | `@riverpodNexusStore` | `.nexus_store.g.dart` | Automatic Riverpod providers |

## Build Runner Setup

Add to `pubspec.yaml`:

```yaml
dev_dependencies:
  build_runner: ^2.4.0
  # Add generators as needed
```

Create `build.yaml` in project root:

```yaml
targets:
  $default:
    builders:
      nexus_store_entity_generator:
        enabled: true
      nexus_store_generator:
        enabled: true
      nexus_store_riverpod_generator:
        enabled: true
```

Run generators:

```bash
# One-time build
dart run build_runner build --delete-conflicting-outputs

# Watch mode (recommended during development)
dart run build_runner watch --delete-conflicting-outputs
```

---

## Entity Generator

Generates type-safe field accessors for Query builder expressions.

### Installation

```yaml
dev_dependencies:
  nexus_store_entity_generator:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_entity_generator
  build_runner: ^2.4.0
```

### Usage

```dart
import 'package:nexus_store/nexus_store.dart';

part 'user.entity.dart';

@NexusEntity()
class User {
  final String id;
  final String name;
  final String email;
  final int age;
  final DateTime createdAt;
  final List<String> roles;
  final bool isActive;
}
```

### Generated Output

```dart
// user.entity.dart
class UserFields {
  static const StringField id = StringField('id');
  static const StringField name = StringField('name');
  static const StringField email = StringField('email');
  static const ComparableField<int> age = ComparableField('age');
  static const ComparableField<DateTime> createdAt = ComparableField('createdAt');
  static const ListField<String> roles = ListField('roles');
  static const Field<bool> isActive = Field('isActive');
}
```

### Type-Safe Queries

```dart
// Instead of string-based queries
final query = Query<User>().where('age', isGreaterThan: 18);

// Use type-safe fields
final query = Query<User>()
  .whereExpression(UserFields.age.greaterThan(18))
  .whereExpression(UserFields.name.contains('John'))
  .whereExpression(UserFields.isActive.equals(true))
  .whereExpression(UserFields.roles.contains('admin'));
```

### Field Type Mapping

| Dart Type | Generated Field Type | Available Operations |
|-----------|---------------------|---------------------|
| `String` | `StringField` | `equals`, `contains`, `startsWith`, `endsWith`, `isIn` |
| `int`, `double`, `num` | `ComparableField<T>` | `equals`, `lessThan`, `greaterThan`, `between`, `isIn` |
| `DateTime`, `Duration` | `ComparableField<T>` | `equals`, `lessThan`, `greaterThan`, `between` |
| `List<E>` | `ListField<E>` | `contains`, `containsAny`, `isEmpty` |
| `bool` | `Field<bool>` | `equals` |
| Other | `Field<T>` | `equals`, `isNull` |

### Configuration Options

```dart
@NexusEntity(
  fieldsSuffix: 'Columns',  // Default: 'Fields'
  generateFields: true,      // Default: true
)
class User { ... }

// Generates: UserColumns instead of UserFields
```

---

## Lazy Generator

Generates lazy-loaded field accessors for on-demand data loading.

### Installation

```yaml
dev_dependencies:
  nexus_store_generator:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_generator
  build_runner: ^2.4.0
```

### Usage

```dart
import 'package:nexus_store/nexus_store.dart';

part 'post.lazy.dart';

@NexusLazy()
class Post {
  final String id;
  final String title;
  final String content;

  @Lazy(placeholder: [])
  final List<Comment> comments;

  @Lazy(placeholder: null, preloadOnWatch: true)
  final User? author;
}
```

### Generated Output

```dart
// post.lazy.dart

/// Mixin with load methods
mixin PostLazyAccessors {
  bool get isCommentsLoaded;
  Future<List<Comment>> loadComments();

  bool get isAuthorLoaded;
  Future<User?> loadAuthor();
}

/// Wrapper class extending LazyEntity
class LazyPost extends LazyEntity<Post> with PostLazyAccessors {
  LazyPost(Post entity, FieldLoader loader) : super(entity, loader);

  @override
  bool get isCommentsLoaded => isFieldLoaded('comments');

  @override
  Future<List<Comment>> loadComments() => loadField('comments');

  @override
  bool get isAuthorLoaded => isFieldLoaded('author');

  @override
  Future<User?> loadAuthor() => loadField('author');
}
```

### Using Lazy Entities

```dart
// Create lazy wrapper
final lazyPost = LazyPost(post, postFieldLoader);

// Check if loaded
if (!lazyPost.isCommentsLoaded) {
  // Load on demand
  final comments = await lazyPost.loadComments();
}

// Access underlying entity
final post = lazyPost.entity;
```

### @Lazy Annotation Options

```dart
@Lazy(
  placeholder: [],           // Value to return when not loaded
  preloadOnWatch: false,     // Auto-load when entity is watched
)
final List<Comment> comments;
```

### Configuration Options

```dart
@NexusLazy(
  generateAccessors: true,  // Generate mixin with load methods
  generateWrapper: true,    // Generate LazyEntity wrapper class
)
class Post { ... }
```

---

## Riverpod Generator

Generates Riverpod providers from annotated store factory functions.

### Installation

```yaml
dev_dependencies:
  nexus_store_riverpod_generator:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_riverpod_generator
  riverpod_generator: ^2.0.0
  build_runner: ^2.4.0
```

### Usage

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:nexus_store_riverpod_binding/nexus_store_riverpod_binding.dart';

part 'user_store.g.dart';
part 'user_store.nexus_store.g.dart';

@riverpodNexusStore
NexusStore<User, String> userStore(UserStoreRef ref) {
  final backend = ref.watch(backendProvider);
  return NexusStore(
    backend: backend,
    config: StoreConfig.defaults,
  );
}
```

### Generated Providers

```dart
// user_store.nexus_store.g.dart

/// The store itself
final userStoreProvider = Provider<NexusStore<User, String>>((ref) {
  return userStore(ref);
});

/// Stream of all entities
final userProvider = StreamProvider<List<User>>((ref) {
  return ref.watch(userStoreProvider).watchAll();
});

/// Stream of single entity by ID
final userByIdProvider = StreamProvider.family<User?, String>((ref, id) {
  return ref.watch(userStoreProvider).watch(id);
});

/// Stream with StoreResult status
final userStatusProvider = StreamProvider<StoreResult<List<User>>>((ref) {
  return ref.watch(userStoreProvider).watchAllWithStatus();
});
```

### Configuration Options

```dart
@riverpodNexusStore
@RiverpodNexusStoreConfig(
  keepAlive: true,    // Prevent auto-dispose
  name: 'customer',   // Custom name prefix (generates customerStoreProvider, etc.)
)
NexusStore<Customer, String> customerStore(CustomerStoreRef ref) { ... }
```

### Using Generated Providers

```dart
class UserListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access store for mutations
    final store = ref.read(userStoreProvider);

    // Watch list updates
    final usersAsync = ref.watch(userProvider);

    // Watch specific user
    final userAsync = ref.watch(userByIdProvider('user-123'));

    // Watch with loading status
    final statusAsync = ref.watch(userStatusProvider);

    return usersAsync.when(
      data: (users) => ListView.builder(
        itemCount: users.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(users[i].name),
          onTap: () => store.delete(users[i].id),
        ),
      ),
      loading: () => CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
```

### Auto-Dispose Behavior

By default, generated providers auto-dispose when no longer watched. Use `keepAlive: true` to persist:

```dart
@riverpodNexusStore
@RiverpodNexusStoreConfig(keepAlive: true)
NexusStore<User, String> userStore(UserStoreRef ref) {
  ref.onDispose(() {
    // Cleanup when provider is disposed
  });
  return NexusStore(...);
}
```
