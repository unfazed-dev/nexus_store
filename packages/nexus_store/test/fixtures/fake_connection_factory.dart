import 'package:nexus_store/src/pool/connection_factory.dart';

import 'fake_connection.dart';

/// A fake connection factory for testing.
///
/// Provides control flags for simulating various failure scenarios.
class FakeConnectionFactory implements ConnectionFactory<FakeConnection> {
  /// Number of connections created.
  int createCount = 0;

  /// Number of connections destroyed.
  int destroyCount = 0;

  /// Number of validations performed.
  int validateCount = 0;

  /// Whether to fail when creating connections.
  bool shouldFailOnCreate = false;

  /// Whether to fail when validating connections.
  bool shouldFailOnValidate = false;

  /// Whether to fail when destroying connections.
  bool shouldFailOnDestroy = false;

  /// Optional delay before creating a connection.
  Duration? createDelay;

  /// Optional delay before validating a connection.
  Duration? validateDelay;

  /// Custom exception to throw on failure.
  Exception? exceptionToThrow;

  /// List of all created connections.
  final List<FakeConnection> createdConnections = [];

  /// List of all destroyed connections.
  final List<FakeConnection> destroyedConnections = [];

  @override
  Future<FakeConnection> create() async {
    if (createDelay != null) {
      await Future.delayed(createDelay!);
    }

    if (shouldFailOnCreate) {
      throw exceptionToThrow ?? Exception('Failed to create connection');
    }

    createCount++;
    final connection = FakeConnection();
    createdConnections.add(connection);
    return connection;
  }

  @override
  Future<void> destroy(FakeConnection connection) async {
    if (shouldFailOnDestroy) {
      throw exceptionToThrow ?? Exception('Failed to destroy connection');
    }

    destroyCount++;
    connection.close();
    destroyedConnections.add(connection);
  }

  @override
  Future<bool> validate(FakeConnection connection) async {
    if (validateDelay != null) {
      await Future.delayed(validateDelay!);
    }

    validateCount++;

    if (shouldFailOnValidate) {
      return false;
    }

    return connection.isOpen;
  }

  /// Resets all counters and flags.
  void reset() {
    createCount = 0;
    destroyCount = 0;
    validateCount = 0;
    shouldFailOnCreate = false;
    shouldFailOnValidate = false;
    shouldFailOnDestroy = false;
    createDelay = null;
    validateDelay = null;
    exceptionToThrow = null;
    createdConnections.clear();
    destroyedConnections.clear();
    FakeConnection.resetCounter();
  }
}
