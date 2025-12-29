// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schema_validation_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SchemaValidationConfig {
  /// Validation mode determining error handling.
  ///
  /// Defaults to [SchemaValidationMode.warn].
  SchemaValidationMode get mode;

  /// Whether schema validation is enabled.
  ///
  /// When false, all validation is skipped. Defaults to true.
  bool get enabled;

  /// Whether to validate entities before saving.
  ///
  /// Defaults to true.
  bool get validateOnSave;

  /// Whether to validate entities after reading.
  ///
  /// Defaults to false (for performance).
  bool get validateOnRead;

  /// Create a copy of SchemaValidationConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SchemaValidationConfigCopyWith<SchemaValidationConfig> get copyWith =>
      _$SchemaValidationConfigCopyWithImpl<SchemaValidationConfig>(
          this as SchemaValidationConfig, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SchemaValidationConfig &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.validateOnSave, validateOnSave) ||
                other.validateOnSave == validateOnSave) &&
            (identical(other.validateOnRead, validateOnRead) ||
                other.validateOnRead == validateOnRead));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, mode, enabled, validateOnSave, validateOnRead);

  @override
  String toString() {
    return 'SchemaValidationConfig(mode: $mode, enabled: $enabled, validateOnSave: $validateOnSave, validateOnRead: $validateOnRead)';
  }
}

/// @nodoc
abstract mixin class $SchemaValidationConfigCopyWith<$Res> {
  factory $SchemaValidationConfigCopyWith(SchemaValidationConfig value,
          $Res Function(SchemaValidationConfig) _then) =
      _$SchemaValidationConfigCopyWithImpl;
  @useResult
  $Res call(
      {SchemaValidationMode mode,
      bool enabled,
      bool validateOnSave,
      bool validateOnRead});
}

/// @nodoc
class _$SchemaValidationConfigCopyWithImpl<$Res>
    implements $SchemaValidationConfigCopyWith<$Res> {
  _$SchemaValidationConfigCopyWithImpl(this._self, this._then);

  final SchemaValidationConfig _self;
  final $Res Function(SchemaValidationConfig) _then;

  /// Create a copy of SchemaValidationConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? enabled = null,
    Object? validateOnSave = null,
    Object? validateOnRead = null,
  }) {
    return _then(_self.copyWith(
      mode: null == mode
          ? _self.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as SchemaValidationMode,
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      validateOnSave: null == validateOnSave
          ? _self.validateOnSave
          : validateOnSave // ignore: cast_nullable_to_non_nullable
              as bool,
      validateOnRead: null == validateOnRead
          ? _self.validateOnRead
          : validateOnRead // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [SchemaValidationConfig].
extension SchemaValidationConfigPatterns on SchemaValidationConfig {
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
    TResult Function(_SchemaValidationConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SchemaValidationConfig() when $default != null:
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
    TResult Function(_SchemaValidationConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SchemaValidationConfig():
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
    TResult? Function(_SchemaValidationConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SchemaValidationConfig() when $default != null:
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
    TResult Function(SchemaValidationMode mode, bool enabled,
            bool validateOnSave, bool validateOnRead)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SchemaValidationConfig() when $default != null:
        return $default(_that.mode, _that.enabled, _that.validateOnSave,
            _that.validateOnRead);
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
    TResult Function(SchemaValidationMode mode, bool enabled,
            bool validateOnSave, bool validateOnRead)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SchemaValidationConfig():
        return $default(_that.mode, _that.enabled, _that.validateOnSave,
            _that.validateOnRead);
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
    TResult? Function(SchemaValidationMode mode, bool enabled,
            bool validateOnSave, bool validateOnRead)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SchemaValidationConfig() when $default != null:
        return $default(_that.mode, _that.enabled, _that.validateOnSave,
            _that.validateOnRead);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _SchemaValidationConfig extends SchemaValidationConfig {
  const _SchemaValidationConfig(
      {this.mode = SchemaValidationMode.warn,
      this.enabled = true,
      this.validateOnSave = true,
      this.validateOnRead = false})
      : super._();

  /// Validation mode determining error handling.
  ///
  /// Defaults to [SchemaValidationMode.warn].
  @override
  @JsonKey()
  final SchemaValidationMode mode;

  /// Whether schema validation is enabled.
  ///
  /// When false, all validation is skipped. Defaults to true.
  @override
  @JsonKey()
  final bool enabled;

  /// Whether to validate entities before saving.
  ///
  /// Defaults to true.
  @override
  @JsonKey()
  final bool validateOnSave;

  /// Whether to validate entities after reading.
  ///
  /// Defaults to false (for performance).
  @override
  @JsonKey()
  final bool validateOnRead;

  /// Create a copy of SchemaValidationConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SchemaValidationConfigCopyWith<_SchemaValidationConfig> get copyWith =>
      __$SchemaValidationConfigCopyWithImpl<_SchemaValidationConfig>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SchemaValidationConfig &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.validateOnSave, validateOnSave) ||
                other.validateOnSave == validateOnSave) &&
            (identical(other.validateOnRead, validateOnRead) ||
                other.validateOnRead == validateOnRead));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, mode, enabled, validateOnSave, validateOnRead);

  @override
  String toString() {
    return 'SchemaValidationConfig(mode: $mode, enabled: $enabled, validateOnSave: $validateOnSave, validateOnRead: $validateOnRead)';
  }
}

/// @nodoc
abstract mixin class _$SchemaValidationConfigCopyWith<$Res>
    implements $SchemaValidationConfigCopyWith<$Res> {
  factory _$SchemaValidationConfigCopyWith(_SchemaValidationConfig value,
          $Res Function(_SchemaValidationConfig) _then) =
      __$SchemaValidationConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {SchemaValidationMode mode,
      bool enabled,
      bool validateOnSave,
      bool validateOnRead});
}

/// @nodoc
class __$SchemaValidationConfigCopyWithImpl<$Res>
    implements _$SchemaValidationConfigCopyWith<$Res> {
  __$SchemaValidationConfigCopyWithImpl(this._self, this._then);

  final _SchemaValidationConfig _self;
  final $Res Function(_SchemaValidationConfig) _then;

  /// Create a copy of SchemaValidationConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? mode = null,
    Object? enabled = null,
    Object? validateOnSave = null,
    Object? validateOnRead = null,
  }) {
    return _then(_SchemaValidationConfig(
      mode: null == mode
          ? _self.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as SchemaValidationMode,
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      validateOnSave: null == validateOnSave
          ? _self.validateOnSave
          : validateOnSave // ignore: cast_nullable_to_non_nullable
              as bool,
      validateOnRead: null == validateOnRead
          ? _self.validateOnRead
          : validateOnRead // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
