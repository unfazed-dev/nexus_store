// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schema_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FieldSchema {
  /// Name of the field.
  String get name;

  /// Type of the field.
  FieldType get type;

  /// Whether the field is required.
  ///
  /// If true, validation fails when the field is missing.
  bool get isRequired;

  /// Whether the field can be null.
  ///
  /// Defaults to true for optional fields, false for required fields.
  bool get isNullable;

  /// Optional validation constraints.
  ///
  /// Keys and values depend on the field type:
  /// - String: 'minLength', 'maxLength', 'pattern'
  /// - Number: 'min', 'max'
  /// - List: 'minItems', 'maxItems'
  Map<String, dynamic>? get constraints;

  /// Create a copy of FieldSchema
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FieldSchemaCopyWith<FieldSchema> get copyWith =>
      _$FieldSchemaCopyWithImpl<FieldSchema>(this as FieldSchema, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FieldSchema &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.isRequired, isRequired) ||
                other.isRequired == isRequired) &&
            (identical(other.isNullable, isNullable) ||
                other.isNullable == isNullable) &&
            const DeepCollectionEquality()
                .equals(other.constraints, constraints));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, type, isRequired,
      isNullable, const DeepCollectionEquality().hash(constraints));

  @override
  String toString() {
    return 'FieldSchema(name: $name, type: $type, isRequired: $isRequired, isNullable: $isNullable, constraints: $constraints)';
  }
}

/// @nodoc
abstract mixin class $FieldSchemaCopyWith<$Res> {
  factory $FieldSchemaCopyWith(
          FieldSchema value, $Res Function(FieldSchema) _then) =
      _$FieldSchemaCopyWithImpl;
  @useResult
  $Res call(
      {String name,
      FieldType type,
      bool isRequired,
      bool isNullable,
      Map<String, dynamic>? constraints});
}

/// @nodoc
class _$FieldSchemaCopyWithImpl<$Res> implements $FieldSchemaCopyWith<$Res> {
  _$FieldSchemaCopyWithImpl(this._self, this._then);

  final FieldSchema _self;
  final $Res Function(FieldSchema) _then;

  /// Create a copy of FieldSchema
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? type = null,
    Object? isRequired = null,
    Object? isNullable = null,
    Object? constraints = freezed,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as FieldType,
      isRequired: null == isRequired
          ? _self.isRequired
          : isRequired // ignore: cast_nullable_to_non_nullable
              as bool,
      isNullable: null == isNullable
          ? _self.isNullable
          : isNullable // ignore: cast_nullable_to_non_nullable
              as bool,
      constraints: freezed == constraints
          ? _self.constraints
          : constraints // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// Adds pattern-matching-related methods to [FieldSchema].
extension FieldSchemaPatterns on FieldSchema {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_FieldSchema value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FieldSchema() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_FieldSchema value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FieldSchema():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_FieldSchema value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FieldSchema() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String name, FieldType type, bool isRequired,
            bool isNullable, Map<String, dynamic>? constraints)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FieldSchema() when $default != null:
        return $default(_that.name, _that.type, _that.isRequired,
            _that.isNullable, _that.constraints);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String name, FieldType type, bool isRequired,
            bool isNullable, Map<String, dynamic>? constraints)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FieldSchema():
        return $default(_that.name, _that.type, _that.isRequired,
            _that.isNullable, _that.constraints);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String name, FieldType type, bool isRequired,
            bool isNullable, Map<String, dynamic>? constraints)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FieldSchema() when $default != null:
        return $default(_that.name, _that.type, _that.isRequired,
            _that.isNullable, _that.constraints);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _FieldSchema extends FieldSchema {
  const _FieldSchema(
      {required this.name,
      required this.type,
      this.isRequired = false,
      this.isNullable = true,
      final Map<String, dynamic>? constraints})
      : _constraints = constraints,
        super._();

  /// Name of the field.
  @override
  final String name;

  /// Type of the field.
  @override
  final FieldType type;

  /// Whether the field is required.
  ///
  /// If true, validation fails when the field is missing.
  @override
  @JsonKey()
  final bool isRequired;

  /// Whether the field can be null.
  ///
  /// Defaults to true for optional fields, false for required fields.
  @override
  @JsonKey()
  final bool isNullable;

  /// Optional validation constraints.
  ///
  /// Keys and values depend on the field type:
  /// - String: 'minLength', 'maxLength', 'pattern'
  /// - Number: 'min', 'max'
  /// - List: 'minItems', 'maxItems'
  final Map<String, dynamic>? _constraints;

  /// Optional validation constraints.
  ///
  /// Keys and values depend on the field type:
  /// - String: 'minLength', 'maxLength', 'pattern'
  /// - Number: 'min', 'max'
  /// - List: 'minItems', 'maxItems'
  @override
  Map<String, dynamic>? get constraints {
    final value = _constraints;
    if (value == null) return null;
    if (_constraints is EqualUnmodifiableMapView) return _constraints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// Create a copy of FieldSchema
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FieldSchemaCopyWith<_FieldSchema> get copyWith =>
      __$FieldSchemaCopyWithImpl<_FieldSchema>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FieldSchema &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.isRequired, isRequired) ||
                other.isRequired == isRequired) &&
            (identical(other.isNullable, isNullable) ||
                other.isNullable == isNullable) &&
            const DeepCollectionEquality()
                .equals(other._constraints, _constraints));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, type, isRequired,
      isNullable, const DeepCollectionEquality().hash(_constraints));

  @override
  String toString() {
    return 'FieldSchema(name: $name, type: $type, isRequired: $isRequired, isNullable: $isNullable, constraints: $constraints)';
  }
}

/// @nodoc
abstract mixin class _$FieldSchemaCopyWith<$Res>
    implements $FieldSchemaCopyWith<$Res> {
  factory _$FieldSchemaCopyWith(
          _FieldSchema value, $Res Function(_FieldSchema) _then) =
      __$FieldSchemaCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String name,
      FieldType type,
      bool isRequired,
      bool isNullable,
      Map<String, dynamic>? constraints});
}

/// @nodoc
class __$FieldSchemaCopyWithImpl<$Res> implements _$FieldSchemaCopyWith<$Res> {
  __$FieldSchemaCopyWithImpl(this._self, this._then);

  final _FieldSchema _self;
  final $Res Function(_FieldSchema) _then;

  /// Create a copy of FieldSchema
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? type = null,
    Object? isRequired = null,
    Object? isNullable = null,
    Object? constraints = freezed,
  }) {
    return _then(_FieldSchema(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as FieldType,
      isRequired: null == isRequired
          ? _self.isRequired
          : isRequired // ignore: cast_nullable_to_non_nullable
              as bool,
      isNullable: null == isNullable
          ? _self.isNullable
          : isNullable // ignore: cast_nullable_to_non_nullable
              as bool,
      constraints: freezed == constraints
          ? _self._constraints
          : constraints // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
mixin _$SchemaDefinition {
  /// Name of the entity type (e.g., 'User', 'Product').
  String get name;

  /// Field schemas for this entity.
  List<FieldSchema> get fields;

  /// Schema version for migrations.
  int get version;

  /// Whether to reject unknown fields.
  ///
  /// When true, validation fails for fields not in the schema.
  bool get strictMode;

  /// Create a copy of SchemaDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SchemaDefinitionCopyWith<SchemaDefinition> get copyWith =>
      _$SchemaDefinitionCopyWithImpl<SchemaDefinition>(
          this as SchemaDefinition, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SchemaDefinition &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other.fields, fields) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.strictMode, strictMode) ||
                other.strictMode == strictMode));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name,
      const DeepCollectionEquality().hash(fields), version, strictMode);

  @override
  String toString() {
    return 'SchemaDefinition(name: $name, fields: $fields, version: $version, strictMode: $strictMode)';
  }
}

/// @nodoc
abstract mixin class $SchemaDefinitionCopyWith<$Res> {
  factory $SchemaDefinitionCopyWith(
          SchemaDefinition value, $Res Function(SchemaDefinition) _then) =
      _$SchemaDefinitionCopyWithImpl;
  @useResult
  $Res call(
      {String name, List<FieldSchema> fields, int version, bool strictMode});
}

/// @nodoc
class _$SchemaDefinitionCopyWithImpl<$Res>
    implements $SchemaDefinitionCopyWith<$Res> {
  _$SchemaDefinitionCopyWithImpl(this._self, this._then);

  final SchemaDefinition _self;
  final $Res Function(SchemaDefinition) _then;

  /// Create a copy of SchemaDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? fields = null,
    Object? version = null,
    Object? strictMode = null,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      fields: null == fields
          ? _self.fields
          : fields // ignore: cast_nullable_to_non_nullable
              as List<FieldSchema>,
      version: null == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      strictMode: null == strictMode
          ? _self.strictMode
          : strictMode // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [SchemaDefinition].
extension SchemaDefinitionPatterns on SchemaDefinition {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_SchemaDefinition value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SchemaDefinition() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_SchemaDefinition value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SchemaDefinition():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_SchemaDefinition value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SchemaDefinition() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String name, List<FieldSchema> fields, int version,
            bool strictMode)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SchemaDefinition() when $default != null:
        return $default(
            _that.name, _that.fields, _that.version, _that.strictMode);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String name, List<FieldSchema> fields, int version, bool strictMode)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SchemaDefinition():
        return $default(
            _that.name, _that.fields, _that.version, _that.strictMode);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String name, List<FieldSchema> fields, int version,
            bool strictMode)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SchemaDefinition() when $default != null:
        return $default(
            _that.name, _that.fields, _that.version, _that.strictMode);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _SchemaDefinition extends SchemaDefinition {
  const _SchemaDefinition(
      {required this.name,
      required final List<FieldSchema> fields,
      this.version = 1,
      this.strictMode = false})
      : _fields = fields,
        super._();

  /// Name of the entity type (e.g., 'User', 'Product').
  @override
  final String name;

  /// Field schemas for this entity.
  final List<FieldSchema> _fields;

  /// Field schemas for this entity.
  @override
  List<FieldSchema> get fields {
    if (_fields is EqualUnmodifiableListView) return _fields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_fields);
  }

  /// Schema version for migrations.
  @override
  @JsonKey()
  final int version;

  /// Whether to reject unknown fields.
  ///
  /// When true, validation fails for fields not in the schema.
  @override
  @JsonKey()
  final bool strictMode;

  /// Create a copy of SchemaDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SchemaDefinitionCopyWith<_SchemaDefinition> get copyWith =>
      __$SchemaDefinitionCopyWithImpl<_SchemaDefinition>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SchemaDefinition &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._fields, _fields) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.strictMode, strictMode) ||
                other.strictMode == strictMode));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name,
      const DeepCollectionEquality().hash(_fields), version, strictMode);

  @override
  String toString() {
    return 'SchemaDefinition(name: $name, fields: $fields, version: $version, strictMode: $strictMode)';
  }
}

/// @nodoc
abstract mixin class _$SchemaDefinitionCopyWith<$Res>
    implements $SchemaDefinitionCopyWith<$Res> {
  factory _$SchemaDefinitionCopyWith(
          _SchemaDefinition value, $Res Function(_SchemaDefinition) _then) =
      __$SchemaDefinitionCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String name, List<FieldSchema> fields, int version, bool strictMode});
}

/// @nodoc
class __$SchemaDefinitionCopyWithImpl<$Res>
    implements _$SchemaDefinitionCopyWith<$Res> {
  __$SchemaDefinitionCopyWithImpl(this._self, this._then);

  final _SchemaDefinition _self;
  final $Res Function(_SchemaDefinition) _then;

  /// Create a copy of SchemaDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? fields = null,
    Object? version = null,
    Object? strictMode = null,
  }) {
    return _then(_SchemaDefinition(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      fields: null == fields
          ? _self._fields
          : fields // ignore: cast_nullable_to_non_nullable
              as List<FieldSchema>,
      version: null == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      strictMode: null == strictMode
          ? _self.strictMode
          : strictMode // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
