import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection_pool_config.freezed.dart';

/// Configuration for a connection pool.
///
/// Controls the size, timing, and behavior of the connection pool.
///
/// ## Example
///
/// ```dart
/// const config = ConnectionPoolConfig(
///   minConnections: 2,
///   maxConnections: 20,
///   acquireTimeout: Duration(seconds: 10),
///   idleTimeout: Duration(minutes: 5),
/// );
/// ```
@freezed
abstract class ConnectionPoolConfig with _$ConnectionPoolConfig {
  /// Creates a connection pool configuration.
  const factory ConnectionPoolConfig({
    /// Minimum number of connections to maintain in the pool.
    ///
    /// The pool will pre-warm with this many connections on initialization
    /// and will not reduce below this count during idle cleanup.
    @Default(1) int minConnections,

    /// Maximum number of connections allowed in the pool.
    ///
    /// When all connections are in use and more are requested,
    /// requests will wait until a connection is released or timeout.
    @Default(10) int maxConnections,

    /// Maximum time to wait when acquiring a connection from the pool.
    ///
    /// If no connection becomes available within this duration,
    /// a [PoolAcquireTimeoutError] is thrown.
    @Default(Duration(seconds: 30)) Duration acquireTimeout,

    /// Duration after which an idle connection may be closed.
    ///
    /// Connections that have been idle longer than this duration
    /// may be closed to free resources, as long as [minConnections]
    /// are maintained.
    @Default(Duration(minutes: 10)) Duration idleTimeout,

    /// Maximum lifetime of a connection regardless of usage.
    ///
    /// Connections older than this are closed and replaced,
    /// preventing issues with stale connections.
    @Default(Duration(hours: 1)) Duration maxLifetime,

    /// Interval for periodic health checks on idle connections.
    ///
    /// The pool will check the health of idle connections at this interval
    /// and replace any that fail the health check.
    @Default(Duration(minutes: 1)) Duration healthCheckInterval,

    /// Whether to validate connections before returning them from the pool.
    ///
    /// When true, connections are validated before being returned to a caller.
    /// Invalid connections are destroyed and a new one is tried.
    @Default(true) bool testOnBorrow,

    /// Whether to validate connections when they are returned to the pool.
    ///
    /// When true, connections are validated when released back to the pool.
    /// Invalid connections are destroyed rather than returned to the pool.
    @Default(false) bool testOnReturn,
  }) = _ConnectionPoolConfig;

  const ConnectionPoolConfig._();

  /// Default configuration suitable for most use cases.
  static const ConnectionPoolConfig defaults = ConnectionPoolConfig();

  /// High-performance configuration with more connections.
  ///
  /// Uses:
  /// - 5 minimum connections for faster response under load
  /// - 50 maximum connections for high concurrency
  /// - 5 minute idle timeout to quickly release unused connections
  static const ConnectionPoolConfig highPerformance = ConnectionPoolConfig(
    minConnections: 5,
    maxConnections: 50,
    idleTimeout: Duration(minutes: 5),
  );

  /// Validates the configuration constraints.
  ///
  /// Returns true if:
  /// - [minConnections] is non-negative
  /// - [maxConnections] is greater than or equal to [minConnections]
  /// - [acquireTimeout] is positive
  bool get isValid =>
      minConnections >= 0 &&
      maxConnections >= minConnections &&
      acquireTimeout > Duration.zero;
}
