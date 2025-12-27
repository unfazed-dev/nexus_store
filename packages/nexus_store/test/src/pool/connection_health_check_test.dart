import 'package:nexus_store/src/pool/connection_health_check.dart';
import 'package:test/test.dart';

import '../../fixtures/fake_connection.dart';

void main() {
  group('ConnectionHealthCheck', () {
    group('NoOpHealthCheck', () {
      late NoOpHealthCheck<FakeConnection> healthCheck;

      setUp(() {
        healthCheck = const NoOpHealthCheck<FakeConnection>();
      });

      test('should always return true for isHealthy', () async {
        final connection = FakeConnection();

        final result = await healthCheck.isHealthy(connection);

        expect(result, isTrue);
      });

      test('should return true for isHealthy even when connection is closed', () async {
        final connection = FakeConnection();
        connection.close();

        final result = await healthCheck.isHealthy(connection);

        expect(result, isTrue);
      });

      test('should always return true for reset', () async {
        final connection = FakeConnection();

        final result = await healthCheck.reset(connection);

        expect(result, isTrue);
      });

      test('should be const constructible', () {
        const check1 = NoOpHealthCheck<FakeConnection>();
        const check2 = NoOpHealthCheck<FakeConnection>();

        expect(identical(check1, check2), isTrue);
      });
    });

    group('FakeHealthCheck', () {
      late FakeHealthCheck healthCheck;

      setUp(() {
        healthCheck = FakeHealthCheck();
      });

      group('isHealthy', () {
        test('should return true for open connection', () async {
          final connection = FakeConnection();

          final result = await healthCheck.isHealthy(connection);

          expect(result, isTrue);
          expect(healthCheck.isHealthyCallCount, equals(1));
        });

        test('should return false for closed connection', () async {
          final connection = FakeConnection();
          connection.close();

          final result = await healthCheck.isHealthy(connection);

          expect(result, isFalse);
        });

        test('should return false when shouldFailHealthCheck is true', () async {
          final connection = FakeConnection();
          healthCheck.shouldFailHealthCheck = true;

          final result = await healthCheck.isHealthy(connection);

          expect(result, isFalse);
        });

        test('should track checked connections', () async {
          final conn1 = FakeConnection('conn-1');
          final conn2 = FakeConnection('conn-2');

          await healthCheck.isHealthy(conn1);
          await healthCheck.isHealthy(conn2);

          expect(healthCheck.checkedConnections, hasLength(2));
          expect(healthCheck.checkedConnections, contains(conn1));
          expect(healthCheck.checkedConnections, contains(conn2));
        });
      });

      group('reset', () {
        test('should return true by default', () async {
          final connection = FakeConnection();

          final result = await healthCheck.reset(connection);

          expect(result, isTrue);
          expect(healthCheck.resetCallCount, equals(1));
        });

        test('should return false when shouldFailReset is true', () async {
          final connection = FakeConnection();
          healthCheck.shouldFailReset = true;

          final result = await healthCheck.reset(connection);

          expect(result, isFalse);
        });

        test('should track reset connections', () async {
          final conn1 = FakeConnection('conn-1');
          final conn2 = FakeConnection('conn-2');

          await healthCheck.reset(conn1);
          await healthCheck.reset(conn2);

          expect(healthCheck.resetConnections, hasLength(2));
          expect(healthCheck.resetConnections, contains(conn1));
          expect(healthCheck.resetConnections, contains(conn2));
        });
      });

      group('reset (method)', () {
        test('should reset all counters and flags', () async {
          final connection = FakeConnection();
          await healthCheck.isHealthy(connection);
          await healthCheck.reset(connection);
          healthCheck.shouldFailHealthCheck = true;
          healthCheck.shouldFailReset = true;

          healthCheck.resetState();

          expect(healthCheck.isHealthyCallCount, equals(0));
          expect(healthCheck.resetCallCount, equals(0));
          expect(healthCheck.shouldFailHealthCheck, isFalse);
          expect(healthCheck.shouldFailReset, isFalse);
          expect(healthCheck.checkedConnections, isEmpty);
          expect(healthCheck.resetConnections, isEmpty);
        });
      });
    });
  });
}

/// A fake health check for testing.
class FakeHealthCheck implements ConnectionHealthCheck<FakeConnection> {
  /// Number of times isHealthy was called.
  int isHealthyCallCount = 0;

  /// Number of times reset was called.
  int resetCallCount = 0;

  /// Whether isHealthy should return false.
  bool shouldFailHealthCheck = false;

  /// Whether reset should return false.
  bool shouldFailReset = false;

  /// List of connections checked via isHealthy.
  final List<FakeConnection> checkedConnections = [];

  /// List of connections reset via reset.
  final List<FakeConnection> resetConnections = [];

  @override
  Future<bool> isHealthy(FakeConnection connection) async {
    isHealthyCallCount++;
    checkedConnections.add(connection);

    if (shouldFailHealthCheck) {
      return false;
    }

    return connection.isOpen;
  }

  @override
  Future<bool> reset(FakeConnection connection) async {
    resetCallCount++;
    resetConnections.add(connection);

    if (shouldFailReset) {
      return false;
    }

    return true;
  }

  /// Resets all counters and flags.
  void resetState() {
    isHealthyCallCount = 0;
    resetCallCount = 0;
    shouldFailHealthCheck = false;
    shouldFailReset = false;
    checkedConnections.clear();
    resetConnections.clear();
  }
}
