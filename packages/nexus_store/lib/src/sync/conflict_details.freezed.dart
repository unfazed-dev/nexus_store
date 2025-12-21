// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conflict_details.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ConflictDetails<T> {
  /// The local version of the entity.
  T get localValue;

  /// The remote version of the entity.
  T get remoteValue;

  /// When the local version was last modified.
  DateTime get localTimestamp;

  /// When the remote version was last modified.
  DateTime get remoteTimestamp;

  /// The set of field names that have conflicting values.
  ///
  /// If null, the specific conflicting fields are not known.
  Set<String>? get conflictingFields;

  /// Create a copy of ConflictDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ConflictDetailsCopyWith<T, ConflictDetails<T>> get copyWith =>
      _$ConflictDetailsCopyWithImpl<T, ConflictDetails<T>>(
          this as ConflictDetails<T>, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ConflictDetails<T> &&
            const DeepCollectionEquality()
                .equals(other.localValue, localValue) &&
            const DeepCollectionEquality()
                .equals(other.remoteValue, remoteValue) &&
            (identical(other.localTimestamp, localTimestamp) ||
                other.localTimestamp == localTimestamp) &&
            (identical(other.remoteTimestamp, remoteTimestamp) ||
                other.remoteTimestamp == remoteTimestamp) &&
            const DeepCollectionEquality()
                .equals(other.conflictingFields, conflictingFields));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(localValue),
      const DeepCollectionEquality().hash(remoteValue),
      localTimestamp,
      remoteTimestamp,
      const DeepCollectionEquality().hash(conflictingFields));

  @override
  String toString() {
    return 'ConflictDetails<$T>(localValue: $localValue, remoteValue: $remoteValue, localTimestamp: $localTimestamp, remoteTimestamp: $remoteTimestamp, conflictingFields: $conflictingFields)';
  }
}

/// @nodoc
abstract mixin class $ConflictDetailsCopyWith<T, $Res> {
  factory $ConflictDetailsCopyWith(
          ConflictDetails<T> value, $Res Function(ConflictDetails<T>) _then) =
      _$ConflictDetailsCopyWithImpl;
  @useResult
  $Res call(
      {T localValue,
      T remoteValue,
      DateTime localTimestamp,
      DateTime remoteTimestamp,
      Set<String>? conflictingFields});
}

/// @nodoc
class _$ConflictDetailsCopyWithImpl<T, $Res>
    implements $ConflictDetailsCopyWith<T, $Res> {
  _$ConflictDetailsCopyWithImpl(this._self, this._then);

  final ConflictDetails<T> _self;
  final $Res Function(ConflictDetails<T>) _then;

  /// Create a copy of ConflictDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? localValue = freezed,
    Object? remoteValue = freezed,
    Object? localTimestamp = null,
    Object? remoteTimestamp = null,
    Object? conflictingFields = freezed,
  }) {
    return _then(_self.copyWith(
      localValue: freezed == localValue
          ? _self.localValue
          : localValue // ignore: cast_nullable_to_non_nullable
              as T,
      remoteValue: freezed == remoteValue
          ? _self.remoteValue
          : remoteValue // ignore: cast_nullable_to_non_nullable
              as T,
      localTimestamp: null == localTimestamp
          ? _self.localTimestamp
          : localTimestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      remoteTimestamp: null == remoteTimestamp
          ? _self.remoteTimestamp
          : remoteTimestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      conflictingFields: freezed == conflictingFields
          ? _self.conflictingFields
          : conflictingFields // ignore: cast_nullable_to_non_nullable
              as Set<String>?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ConflictDetails].
extension ConflictDetailsPatterns<T> on ConflictDetails<T> {
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
    TResult Function(_ConflictDetails<T> value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ConflictDetails() when $default != null:
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
    TResult Function(_ConflictDetails<T> value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConflictDetails():
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
    TResult? Function(_ConflictDetails<T> value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConflictDetails() when $default != null:
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
    TResult Function(T localValue, T remoteValue, DateTime localTimestamp,
            DateTime remoteTimestamp, Set<String>? conflictingFields)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ConflictDetails() when $default != null:
        return $default(
            _that.localValue,
            _that.remoteValue,
            _that.localTimestamp,
            _that.remoteTimestamp,
            _that.conflictingFields);
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
    TResult Function(T localValue, T remoteValue, DateTime localTimestamp,
            DateTime remoteTimestamp, Set<String>? conflictingFields)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConflictDetails():
        return $default(
            _that.localValue,
            _that.remoteValue,
            _that.localTimestamp,
            _that.remoteTimestamp,
            _that.conflictingFields);
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
    TResult? Function(T localValue, T remoteValue, DateTime localTimestamp,
            DateTime remoteTimestamp, Set<String>? conflictingFields)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConflictDetails() when $default != null:
        return $default(
            _that.localValue,
            _that.remoteValue,
            _that.localTimestamp,
            _that.remoteTimestamp,
            _that.conflictingFields);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ConflictDetails<T> extends ConflictDetails<T> {
  const _ConflictDetails(
      {required this.localValue,
      required this.remoteValue,
      required this.localTimestamp,
      required this.remoteTimestamp,
      final Set<String>? conflictingFields})
      : _conflictingFields = conflictingFields,
        super._();

  /// The local version of the entity.
  @override
  final T localValue;

  /// The remote version of the entity.
  @override
  final T remoteValue;

  /// When the local version was last modified.
  @override
  final DateTime localTimestamp;

  /// When the remote version was last modified.
  @override
  final DateTime remoteTimestamp;

  /// The set of field names that have conflicting values.
  ///
  /// If null, the specific conflicting fields are not known.
  final Set<String>? _conflictingFields;

  /// The set of field names that have conflicting values.
  ///
  /// If null, the specific conflicting fields are not known.
  @override
  Set<String>? get conflictingFields {
    final value = _conflictingFields;
    if (value == null) return null;
    if (_conflictingFields is EqualUnmodifiableSetView)
      return _conflictingFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(value);
  }

  /// Create a copy of ConflictDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ConflictDetailsCopyWith<T, _ConflictDetails<T>> get copyWith =>
      __$ConflictDetailsCopyWithImpl<T, _ConflictDetails<T>>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ConflictDetails<T> &&
            const DeepCollectionEquality()
                .equals(other.localValue, localValue) &&
            const DeepCollectionEquality()
                .equals(other.remoteValue, remoteValue) &&
            (identical(other.localTimestamp, localTimestamp) ||
                other.localTimestamp == localTimestamp) &&
            (identical(other.remoteTimestamp, remoteTimestamp) ||
                other.remoteTimestamp == remoteTimestamp) &&
            const DeepCollectionEquality()
                .equals(other._conflictingFields, _conflictingFields));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(localValue),
      const DeepCollectionEquality().hash(remoteValue),
      localTimestamp,
      remoteTimestamp,
      const DeepCollectionEquality().hash(_conflictingFields));

  @override
  String toString() {
    return 'ConflictDetails<$T>(localValue: $localValue, remoteValue: $remoteValue, localTimestamp: $localTimestamp, remoteTimestamp: $remoteTimestamp, conflictingFields: $conflictingFields)';
  }
}

/// @nodoc
abstract mixin class _$ConflictDetailsCopyWith<T, $Res>
    implements $ConflictDetailsCopyWith<T, $Res> {
  factory _$ConflictDetailsCopyWith(
          _ConflictDetails<T> value, $Res Function(_ConflictDetails<T>) _then) =
      __$ConflictDetailsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {T localValue,
      T remoteValue,
      DateTime localTimestamp,
      DateTime remoteTimestamp,
      Set<String>? conflictingFields});
}

/// @nodoc
class __$ConflictDetailsCopyWithImpl<T, $Res>
    implements _$ConflictDetailsCopyWith<T, $Res> {
  __$ConflictDetailsCopyWithImpl(this._self, this._then);

  final _ConflictDetails<T> _self;
  final $Res Function(_ConflictDetails<T>) _then;

  /// Create a copy of ConflictDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? localValue = freezed,
    Object? remoteValue = freezed,
    Object? localTimestamp = null,
    Object? remoteTimestamp = null,
    Object? conflictingFields = freezed,
  }) {
    return _then(_ConflictDetails<T>(
      localValue: freezed == localValue
          ? _self.localValue
          : localValue // ignore: cast_nullable_to_non_nullable
              as T,
      remoteValue: freezed == remoteValue
          ? _self.remoteValue
          : remoteValue // ignore: cast_nullable_to_non_nullable
              as T,
      localTimestamp: null == localTimestamp
          ? _self.localTimestamp
          : localTimestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      remoteTimestamp: null == remoteTimestamp
          ? _self.remoteTimestamp
          : remoteTimestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      conflictingFields: freezed == conflictingFields
          ? _self._conflictingFields
          : conflictingFields // ignore: cast_nullable_to_non_nullable
              as Set<String>?,
    ));
  }
}

// dart format on
