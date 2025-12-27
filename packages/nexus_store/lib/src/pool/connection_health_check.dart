/// Interface for checking the health of pooled connections.
///
/// Implementations of this interface are used by [ConnectionPool] to
/// verify that idle connections are still usable and to attempt recovery
/// of unhealthy connections.
///
/// ## Example
///
/// ```dart
/// class PostgresHealthCheck implements ConnectionHealthCheck<PgConnection> {
///   @override
///   Future<bool> isHealthy(PgConnection connection) async {
///     try {
///       await connection.execute('SELECT 1');
///       return true;
///     } catch (_) {
///       return false;
///     }
///   }
///
///   @override
///   Future<bool> reset(PgConnection connection) async {
///     try {
///       await connection.execute('DISCARD ALL');
///       return true;
///     } catch (_) {
///       return false;
///     }
///   }
/// }
/// ```
abstract interface class ConnectionHealthCheck<C> {
  /// Checks if the connection is healthy and usable.
  ///
  /// This should be a quick, lightweight check (e.g., a ping or simple query)
  /// to verify the connection is still alive and responsive.
  ///
  /// Returns `true` if the connection is healthy, `false` otherwise.
  /// Should not throw exceptions.
  Future<bool> isHealthy(C connection);

  /// Attempts to reset/refresh the connection to a clean state.
  ///
  /// This is called when a connection is returned to the pool or when
  /// a health check fails but recovery might be possible.
  ///
  /// Returns `true` if the reset succeeded and the connection is usable,
  /// `false` if the connection should be destroyed instead.
  /// Should not throw exceptions.
  Future<bool> reset(C connection);
}

/// A no-op health check that always reports connections as healthy.
///
/// Use this when health checking is not needed or when the connection
/// type doesn't support health checks.
///
/// This is the default health check used by [ConnectionPool] when
/// no custom health check is provided.
class NoOpHealthCheck<C> implements ConnectionHealthCheck<C> {
  /// Creates a no-op health check.
  const NoOpHealthCheck();

  @override
  Future<bool> isHealthy(C connection) async => true;

  @override
  Future<bool> reset(C connection) async => true;
}
