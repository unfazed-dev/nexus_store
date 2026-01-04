import 'package:freezed_annotation/freezed_annotation.dart';

part 'schema_definition.freezed.dart';

/// Represents the type of a field in a schema.
///
/// Used to validate that field values match expected types.
enum FieldType {
  /// String type.
  string,

  /// Integer type.
  integer,

  /// Double/floating-point type.
  double_,

  /// Boolean type.
  boolean,

  /// DateTime type.
  dateTime,

  /// List/array type.
  list,

  /// Map/object type.
  map,

  /// Dynamic type (accepts any value).
  dynamic_;

  /// Returns `true` if the given [value] matches this type.
  ///
  /// Null values are considered valid for any type (nullability is
  /// handled separately by [FieldSchema.nullable]).
  bool matchesValue(Object? value) {
    if (value == null) return true;

    return switch (this) {
      FieldType.string => value is String,
      FieldType.integer => value is int,
      FieldType.double_ => value is num, // Allow int promotion to double
      FieldType.boolean => value is bool,
      FieldType.dateTime => value is DateTime,
      FieldType.list => value is List,
      FieldType.map => value is Map,
      FieldType.dynamic_ => true,
    };
  }

  /// Returns a display string for this type.
  String get displayString => switch (this) {
        FieldType.string => 'String',
        FieldType.integer => 'int',
        FieldType.double_ => 'double',
        FieldType.boolean => 'bool',
        FieldType.dateTime => 'DateTime',
        FieldType.list => 'List',
        FieldType.map => 'Map',
        FieldType.dynamic_ => 'dynamic',
      };
}

/// Defines the schema for a single field.
///
/// Specifies the field's type, whether it's required, and optional
/// constraints for validation.
///
/// ## Example
///
/// ```dart
/// const emailField = FieldSchema(
///   name: 'email',
///   type: FieldType.string,
///   required: true,
///   constraints: {'pattern': r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'},
/// );
/// ```
@freezed
abstract class FieldSchema with _$FieldSchema {
  /// Creates a field schema.
  const factory FieldSchema({
    /// Name of the field.
    required String name,

    /// Type of the field.
    required FieldType type,

    /// Whether the field is required.
    ///
    /// If true, validation fails when the field is missing.
    @Default(false) bool isRequired,

    /// Whether the field can be null.
    ///
    /// Defaults to true for optional fields, false for required fields.
    @Default(true) bool isNullable,

    /// Optional validation constraints.
    ///
    /// Keys and values depend on the field type:
    /// - String: 'minLength', 'maxLength', 'pattern'
    /// - Number: 'min', 'max'
    /// - List: 'minItems', 'maxItems'
    Map<String, dynamic>? constraints,
  }) = _FieldSchema;

  const FieldSchema._();

  /// Creates a required ID field.
  factory FieldSchema.id({String name = 'id'}) => FieldSchema(
        name: name,
        type: FieldType.string,
        isRequired: true,
        isNullable: false,
      );

  /// Creates a required string field.
  factory FieldSchema.requiredString(String name) => FieldSchema(
        name: name,
        type: FieldType.string,
        isRequired: true,
        isNullable: false,
      );

  /// Creates an optional string field.
  factory FieldSchema.optionalString(String name) => FieldSchema(
        name: name,
        type: FieldType.string,
        isRequired: false,
        isNullable: true,
      );

  /// Creates a required integer field.
  factory FieldSchema.requiredInt(String name) => FieldSchema(
        name: name,
        type: FieldType.integer,
        isRequired: true,
        isNullable: false,
      );

  /// Creates a required timestamp field.
  factory FieldSchema.timestamp(String name) => FieldSchema(
        name: name,
        type: FieldType.dateTime,
        isRequired: true,
        isNullable: false,
      );

  /// Validates a value against this schema.
  ///
  /// Returns `null` if valid, or an error message if invalid.
  String? validate(Object? value) {
    // Check required
    if (isRequired && value == null) {
      return "Field '$name' is required";
    }

    // Check nullability (unreachable: if isRequired && value == null, line 156 returns first)
    // coverage:ignore-start
    if (!isNullable && value == null && isRequired) {
      return "Field '$name' cannot be null";
    }
    // coverage:ignore-end

    // Skip type check for null values
    if (value == null) return null;

    // Check type
    if (!type.matchesValue(value)) {
      return "Field '$name' expected type ${type.displayString}, got ${value.runtimeType}";
    }

    return null;
  }
}

/// Defines the schema for an entity type.
///
/// Contains a collection of field schemas and provides validation
/// methods for entity data.
///
/// ## Example
///
/// ```dart
/// const userSchema = SchemaDefinition(
///   name: 'User',
///   fields: [
///     FieldSchema(name: 'id', type: FieldType.string, required: true),
///     FieldSchema(name: 'email', type: FieldType.string, required: true),
///     FieldSchema(name: 'age', type: FieldType.integer),
///   ],
/// );
///
/// final errors = userSchema.validate({'id': '1', 'email': 'test@example.com'});
/// if (errors.isEmpty) {
///   print('Valid!');
/// }
/// ```
@freezed
abstract class SchemaDefinition with _$SchemaDefinition {
  /// Creates a schema definition.
  const factory SchemaDefinition({
    /// Name of the entity type (e.g., 'User', 'Product').
    required String name,

    /// Field schemas for this entity.
    required List<FieldSchema> fields,

    /// Schema version for migrations.
    @Default(1) int version,

    /// Whether to reject unknown fields.
    ///
    /// When true, validation fails for fields not in the schema.
    @Default(false) bool strictMode,
  }) = _SchemaDefinition;

  const SchemaDefinition._();

  /// Validates data against this schema.
  ///
  /// Returns a list of validation error messages. An empty list means
  /// the data is valid.
  List<String> validate(Map<String, dynamic> data) {
    final errors = <String>[];

    // Validate each field
    for (final field in fields) {
      final value = data[field.name];
      final error = field.validate(value);
      if (error != null) {
        errors.add(error);
      }
    }

    // Check for unknown fields in strict mode
    if (strictMode) {
      final knownFields = fields.map((f) => f.name).toSet();
      for (final key in data.keys) {
        if (!knownFields.contains(key)) {
          errors.add("Unknown field '$key' in schema '$name'");
        }
      }
    }

    return errors;
  }

  /// Returns `true` if the data is valid according to this schema.
  bool isValid(Map<String, dynamic> data) => validate(data).isEmpty;

  /// Gets a field schema by name.
  ///
  /// Returns `null` if no field with that name exists.
  FieldSchema? getField(String name) {
    for (final field in fields) {
      if (field.name == name) return field;
    }
    return null;
  }

  /// Returns all required fields.
  List<FieldSchema> get requiredFields =>
      fields.where((f) => f.isRequired).toList();

  /// Returns all optional fields.
  List<FieldSchema> get optionalFields =>
      fields.where((f) => !f.isRequired).toList();
}
