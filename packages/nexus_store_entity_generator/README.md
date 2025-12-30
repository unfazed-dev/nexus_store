# nexus_store_entity_generator

Code generator for nexus_store type-safe entity field accessors.

## Installation

Add this package as a dev dependency:

```yaml
dev_dependencies:
  nexus_store_entity_generator:
    path: ../nexus_store_entity_generator  # or from pub.dev
  build_runner: ^2.4.0
```

## Usage

### 1. Annotate your entities

```dart
import 'package:nexus_store/nexus_store.dart';

@NexusEntity()
class User {
  final String id;
  final String name;
  final int age;
  final DateTime createdAt;
  final List<String> tags;

  User({
    required this.id,
    required this.name,
    required this.age,
    required this.createdAt,
    required this.tags,
  });
}
```

### 2. Run the generator

```bash
dart run build_runner build
```

### 3. Use the generated fields

```dart
import 'user.entity.dart';

final query = Query<User>()
  .whereExpression(UserFields.age.greaterThan(18))
  .whereExpression(UserFields.name.startsWith('Dr.'))
  .orderByTyped(UserFields.createdAt, descending: true);
```

## Generated Output

For the `User` class above, the generator creates:

```dart
class UserFields extends Fields<User> {
  UserFields._();
  static const instance = UserFields._();

  static final id = StringField<User>('id');
  static final name = StringField<User>('name');
  static final age = ComparableField<User, int>('age');
  static final createdAt = ComparableField<User, DateTime>('createdAt');
  static final tags = ListField<User, String>('tags');
}
```

## Type Mapping

| Dart Type | Generated Field Class |
|-----------|----------------------|
| `String` | `StringField<T>` |
| `int`, `double`, `num` | `ComparableField<T, F>` |
| `DateTime`, `Duration` | `ComparableField<T, F>` |
| `List<E>` | `ListField<T, E>` |
| `bool`, other types | `Field<T, F>` |

## Configuration

### Custom suffix

```dart
@NexusEntity(fieldsSuffix: 'Columns')
class Product { ... }

// Generates: ProductColumns instead of ProductFields
```

### Disable generation

```dart
@NexusEntity(generateFields: false)
class InternalEntity { ... }

// No code generated
```

## License

See repository license.
