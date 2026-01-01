import 'dart:async';

import 'package:sqlite_crdt/sqlite_crdt.dart';

/// Abstract interface for CRDT database operations.
///
/// This abstraction allows for easy mocking in tests, as the concrete
/// SqliteCrdt class and its dependencies are difficult to mock directly.
///
/// Example usage in production:
/// ```dart
/// final crdt = await SqliteCrdt.openInMemory(...);
/// final wrapper = DefaultCrdtDatabaseWrapper(crdt);
/// final backend = CrdtBackend.withWrapper(db: wrapper, ...);
/// ```
///
/// Example usage in tests:
/// ```dart
/// final mockWrapper = MockCrdtDatabaseWrapper();
/// when(() => mockWrapper.query(any(), any()))
///     .thenAnswer((_) async => [...]);
/// final backend = CrdtBackend.withWrapper(db: mockWrapper, ...);
/// ```
abstract class CrdtDatabaseWrapper {
  /// Performs a SQL query with optional [args] and returns results as a list
  /// of column maps.
  Future<List<Map<String, Object?>>> query(String sql, [List<Object?>? args]);

  /// Executes a SQL statement with optional [args].
  Future<void> execute(String sql, [List<Object?>? args]);

  /// Watches a SQL query and returns a stream of results.
  /// The [argsFunction] is called each time the query is re-evaluated.
  Stream<List<Map<String, Object?>>> watch(
    String sql, [
    List<Object?> Function()? argsFunction,
  ]);

  /// Executes operations within a transaction.
  /// The callback receives a [CrdtTransactionContext] for executing statements.
  Future<void> transaction(
    Future<void> Function(CrdtTransactionContext txn) callback,
  );

  /// Gets all changes since the given HLC timestamp.
  /// If [modifiedAfter] is null, returns all changes (full sync).
  Future<CrdtChangeset> getChangeset({Hlc? modifiedAfter});

  /// Applies a remote changeset, merging with Last-Writer-Wins resolution.
  Future<void> merge(CrdtChangeset changeset);

  /// The unique node ID for this CRDT instance.
  String get nodeId;

  /// Closes the database connection.
  Future<void> close();
}

/// Transaction context for write operations within a transaction.
// ignore: one_member_abstracts
abstract class CrdtTransactionContext {
  /// Executes a SQL statement within the transaction.
  Future<void> execute(String sql, [List<Object?>? args]);
}

/// Default implementation that wraps a real SqliteCrdt.
class DefaultCrdtDatabaseWrapper implements CrdtDatabaseWrapper {
  /// Creates a wrapper around a SqliteCrdt instance.
  DefaultCrdtDatabaseWrapper(this._crdt);

  final SqliteCrdt _crdt;

  @override
  Future<List<Map<String, Object?>>> query(
    String sql, [
    List<Object?>? args,
  ]) =>
      _crdt.query(sql, args);

  @override
  Future<void> execute(String sql, [List<Object?>? args]) =>
      _crdt.execute(sql, args);

  @override
  Stream<List<Map<String, Object?>>> watch(
    String sql, [
    List<Object?> Function()? argsFunction,
  ]) =>
      _crdt.watch(sql, argsFunction);

  @override
  Future<void> transaction(
    Future<void> Function(CrdtTransactionContext txn) callback,
  ) =>
      _crdt.transaction((executor) async {
        final wrappedTxn = _DefaultCrdtTransactionContext(executor);
        await callback(wrappedTxn);
      });

  @override
  Future<CrdtChangeset> getChangeset({Hlc? modifiedAfter}) =>
      _crdt.getChangeset(modifiedAfter: modifiedAfter);

  @override
  Future<void> merge(CrdtChangeset changeset) => _crdt.merge(changeset);

  @override
  String get nodeId => _crdt.nodeId;

  @override
  Future<void> close() => _crdt.close();
}

class _DefaultCrdtTransactionContext implements CrdtTransactionContext {
  _DefaultCrdtTransactionContext(this._executor);

  final CrdtExecutor _executor;

  @override
  Future<void> execute(String sql, [List<Object?>? args]) =>
      _executor.execute(sql, args);
}
