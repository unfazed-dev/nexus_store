import 'package:nexus_store/src/pool/pool_metrics.dart';
import 'package:test/test.dart';

void main() {
  group('PoolMetrics', () {
    group('construction', () {
      test('should create with all required fields', () {
        final timestamp = DateTime.now();
        final metrics = PoolMetrics(
          totalConnections: 10,
          idleConnections: 5,
          activeConnections: 5,
          waitingRequests: 2,
          averageAcquireTime: const Duration(milliseconds: 15),
          peakActiveConnections: 8,
          totalConnectionsCreated: 12,
          totalConnectionsDestroyed: 2,
          timestamp: timestamp,
        );

        expect(metrics.totalConnections, equals(10));
        expect(metrics.idleConnections, equals(5));
        expect(metrics.activeConnections, equals(5));
        expect(metrics.waitingRequests, equals(2));
        expect(
          metrics.averageAcquireTime,
          equals(const Duration(milliseconds: 15)),
        );
        expect(metrics.peakActiveConnections, equals(8));
        expect(metrics.totalConnectionsCreated, equals(12));
        expect(metrics.totalConnectionsDestroyed, equals(2));
        expect(metrics.timestamp, equals(timestamp));
      });
    });

    group('empty factory', () {
      test('should create metrics with zero values', () {
        final metrics = PoolMetrics.empty;

        expect(metrics.totalConnections, equals(0));
        expect(metrics.idleConnections, equals(0));
        expect(metrics.activeConnections, equals(0));
        expect(metrics.waitingRequests, equals(0));
        expect(metrics.averageAcquireTime, equals(Duration.zero));
        expect(metrics.peakActiveConnections, equals(0));
        expect(metrics.totalConnectionsCreated, equals(0));
        expect(metrics.totalConnectionsDestroyed, equals(0));
      });

      test('should have a recent timestamp', () {
        final before = DateTime.now();
        final metrics = PoolMetrics.empty;
        final after = DateTime.now();

        expect(
          metrics.timestamp.isAfter(before) ||
              metrics.timestamp.isAtSameMomentAs(before),
          isTrue,
        );
        expect(
          metrics.timestamp.isBefore(after) ||
              metrics.timestamp.isAtSameMomentAs(after),
          isTrue,
        );
      });
    });

    group('copyWith', () {
      test('should create copy with modified totalConnections', () {
        final original = PoolMetrics.empty;
        final copy = original.copyWith(totalConnections: 5);
        expect(copy.totalConnections, equals(5));
        expect(copy.idleConnections, equals(0));
      });

      test('should create copy with modified activeConnections', () {
        final original = PoolMetrics.empty;
        final copy = original.copyWith(activeConnections: 3);
        expect(copy.activeConnections, equals(3));
      });

      test('should create copy with modified averageAcquireTime', () {
        final original = PoolMetrics.empty;
        final copy = original.copyWith(
          averageAcquireTime: const Duration(milliseconds: 50),
        );
        expect(
          copy.averageAcquireTime,
          equals(const Duration(milliseconds: 50)),
        );
      });

      test('should create copy with multiple modified fields', () {
        final original = PoolMetrics.empty;
        final copy = original.copyWith(
          totalConnections: 10,
          idleConnections: 4,
          activeConnections: 6,
          waitingRequests: 1,
        );
        expect(copy.totalConnections, equals(10));
        expect(copy.idleConnections, equals(4));
        expect(copy.activeConnections, equals(6));
        expect(copy.waitingRequests, equals(1));
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
        final metrics1 = PoolMetrics(
          totalConnections: 5,
          idleConnections: 3,
          activeConnections: 2,
          waitingRequests: 0,
          averageAcquireTime: const Duration(milliseconds: 10),
          peakActiveConnections: 4,
          totalConnectionsCreated: 6,
          totalConnectionsDestroyed: 1,
          timestamp: timestamp,
        );
        final metrics2 = PoolMetrics(
          totalConnections: 5,
          idleConnections: 3,
          activeConnections: 2,
          waitingRequests: 0,
          averageAcquireTime: const Duration(milliseconds: 10),
          peakActiveConnections: 4,
          totalConnectionsCreated: 6,
          totalConnectionsDestroyed: 1,
          timestamp: timestamp,
        );
        expect(metrics1, equals(metrics2));
      });

      test('should not be equal for different values', () {
        final timestamp = DateTime.now();
        final metrics1 = PoolMetrics(
          totalConnections: 5,
          idleConnections: 3,
          activeConnections: 2,
          waitingRequests: 0,
          averageAcquireTime: const Duration(milliseconds: 10),
          peakActiveConnections: 4,
          totalConnectionsCreated: 6,
          totalConnectionsDestroyed: 1,
          timestamp: timestamp,
        );
        final metrics2 = PoolMetrics(
          totalConnections: 10, // Different
          idleConnections: 3,
          activeConnections: 2,
          waitingRequests: 0,
          averageAcquireTime: const Duration(milliseconds: 10),
          peakActiveConnections: 4,
          totalConnectionsCreated: 6,
          totalConnectionsDestroyed: 1,
          timestamp: timestamp,
        );
        expect(metrics1, isNot(equals(metrics2)));
      });

      test('should have same hashCode for equal metrics', () {
        final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
        final metrics1 = PoolMetrics(
          totalConnections: 5,
          idleConnections: 3,
          activeConnections: 2,
          waitingRequests: 0,
          averageAcquireTime: const Duration(milliseconds: 10),
          peakActiveConnections: 4,
          totalConnectionsCreated: 6,
          totalConnectionsDestroyed: 1,
          timestamp: timestamp,
        );
        final metrics2 = PoolMetrics(
          totalConnections: 5,
          idleConnections: 3,
          activeConnections: 2,
          waitingRequests: 0,
          averageAcquireTime: const Duration(milliseconds: 10),
          peakActiveConnections: 4,
          totalConnectionsCreated: 6,
          totalConnectionsDestroyed: 1,
          timestamp: timestamp,
        );
        expect(metrics1.hashCode, equals(metrics2.hashCode));
      });
    });

    group('utilization', () {
      test('should calculate utilization rate correctly', () {
        final metrics = PoolMetrics(
          totalConnections: 10,
          idleConnections: 4,
          activeConnections: 6,
          waitingRequests: 0,
          averageAcquireTime: Duration.zero,
          peakActiveConnections: 8,
          totalConnectionsCreated: 10,
          totalConnectionsDestroyed: 0,
          timestamp: DateTime.now(),
        );
        expect(metrics.utilizationRate, closeTo(0.6, 0.001));
      });

      test('should return 0 utilization when no connections', () {
        final metrics = PoolMetrics.empty;
        expect(metrics.utilizationRate, equals(0.0));
      });

      test('should return 1.0 when fully utilized', () {
        final metrics = PoolMetrics(
          totalConnections: 5,
          idleConnections: 0,
          activeConnections: 5,
          waitingRequests: 2,
          averageAcquireTime: Duration.zero,
          peakActiveConnections: 5,
          totalConnectionsCreated: 5,
          totalConnectionsDestroyed: 0,
          timestamp: DateTime.now(),
        );
        expect(metrics.utilizationRate, equals(1.0));
      });
    });
  });
}
