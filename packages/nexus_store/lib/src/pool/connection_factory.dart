/// Factory for creating and managing connection lifecycle.
///
/// Implementations of this interface are responsible for creating new
/// connections, destroying them when they're no longer needed, and
/// validating that existing connections are still usable.
///
/// ## Example
///
/// ```dart
/// class PostgresConnectionFactory implements ConnectionFactory<PgConnection> {
///   final String connectionString;
///
///   PostgresConnectionFactory(this.connectionString);
///
///   @override
///   Future<PgConnection> create() async {
///     return await PgConnection.open(connectionString);
///   }
///
///   @override
///   Future<void> destroy(PgConnection connection) async {
///     await connection.close();
///   }
///
///   @override
///   Future<bool> validate(PgConnection connection) async {
///     try {
///       await connection.execute('SELECT 1');
///       return true;
///     } catch (_) {
///       return false;
///     }
///   }
/// }
/// ```
abstract interface class ConnectionFactory<C> {
  /// Creates a new connection.
  ///
  /// This method should establish a new connection to the underlying
  /// resource (database, service, etc.).
  ///
  /// Throws an exception if the connection cannot be created.
  Future<C> create();

  /// Destroys a connection and releases its resources.
  ///
  /// This method should properly close the connection and clean up
  /// any associated resources.
  ///
  /// Should not throw exceptions even if the connection is already closed.
  Future<void> destroy(C connection);

  /// Validates that a connection is still usable.
  ///
  /// This is typically a quick check (e.g., ping) to verify the connection
  /// is still alive and responsive.
  ///
  /// Returns `true` if the connection is valid, `false` otherwise.
  /// Should not throw exceptions.
  Future<bool> validate(C connection);
}
