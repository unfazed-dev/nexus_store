import 'package:nexus_store/src/pool/connection_pool.dart';
import 'package:nexus_store/src/pool/connection_pool_config.dart';
import 'package:nexus_store/src/pool/connection_scope.dart';
import 'package:test/test.dart';

import '../../fixtures/fake_connection.dart';
import '../../fixtures/fake_connection_factory.dart';

void main() {
  group('ConnectionScope', () {
    late FakeConnectionFactory factory;
    late ConnectionPool<FakeConnection> pool;

    setUp(() async {
      FakeConnection.resetCounter();
      factory = FakeConnectionFactory();
      pool = ConnectionPool<FakeConnection>(
        factory: factory,
        config: const ConnectionPoolConfig(
          minConnections: 0,
          maxConnections: 10,
        ),
      );
      await pool.initialize();
    });

    tearDown(() async {
      if (pool.isInitialized && !pool.isDisposed) {
        await pool.close();
      }
    });

    group('borrow', () {
      test('should borrow a connection from pool', () async {
        final scope = ConnectionScope<FakeConnection>(pool);

        final connection = await scope.borrow();

        expect(connection, isNotNull);
        expect(connection.isOpen, isTrue);
      });

      test('should track borrowed connections count', () async {
        final scope = ConnectionScope<FakeConnection>(pool);
        expect(scope.borrowedCount, equals(0));

        await scope.borrow();
        expect(scope.borrowedCount, equals(1));

        await scope.borrow();
        expect(scope.borrowedCount, equals(2));
      });

      test('should allow borrowing multiple connections', () async {
        final scope = ConnectionScope<FakeConnection>(pool);

        final conn1 = await scope.borrow();
        final conn2 = await scope.borrow();
        final conn3 = await scope.borrow();

        expect(conn1.id, isNot(equals(conn2.id)));
        expect(conn2.id, isNot(equals(conn3.id)));
        expect(scope.borrowedCount, equals(3));
      });
    });

    group('releaseAll', () {
      test('should release all borrowed connections', () async {
        final scope = ConnectionScope<FakeConnection>(pool);
        await scope.borrow();
        await scope.borrow();
        await scope.borrow();
        expect(pool.currentMetrics.activeConnections, equals(3));

        scope.releaseAll();
        await Future.delayed(Duration.zero);

        expect(scope.borrowedCount, equals(0));
        expect(pool.currentMetrics.activeConnections, equals(0));
      });

      test('should be idempotent', () async {
        final scope = ConnectionScope<FakeConnection>(pool);
        await scope.borrow();
        await scope.borrow();

        scope.releaseAll();
        scope.releaseAll();
        scope.releaseAll();

        expect(scope.borrowedCount, equals(0));
      });

      test('should do nothing when no connections borrowed', () {
        final scope = ConnectionScope<FakeConnection>(pool);

        scope.releaseAll();

        expect(scope.borrowedCount, equals(0));
      });
    });

    group('isEmpty', () {
      test('should return true when no connections borrowed', () {
        final scope = ConnectionScope<FakeConnection>(pool);

        expect(scope.isEmpty, isTrue);
      });

      test('should return false when connections are borrowed', () async {
        final scope = ConnectionScope<FakeConnection>(pool);
        await scope.borrow();

        expect(scope.isEmpty, isFalse);
      });
    });
  });

  group('ConnectionPoolScopeExtension', () {
    late FakeConnectionFactory factory;
    late ConnectionPool<FakeConnection> pool;

    setUp(() async {
      FakeConnection.resetCounter();
      factory = FakeConnectionFactory();
      pool = ConnectionPool<FakeConnection>(
        factory: factory,
        config: const ConnectionPoolConfig(
          minConnections: 0,
          maxConnections: 10,
        ),
      );
      await pool.initialize();
    });

    tearDown(() async {
      if (pool.isInitialized && !pool.isDisposed) {
        await pool.close();
      }
    });

    test('withScope should provide scope and release on completion', () async {
      final result = await pool.withScope((scope) async {
        final conn = await scope.borrow();
        expect(pool.currentMetrics.activeConnections, equals(1));
        return conn.id;
      });

      await Future.delayed(Duration.zero);
      expect(result, isNotNull);
      expect(pool.currentMetrics.activeConnections, equals(0));
    });

    test('withScope should release on error', () async {
      try {
        await pool.withScope((scope) async {
          await scope.borrow();
          await scope.borrow();
          throw Exception('Test error');
        });
      } catch (_) {}

      await Future.delayed(Duration.zero);
      expect(pool.currentMetrics.activeConnections, equals(0));
    });

    test('withScope should propagate exceptions', () async {
      expect(
        () => pool.withScope((scope) async {
          throw Exception('Test error');
        }),
        throwsException,
      );
    });

    test('withScope should allow multiple borrows', () async {
      final ids = await pool.withScope((scope) async {
        final conn1 = await scope.borrow();
        final conn2 = await scope.borrow();
        final conn3 = await scope.borrow();
        return [conn1.id, conn2.id, conn3.id];
      });

      expect(ids.length, equals(3));
      expect(ids.toSet().length, equals(3)); // All unique
    });
  });
}
