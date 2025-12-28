import 'package:nexus_store/src/errors/store_errors.dart';
import 'package:test/test.dart';

void main() {
  group('PoolError', () {
    group('PoolNotInitializedError', () {
      test('should have correct message', () {
        const error = PoolNotInitializedError(
          message: 'Pool not initialized',
        );
        expect(error.message, equals('Pool not initialized'));
      });

      test('should have correct error code', () {
        const error = PoolNotInitializedError(
          message: 'Pool not initialized',
        );
        expect(error.code, equals('POOL_NOT_INITIALIZED'));
      });

      test('should have correct errorName', () {
        const error = PoolNotInitializedError(
          message: 'Pool not initialized',
        );
        expect(error.errorName, equals('PoolNotInitializedError'));
      });

      test('should not be retryable', () {
        const error = PoolNotInitializedError(
          message: 'Pool not initialized',
        );
        expect(error.isRetryable, isFalse);
      });

      test('should be a StoreError', () {
        const error = PoolNotInitializedError(
          message: 'Pool not initialized',
        );
        expect(error, isA<StoreError>());
      });

      test('should be a PoolError', () {
        const error = PoolNotInitializedError(
          message: 'Pool not initialized',
        );
        expect(error, isA<PoolError>());
      });
    });

    group('PoolDisposedError', () {
      test('should have correct message', () {
        const error = PoolDisposedError(
          message: 'Pool has been disposed',
        );
        expect(error.message, equals('Pool has been disposed'));
      });

      test('should have correct error code', () {
        const error = PoolDisposedError(
          message: 'Pool has been disposed',
        );
        expect(error.code, equals('POOL_DISPOSED'));
      });

      test('should have correct errorName', () {
        const error = PoolDisposedError(
          message: 'Pool has been disposed',
        );
        expect(error.errorName, equals('PoolDisposedError'));
      });

      test('should not be retryable', () {
        const error = PoolDisposedError(
          message: 'Pool has been disposed',
        );
        expect(error.isRetryable, isFalse);
      });
    });

    group('PoolAcquireTimeoutError', () {
      test('should have correct message', () {
        const error = PoolAcquireTimeoutError(
          message: 'Failed to acquire connection within 30s',
        );
        expect(error.message, equals('Failed to acquire connection within 30s'));
      });

      test('should have correct error code', () {
        const error = PoolAcquireTimeoutError(
          message: 'Timeout',
        );
        expect(error.code, equals('POOL_ACQUIRE_TIMEOUT'));
      });

      test('should have correct errorName', () {
        const error = PoolAcquireTimeoutError(
          message: 'Timeout',
        );
        expect(error.errorName, equals('PoolAcquireTimeoutError'));
      });

      test('should be retryable', () {
        const error = PoolAcquireTimeoutError(
          message: 'Timeout',
        );
        expect(error.isRetryable, isTrue);
      });
    });

    group('PoolClosedError', () {
      test('should have correct message', () {
        const error = PoolClosedError(
          message: 'Pool is closing',
        );
        expect(error.message, equals('Pool is closing'));
      });

      test('should have correct error code', () {
        const error = PoolClosedError(
          message: 'Pool is closing',
        );
        expect(error.code, equals('POOL_CLOSED'));
      });

      test('should have correct errorName', () {
        const error = PoolClosedError(
          message: 'Pool is closing',
        );
        expect(error.errorName, equals('PoolClosedError'));
      });

      test('should not be retryable', () {
        const error = PoolClosedError(
          message: 'Pool is closing',
        );
        expect(error.isRetryable, isFalse);
      });
    });

    group('PoolExhaustedError', () {
      test('should have correct message', () {
        const error = PoolExhaustedError(
          message: 'Connection pool exhausted',
        );
        expect(error.message, equals('Connection pool exhausted'));
      });

      test('should have correct error code', () {
        const error = PoolExhaustedError(
          message: 'Pool exhausted',
        );
        expect(error.code, equals('POOL_EXHAUSTED'));
      });

      test('should have correct errorName', () {
        const error = PoolExhaustedError(
          message: 'Pool exhausted',
        );
        expect(error.errorName, equals('PoolExhaustedError'));
      });

      test('should be retryable', () {
        const error = PoolExhaustedError(
          message: 'Pool exhausted',
        );
        expect(error.isRetryable, isTrue);
      });
    });

    group('PoolConnectionError', () {
      test('should have correct message', () {
        const error = PoolConnectionError(
          message: 'Failed to create connection',
        );
        expect(error.message, equals('Failed to create connection'));
      });

      test('should have correct error code', () {
        const error = PoolConnectionError(
          message: 'Connection error',
        );
        expect(error.code, equals('POOL_CONNECTION_ERROR'));
      });

      test('should have correct errorName', () {
        const error = PoolConnectionError(
          message: 'Connection error',
        );
        expect(error.errorName, equals('PoolConnectionError'));
      });

      test('should be retryable', () {
        const error = PoolConnectionError(
          message: 'Connection error',
        );
        expect(error.isRetryable, isTrue);
      });

      test('should support cause', () {
        final cause = Exception('Underlying error');
        final error = PoolConnectionError(
          message: 'Connection error',
          cause: cause,
        );
        expect(error.cause, equals(cause));
      });
    });

    group('toString', () {
      test('should include error name and message', () {
        const error = PoolNotInitializedError(
          message: 'Pool not initialized',
        );
        final str = error.toString();
        expect(str, contains('PoolNotInitializedError'));
        expect(str, contains('Pool not initialized'));
      });

      test('should include error code', () {
        const error = PoolAcquireTimeoutError(
          message: 'Timeout',
        );
        final str = error.toString();
        expect(str, contains('POOL_ACQUIRE_TIMEOUT'));
      });

      test('should include cause if present', () {
        final error = PoolConnectionError(
          message: 'Failed',
          cause: Exception('Underlying error'),
        );
        final str = error.toString();
        expect(str, contains('Caused by'));
        expect(str, contains('Underlying error'));
      });
    });
  });
}
