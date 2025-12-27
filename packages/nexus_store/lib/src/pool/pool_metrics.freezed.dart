// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pool_metrics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PoolMetrics {
  /// Total connections in the pool (idle + active).
  int get totalConnections;

  /// Number of idle connections available for borrowing.
  int get idleConnections;

  /// Number of connections currently in use.
  int get activeConnections;

  /// Number of requests waiting for a connection.
  int get waitingRequests;

  /// Average time to acquire a connection.
  Duration get averageAcquireTime;

  /// Peak number of active connections since pool started.
  int get peakActiveConnections;

  /// Total connections created since pool started.
  int get totalConnectionsCreated;

  /// Total connections destroyed since pool started.
  int get totalConnectionsDestroyed;

  /// When these metrics were captured.
  DateTime get timestamp;

  /// Create a copy of PoolMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PoolMetricsCopyWith<PoolMetrics> get copyWith =>
      _$PoolMetricsCopyWithImpl<PoolMetrics>(this as PoolMetrics, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PoolMetrics &&
            (identical(other.totalConnections, totalConnections) ||
                other.totalConnections == totalConnections) &&
            (identical(other.idleConnections, idleConnections) ||
                other.idleConnections == idleConnections) &&
            (identical(other.activeConnections, activeConnections) ||
                other.activeConnections == activeConnections) &&
            (identical(other.waitingRequests, waitingRequests) ||
                other.waitingRequests == waitingRequests) &&
            (identical(other.averageAcquireTime, averageAcquireTime) ||
                other.averageAcquireTime == averageAcquireTime) &&
            (identical(other.peakActiveConnections, peakActiveConnections) ||
                other.peakActiveConnections == peakActiveConnections) &&
            (identical(
                    other.totalConnectionsCreated, totalConnectionsCreated) ||
                other.totalConnectionsCreated == totalConnectionsCreated) &&
            (identical(other.totalConnectionsDestroyed,
                    totalConnectionsDestroyed) ||
                other.totalConnectionsDestroyed == totalConnectionsDestroyed) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      totalConnections,
      idleConnections,
      activeConnections,
      waitingRequests,
      averageAcquireTime,
      peakActiveConnections,
      totalConnectionsCreated,
      totalConnectionsDestroyed,
      timestamp);

  @override
  String toString() {
    return 'PoolMetrics(totalConnections: $totalConnections, idleConnections: $idleConnections, activeConnections: $activeConnections, waitingRequests: $waitingRequests, averageAcquireTime: $averageAcquireTime, peakActiveConnections: $peakActiveConnections, totalConnectionsCreated: $totalConnectionsCreated, totalConnectionsDestroyed: $totalConnectionsDestroyed, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class $PoolMetricsCopyWith<$Res> {
  factory $PoolMetricsCopyWith(
          PoolMetrics value, $Res Function(PoolMetrics) _then) =
      _$PoolMetricsCopyWithImpl;
  @useResult
  $Res call(
      {int totalConnections,
      int idleConnections,
      int activeConnections,
      int waitingRequests,
      Duration averageAcquireTime,
      int peakActiveConnections,
      int totalConnectionsCreated,
      int totalConnectionsDestroyed,
      DateTime timestamp});
}

/// @nodoc
class _$PoolMetricsCopyWithImpl<$Res> implements $PoolMetricsCopyWith<$Res> {
  _$PoolMetricsCopyWithImpl(this._self, this._then);

  final PoolMetrics _self;
  final $Res Function(PoolMetrics) _then;

  /// Create a copy of PoolMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalConnections = null,
    Object? idleConnections = null,
    Object? activeConnections = null,
    Object? waitingRequests = null,
    Object? averageAcquireTime = null,
    Object? peakActiveConnections = null,
    Object? totalConnectionsCreated = null,
    Object? totalConnectionsDestroyed = null,
    Object? timestamp = null,
  }) {
    return _then(_self.copyWith(
      totalConnections: null == totalConnections
          ? _self.totalConnections
          : totalConnections // ignore: cast_nullable_to_non_nullable
              as int,
      idleConnections: null == idleConnections
          ? _self.idleConnections
          : idleConnections // ignore: cast_nullable_to_non_nullable
              as int,
      activeConnections: null == activeConnections
          ? _self.activeConnections
          : activeConnections // ignore: cast_nullable_to_non_nullable
              as int,
      waitingRequests: null == waitingRequests
          ? _self.waitingRequests
          : waitingRequests // ignore: cast_nullable_to_non_nullable
              as int,
      averageAcquireTime: null == averageAcquireTime
          ? _self.averageAcquireTime
          : averageAcquireTime // ignore: cast_nullable_to_non_nullable
              as Duration,
      peakActiveConnections: null == peakActiveConnections
          ? _self.peakActiveConnections
          : peakActiveConnections // ignore: cast_nullable_to_non_nullable
              as int,
      totalConnectionsCreated: null == totalConnectionsCreated
          ? _self.totalConnectionsCreated
          : totalConnectionsCreated // ignore: cast_nullable_to_non_nullable
              as int,
      totalConnectionsDestroyed: null == totalConnectionsDestroyed
          ? _self.totalConnectionsDestroyed
          : totalConnectionsDestroyed // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [PoolMetrics].
extension PoolMetricsPatterns on PoolMetrics {
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
    TResult Function(_PoolMetrics value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PoolMetrics() when $default != null:
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
    TResult Function(_PoolMetrics value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PoolMetrics():
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
    TResult? Function(_PoolMetrics value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PoolMetrics() when $default != null:
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
            int totalConnections,
            int idleConnections,
            int activeConnections,
            int waitingRequests,
            Duration averageAcquireTime,
            int peakActiveConnections,
            int totalConnectionsCreated,
            int totalConnectionsDestroyed,
            DateTime timestamp)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PoolMetrics() when $default != null:
        return $default(
            _that.totalConnections,
            _that.idleConnections,
            _that.activeConnections,
            _that.waitingRequests,
            _that.averageAcquireTime,
            _that.peakActiveConnections,
            _that.totalConnectionsCreated,
            _that.totalConnectionsDestroyed,
            _that.timestamp);
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
            int totalConnections,
            int idleConnections,
            int activeConnections,
            int waitingRequests,
            Duration averageAcquireTime,
            int peakActiveConnections,
            int totalConnectionsCreated,
            int totalConnectionsDestroyed,
            DateTime timestamp)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PoolMetrics():
        return $default(
            _that.totalConnections,
            _that.idleConnections,
            _that.activeConnections,
            _that.waitingRequests,
            _that.averageAcquireTime,
            _that.peakActiveConnections,
            _that.totalConnectionsCreated,
            _that.totalConnectionsDestroyed,
            _that.timestamp);
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
            int totalConnections,
            int idleConnections,
            int activeConnections,
            int waitingRequests,
            Duration averageAcquireTime,
            int peakActiveConnections,
            int totalConnectionsCreated,
            int totalConnectionsDestroyed,
            DateTime timestamp)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PoolMetrics() when $default != null:
        return $default(
            _that.totalConnections,
            _that.idleConnections,
            _that.activeConnections,
            _that.waitingRequests,
            _that.averageAcquireTime,
            _that.peakActiveConnections,
            _that.totalConnectionsCreated,
            _that.totalConnectionsDestroyed,
            _that.timestamp);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _PoolMetrics extends PoolMetrics {
  const _PoolMetrics(
      {required this.totalConnections,
      required this.idleConnections,
      required this.activeConnections,
      required this.waitingRequests,
      required this.averageAcquireTime,
      required this.peakActiveConnections,
      required this.totalConnectionsCreated,
      required this.totalConnectionsDestroyed,
      required this.timestamp})
      : super._();

  /// Total connections in the pool (idle + active).
  @override
  final int totalConnections;

  /// Number of idle connections available for borrowing.
  @override
  final int idleConnections;

  /// Number of connections currently in use.
  @override
  final int activeConnections;

  /// Number of requests waiting for a connection.
  @override
  final int waitingRequests;

  /// Average time to acquire a connection.
  @override
  final Duration averageAcquireTime;

  /// Peak number of active connections since pool started.
  @override
  final int peakActiveConnections;

  /// Total connections created since pool started.
  @override
  final int totalConnectionsCreated;

  /// Total connections destroyed since pool started.
  @override
  final int totalConnectionsDestroyed;

  /// When these metrics were captured.
  @override
  final DateTime timestamp;

  /// Create a copy of PoolMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PoolMetricsCopyWith<_PoolMetrics> get copyWith =>
      __$PoolMetricsCopyWithImpl<_PoolMetrics>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PoolMetrics &&
            (identical(other.totalConnections, totalConnections) ||
                other.totalConnections == totalConnections) &&
            (identical(other.idleConnections, idleConnections) ||
                other.idleConnections == idleConnections) &&
            (identical(other.activeConnections, activeConnections) ||
                other.activeConnections == activeConnections) &&
            (identical(other.waitingRequests, waitingRequests) ||
                other.waitingRequests == waitingRequests) &&
            (identical(other.averageAcquireTime, averageAcquireTime) ||
                other.averageAcquireTime == averageAcquireTime) &&
            (identical(other.peakActiveConnections, peakActiveConnections) ||
                other.peakActiveConnections == peakActiveConnections) &&
            (identical(
                    other.totalConnectionsCreated, totalConnectionsCreated) ||
                other.totalConnectionsCreated == totalConnectionsCreated) &&
            (identical(other.totalConnectionsDestroyed,
                    totalConnectionsDestroyed) ||
                other.totalConnectionsDestroyed == totalConnectionsDestroyed) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      totalConnections,
      idleConnections,
      activeConnections,
      waitingRequests,
      averageAcquireTime,
      peakActiveConnections,
      totalConnectionsCreated,
      totalConnectionsDestroyed,
      timestamp);

  @override
  String toString() {
    return 'PoolMetrics(totalConnections: $totalConnections, idleConnections: $idleConnections, activeConnections: $activeConnections, waitingRequests: $waitingRequests, averageAcquireTime: $averageAcquireTime, peakActiveConnections: $peakActiveConnections, totalConnectionsCreated: $totalConnectionsCreated, totalConnectionsDestroyed: $totalConnectionsDestroyed, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class _$PoolMetricsCopyWith<$Res>
    implements $PoolMetricsCopyWith<$Res> {
  factory _$PoolMetricsCopyWith(
          _PoolMetrics value, $Res Function(_PoolMetrics) _then) =
      __$PoolMetricsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int totalConnections,
      int idleConnections,
      int activeConnections,
      int waitingRequests,
      Duration averageAcquireTime,
      int peakActiveConnections,
      int totalConnectionsCreated,
      int totalConnectionsDestroyed,
      DateTime timestamp});
}

/// @nodoc
class __$PoolMetricsCopyWithImpl<$Res> implements _$PoolMetricsCopyWith<$Res> {
  __$PoolMetricsCopyWithImpl(this._self, this._then);

  final _PoolMetrics _self;
  final $Res Function(_PoolMetrics) _then;

  /// Create a copy of PoolMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? totalConnections = null,
    Object? idleConnections = null,
    Object? activeConnections = null,
    Object? waitingRequests = null,
    Object? averageAcquireTime = null,
    Object? peakActiveConnections = null,
    Object? totalConnectionsCreated = null,
    Object? totalConnectionsDestroyed = null,
    Object? timestamp = null,
  }) {
    return _then(_PoolMetrics(
      totalConnections: null == totalConnections
          ? _self.totalConnections
          : totalConnections // ignore: cast_nullable_to_non_nullable
              as int,
      idleConnections: null == idleConnections
          ? _self.idleConnections
          : idleConnections // ignore: cast_nullable_to_non_nullable
              as int,
      activeConnections: null == activeConnections
          ? _self.activeConnections
          : activeConnections // ignore: cast_nullable_to_non_nullable
              as int,
      waitingRequests: null == waitingRequests
          ? _self.waitingRequests
          : waitingRequests // ignore: cast_nullable_to_non_nullable
              as int,
      averageAcquireTime: null == averageAcquireTime
          ? _self.averageAcquireTime
          : averageAcquireTime // ignore: cast_nullable_to_non_nullable
              as Duration,
      peakActiveConnections: null == peakActiveConnections
          ? _self.peakActiveConnections
          : peakActiveConnections // ignore: cast_nullable_to_non_nullable
              as int,
      totalConnectionsCreated: null == totalConnectionsCreated
          ? _self.totalConnectionsCreated
          : totalConnectionsCreated // ignore: cast_nullable_to_non_nullable
              as int,
      totalConnectionsDestroyed: null == totalConnectionsDestroyed
          ? _self.totalConnectionsDestroyed
          : totalConnectionsDestroyed // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
