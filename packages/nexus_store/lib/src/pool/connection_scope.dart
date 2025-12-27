import 'connection_pool.dart';
import 'pooled_connection.dart';

/// A scope that manages borrowing multiple connections from a pool.
///
/// The scope tracks all borrowed connections and can release them all at once.
/// This is useful for operations that need multiple connections and want to
/// ensure they are all returned to the pool when done.
///
/// ## Example
///
/// ```dart
/// final scope = ConnectionScope<Database>(pool);
/// try {
///   final conn1 = await scope.borrow();
///   final conn2 = await scope.borrow();
///   // Use connections...
/// } finally {
///   scope.releaseAll();
/// }
/// ```
///
/// Or use the [ConnectionPoolScopeExtension.withScope] extension method:
///
/// ```dart
/// await pool.withScope((scope) async {
///   final conn1 = await scope.borrow();
///   final conn2 = await scope.borrow();
///   // Connections are automatically released when scope completes
/// });
/// ```
class ConnectionScope<C> {
  /// Creates a connection scope for the given pool.
  ConnectionScope(this._pool);

  final ConnectionPool<C> _pool;
  final List<PooledConnection<C>> _borrowedConnections = [];

  /// The number of currently borrowed connections.
  int get borrowedCount => _borrowedConnections.length;

  /// Whether no connections are currently borrowed.
  bool get isEmpty => _borrowedConnections.isEmpty;

  /// Borrows a connection from the pool.
  ///
  /// The connection is tracked by this scope and will be released
  /// when [releaseAll] is called.
  ///
  /// Returns the borrowed connection.
  Future<C> borrow() async {
    final pooled = await _pool.acquire();
    _borrowedConnections.add(pooled);
    return pooled.connection;
  }

  /// Releases all borrowed connections back to the pool.
  ///
  /// After this call, [borrowedCount] will be 0.
  /// This method is idempotent - calling it multiple times has no effect.
  void releaseAll() {
    for (final pooled in _borrowedConnections) {
      _pool.release(pooled);
    }
    _borrowedConnections.clear();
  }
}

/// Extension methods for using scoped connections with [ConnectionPool].
extension ConnectionPoolScopeExtension<C> on ConnectionPool<C> {
  /// Executes an operation with a connection scope.
  ///
  /// Creates a [ConnectionScope], executes the operation, and automatically
  /// releases all borrowed connections when done, even if an error occurs.
  ///
  /// This is the recommended way to borrow multiple connections for a
  /// single operation:
  ///
  /// ```dart
  /// final results = await pool.withScope((scope) async {
  ///   final conn1 = await scope.borrow();
  ///   final conn2 = await scope.borrow();
  ///
  ///   final result1 = await conn1.query('...');
  ///   final result2 = await conn2.query('...');
  ///
  ///   return [result1, result2];
  /// });
  /// ```
  Future<R> withScope<R>(
    Future<R> Function(ConnectionScope<C> scope) operation,
  ) async {
    final scope = ConnectionScope<C>(this);
    try {
      return await operation(scope);
    } finally {
      scope.releaseAll();
    }
  }
}
