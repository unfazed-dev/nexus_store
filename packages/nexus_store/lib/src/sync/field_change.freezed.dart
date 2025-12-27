// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'field_change.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FieldChange {
  /// The name of the field that changed.
  String get fieldName;

  /// The previous value of the field (null if field was added).
  dynamic get oldValue;

  /// The new value of the field (null if field was removed).
  dynamic get newValue;

  /// When the change was detected.
  DateTime get timestamp;

  /// Create a copy of FieldChange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FieldChangeCopyWith<FieldChange> get copyWith =>
      _$FieldChangeCopyWithImpl<FieldChange>(this as FieldChange, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FieldChange &&
            (identical(other.fieldName, fieldName) ||
                other.fieldName == fieldName) &&
            const DeepCollectionEquality().equals(other.oldValue, oldValue) &&
            const DeepCollectionEquality().equals(other.newValue, newValue) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      fieldName,
      const DeepCollectionEquality().hash(oldValue),
      const DeepCollectionEquality().hash(newValue),
      timestamp);

  @override
  String toString() {
    return 'FieldChange(fieldName: $fieldName, oldValue: $oldValue, newValue: $newValue, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class $FieldChangeCopyWith<$Res> {
  factory $FieldChangeCopyWith(
          FieldChange value, $Res Function(FieldChange) _then) =
      _$FieldChangeCopyWithImpl;
  @useResult
  $Res call(
      {String fieldName,
      dynamic oldValue,
      dynamic newValue,
      DateTime timestamp});
}

/// @nodoc
class _$FieldChangeCopyWithImpl<$Res> implements $FieldChangeCopyWith<$Res> {
  _$FieldChangeCopyWithImpl(this._self, this._then);

  final FieldChange _self;
  final $Res Function(FieldChange) _then;

  /// Create a copy of FieldChange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fieldName = null,
    Object? oldValue = freezed,
    Object? newValue = freezed,
    Object? timestamp = null,
  }) {
    return _then(_self.copyWith(
      fieldName: null == fieldName
          ? _self.fieldName
          : fieldName // ignore: cast_nullable_to_non_nullable
              as String,
      oldValue: freezed == oldValue
          ? _self.oldValue
          : oldValue // ignore: cast_nullable_to_non_nullable
              as dynamic,
      newValue: freezed == newValue
          ? _self.newValue
          : newValue // ignore: cast_nullable_to_non_nullable
              as dynamic,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [FieldChange].
extension FieldChangePatterns on FieldChange {
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
    TResult Function(_FieldChange value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FieldChange() when $default != null:
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
    TResult Function(_FieldChange value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FieldChange():
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
    TResult? Function(_FieldChange value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FieldChange() when $default != null:
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
    TResult Function(String fieldName, dynamic oldValue, dynamic newValue,
            DateTime timestamp)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FieldChange() when $default != null:
        return $default(
            _that.fieldName, _that.oldValue, _that.newValue, _that.timestamp);
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
    TResult Function(String fieldName, dynamic oldValue, dynamic newValue,
            DateTime timestamp)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FieldChange():
        return $default(
            _that.fieldName, _that.oldValue, _that.newValue, _that.timestamp);
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
    TResult? Function(String fieldName, dynamic oldValue, dynamic newValue,
            DateTime timestamp)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FieldChange() when $default != null:
        return $default(
            _that.fieldName, _that.oldValue, _that.newValue, _that.timestamp);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _FieldChange extends FieldChange {
  const _FieldChange(
      {required this.fieldName,
      required this.oldValue,
      required this.newValue,
      required this.timestamp})
      : super._();

  /// The name of the field that changed.
  @override
  final String fieldName;

  /// The previous value of the field (null if field was added).
  @override
  final dynamic oldValue;

  /// The new value of the field (null if field was removed).
  @override
  final dynamic newValue;

  /// When the change was detected.
  @override
  final DateTime timestamp;

  /// Create a copy of FieldChange
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FieldChangeCopyWith<_FieldChange> get copyWith =>
      __$FieldChangeCopyWithImpl<_FieldChange>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FieldChange &&
            (identical(other.fieldName, fieldName) ||
                other.fieldName == fieldName) &&
            const DeepCollectionEquality().equals(other.oldValue, oldValue) &&
            const DeepCollectionEquality().equals(other.newValue, newValue) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      fieldName,
      const DeepCollectionEquality().hash(oldValue),
      const DeepCollectionEquality().hash(newValue),
      timestamp);

  @override
  String toString() {
    return 'FieldChange(fieldName: $fieldName, oldValue: $oldValue, newValue: $newValue, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class _$FieldChangeCopyWith<$Res>
    implements $FieldChangeCopyWith<$Res> {
  factory _$FieldChangeCopyWith(
          _FieldChange value, $Res Function(_FieldChange) _then) =
      __$FieldChangeCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String fieldName,
      dynamic oldValue,
      dynamic newValue,
      DateTime timestamp});
}

/// @nodoc
class __$FieldChangeCopyWithImpl<$Res> implements _$FieldChangeCopyWith<$Res> {
  __$FieldChangeCopyWithImpl(this._self, this._then);

  final _FieldChange _self;
  final $Res Function(_FieldChange) _then;

  /// Create a copy of FieldChange
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? fieldName = null,
    Object? oldValue = freezed,
    Object? newValue = freezed,
    Object? timestamp = null,
  }) {
    return _then(_FieldChange(
      fieldName: null == fieldName
          ? _self.fieldName
          : fieldName // ignore: cast_nullable_to_non_nullable
              as String,
      oldValue: freezed == oldValue
          ? _self.oldValue
          : oldValue // ignore: cast_nullable_to_non_nullable
              as dynamic,
      newValue: freezed == newValue
          ? _self.newValue
          : newValue // ignore: cast_nullable_to_non_nullable
              as dynamic,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
