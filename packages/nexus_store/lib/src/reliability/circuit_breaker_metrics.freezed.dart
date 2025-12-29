// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'circuit_breaker_metrics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CircuitBreakerMetrics {
  /// Current state of the circuit breaker.
  CircuitBreakerState get state;

  /// Number of failures recorded in the current window.
  int get failureCount;

  /// Number of successes recorded in the current window.
  int get successCount;

  /// Total number of requests processed.
  int get totalRequests;

  /// Number of requests rejected due to open circuit.
  int get rejectedRequests;

  /// Timestamp when this snapshot was taken.
  DateTime get timestamp;

  /// Time of the last recorded failure, if any.
  DateTime? get lastFailureTime;

  /// Time of the last state transition, if any.
  DateTime? get lastStateChange;

  /// Create a copy of CircuitBreakerMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CircuitBreakerMetricsCopyWith<CircuitBreakerMetrics> get copyWith =>
      _$CircuitBreakerMetricsCopyWithImpl<CircuitBreakerMetrics>(
          this as CircuitBreakerMetrics, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CircuitBreakerMetrics &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.failureCount, failureCount) ||
                other.failureCount == failureCount) &&
            (identical(other.successCount, successCount) ||
                other.successCount == successCount) &&
            (identical(other.totalRequests, totalRequests) ||
                other.totalRequests == totalRequests) &&
            (identical(other.rejectedRequests, rejectedRequests) ||
                other.rejectedRequests == rejectedRequests) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.lastFailureTime, lastFailureTime) ||
                other.lastFailureTime == lastFailureTime) &&
            (identical(other.lastStateChange, lastStateChange) ||
                other.lastStateChange == lastStateChange));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      state,
      failureCount,
      successCount,
      totalRequests,
      rejectedRequests,
      timestamp,
      lastFailureTime,
      lastStateChange);

  @override
  String toString() {
    return 'CircuitBreakerMetrics(state: $state, failureCount: $failureCount, successCount: $successCount, totalRequests: $totalRequests, rejectedRequests: $rejectedRequests, timestamp: $timestamp, lastFailureTime: $lastFailureTime, lastStateChange: $lastStateChange)';
  }
}

/// @nodoc
abstract mixin class $CircuitBreakerMetricsCopyWith<$Res> {
  factory $CircuitBreakerMetricsCopyWith(CircuitBreakerMetrics value,
          $Res Function(CircuitBreakerMetrics) _then) =
      _$CircuitBreakerMetricsCopyWithImpl;
  @useResult
  $Res call(
      {CircuitBreakerState state,
      int failureCount,
      int successCount,
      int totalRequests,
      int rejectedRequests,
      DateTime timestamp,
      DateTime? lastFailureTime,
      DateTime? lastStateChange});
}

/// @nodoc
class _$CircuitBreakerMetricsCopyWithImpl<$Res>
    implements $CircuitBreakerMetricsCopyWith<$Res> {
  _$CircuitBreakerMetricsCopyWithImpl(this._self, this._then);

  final CircuitBreakerMetrics _self;
  final $Res Function(CircuitBreakerMetrics) _then;

  /// Create a copy of CircuitBreakerMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
    Object? failureCount = null,
    Object? successCount = null,
    Object? totalRequests = null,
    Object? rejectedRequests = null,
    Object? timestamp = null,
    Object? lastFailureTime = freezed,
    Object? lastStateChange = freezed,
  }) {
    return _then(_self.copyWith(
      state: null == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as CircuitBreakerState,
      failureCount: null == failureCount
          ? _self.failureCount
          : failureCount // ignore: cast_nullable_to_non_nullable
              as int,
      successCount: null == successCount
          ? _self.successCount
          : successCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalRequests: null == totalRequests
          ? _self.totalRequests
          : totalRequests // ignore: cast_nullable_to_non_nullable
              as int,
      rejectedRequests: null == rejectedRequests
          ? _self.rejectedRequests
          : rejectedRequests // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastFailureTime: freezed == lastFailureTime
          ? _self.lastFailureTime
          : lastFailureTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastStateChange: freezed == lastStateChange
          ? _self.lastStateChange
          : lastStateChange // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [CircuitBreakerMetrics].
extension CircuitBreakerMetricsPatterns on CircuitBreakerMetrics {
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
    TResult Function(_CircuitBreakerMetrics value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CircuitBreakerMetrics() when $default != null:
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
    TResult Function(_CircuitBreakerMetrics value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CircuitBreakerMetrics():
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
    TResult? Function(_CircuitBreakerMetrics value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CircuitBreakerMetrics() when $default != null:
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
            CircuitBreakerState state,
            int failureCount,
            int successCount,
            int totalRequests,
            int rejectedRequests,
            DateTime timestamp,
            DateTime? lastFailureTime,
            DateTime? lastStateChange)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CircuitBreakerMetrics() when $default != null:
        return $default(
            _that.state,
            _that.failureCount,
            _that.successCount,
            _that.totalRequests,
            _that.rejectedRequests,
            _that.timestamp,
            _that.lastFailureTime,
            _that.lastStateChange);
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
            CircuitBreakerState state,
            int failureCount,
            int successCount,
            int totalRequests,
            int rejectedRequests,
            DateTime timestamp,
            DateTime? lastFailureTime,
            DateTime? lastStateChange)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CircuitBreakerMetrics():
        return $default(
            _that.state,
            _that.failureCount,
            _that.successCount,
            _that.totalRequests,
            _that.rejectedRequests,
            _that.timestamp,
            _that.lastFailureTime,
            _that.lastStateChange);
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
            CircuitBreakerState state,
            int failureCount,
            int successCount,
            int totalRequests,
            int rejectedRequests,
            DateTime timestamp,
            DateTime? lastFailureTime,
            DateTime? lastStateChange)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CircuitBreakerMetrics() when $default != null:
        return $default(
            _that.state,
            _that.failureCount,
            _that.successCount,
            _that.totalRequests,
            _that.rejectedRequests,
            _that.timestamp,
            _that.lastFailureTime,
            _that.lastStateChange);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _CircuitBreakerMetrics extends CircuitBreakerMetrics {
  const _CircuitBreakerMetrics(
      {required this.state,
      required this.failureCount,
      required this.successCount,
      required this.totalRequests,
      required this.rejectedRequests,
      required this.timestamp,
      this.lastFailureTime,
      this.lastStateChange})
      : super._();

  /// Current state of the circuit breaker.
  @override
  final CircuitBreakerState state;

  /// Number of failures recorded in the current window.
  @override
  final int failureCount;

  /// Number of successes recorded in the current window.
  @override
  final int successCount;

  /// Total number of requests processed.
  @override
  final int totalRequests;

  /// Number of requests rejected due to open circuit.
  @override
  final int rejectedRequests;

  /// Timestamp when this snapshot was taken.
  @override
  final DateTime timestamp;

  /// Time of the last recorded failure, if any.
  @override
  final DateTime? lastFailureTime;

  /// Time of the last state transition, if any.
  @override
  final DateTime? lastStateChange;

  /// Create a copy of CircuitBreakerMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CircuitBreakerMetricsCopyWith<_CircuitBreakerMetrics> get copyWith =>
      __$CircuitBreakerMetricsCopyWithImpl<_CircuitBreakerMetrics>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CircuitBreakerMetrics &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.failureCount, failureCount) ||
                other.failureCount == failureCount) &&
            (identical(other.successCount, successCount) ||
                other.successCount == successCount) &&
            (identical(other.totalRequests, totalRequests) ||
                other.totalRequests == totalRequests) &&
            (identical(other.rejectedRequests, rejectedRequests) ||
                other.rejectedRequests == rejectedRequests) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.lastFailureTime, lastFailureTime) ||
                other.lastFailureTime == lastFailureTime) &&
            (identical(other.lastStateChange, lastStateChange) ||
                other.lastStateChange == lastStateChange));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      state,
      failureCount,
      successCount,
      totalRequests,
      rejectedRequests,
      timestamp,
      lastFailureTime,
      lastStateChange);

  @override
  String toString() {
    return 'CircuitBreakerMetrics(state: $state, failureCount: $failureCount, successCount: $successCount, totalRequests: $totalRequests, rejectedRequests: $rejectedRequests, timestamp: $timestamp, lastFailureTime: $lastFailureTime, lastStateChange: $lastStateChange)';
  }
}

/// @nodoc
abstract mixin class _$CircuitBreakerMetricsCopyWith<$Res>
    implements $CircuitBreakerMetricsCopyWith<$Res> {
  factory _$CircuitBreakerMetricsCopyWith(_CircuitBreakerMetrics value,
          $Res Function(_CircuitBreakerMetrics) _then) =
      __$CircuitBreakerMetricsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {CircuitBreakerState state,
      int failureCount,
      int successCount,
      int totalRequests,
      int rejectedRequests,
      DateTime timestamp,
      DateTime? lastFailureTime,
      DateTime? lastStateChange});
}

/// @nodoc
class __$CircuitBreakerMetricsCopyWithImpl<$Res>
    implements _$CircuitBreakerMetricsCopyWith<$Res> {
  __$CircuitBreakerMetricsCopyWithImpl(this._self, this._then);

  final _CircuitBreakerMetrics _self;
  final $Res Function(_CircuitBreakerMetrics) _then;

  /// Create a copy of CircuitBreakerMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? state = null,
    Object? failureCount = null,
    Object? successCount = null,
    Object? totalRequests = null,
    Object? rejectedRequests = null,
    Object? timestamp = null,
    Object? lastFailureTime = freezed,
    Object? lastStateChange = freezed,
  }) {
    return _then(_CircuitBreakerMetrics(
      state: null == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as CircuitBreakerState,
      failureCount: null == failureCount
          ? _self.failureCount
          : failureCount // ignore: cast_nullable_to_non_nullable
              as int,
      successCount: null == successCount
          ? _self.successCount
          : successCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalRequests: null == totalRequests
          ? _self.totalRequests
          : totalRequests // ignore: cast_nullable_to_non_nullable
              as int,
      rejectedRequests: null == rejectedRequests
          ? _self.rejectedRequests
          : rejectedRequests // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastFailureTime: freezed == lastFailureTime
          ? _self.lastFailureTime
          : lastFailureTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastStateChange: freezed == lastStateChange
          ? _self.lastStateChange
          : lastStateChange // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
