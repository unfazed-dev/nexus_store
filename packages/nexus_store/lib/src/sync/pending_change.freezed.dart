// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_change.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PendingChange<T> {
  /// Unique identifier for this pending change.
  String get id;

  /// The entity being changed.
  T get item;

  /// The type of operation (create, update, delete).
  PendingChangeOperation get operation;

  /// When this change was first queued.
  DateTime get createdAt;

  /// The original value before the change (for undo support).
  ///
  /// For create operations, this is null.
  /// For update operations, this is the value before the update.
  /// For delete operations, this is the deleted entity.
  T? get originalValue;

  /// Number of retry attempts.
  int get retryCount;

  /// The last error that occurred during sync, if any.
  Object? get lastError;

  /// When the last sync attempt was made.
  DateTime? get lastAttempt;

  /// Create a copy of PendingChange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PendingChangeCopyWith<T, PendingChange<T>> get copyWith =>
      _$PendingChangeCopyWithImpl<T, PendingChange<T>>(
          this as PendingChange<T>, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PendingChange<T> &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other.item, item) &&
            (identical(other.operation, operation) ||
                other.operation == operation) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality()
                .equals(other.originalValue, originalValue) &&
            (identical(other.retryCount, retryCount) ||
                other.retryCount == retryCount) &&
            const DeepCollectionEquality().equals(other.lastError, lastError) &&
            (identical(other.lastAttempt, lastAttempt) ||
                other.lastAttempt == lastAttempt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      const DeepCollectionEquality().hash(item),
      operation,
      createdAt,
      const DeepCollectionEquality().hash(originalValue),
      retryCount,
      const DeepCollectionEquality().hash(lastError),
      lastAttempt);

  @override
  String toString() {
    return 'PendingChange<$T>(id: $id, item: $item, operation: $operation, createdAt: $createdAt, originalValue: $originalValue, retryCount: $retryCount, lastError: $lastError, lastAttempt: $lastAttempt)';
  }
}

/// @nodoc
abstract mixin class $PendingChangeCopyWith<T, $Res> {
  factory $PendingChangeCopyWith(
          PendingChange<T> value, $Res Function(PendingChange<T>) _then) =
      _$PendingChangeCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      T item,
      PendingChangeOperation operation,
      DateTime createdAt,
      T? originalValue,
      int retryCount,
      Object? lastError,
      DateTime? lastAttempt});
}

/// @nodoc
class _$PendingChangeCopyWithImpl<T, $Res>
    implements $PendingChangeCopyWith<T, $Res> {
  _$PendingChangeCopyWithImpl(this._self, this._then);

  final PendingChange<T> _self;
  final $Res Function(PendingChange<T>) _then;

  /// Create a copy of PendingChange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? item = freezed,
    Object? operation = null,
    Object? createdAt = null,
    Object? originalValue = freezed,
    Object? retryCount = null,
    Object? lastError = freezed,
    Object? lastAttempt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      item: freezed == item
          ? _self.item
          : item // ignore: cast_nullable_to_non_nullable
              as T,
      operation: null == operation
          ? _self.operation
          : operation // ignore: cast_nullable_to_non_nullable
              as PendingChangeOperation,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      originalValue: freezed == originalValue
          ? _self.originalValue
          : originalValue // ignore: cast_nullable_to_non_nullable
              as T?,
      retryCount: null == retryCount
          ? _self.retryCount
          : retryCount // ignore: cast_nullable_to_non_nullable
              as int,
      lastError: freezed == lastError ? _self.lastError : lastError,
      lastAttempt: freezed == lastAttempt
          ? _self.lastAttempt
          : lastAttempt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [PendingChange].
extension PendingChangePatterns<T> on PendingChange<T> {
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
    TResult Function(_PendingChange<T> value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PendingChange() when $default != null:
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
    TResult Function(_PendingChange<T> value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PendingChange():
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
    TResult? Function(_PendingChange<T> value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PendingChange() when $default != null:
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
    TResult Function(
            String id,
            T item,
            PendingChangeOperation operation,
            DateTime createdAt,
            T? originalValue,
            int retryCount,
            Object? lastError,
            DateTime? lastAttempt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PendingChange() when $default != null:
        return $default(
            _that.id,
            _that.item,
            _that.operation,
            _that.createdAt,
            _that.originalValue,
            _that.retryCount,
            _that.lastError,
            _that.lastAttempt);
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
            String id,
            T item,
            PendingChangeOperation operation,
            DateTime createdAt,
            T? originalValue,
            int retryCount,
            Object? lastError,
            DateTime? lastAttempt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PendingChange():
        return $default(
            _that.id,
            _that.item,
            _that.operation,
            _that.createdAt,
            _that.originalValue,
            _that.retryCount,
            _that.lastError,
            _that.lastAttempt);
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
    TResult? Function(
            String id,
            T item,
            PendingChangeOperation operation,
            DateTime createdAt,
            T? originalValue,
            int retryCount,
            Object? lastError,
            DateTime? lastAttempt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PendingChange() when $default != null:
        return $default(
            _that.id,
            _that.item,
            _that.operation,
            _that.createdAt,
            _that.originalValue,
            _that.retryCount,
            _that.lastError,
            _that.lastAttempt);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _PendingChange<T> extends PendingChange<T> {
  const _PendingChange(
      {required this.id,
      required this.item,
      required this.operation,
      required this.createdAt,
      this.originalValue,
      this.retryCount = 0,
      this.lastError,
      this.lastAttempt})
      : super._();

  /// Unique identifier for this pending change.
  @override
  final String id;

  /// The entity being changed.
  @override
  final T item;

  /// The type of operation (create, update, delete).
  @override
  final PendingChangeOperation operation;

  /// When this change was first queued.
  @override
  final DateTime createdAt;

  /// The original value before the change (for undo support).
  ///
  /// For create operations, this is null.
  /// For update operations, this is the value before the update.
  /// For delete operations, this is the deleted entity.
  @override
  final T? originalValue;

  /// Number of retry attempts.
  @override
  @JsonKey()
  final int retryCount;

  /// The last error that occurred during sync, if any.
  @override
  final Object? lastError;

  /// When the last sync attempt was made.
  @override
  final DateTime? lastAttempt;

  /// Create a copy of PendingChange
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PendingChangeCopyWith<T, _PendingChange<T>> get copyWith =>
      __$PendingChangeCopyWithImpl<T, _PendingChange<T>>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PendingChange<T> &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other.item, item) &&
            (identical(other.operation, operation) ||
                other.operation == operation) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality()
                .equals(other.originalValue, originalValue) &&
            (identical(other.retryCount, retryCount) ||
                other.retryCount == retryCount) &&
            const DeepCollectionEquality().equals(other.lastError, lastError) &&
            (identical(other.lastAttempt, lastAttempt) ||
                other.lastAttempt == lastAttempt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      const DeepCollectionEquality().hash(item),
      operation,
      createdAt,
      const DeepCollectionEquality().hash(originalValue),
      retryCount,
      const DeepCollectionEquality().hash(lastError),
      lastAttempt);

  @override
  String toString() {
    return 'PendingChange<$T>(id: $id, item: $item, operation: $operation, createdAt: $createdAt, originalValue: $originalValue, retryCount: $retryCount, lastError: $lastError, lastAttempt: $lastAttempt)';
  }
}

/// @nodoc
abstract mixin class _$PendingChangeCopyWith<T, $Res>
    implements $PendingChangeCopyWith<T, $Res> {
  factory _$PendingChangeCopyWith(
          _PendingChange<T> value, $Res Function(_PendingChange<T>) _then) =
      __$PendingChangeCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      T item,
      PendingChangeOperation operation,
      DateTime createdAt,
      T? originalValue,
      int retryCount,
      Object? lastError,
      DateTime? lastAttempt});
}

/// @nodoc
class __$PendingChangeCopyWithImpl<T, $Res>
    implements _$PendingChangeCopyWith<T, $Res> {
  __$PendingChangeCopyWithImpl(this._self, this._then);

  final _PendingChange<T> _self;
  final $Res Function(_PendingChange<T>) _then;

  /// Create a copy of PendingChange
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? item = freezed,
    Object? operation = null,
    Object? createdAt = null,
    Object? originalValue = freezed,
    Object? retryCount = null,
    Object? lastError = freezed,
    Object? lastAttempt = freezed,
  }) {
    return _then(_PendingChange<T>(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      item: freezed == item
          ? _self.item
          : item // ignore: cast_nullable_to_non_nullable
              as T,
      operation: null == operation
          ? _self.operation
          : operation // ignore: cast_nullable_to_non_nullable
              as PendingChangeOperation,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      originalValue: freezed == originalValue
          ? _self.originalValue
          : originalValue // ignore: cast_nullable_to_non_nullable
              as T?,
      retryCount: null == retryCount
          ? _self.retryCount
          : retryCount // ignore: cast_nullable_to_non_nullable
              as int,
      lastError: freezed == lastError ? _self.lastError : lastError,
      lastAttempt: freezed == lastAttempt
          ? _self.lastAttempt
          : lastAttempt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
