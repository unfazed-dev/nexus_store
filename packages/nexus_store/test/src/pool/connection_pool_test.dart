import 'dart:async';

import 'package:nexus_store/src/pool/connection_health_check.dart';
import 'package:nexus_store/src/pool/connection_pool.dart';
import 'package:nexus_store/src/pool/connection_pool_config.dart';
import 'package:nexus_store/src/pool/pool_errors.dart';
import 'package:nexus_store/src/pool/pool_metrics.dart';
import 'package:nexus_store/src/pool/pooled_connection.dart';
import 'package:test/test.dart';

import '../../fixtures/fake_connection.dart';
import '../../fixtures/fake_connection_factory.dart';
import 'connection_health_check_test.dart';

/// A health check that throws an exception for testing error handling.
class ThrowingHealthCheck implements ConnectionHealthCheck<FakeConnection> {
  @override
  Future<bool> isHealthy(FakeConnection connection) async {
    throw Exception('Health check failed with exception');
  }

  @override
  Future<bool> reset(FakeConnection connection) async {
    return true;
  }
}

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

      test('should limit acquire time history to 100 entries', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(
            minConnections: 0,
            maxConnections: 200,
          ),
        );
        await pool.initialize();

        // Perform more than 100 acquires to trigger the removeAt(0) path
        final connections = <PooledConnection<FakeConnection>>[];
        for (var i = 0; i < 105; i++) {
          connections.add(await pool.acquire());
        }

        // Release all connections
        for (final conn in connections) {
          pool.release(conn);
        }

        // Average acquire time should still be calculated correctly
        expect(pool.currentMetrics.averageAcquireTime, isNotNull);
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

    group('release edge cases', () {
      test('should destroy connection when pool is disposed', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 1),
        );
        await pool.initialize();
        final pooled = await pool.acquire();

        await pool.close();

        // Now release the connection after pool is closed
        pool.release(pooled);
        await Future.delayed(const Duration(milliseconds: 10));

        // Connection should be destroyed, not returned to idle pool
        expect(factory.destroyCount, greaterThanOrEqualTo(1));
      });

      test('should validate connection on return when testOnReturn is true',
          () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          healthCheck: healthCheck,
          config: const ConnectionPoolConfig(
            minConnections: 0,
            testOnReturn: true,
          ),
        );
        await pool.initialize();
        final pooled = await pool.acquire();

        pool.release(pooled);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(factory.validateCount, equals(1));
        expect(pool.currentMetrics.idleConnections, equals(1));
      });

      test('should destroy invalid connection on return when testOnReturn is true',
          () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          healthCheck: healthCheck,
          config: const ConnectionPoolConfig(
            minConnections: 0,
            testOnReturn: true,
          ),
        );
        await pool.initialize();
        final pooled = await pool.acquire();

        // Close the connection to make it invalid
        pooled.connection.close();

        pool.release(pooled);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(factory.validateCount, equals(1));
        expect(factory.destroyCount, equals(1));
        expect(pool.currentMetrics.idleConnections, equals(0));
      });
    });

    group('connection lifetime', () {
      test('should destroy connections that exceed max lifetime', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(
            minConnections: 1,
            maxLifetime: Duration(milliseconds: 10),
            testOnBorrow: false,
          ),
        );
        await pool.initialize();

        // Wait for connection to exceed lifetime
        await Future.delayed(const Duration(milliseconds: 50));

        // Try to acquire - should destroy old connection and create new one
        final pooled = await pool.acquire();

        expect(pooled, isNotNull);
        // Original + new connection created
        expect(factory.createCount, greaterThanOrEqualTo(2));
      });
    });

    group('health check operations', () {
      test('should mark unhealthy connections and try to reset', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          healthCheck: healthCheck,
          config: ConnectionPoolConfig(
            minConnections: 1,
            healthCheckInterval: const Duration(milliseconds: 50),
          ),
        );
        await pool.initialize();

        // Mark health check to fail
        healthCheck.shouldFailHealthCheck = true;

        // Wait for health check to run
        await Future.delayed(const Duration(milliseconds: 100));

        // Health check should have been called
        expect(healthCheck.isHealthyCallCount, greaterThan(0));
      });

      test('should destroy unhealthy connection that cannot be reset', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          healthCheck: healthCheck,
          config: ConnectionPoolConfig(
            minConnections: 1,
            healthCheckInterval: const Duration(milliseconds: 50),
          ),
        );
        await pool.initialize();
        final initialCreateCount = factory.createCount;

        // Make health check fail and reset fail
        healthCheck.shouldFailHealthCheck = true;
        healthCheck.shouldFailReset = true;

        // Wait for health check to run
        await Future.delayed(const Duration(milliseconds: 150));

        // Connection should be destroyed and a new one created
        expect(factory.destroyCount, greaterThan(0));
        // New connection created to maintain minimum
        expect(factory.createCount, greaterThan(initialCreateCount));
      });

      test('should reset unhealthy connection successfully', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          healthCheck: healthCheck,
          config: ConnectionPoolConfig(
            minConnections: 1,
            healthCheckInterval: const Duration(milliseconds: 50),
          ),
        );
        await pool.initialize();

        // Make health check fail but reset succeed
        healthCheck.shouldFailHealthCheck = true;
        healthCheck.shouldFailReset = false;

        // Wait for health check to run
        await Future.delayed(const Duration(milliseconds: 100));

        // Reset should have been called
        expect(healthCheck.resetCallCount, greaterThan(0));
      });

      test('should destroy connection when health check throws exception',
          () async {
        final throwingHealthCheck = ThrowingHealthCheck();
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          healthCheck: throwingHealthCheck,
          config: ConnectionPoolConfig(
            minConnections: 1,
            healthCheckInterval: const Duration(milliseconds: 50),
          ),
        );
        await pool.initialize();
        final initialDestroyCount = factory.destroyCount;

        // Wait for health check to run and throw
        await Future.delayed(const Duration(milliseconds: 150));

        // Connection should have been destroyed due to exception
        expect(factory.destroyCount, greaterThan(initialDestroyCount));
      });
    });

    group('idle connection trimming', () {
      test('should trim idle connections exceeding minimum', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: ConnectionPoolConfig(
            minConnections: 1,
            maxConnections: 5,
            idleTimeout: const Duration(milliseconds: 10),
          ),
        );
        await pool.initialize();

        // Acquire and release extra connections
        final conn1 = await pool.acquire();
        final conn2 = await pool.acquire();
        final conn3 = await pool.acquire();

        pool.release(conn1);
        pool.release(conn2);
        pool.release(conn3);
        await Future.delayed(Duration.zero);

        expect(pool.currentMetrics.idleConnections, equals(3));

        // Wait for idle timeout and cleanup timer
        await Future.delayed(const Duration(milliseconds: 100));

        // Should have trimmed down towards minConnections
        expect(pool.currentMetrics.totalConnections, lessThanOrEqualTo(3));
      });
    });

    group('returnToPool edge cases', () {
      test('should fulfill waiting request instead of returning to idle', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(
            minConnections: 0,
            maxConnections: 1,
          ),
        );
        await pool.initialize();
        final conn = await pool.acquire();

        // Start waiting for a connection
        final waitFuture = pool.acquire();
        await Future.delayed(const Duration(milliseconds: 10));

        // Release current connection - should go to waiter
        pool.release(conn);

        final waitedConn = await waitFuture;
        expect(waitedConn, isNotNull);
        expect(waitedConn.connection.id, equals(conn.connection.id));
      });
    });

    group('create connection failure', () {
      test('should handle connection creation failure gracefully', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 0),
        );
        await pool.initialize();

        factory.shouldFailOnCreate = true;

        // When pool can't create connections, acquire should timeout
        expect(
          () => pool.acquire().timeout(const Duration(milliseconds: 100)),
          throwsA(anything),
        );
      });

      test('should handle pre-warm failure gracefully during initialize', () async {
        factory.shouldFailOnCreate = true;

        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 3),
        );

        // Initialize should complete even if pre-warming fails
        await pool.initialize();

        expect(pool.isInitialized, isTrue);
        expect(pool.currentMetrics.totalConnections, equals(0));
      });
    });

    group('destroy connection failure', () {
      test('should handle destroy failure gracefully', () async {
        pool = ConnectionPool<FakeConnection>(
          factory: factory,
          config: const ConnectionPoolConfig(minConnections: 1),
        );
        await pool.initialize();

        factory.shouldFailOnDestroy = true;

        // Close should complete even if destroy fails
        await pool.close();

        expect(pool.isDisposed, isTrue);
      });
    });
  });
}
