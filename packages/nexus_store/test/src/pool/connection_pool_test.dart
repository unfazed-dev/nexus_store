import 'dart:async';

import 'package:nexus_store/src/pool/connection_pool.dart';
import 'package:nexus_store/src/pool/connection_pool_config.dart';
import 'package:nexus_store/src/pool/pool_errors.dart';
import 'package:nexus_store/src/pool/pool_metrics.dart';
import 'package:nexus_store/src/pool/pooled_connection.dart';
import 'package:test/test.dart';

import '../../fixtures/fake_connection.dart';
import '../../fixtures/fake_connection_factory.dart';
import 'connection_health_check_test.dart';

void main() {
  group('ConnectionPool', () {
    late FakeConnectionFactory factory;
    late FakeHealthCheck healthCheck;
    late ConnectionPool<FakeConnection> pool;

    setUp(() {
      FakeConnection.resetCounter();
      factory = FakeConnectionFactory();
      healthCheck = FakeHealthCheck();
    });

    tearDown(() async {
      if (pool.isInitialized && !pool.isDisposed) {
        await pool.close();
      }
    });

    group('lifecycle', () {
      test('should not be initialized before initialize() is called', () {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 0),
        );

        expect(pool.isInitialized, isFalse);
        expect(pool.isDisposed, isFalse);
      });

      test('should be initialized after initialize() is called', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 0),
        );

        await pool.initialize();

        expect(pool.isInitialized, isTrue);
        expect(pool.isDisposed, isFalse);
      });

      test('should pre-warm pool with minConnections', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 3),
        );

        await pool.initialize();

        expect(factory.createCount, equals(3));
        expect(pool.currentMetrics.idleConnections, equals(3));
      });

      test('should be idempotent for multiple initialize calls', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 2),
        );

        await pool.initialize();
        await pool.initialize();
        await pool.initialize();

        expect(factory.createCount, equals(2));
      });

      test('should throw when initialize() called on disposed pool', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 0),
        );
        await pool.initialize();
        await pool.close();

        expect(
          () => pool.initialize(),
          throwsA(isA<PoolDisposedError>()),
        );
      });

      test('should be disposed after close() is called', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 2),
        );
        await pool.initialize();

        await pool.close();

        expect(pool.isDisposed, isTrue);
      });

      test('should destroy all connections on close', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 3),
        );
        await pool.initialize();

        await pool.close();

        expect(factory.destroyCount, equals(3));
      });

      test('should be idempotent for multiple close calls', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 2),
        );
        await pool.initialize();

        await pool.close();
        await pool.close();
        await pool.close();

        expect(factory.destroyCount, equals(2));
      });
    });

    group('acquire', () {
      test('should throw when pool is not initialized', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 0),
        );

        expect(
          () => pool.acquire(),
          throwsA(isA<PoolNotInitializedError>()),
        );
      });

      test('should throw when pool is disposed', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 0),
        );
        await pool.initialize();
        await pool.close();

        expect(
          () => pool.acquire(),
          throwsA(isA<PoolDisposedError>()),
        );
      });

      test('should return connection from idle pool', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 1),
        );
        await pool.initialize();

        final pooled = await pool.acquire();

        expect(pooled, isNotNull);
        expect(pooled.connection.isOpen, isTrue);
      });

      test('should create new connection when idle pool is empty', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 0),
        );
        await pool.initialize();

        final pooled = await pool.acquire();

        expect(pooled, isNotNull);
        expect(factory.createCount, equals(1));
      });

      test('should mark connection as used when acquired', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 1),
        );
        await pool.initialize();

        final pooled = await pool.acquire();

        expect(pooled.useCount, equals(1));
      });

      test('should update metrics when connection acquired', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 2),
        );
        await pool.initialize();

        await pool.acquire();

        expect(pool.currentMetrics.activeConnections, equals(1));
        expect(pool.currentMetrics.idleConnections, equals(1));
      });
    });

    group('release', () {
      test('should return connection to idle pool', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 1),
        );
        await pool.initialize();
        final pooled = await pool.acquire();
        expect(pool.currentMetrics.idleConnections, equals(0));

        pool.release(pooled);
        // Give time for async release to complete
        await Future.delayed(Duration.zero);

        expect(pool.currentMetrics.idleConnections, equals(1));
        expect(pool.currentMetrics.activeConnections, equals(0));
      });

      test('should allow connection reuse after release', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 0),
        );
        await pool.initialize();
        final pooled1 = await pool.acquire();
        final connectionId = pooled1.connection.id;
        pool.release(pooled1);
        await Future.delayed(Duration.zero);

        final pooled2 = await pool.acquire();

        expect(pooled2.connection.id, equals(connectionId));
        expect(factory.createCount, equals(1));
      });

      test('should increment useCount on reuse', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 0),
        );
        await pool.initialize();
        final pooled1 = await pool.acquire();
        pool.release(pooled1);
        await Future.delayed(Duration.zero);

        final pooled2 = await pool.acquire();

        expect(pooled2.useCount, equals(2));
      });
    });

    group('pool sizing', () {
      test('should not exceed maxConnections', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(
            minConnections: 0,
            maxConnections: 2,
            acquireTimeout: Duration(milliseconds: 100),
          ),
        );
        await pool.initialize();

        // Acquire all connections
        await pool.acquire();
        await pool.acquire();

        // Third acquire should timeout
        expect(
          () => pool.acquire(),
          throwsA(isA<PoolAcquireTimeoutError>()),
        );
      });

      test('should track total connections correctly', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(
            minConnections: 1,
            maxConnections: 5,
          ),
        );
        await pool.initialize();

        await pool.acquire();
        await pool.acquire();

        expect(pool.currentMetrics.totalConnections, equals(2));
      });
    });

    group('waiting queue', () {
      test('should queue requests when pool exhausted', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(
            minConnections: 0,
            maxConnections: 1,
          ),
        );
        await pool.initialize();
        final conn1 = await pool.acquire();

        // Start waiting for second connection
        final future = pool.acquire();
        await Future.delayed(const Duration(milliseconds: 10));
        expect(pool.currentMetrics.waitingRequests, equals(1));

        // Release first connection
        pool.release(conn1);

        // Second acquire should complete
        final conn2 = await future;
        expect(conn2, isNotNull);
      });

      test('should process waiting requests in FIFO order', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(
            minConnections: 0,
            maxConnections: 1,
          ),
        );
        await pool.initialize();
        final conn = await pool.acquire();

        final results = <int>[];
        late PooledConnection<FakeConnection> conn1;
        final future1 = pool.acquire().then((c) {
          conn1 = c;
          results.add(1);
        });
        final future2 = pool.acquire().then((_) {
          results.add(2);
        });
        await Future.delayed(const Duration(milliseconds: 10));

        // Release conn - should go to future1
        pool.release(conn);
        await future1;

        // Release conn1 - should go to future2
        pool.release(conn1);
        await future2;

        expect(results, equals([1, 2]));
      });

      test('should timeout waiting requests', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(
            minConnections: 0,
            maxConnections: 1,
            acquireTimeout: Duration(milliseconds: 50),
          ),
        );
        await pool.initialize();
        await pool.acquire();

        expect(
          () => pool.acquire(),
          throwsA(isA<PoolAcquireTimeoutError>()),
        );
      });

      test('should reject waiting requests on close', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(
            minConnections: 0,
            maxConnections: 1,
          ),
        );
        await pool.initialize();
        await pool.acquire();

        final future = pool.acquire();
        await Future.delayed(const Duration(milliseconds: 10));

        // Set up expectation BEFORE closing to catch the error
        final expectation = expectLater(
          future,
          throwsA(isA<PoolClosedError>()),
        );

        await pool.close();
        await expectation;
      });
    });

    group('validation', () {
      test('should validate connection on borrow when testOnBorrow is true',
          () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          healthCheck: healthCheck,
          config: const ConnectionPoolConfig(
            minConnections: 1,
            testOnBorrow: true,
          ),
        );
        await pool.initialize();

        await pool.acquire();

        expect(factory.validateCount, equals(1));
      });

      test('should skip validation when testOnBorrow is false', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          healthCheck: healthCheck,
          config: const ConnectionPoolConfig(
            minConnections: 1,
            testOnBorrow: false,
          ),
        );
        await pool.initialize();

        await pool.acquire();

        expect(factory.validateCount, equals(0));
      });

      test('should destroy invalid connection and get another', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          healthCheck: healthCheck,
          config: const ConnectionPoolConfig(
            minConnections: 2,
            testOnBorrow: true,
          ),
        );
        await pool.initialize();
        // Make first validation fail by closing the first connection
        factory.shouldFailOnValidate = false;
        // We need to make the first connection invalid
        // Since we can't control which one is picked, we'll close the first created
        factory.createdConnections.first.close();

        final pooled = await pool.acquire();

        expect(pooled.connection.isOpen, isTrue);
      });
    });

    group('withConnection', () {
      test('should acquire and release connection automatically', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 1),
        );
        await pool.initialize();

        final result = await pool.withConnection((conn) async {
          expect(pool.currentMetrics.activeConnections, equals(1));
          return conn.id;
        });

        expect(result, isNotNull);
        await Future.delayed(Duration.zero);
        expect(pool.currentMetrics.activeConnections, equals(0));
      });

      test('should release connection on error', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 1),
        );
        await pool.initialize();

        try {
          await pool.withConnection((conn) async {
            throw Exception('Test error');
          });
        } catch (_) {}

        await Future.delayed(Duration.zero);
        expect(pool.currentMetrics.activeConnections, equals(0));
      });

      test('should propagate exceptions', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 1),
        );
        await pool.initialize();

        expect(
          () => pool.withConnection((conn) async {
            throw Exception('Test error');
          }),
          throwsException,
        );
      });
    });

    group('metrics', () {
      test('should provide current metrics', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 2),
        );
        await pool.initialize();

        final metrics = pool.currentMetrics;

        expect(metrics.totalConnections, equals(2));
        expect(metrics.idleConnections, equals(2));
        expect(metrics.activeConnections, equals(0));
      });

      test('should stream metrics updates', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 1),
        );
        await pool.initialize();

        final metricsList = <PoolMetrics>[];
        final subscription = pool.metricsStream.listen(metricsList.add);

        await pool.acquire();
        await Future.delayed(const Duration(milliseconds: 50));

        await subscription.cancel();

        expect(metricsList.length, greaterThanOrEqualTo(1));
        expect(metricsList.any((m) => m.activeConnections == 1), isTrue);
      });

      test('should track peak active connections', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(
            minConnections: 0,
            maxConnections: 5,
          ),
        );
        await pool.initialize();

        final conn1 = await pool.acquire();
        final conn2 = await pool.acquire();
        final conn3 = await pool.acquire();
        pool.release(conn1);
        pool.release(conn2);
        pool.release(conn3);

        expect(pool.currentMetrics.peakActiveConnections, equals(3));
      });

      test('should track total connections created', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 0),
        );
        await pool.initialize();

        await pool.acquire();
        await pool.acquire();
        await pool.acquire();

        expect(pool.currentMetrics.totalConnectionsCreated, equals(3));
      });
    });

    group('config access', () {
      test('should expose configuration', () {
        const config = ConnectionPoolConfig(
          minConnections: 5,
          maxConnections: 20,
        );
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: config,
        );

        expect(pool.config, equals(config));
      });
    });
  });
}
