/// A wrapper around a connection that tracks its lifecycle in the pool.
///
/// [PooledConnection] maintains metadata about when a connection was created,
/// when it was last used, how many times it has been borrowed, and its
/// current health status.
///
/// ## Example
///
/// ```dart
/// final pooled = PooledConnection<DatabaseConnection>(
///   connection: dbConnection,
///   createdAt: DateTime.now(),
/// );
///
/// // Use the connection
/// pooled.markUsed();
///
/// // Check if it's too old
/// if (pooled.hasExceededLifetime(Duration(hours: 1))) {
///   // Should be replaced
/// }
/// ```
class PooledConnection<C> {
  /// Creates a pooled connection wrapper.
  ///
  /// [connection] is the underlying connection being pooled.
  /// [createdAt] is the time when this connection was created.
  PooledConnection({
    required this.connection,
    required DateTime createdAt,
  })  : _createdAt = createdAt,
        _lastUsedAt = createdAt;

  /// The underlying connection being pooled.
  final C connection;

  final DateTime _createdAt;
  DateTime _lastUsedAt;
  int _useCount = 0;
  bool _isHealthy = true;

  /// When this connection was created.
  DateTime get createdAt => _createdAt;

  /// When this connection was last borrowed from the pool.
  DateTime get lastUsedAt => _lastUsedAt;

  /// Number of times this connection has been borrowed.
  int get useCount => _useCount;

  /// Whether this connection is considered healthy.
  ///
  /// Set by health check operations.
  bool get isHealthy => _isHealthy;

  /// How long since this connection was created.
  Duration get age => DateTime.now().difference(_createdAt);

  /// How long since this connection was last used.
  Duration get idleDuration => DateTime.now().difference(_lastUsedAt);

  /// Marks this connection as having been used (borrowed).
  ///
  /// Increments [useCount] and updates [lastUsedAt].
  void markUsed() {
    _lastUsedAt = DateTime.now();
    _useCount++;
  }

  /// Sets the health status of this connection.
  ///
  /// Called by health check operations to mark connections
  /// as healthy or unhealthy.
  void setHealthy(bool healthy) => _isHealthy = healthy;

  /// Whether this connection has exceeded its maximum lifetime.
  ///
  /// Connections that exceed their maximum lifetime should be closed
  /// and replaced with new ones to prevent issues with stale connections.
  bool hasExceededLifetime(Duration maxLifetime) => age > maxLifetime;

  /// Whether this connection has exceeded its idle timeout.
  ///
  /// Idle connections that exceed this timeout may be closed
  /// to free resources, as long as minimum pool size is maintained.
  bool hasExceededIdleTimeout(Duration idleTimeout) =>
      idleDuration > idleTimeout;
}
