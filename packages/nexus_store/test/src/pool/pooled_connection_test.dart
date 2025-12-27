import 'package:nexus_store/src/pool/pooled_connection.dart';
import 'package:test/test.dart';

void main() {
  group('PooledConnection', () {
    late DateTime createdAt;
    late PooledConnection<_MockConnection> pooledConnection;

    setUp(() {
      createdAt = DateTime.now();
      pooledConnection = PooledConnection<_MockConnection>(
        connection: _MockConnection('test-1'),
        createdAt: createdAt,
      );
    });

    group('initial state', () {
      test('should store the underlying connection', () {
        expect(pooledConnection.connection.id, equals('test-1'));
      });

      test('should have createdAt set to provided time', () {
        expect(pooledConnection.createdAt, equals(createdAt));
      });

      test('should have lastUsedAt set to createdAt initially', () {
        expect(pooledConnection.lastUsedAt, equals(createdAt));
      });

      test('should have useCount of 0 initially', () {
        expect(pooledConnection.useCount, equals(0));
      });

      test('should be healthy initially', () {
        expect(pooledConnection.isHealthy, isTrue);
      });
    });

    group('markUsed', () {
      test('should increment useCount', () {
        pooledConnection.markUsed();
        expect(pooledConnection.useCount, equals(1));
      });

      test('should increment useCount multiple times', () {
        pooledConnection.markUsed();
        pooledConnection.markUsed();
        pooledConnection.markUsed();
        expect(pooledConnection.useCount, equals(3));
      });

      test('should update lastUsedAt', () async {
        await Future.delayed(const Duration(milliseconds: 10));
        pooledConnection.markUsed();
        expect(
          pooledConnection.lastUsedAt.isAfter(createdAt),
          isTrue,
        );
      });
    });

    group('setHealthy', () {
      test('should set healthy to false', () {
        pooledConnection.setHealthy(false);
        expect(pooledConnection.isHealthy, isFalse);
      });

      test('should set healthy to true', () {
        pooledConnection.setHealthy(false);
        pooledConnection.setHealthy(true);
        expect(pooledConnection.isHealthy, isTrue);
      });
    });

    group('age', () {
      test('should return duration since creation', () async {
        await Future.delayed(const Duration(milliseconds: 50));
        final age = pooledConnection.age;
        expect(age.inMilliseconds, greaterThanOrEqualTo(50));
      });

      test('should increase over time', () async {
        final age1 = pooledConnection.age;
        await Future.delayed(const Duration(milliseconds: 20));
        final age2 = pooledConnection.age;
        expect(age2, greaterThan(age1));
      });
    });

    group('idleDuration', () {
      test('should return duration since last use', () async {
        await Future.delayed(const Duration(milliseconds: 50));
        final idle = pooledConnection.idleDuration;
        expect(idle.inMilliseconds, greaterThanOrEqualTo(50));
      });

      test('should reset when markUsed is called', () async {
        await Future.delayed(const Duration(milliseconds: 50));
        pooledConnection.markUsed();
        final idle = pooledConnection.idleDuration;
        expect(idle.inMilliseconds, lessThan(50));
      });
    });

    group('hasExceededLifetime', () {
      test('should return false when age is less than maxLifetime', () {
        final exceeded = pooledConnection.hasExceededLifetime(
          const Duration(hours: 1),
        );
        expect(exceeded, isFalse);
      });

      test('should return true when age exceeds maxLifetime', () {
        // Create a connection with old createdAt
        final oldConnection = PooledConnection<_MockConnection>(
          connection: _MockConnection('old'),
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        );
        final exceeded = oldConnection.hasExceededLifetime(
          const Duration(hours: 1),
        );
        expect(exceeded, isTrue);
      });

      test('should return false when age equals maxLifetime', () {
        final exactTime = DateTime.now();
        final conn = PooledConnection<_MockConnection>(
          connection: _MockConnection('exact'),
          createdAt: exactTime,
        );
        // Age is essentially 0, so shouldn't exceed 0 duration
        final exceeded = conn.hasExceededLifetime(const Duration(seconds: 1));
        expect(exceeded, isFalse);
      });
    });

    group('hasExceededIdleTimeout', () {
      test('should return false when idle time is less than timeout', () {
        final exceeded = pooledConnection.hasExceededIdleTimeout(
          const Duration(minutes: 10),
        );
        expect(exceeded, isFalse);
      });

      test('should return true when idle time exceeds timeout', () {
        // Create a connection that was last used a long time ago
        final oldConnection = PooledConnection<_MockConnection>(
          connection: _MockConnection('idle'),
          createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
        );
        final exceeded = oldConnection.hasExceededIdleTimeout(
          const Duration(minutes: 10),
        );
        expect(exceeded, isTrue);
      });

      test('should return false after markUsed is called', () async {
        // Create old connection
        final oldConnection = PooledConnection<_MockConnection>(
          connection: _MockConnection('was-idle'),
          createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
        );
        // Should exceed idle timeout
        expect(
          oldConnection.hasExceededIdleTimeout(const Duration(minutes: 10)),
          isTrue,
        );
        // Mark as used
        oldConnection.markUsed();
        // Should no longer exceed idle timeout
        expect(
          oldConnection.hasExceededIdleTimeout(const Duration(minutes: 10)),
          isFalse,
        );
      });
    });

    group('generic type', () {
      test('should work with different connection types', () {
        final stringConnection = PooledConnection<String>(
          connection: 'test-string',
          createdAt: DateTime.now(),
        );
        expect(stringConnection.connection, equals('test-string'));
      });

      test('should work with complex types', () {
        final mapConnection = PooledConnection<Map<String, dynamic>>(
          connection: {'id': 1, 'name': 'test'},
          createdAt: DateTime.now(),
        );
        expect(mapConnection.connection['id'], equals(1));
      });
    });
  });
}

/// Mock connection class for testing.
class _MockConnection {
  _MockConnection(this.id);

  final String id;
}
