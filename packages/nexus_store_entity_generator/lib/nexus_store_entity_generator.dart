/// Code generator for nexus_store type-safe entity field accessors.
///
/// This package provides a code generator that creates type-safe field
/// accessor classes from `@NexusEntity` annotated classes.
///
/// ## Usage
///
/// 1. Add this package as a dev dependency:
///
/// ```yaml
/// dev_dependencies:
///   nexus_store_entity_generator:
///     path: ../nexus_store_entity_generator
///   build_runner: ^2.4.0
/// ```
///
/// 2. Annotate your entities with `@NexusEntity()`:
///
/// ```dart
/// import 'package:nexus_store/nexus_store.dart';
///
/// @NexusEntity()
/// class User {
///   final String id;
///   final String name;
///   final int age;
///   final DateTime createdAt;
///   final List<String> tags;
///
///   User({...});
/// }
/// ```
///
/// 3. Run the generator:
///
/// ```bash
/// dart run build_runner build
/// ```
///
/// 4. Use the generated fields:
///
/// ```dart
/// final query = Query<User>()
///   .whereExpression(UserFields.age.greaterThan(18))
///   .whereExpression(UserFields.name.startsWith('Dr.'));
/// ```
library;

export 'src/entity_generator.dart';
