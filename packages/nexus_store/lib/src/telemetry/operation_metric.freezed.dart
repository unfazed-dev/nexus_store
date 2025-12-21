// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'operation_metric.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OperationMetric {
  /// The type of operation performed.
  OperationType get operation;

  /// Duration of the operation.
  Duration get duration;

  /// Whether the operation succeeded.
  bool get success;

  /// Number of items affected by the operation.
  int get itemCount;

  /// The fetch/write policy used (if applicable).
  String? get policy;

  /// When the metric was recorded.
  DateTime get timestamp;

  /// Optional error message if operation failed.
  String? get errorMessage;

  /// Create a copy of OperationMetric
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $OperationMetricCopyWith<OperationMetric> get copyWith =>
      _$OperationMetricCopyWithImpl<OperationMetric>(
          this as OperationMetric, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is OperationMetric &&
            (identical(other.operation, operation) ||
                other.operation == operation) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.itemCount, itemCount) ||
                other.itemCount == itemCount) &&
            (identical(other.policy, policy) || other.policy == policy) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(runtimeType, operation, duration, success,
      itemCount, policy, timestamp, errorMessage);

  @override
  String toString() {
    return 'OperationMetric(operation: $operation, duration: $duration, success: $success, itemCount: $itemCount, policy: $policy, timestamp: $timestamp, errorMessage: $errorMessage)';
  }
}

/// @nodoc
abstract mixin class $OperationMetricCopyWith<$Res> {
  factory $OperationMetricCopyWith(
          OperationMetric value, $Res Function(OperationMetric) _then) =
      _$OperationMetricCopyWithImpl;
  @useResult
  $Res call(
      {OperationType operation,
      Duration duration,
      bool success,
      int itemCount,
      String? policy,
      DateTime timestamp,
      String? errorMessage});
}

/// @nodoc
class _$OperationMetricCopyWithImpl<$Res>
    implements $OperationMetricCopyWith<$Res> {
  _$OperationMetricCopyWithImpl(this._self, this._then);

  final OperationMetric _self;
  final $Res Function(OperationMetric) _then;

  /// Create a copy of OperationMetric
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? operation = null,
    Object? duration = null,
    Object? success = null,
    Object? itemCount = null,
    Object? policy = freezed,
    Object? timestamp = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_self.copyWith(
      operation: null == operation
          ? _self.operation
          : operation // ignore: cast_nullable_to_non_nullable
              as OperationType,
      duration: null == duration
          ? _self.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as Duration,
      success: null == success
          ? _self.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      itemCount: null == itemCount
          ? _self.itemCount
          : itemCount // ignore: cast_nullable_to_non_nullable
              as int,
      policy: freezed == policy
          ? _self.policy
          : policy // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      errorMessage: freezed == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [OperationMetric].
extension OperationMetricPatterns on OperationMetric {
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
    TResult Function(_OperationMetric value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _OperationMetric() when $default != null:
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
    TResult Function(_OperationMetric value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OperationMetric():
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
    TResult? Function(_OperationMetric value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OperationMetric() when $default != null:
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
            OperationType operation,
            Duration duration,
            bool success,
            int itemCount,
            String? policy,
            DateTime timestamp,
            String? errorMessage)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _OperationMetric() when $default != null:
        return $default(_that.operation, _that.duration, _that.success,
            _that.itemCount, _that.policy, _that.timestamp, _that.errorMessage);
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
            OperationType operation,
            Duration duration,
            bool success,
            int itemCount,
            String? policy,
            DateTime timestamp,
            String? errorMessage)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OperationMetric():
        return $default(_that.operation, _that.duration, _that.success,
            _that.itemCount, _that.policy, _that.timestamp, _that.errorMessage);
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
            OperationType operation,
            Duration duration,
            bool success,
            int itemCount,
            String? policy,
            DateTime timestamp,
            String? errorMessage)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OperationMetric() when $default != null:
        return $default(_that.operation, _that.duration, _that.success,
            _that.itemCount, _that.policy, _that.timestamp, _that.errorMessage);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _OperationMetric extends OperationMetric {
  const _OperationMetric(
      {required this.operation,
      required this.duration,
      required this.success,
      this.itemCount = 1,
      this.policy,
      required this.timestamp,
      this.errorMessage})
      : super._();

  /// The type of operation performed.
  @override
  final OperationType operation;

  /// Duration of the operation.
  @override
  final Duration duration;

  /// Whether the operation succeeded.
  @override
  final bool success;

  /// Number of items affected by the operation.
  @override
  @JsonKey()
  final int itemCount;

  /// The fetch/write policy used (if applicable).
  @override
  final String? policy;

  /// When the metric was recorded.
  @override
  final DateTime timestamp;

  /// Optional error message if operation failed.
  @override
  final String? errorMessage;

  /// Create a copy of OperationMetric
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$OperationMetricCopyWith<_OperationMetric> get copyWith =>
      __$OperationMetricCopyWithImpl<_OperationMetric>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _OperationMetric &&
            (identical(other.operation, operation) ||
                other.operation == operation) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.itemCount, itemCount) ||
                other.itemCount == itemCount) &&
            (identical(other.policy, policy) || other.policy == policy) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(runtimeType, operation, duration, success,
      itemCount, policy, timestamp, errorMessage);

  @override
  String toString() {
    return 'OperationMetric(operation: $operation, duration: $duration, success: $success, itemCount: $itemCount, policy: $policy, timestamp: $timestamp, errorMessage: $errorMessage)';
  }
}

/// @nodoc
abstract mixin class _$OperationMetricCopyWith<$Res>
    implements $OperationMetricCopyWith<$Res> {
  factory _$OperationMetricCopyWith(
          _OperationMetric value, $Res Function(_OperationMetric) _then) =
      __$OperationMetricCopyWithImpl;
  @override
  @useResult
  $Res call(
      {OperationType operation,
      Duration duration,
      bool success,
      int itemCount,
      String? policy,
      DateTime timestamp,
      String? errorMessage});
}

/// @nodoc
class __$OperationMetricCopyWithImpl<$Res>
    implements _$OperationMetricCopyWith<$Res> {
  __$OperationMetricCopyWithImpl(this._self, this._then);

  final _OperationMetric _self;
  final $Res Function(_OperationMetric) _then;

  /// Create a copy of OperationMetric
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? operation = null,
    Object? duration = null,
    Object? success = null,
    Object? itemCount = null,
    Object? policy = freezed,
    Object? timestamp = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_OperationMetric(
      operation: null == operation
          ? _self.operation
          : operation // ignore: cast_nullable_to_non_nullable
              as OperationType,
      duration: null == duration
          ? _self.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as Duration,
      success: null == success
          ? _self.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      itemCount: null == itemCount
          ? _self.itemCount
          : itemCount // ignore: cast_nullable_to_non_nullable
              as int,
      policy: freezed == policy
          ? _self.policy
          : policy // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      errorMessage: freezed == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
