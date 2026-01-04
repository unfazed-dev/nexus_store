import 'dart:async';

import 'package:powersync/powersync.dart' as ps;

/// Abstract interface for PowerSync database operations.
///
/// This abstraction allows for easy mocking in tests, as the concrete
/// PowerSync classes (like ResultSet) are final and cannot be mocked directly.
///
/// Example usage in production:
/// ```dart
/// final wrapper = DefaultPowerSyncDatabaseWrapper(powerSyncDatabase);
/// final backend = PowerSyncBackend(db: wrapper, ...);
/// ```
///
/// Example usage in tests:
/// ```dart
/// final mockWrapper = MockPowerSyncDatabaseWrapper();
/// when(() => mockWrapper.execute(any(), any()))
///     .thenAnswer((_) async => [...]);
/// final backend = PowerSyncBackend(db: mockWrapper, ...);
/// ```
abstract class PowerSyncDatabaseWrapper {
  /// Executes a SQL query and returns results as a list of maps.
  Future<List<Map<String, dynamic>>> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]);

  /// Watches a SQL query and returns a stream of results.
  Stream<List<Map<String, dynamic>>> watch(
    String sql, {
    List<Object?> parameters = const [],
  });

  /// Executes operations within a write transaction.
  Future<T> writeTransaction<T>(
    Future<T> Function(PowerSyncTransactionContext tx) callback,
  );

  /// Stream of sync status updates.
  Stream<ps.SyncStatus> get statusStream;

  /// Current sync status.
  ps.SyncStatus get currentStatus;
}

/// Transaction context for write operations.
// ignore: one_member_abstracts
abstract class PowerSyncTransactionContext {
  /// Executes a SQL statement within the transaction.
  Future<void> execute(String sql, [List<Object?> parameters = const []]);
}

// coverage:ignore-start
/// Default implementation that wraps a real PowerSyncDatabase.
///
/// Coverage excluded: Requires native FFI SQLite bindings which cannot
/// be unit tested without native libraries. Logic is tested via
/// PowerSyncDatabaseWrapper abstraction with mock implementations.
class DefaultPowerSyncDatabaseWrapper implements PowerSyncDatabaseWrapper {
  /// Creates a wrapper around a PowerSyncDatabase.
  DefaultPowerSyncDatabaseWrapper(this._db);

  final ps.PowerSyncDatabase _db;

  @override
  Future<List<Map<String, dynamic>>> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final results = await _db.execute(sql, parameters);
    return results.map(Map<String, dynamic>.from).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> watch(
    String sql, {
    List<Object?> parameters = const [],
  }) =>
      _db.watch(sql, parameters: parameters).map(
            (results) => results.map(Map<String, dynamic>.from).toList(),
          );

  @override
  Future<T> writeTransaction<T>(
    Future<T> Function(PowerSyncTransactionContext tx) callback,
  ) async =>
      _db.writeTransaction((tx) async {
        final wrappedTx = _DefaultTransactionContext(tx);
        return callback(wrappedTx);
      });

  @override
  Stream<ps.SyncStatus> get statusStream => _db.statusStream;

  @override
  ps.SyncStatus get currentStatus => _db.currentStatus;
}

class _DefaultTransactionContext implements PowerSyncTransactionContext {
  _DefaultTransactionContext(this._tx);

  final dynamic _tx;

  @override
  Future<void> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    // ignore: avoid_dynamic_calls
    await _tx.execute(sql, parameters);
  }
}
// coverage:ignore-end
