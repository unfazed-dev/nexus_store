// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delta_change.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeltaChange<ID> {
  /// The unique identifier of the entity that changed.
  ID get entityId;

  /// List of individual field changes.
  List<FieldChange> get changes;

  /// When this delta was created.
  DateTime get timestamp;

  /// The base version of the entity before changes.
  ///
  /// Used for optimistic concurrency control. When applying a delta,
  /// the current version must match this base version.
  int? get baseVersion;

  /// Create a copy of DeltaChange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DeltaChangeCopyWith<ID, DeltaChange<ID>> get copyWith =>
      _$DeltaChangeCopyWithImpl<ID, DeltaChange<ID>>(
          this as DeltaChange<ID>, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DeltaChange<ID> &&
            const DeepCollectionEquality().equals(other.entityId, entityId) &&
            const DeepCollectionEquality().equals(other.changes, changes) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.baseVersion, baseVersion) ||
                other.baseVersion == baseVersion));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(entityId),
      const DeepCollectionEquality().hash(changes),
      timestamp,
      baseVersion);

  @override
  String toString() {
    return 'DeltaChange<$ID>(entityId: $entityId, changes: $changes, timestamp: $timestamp, baseVersion: $baseVersion)';
  }
}

/// @nodoc
abstract mixin class $DeltaChangeCopyWith<ID, $Res> {
  factory $DeltaChangeCopyWith(
          DeltaChange<ID> value, $Res Function(DeltaChange<ID>) _then) =
      _$DeltaChangeCopyWithImpl;
  @useResult
  $Res call(
      {ID entityId,
      List<FieldChange> changes,
      DateTime timestamp,
      int? baseVersion});
}

/// @nodoc
class _$DeltaChangeCopyWithImpl<ID, $Res>
    implements $DeltaChangeCopyWith<ID, $Res> {
  _$DeltaChangeCopyWithImpl(this._self, this._then);

  final DeltaChange<ID> _self;
  final $Res Function(DeltaChange<ID>) _then;

  /// Create a copy of DeltaChange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? entityId = freezed,
    Object? changes = null,
    Object? timestamp = null,
    Object? baseVersion = freezed,
  }) {
    return _then(_self.copyWith(
      entityId: freezed == entityId
          ? _self.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as ID,
      changes: null == changes
          ? _self.changes
          : changes // ignore: cast_nullable_to_non_nullable
              as List<FieldChange>,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      baseVersion: freezed == baseVersion
          ? _self.baseVersion
          : baseVersion // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [DeltaChange].
extension DeltaChangePatterns<ID> on DeltaChange<ID> {
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
    TResult Function(_DeltaChange<ID> value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DeltaChange() when $default != null:
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
    TResult Function(_DeltaChange<ID> value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DeltaChange():
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
    TResult? Function(_DeltaChange<ID> value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DeltaChange() when $default != null:
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
    TResult Function(ID entityId, List<FieldChange> changes, DateTime timestamp,
            int? baseVersion)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DeltaChange() when $default != null:
        return $default(
            _that.entityId, _that.changes, _that.timestamp, _that.baseVersion);
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
    TResult Function(ID entityId, List<FieldChange> changes, DateTime timestamp,
            int? baseVersion)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DeltaChange():
        return $default(
            _that.entityId, _that.changes, _that.timestamp, _that.baseVersion);
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
    TResult? Function(ID entityId, List<FieldChange> changes,
            DateTime timestamp, int? baseVersion)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DeltaChange() when $default != null:
        return $default(
            _that.entityId, _that.changes, _that.timestamp, _that.baseVersion);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _DeltaChange<ID> extends DeltaChange<ID> {
  const _DeltaChange(
      {required this.entityId,
      required final List<FieldChange> changes,
      required this.timestamp,
      this.baseVersion})
      : _changes = changes,
        super._();

  /// The unique identifier of the entity that changed.
  @override
  final ID entityId;

  /// List of individual field changes.
  final List<FieldChange> _changes;

  /// List of individual field changes.
  @override
  List<FieldChange> get changes {
    if (_changes is EqualUnmodifiableListView) return _changes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_changes);
  }

  /// When this delta was created.
  @override
  final DateTime timestamp;

  /// The base version of the entity before changes.
  ///
  /// Used for optimistic concurrency control. When applying a delta,
  /// the current version must match this base version.
  @override
  final int? baseVersion;

  /// Create a copy of DeltaChange
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DeltaChangeCopyWith<ID, _DeltaChange<ID>> get copyWith =>
      __$DeltaChangeCopyWithImpl<ID, _DeltaChange<ID>>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DeltaChange<ID> &&
            const DeepCollectionEquality().equals(other.entityId, entityId) &&
            const DeepCollectionEquality().equals(other._changes, _changes) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.baseVersion, baseVersion) ||
                other.baseVersion == baseVersion));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(entityId),
      const DeepCollectionEquality().hash(_changes),
      timestamp,
      baseVersion);

  @override
  String toString() {
    return 'DeltaChange<$ID>(entityId: $entityId, changes: $changes, timestamp: $timestamp, baseVersion: $baseVersion)';
  }
}

/// @nodoc
abstract mixin class _$DeltaChangeCopyWith<ID, $Res>
    implements $DeltaChangeCopyWith<ID, $Res> {
  factory _$DeltaChangeCopyWith(
          _DeltaChange<ID> value, $Res Function(_DeltaChange<ID>) _then) =
      __$DeltaChangeCopyWithImpl;
  @override
  @useResult
  $Res call(
      {ID entityId,
      List<FieldChange> changes,
      DateTime timestamp,
      int? baseVersion});
}

/// @nodoc
class __$DeltaChangeCopyWithImpl<ID, $Res>
    implements _$DeltaChangeCopyWith<ID, $Res> {
  __$DeltaChangeCopyWithImpl(this._self, this._then);

  final _DeltaChange<ID> _self;
  final $Res Function(_DeltaChange<ID>) _then;

  /// Create a copy of DeltaChange
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? entityId = freezed,
    Object? changes = null,
    Object? timestamp = null,
    Object? baseVersion = freezed,
  }) {
    return _then(_DeltaChange<ID>(
      entityId: freezed == entityId
          ? _self.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as ID,
      changes: null == changes
          ? _self._changes
          : changes // ignore: cast_nullable_to_non_nullable
              as List<FieldChange>,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      baseVersion: freezed == baseVersion
          ? _self.baseVersion
          : baseVersion // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
