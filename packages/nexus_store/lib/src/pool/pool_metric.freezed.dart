// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pool_metric.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PoolMetric {
  /// The type of pool event.
  PoolEvent get event;

  /// Optional name to identify the pool.
  String? get poolName;

  /// Duration of the operation (for acquired events).
  Duration? get duration;

  /// Number of active connections at the time of the event.
  int? get activeConnections;

  /// Number of idle connections at the time of the event.
  int? get idleConnections;

  /// Number of waiting requests at the time of the event.
  int? get waitingRequests;

  /// When the event occurred.
  DateTime get timestamp;

  /// Create a copy of PoolMetric
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PoolMetricCopyWith<PoolMetric> get copyWith =>
      _$PoolMetricCopyWithImpl<PoolMetric>(this as PoolMetric, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PoolMetric &&
            (identical(other.event, event) || other.event == event) &&
            (identical(other.poolName, poolName) ||
                other.poolName == poolName) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.activeConnections, activeConnections) ||
                other.activeConnections == activeConnections) &&
            (identical(other.idleConnections, idleConnections) ||
                other.idleConnections == idleConnections) &&
            (identical(other.waitingRequests, waitingRequests) ||
                other.waitingRequests == waitingRequests) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(runtimeType, event, poolName, duration,
      activeConnections, idleConnections, waitingRequests, timestamp);

  @override
  String toString() {
    return 'PoolMetric(event: $event, poolName: $poolName, duration: $duration, activeConnections: $activeConnections, idleConnections: $idleConnections, waitingRequests: $waitingRequests, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class $PoolMetricCopyWith<$Res> {
  factory $PoolMetricCopyWith(
          PoolMetric value, $Res Function(PoolMetric) _then) =
      _$PoolMetricCopyWithImpl;
  @useResult
  $Res call(
      {PoolEvent event,
      String? poolName,
      Duration? duration,
      int? activeConnections,
      int? idleConnections,
      int? waitingRequests,
      DateTime timestamp});
}

/// @nodoc
class _$PoolMetricCopyWithImpl<$Res> implements $PoolMetricCopyWith<$Res> {
  _$PoolMetricCopyWithImpl(this._self, this._then);

  final PoolMetric _self;
  final $Res Function(PoolMetric) _then;

  /// Create a copy of PoolMetric
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? event = null,
    Object? poolName = freezed,
    Object? duration = freezed,
    Object? activeConnections = freezed,
    Object? idleConnections = freezed,
    Object? waitingRequests = freezed,
    Object? timestamp = null,
  }) {
    return _then(_self.copyWith(
      event: null == event
          ? _self.event
          : event // ignore: cast_nullable_to_non_nullable
              as PoolEvent,
      poolName: freezed == poolName
          ? _self.poolName
          : poolName // ignore: cast_nullable_to_non_nullable
              as String?,
      duration: freezed == duration
          ? _self.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as Duration?,
      activeConnections: freezed == activeConnections
          ? _self.activeConnections
          : activeConnections // ignore: cast_nullable_to_non_nullable
              as int?,
      idleConnections: freezed == idleConnections
          ? _self.idleConnections
          : idleConnections // ignore: cast_nullable_to_non_nullable
              as int?,
      waitingRequests: freezed == waitingRequests
          ? _self.waitingRequests
          : waitingRequests // ignore: cast_nullable_to_non_nullable
              as int?,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [PoolMetric].
extension PoolMetricPatterns on PoolMetric {
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
    TResult Function(_PoolMetric value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PoolMetric() when $default != null:
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
    TResult Function(_PoolMetric value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PoolMetric():
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
    TResult? Function(_PoolMetric value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PoolMetric() when $default != null:
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
            PoolEvent event,
            String? poolName,
            Duration? duration,
            int? activeConnections,
            int? idleConnections,
            int? waitingRequests,
            DateTime timestamp)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PoolMetric() when $default != null:
        return $default(
            _that.event,
            _that.poolName,
            _that.duration,
            _that.activeConnections,
            _that.idleConnections,
            _that.waitingRequests,
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
            PoolEvent event,
            String? poolName,
            Duration? duration,
            int? activeConnections,
            int? idleConnections,
            int? waitingRequests,
            DateTime timestamp)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PoolMetric():
        return $default(
            _that.event,
            _that.poolName,
            _that.duration,
            _that.activeConnections,
            _that.idleConnections,
            _that.waitingRequests,
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
            PoolEvent event,
            String? poolName,
            Duration? duration,
            int? activeConnections,
            int? idleConnections,
            int? waitingRequests,
            DateTime timestamp)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PoolMetric() when $default != null:
        return $default(
            _that.event,
            _that.poolName,
            _that.duration,
            _that.activeConnections,
            _that.idleConnections,
            _that.waitingRequests,
            _that.timestamp);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _PoolMetric extends PoolMetric {
  const _PoolMetric(
      {required this.event,
      this.poolName,
      this.duration,
      this.activeConnections,
      this.idleConnections,
      this.waitingRequests,
      required this.timestamp})
      : super._();

  /// The type of pool event.
  @override
  final PoolEvent event;

  /// Optional name to identify the pool.
  @override
  final String? poolName;

  /// Duration of the operation (for acquired events).
  @override
  final Duration? duration;

  /// Number of active connections at the time of the event.
  @override
  final int? activeConnections;

  /// Number of idle connections at the time of the event.
  @override
  final int? idleConnections;

  /// Number of waiting requests at the time of the event.
  @override
  final int? waitingRequests;

  /// When the event occurred.
  @override
  final DateTime timestamp;

  /// Create a copy of PoolMetric
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PoolMetricCopyWith<_PoolMetric> get copyWith =>
      __$PoolMetricCopyWithImpl<_PoolMetric>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PoolMetric &&
            (identical(other.event, event) || other.event == event) &&
            (identical(other.poolName, poolName) ||
                other.poolName == poolName) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.activeConnections, activeConnections) ||
                other.activeConnections == activeConnections) &&
            (identical(other.idleConnections, idleConnections) ||
                other.idleConnections == idleConnections) &&
            (identical(other.waitingRequests, waitingRequests) ||
                other.waitingRequests == waitingRequests) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(runtimeType, event, poolName, duration,
      activeConnections, idleConnections, waitingRequests, timestamp);

  @override
  String toString() {
    return 'PoolMetric(event: $event, poolName: $poolName, duration: $duration, activeConnections: $activeConnections, idleConnections: $idleConnections, waitingRequests: $waitingRequests, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class _$PoolMetricCopyWith<$Res>
    implements $PoolMetricCopyWith<$Res> {
  factory _$PoolMetricCopyWith(
          _PoolMetric value, $Res Function(_PoolMetric) _then) =
      __$PoolMetricCopyWithImpl;
  @override
  @useResult
  $Res call(
      {PoolEvent event,
      String? poolName,
      Duration? duration,
      int? activeConnections,
      int? idleConnections,
      int? waitingRequests,
      DateTime timestamp});
}

/// @nodoc
class __$PoolMetricCopyWithImpl<$Res> implements _$PoolMetricCopyWith<$Res> {
  __$PoolMetricCopyWithImpl(this._self, this._then);

  final _PoolMetric _self;
  final $Res Function(_PoolMetric) _then;

  /// Create a copy of PoolMetric
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? event = null,
    Object? poolName = freezed,
    Object? duration = freezed,
    Object? activeConnections = freezed,
    Object? idleConnections = freezed,
    Object? waitingRequests = freezed,
    Object? timestamp = null,
  }) {
    return _then(_PoolMetric(
      event: null == event
          ? _self.event
          : event // ignore: cast_nullable_to_non_nullable
              as PoolEvent,
      poolName: freezed == poolName
          ? _self.poolName
          : poolName // ignore: cast_nullable_to_non_nullable
              as String?,
      duration: freezed == duration
          ? _self.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as Duration?,
      activeConnections: freezed == activeConnections
          ? _self.activeConnections
          : activeConnections // ignore: cast_nullable_to_non_nullable
              as int?,
      idleConnections: freezed == idleConnections
          ? _self.idleConnections
          : idleConnections // ignore: cast_nullable_to_non_nullable
              as int?,
      waitingRequests: freezed == waitingRequests
          ? _self.waitingRequests
          : waitingRequests // ignore: cast_nullable_to_non_nullable
              as int?,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
