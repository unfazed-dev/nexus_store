// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connection_pool_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ConnectionPoolConfig {
  /// Minimum number of connections to maintain in the pool.
  ///
  /// The pool will pre-warm with this many connections on initialization
  /// and will not reduce below this count during idle cleanup.
  int get minConnections;

  /// Maximum number of connections allowed in the pool.
  ///
  /// When all connections are in use and more are requested,
  /// requests will wait until a connection is released or timeout.
  int get maxConnections;

  /// Maximum time to wait when acquiring a connection from the pool.
  ///
  /// If no connection becomes available within this duration,
  /// a [PoolAcquireTimeoutError] is thrown.
  Duration get acquireTimeout;

  /// Duration after which an idle connection may be closed.
  ///
  /// Connections that have been idle longer than this duration
  /// may be closed to free resources, as long as [minConnections]
  /// are maintained.
  Duration get idleTimeout;

  /// Maximum lifetime of a connection regardless of usage.
  ///
  /// Connections older than this are closed and replaced,
  /// preventing issues with stale connections.
  Duration get maxLifetime;

  /// Interval for periodic health checks on idle connections.
  ///
  /// The pool will check the health of idle connections at this interval
  /// and replace any that fail the health check.
  Duration get healthCheckInterval;

  /// Whether to validate connections before returning them from the pool.
  ///
  /// When true, connections are validated before being returned to a caller.
  /// Invalid connections are destroyed and a new one is tried.
  bool get testOnBorrow;

  /// Whether to validate connections when they are returned to the pool.
  ///
  /// When true, connections are validated when released back to the pool.
  /// Invalid connections are destroyed rather than returned to the pool.
  bool get testOnReturn;

  /// Create a copy of ConnectionPoolConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ConnectionPoolConfigCopyWith<ConnectionPoolConfig> get copyWith =>
      _$ConnectionPoolConfigCopyWithImpl<ConnectionPoolConfig>(
          this as ConnectionPoolConfig, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ConnectionPoolConfig &&
            (identical(other.minConnections, minConnections) ||
                other.minConnections == minConnections) &&
            (identical(other.maxConnections, maxConnections) ||
                other.maxConnections == maxConnections) &&
            (identical(other.acquireTimeout, acquireTimeout) ||
                other.acquireTimeout == acquireTimeout) &&
            (identical(other.idleTimeout, idleTimeout) ||
                other.idleTimeout == idleTimeout) &&
            (identical(other.maxLifetime, maxLifetime) ||
                other.maxLifetime == maxLifetime) &&
            (identical(other.healthCheckInterval, healthCheckInterval) ||
                other.healthCheckInterval == healthCheckInterval) &&
            (identical(other.testOnBorrow, testOnBorrow) ||
                other.testOnBorrow == testOnBorrow) &&
            (identical(other.testOnReturn, testOnReturn) ||
                other.testOnReturn == testOnReturn));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      minConnections,
      maxConnections,
      acquireTimeout,
      idleTimeout,
      maxLifetime,
      healthCheckInterval,
      testOnBorrow,
      testOnReturn);

  @override
  String toString() {
    return 'ConnectionPoolConfig(minConnections: $minConnections, maxConnections: $maxConnections, acquireTimeout: $acquireTimeout, idleTimeout: $idleTimeout, maxLifetime: $maxLifetime, healthCheckInterval: $healthCheckInterval, testOnBorrow: $testOnBorrow, testOnReturn: $testOnReturn)';
  }
}

/// @nodoc
abstract mixin class $ConnectionPoolConfigCopyWith<$Res> {
  factory $ConnectionPoolConfigCopyWith(ConnectionPoolConfig value,
          $Res Function(ConnectionPoolConfig) _then) =
      _$ConnectionPoolConfigCopyWithImpl;
  @useResult
  $Res call(
      {int minConnections,
      int maxConnections,
      Duration acquireTimeout,
      Duration idleTimeout,
      Duration maxLifetime,
      Duration healthCheckInterval,
      bool testOnBorrow,
      bool testOnReturn});
}

/// @nodoc
class _$ConnectionPoolConfigCopyWithImpl<$Res>
    implements $ConnectionPoolConfigCopyWith<$Res> {
  _$ConnectionPoolConfigCopyWithImpl(this._self, this._then);

  final ConnectionPoolConfig _self;
  final $Res Function(ConnectionPoolConfig) _then;

  /// Create a copy of ConnectionPoolConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? minConnections = null,
    Object? maxConnections = null,
    Object? acquireTimeout = null,
    Object? idleTimeout = null,
    Object? maxLifetime = null,
    Object? healthCheckInterval = null,
    Object? testOnBorrow = null,
    Object? testOnReturn = null,
  }) {
    return _then(_self.copyWith(
      minConnections: null == minConnections
          ? _self.minConnections
          : minConnections // ignore: cast_nullable_to_non_nullable
              as int,
      maxConnections: null == maxConnections
          ? _self.maxConnections
          : maxConnections // ignore: cast_nullable_to_non_nullable
              as int,
      acquireTimeout: null == acquireTimeout
          ? _self.acquireTimeout
          : acquireTimeout // ignore: cast_nullable_to_non_nullable
              as Duration,
      idleTimeout: null == idleTimeout
          ? _self.idleTimeout
          : idleTimeout // ignore: cast_nullable_to_non_nullable
              as Duration,
      maxLifetime: null == maxLifetime
          ? _self.maxLifetime
          : maxLifetime // ignore: cast_nullable_to_non_nullable
              as Duration,
      healthCheckInterval: null == healthCheckInterval
          ? _self.healthCheckInterval
          : healthCheckInterval // ignore: cast_nullable_to_non_nullable
              as Duration,
      testOnBorrow: null == testOnBorrow
          ? _self.testOnBorrow
          : testOnBorrow // ignore: cast_nullable_to_non_nullable
              as bool,
      testOnReturn: null == testOnReturn
          ? _self.testOnReturn
          : testOnReturn // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [ConnectionPoolConfig].
extension ConnectionPoolConfigPatterns on ConnectionPoolConfig {
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
    TResult Function(_ConnectionPoolConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ConnectionPoolConfig() when $default != null:
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
    TResult Function(_ConnectionPoolConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConnectionPoolConfig():
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
    TResult? Function(_ConnectionPoolConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConnectionPoolConfig() when $default != null:
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
            int minConnections,
            int maxConnections,
            Duration acquireTimeout,
            Duration idleTimeout,
            Duration maxLifetime,
            Duration healthCheckInterval,
            bool testOnBorrow,
            bool testOnReturn)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ConnectionPoolConfig() when $default != null:
        return $default(
            _that.minConnections,
            _that.maxConnections,
            _that.acquireTimeout,
            _that.idleTimeout,
            _that.maxLifetime,
            _that.healthCheckInterval,
            _that.testOnBorrow,
            _that.testOnReturn);
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
            int minConnections,
            int maxConnections,
            Duration acquireTimeout,
            Duration idleTimeout,
            Duration maxLifetime,
            Duration healthCheckInterval,
            bool testOnBorrow,
            bool testOnReturn)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConnectionPoolConfig():
        return $default(
            _that.minConnections,
            _that.maxConnections,
            _that.acquireTimeout,
            _that.idleTimeout,
            _that.maxLifetime,
            _that.healthCheckInterval,
            _that.testOnBorrow,
            _that.testOnReturn);
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
            int minConnections,
            int maxConnections,
            Duration acquireTimeout,
            Duration idleTimeout,
            Duration maxLifetime,
            Duration healthCheckInterval,
            bool testOnBorrow,
            bool testOnReturn)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConnectionPoolConfig() when $default != null:
        return $default(
            _that.minConnections,
            _that.maxConnections,
            _that.acquireTimeout,
            _that.idleTimeout,
            _that.maxLifetime,
            _that.healthCheckInterval,
            _that.testOnBorrow,
            _that.testOnReturn);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ConnectionPoolConfig extends ConnectionPoolConfig {
  const _ConnectionPoolConfig(
      {this.minConnections = 1,
      this.maxConnections = 10,
      this.acquireTimeout = const Duration(seconds: 30),
      this.idleTimeout = const Duration(minutes: 10),
      this.maxLifetime = const Duration(hours: 1),
      this.healthCheckInterval = const Duration(minutes: 1),
      this.testOnBorrow = true,
      this.testOnReturn = false})
      : super._();

  /// Minimum number of connections to maintain in the pool.
  ///
  /// The pool will pre-warm with this many connections on initialization
  /// and will not reduce below this count during idle cleanup.
  @override
  @JsonKey()
  final int minConnections;

  /// Maximum number of connections allowed in the pool.
  ///
  /// When all connections are in use and more are requested,
  /// requests will wait until a connection is released or timeout.
  @override
  @JsonKey()
  final int maxConnections;

  /// Maximum time to wait when acquiring a connection from the pool.
  ///
  /// If no connection becomes available within this duration,
  /// a [PoolAcquireTimeoutError] is thrown.
  @override
  @JsonKey()
  final Duration acquireTimeout;

  /// Duration after which an idle connection may be closed.
  ///
  /// Connections that have been idle longer than this duration
  /// may be closed to free resources, as long as [minConnections]
  /// are maintained.
  @override
  @JsonKey()
  final Duration idleTimeout;

  /// Maximum lifetime of a connection regardless of usage.
  ///
  /// Connections older than this are closed and replaced,
  /// preventing issues with stale connections.
  @override
  @JsonKey()
  final Duration maxLifetime;

  /// Interval for periodic health checks on idle connections.
  ///
  /// The pool will check the health of idle connections at this interval
  /// and replace any that fail the health check.
  @override
  @JsonKey()
  final Duration healthCheckInterval;

  /// Whether to validate connections before returning them from the pool.
  ///
  /// When true, connections are validated before being returned to a caller.
  /// Invalid connections are destroyed and a new one is tried.
  @override
  @JsonKey()
  final bool testOnBorrow;

  /// Whether to validate connections when they are returned to the pool.
  ///
  /// When true, connections are validated when released back to the pool.
  /// Invalid connections are destroyed rather than returned to the pool.
  @override
  @JsonKey()
  final bool testOnReturn;

  /// Create a copy of ConnectionPoolConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ConnectionPoolConfigCopyWith<_ConnectionPoolConfig> get copyWith =>
      __$ConnectionPoolConfigCopyWithImpl<_ConnectionPoolConfig>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ConnectionPoolConfig &&
            (identical(other.minConnections, minConnections) ||
                other.minConnections == minConnections) &&
            (identical(other.maxConnections, maxConnections) ||
                other.maxConnections == maxConnections) &&
            (identical(other.acquireTimeout, acquireTimeout) ||
                other.acquireTimeout == acquireTimeout) &&
            (identical(other.idleTimeout, idleTimeout) ||
                other.idleTimeout == idleTimeout) &&
            (identical(other.maxLifetime, maxLifetime) ||
                other.maxLifetime == maxLifetime) &&
            (identical(other.healthCheckInterval, healthCheckInterval) ||
                other.healthCheckInterval == healthCheckInterval) &&
            (identical(other.testOnBorrow, testOnBorrow) ||
                other.testOnBorrow == testOnBorrow) &&
            (identical(other.testOnReturn, testOnReturn) ||
                other.testOnReturn == testOnReturn));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      minConnections,
      maxConnections,
      acquireTimeout,
      idleTimeout,
      maxLifetime,
      healthCheckInterval,
      testOnBorrow,
      testOnReturn);

  @override
  String toString() {
    return 'ConnectionPoolConfig(minConnections: $minConnections, maxConnections: $maxConnections, acquireTimeout: $acquireTimeout, idleTimeout: $idleTimeout, maxLifetime: $maxLifetime, healthCheckInterval: $healthCheckInterval, testOnBorrow: $testOnBorrow, testOnReturn: $testOnReturn)';
  }
}

/// @nodoc
abstract mixin class _$ConnectionPoolConfigCopyWith<$Res>
    implements $ConnectionPoolConfigCopyWith<$Res> {
  factory _$ConnectionPoolConfigCopyWith(_ConnectionPoolConfig value,
          $Res Function(_ConnectionPoolConfig) _then) =
      __$ConnectionPoolConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int minConnections,
      int maxConnections,
      Duration acquireTimeout,
      Duration idleTimeout,
      Duration maxLifetime,
      Duration healthCheckInterval,
      bool testOnBorrow,
      bool testOnReturn});
}

/// @nodoc
class __$ConnectionPoolConfigCopyWithImpl<$Res>
    implements _$ConnectionPoolConfigCopyWith<$Res> {
  __$ConnectionPoolConfigCopyWithImpl(this._self, this._then);

  final _ConnectionPoolConfig _self;
  final $Res Function(_ConnectionPoolConfig) _then;

  /// Create a copy of ConnectionPoolConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? minConnections = null,
    Object? maxConnections = null,
    Object? acquireTimeout = null,
    Object? idleTimeout = null,
    Object? maxLifetime = null,
    Object? healthCheckInterval = null,
    Object? testOnBorrow = null,
    Object? testOnReturn = null,
  }) {
    return _then(_ConnectionPoolConfig(
      minConnections: null == minConnections
          ? _self.minConnections
          : minConnections // ignore: cast_nullable_to_non_nullable
              as int,
      maxConnections: null == maxConnections
          ? _self.maxConnections
          : maxConnections // ignore: cast_nullable_to_non_nullable
              as int,
      acquireTimeout: null == acquireTimeout
          ? _self.acquireTimeout
          : acquireTimeout // ignore: cast_nullable_to_non_nullable
              as Duration,
      idleTimeout: null == idleTimeout
          ? _self.idleTimeout
          : idleTimeout // ignore: cast_nullable_to_non_nullable
              as Duration,
      maxLifetime: null == maxLifetime
          ? _self.maxLifetime
          : maxLifetime // ignore: cast_nullable_to_non_nullable
              as Duration,
      healthCheckInterval: null == healthCheckInterval
          ? _self.healthCheckInterval
          : healthCheckInterval // ignore: cast_nullable_to_non_nullable
              as Duration,
      testOnBorrow: null == testOnBorrow
          ? _self.testOnBorrow
          : testOnBorrow // ignore: cast_nullable_to_non_nullable
              as bool,
      testOnReturn: null == testOnReturn
          ? _self.testOnReturn
          : testOnReturn // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
