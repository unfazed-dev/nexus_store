import 'package:nexus_store/src/telemetry/error_metric.dart';
import 'package:test/test.dart';

void main() {
  group('ErrorMetric', () {
    final testTimestamp = DateTime(2024, 1, 15, 10, 30, 0);
    final testStackTrace = StackTrace.current;

    group('construction', () {
      test('should create with required fields', () {
        final metric = ErrorMetric(
          error: Exception('Test error'),
          timestamp: testTimestamp,
        );

        expect(metric.error, isA<Exception>());
        expect(metric.timestamp, equals(testTimestamp));
      });

      test('should have false default for recoverable', () {
        final metric = ErrorMetric(
          error: 'Simple error',
          timestamp: testTimestamp,
        );

        expect(metric.recoverable, isFalse);
      });

      test('should have null default for stackTrace', () {
        final metric = ErrorMetric(
          error: Exception('Test'),
          timestamp: testTimestamp,
        );

        expect(metric.stackTrace, isNull);
      });

      test('should have null default for operation', () {
        final metric = ErrorMetric(
          error: Exception('Test'),
          timestamp: testTimestamp,
        );

        expect(metric.operation, isNull);
      });

      test('should accept all fields', () {
        final metric = ErrorMetric(
          error: StateError('Invalid state'),
          stackTrace: testStackTrace,
          operation: 'save',
          recoverable: true,
          timestamp: testTimestamp,
        );

        expect(metric.error, isA<StateError>());
        expect(metric.stackTrace, equals(testStackTrace));
        expect(metric.operation, equals('save'));
        expect(metric.recoverable, isTrue);
      });
    });

    group('error types', () {
      test('should accept Exception', () {
        final metric = ErrorMetric(
          error: Exception('Test exception'),
          timestamp: testTimestamp,
        );

        expect(metric.error, isA<Exception>());
      });

      test('should accept Error', () {
        final metric = ErrorMetric(
          error: StateError('Invalid state'),
          timestamp: testTimestamp,
        );

        expect(metric.error, isA<Error>());
      });

      test('should accept String', () {
        final metric = ErrorMetric(
          error: 'Simple error message',
          timestamp: testTimestamp,
        );

        expect(metric.error, isA<String>());
        expect(metric.error, equals('Simple error message'));
      });

      test('should accept custom error object', () {
        final customError = {'code': 404, 'message': 'Not found'};
        final metric = ErrorMetric(
          error: customError,
          timestamp: testTimestamp,
        );

        expect(metric.error, equals(customError));
      });
    });

    group('equality', () {
      test('should be equal with same values', () {
        final error = Exception('Test');
        final metric1 = ErrorMetric(
          error: error,
          operation: 'get',
          recoverable: false,
          timestamp: testTimestamp,
        );

        final metric2 = ErrorMetric(
          error: error,
          operation: 'get',
          recoverable: false,
          timestamp: testTimestamp,
        );

        expect(metric1, equals(metric2));
        expect(metric1.hashCode, equals(metric2.hashCode));
      });

      test('should not be equal with different error', () {
        final metric1 = ErrorMetric(
          error: Exception('Error 1'),
          timestamp: testTimestamp,
        );

        final metric2 = ErrorMetric(
          error: Exception('Error 2'),
          timestamp: testTimestamp,
        );

        expect(metric1, isNot(equals(metric2)));
      });

      test('should not be equal with different operation', () {
        final error = Exception('Test');
        final metric1 = ErrorMetric(
          error: error,
          operation: 'get',
          timestamp: testTimestamp,
        );

        final metric2 = ErrorMetric(
          error: error,
          operation: 'save',
          timestamp: testTimestamp,
        );

        expect(metric1, isNot(equals(metric2)));
      });

      test('should not be equal with different recoverable', () {
        final error = Exception('Test');
        final metric1 = ErrorMetric(
          error: error,
          recoverable: true,
          timestamp: testTimestamp,
        );

        final metric2 = ErrorMetric(
          error: error,
          recoverable: false,
          timestamp: testTimestamp,
        );

        expect(metric1, isNot(equals(metric2)));
      });
    });

    group('copyWith', () {
      test('should create copy with modified error', () {
        final original = ErrorMetric(
          error: Exception('Original'),
          timestamp: testTimestamp,
        );

        final newError = Exception('New');
        final copy = original.copyWith(error: newError);

        expect(copy.error, equals(newError));
        expect(copy.timestamp, equals(original.timestamp));
      });

      test('should create copy with modified operation', () {
        final original = ErrorMetric(
          error: Exception('Test'),
          operation: 'get',
          timestamp: testTimestamp,
        );

        final copy = original.copyWith(operation: 'save');

        expect(copy.operation, equals('save'));
      });

      test('should create copy with modified recoverable', () {
        final original = ErrorMetric(
          error: Exception('Test'),
          recoverable: false,
          timestamp: testTimestamp,
        );

        final copy = original.copyWith(recoverable: true);

        expect(copy.recoverable, isTrue);
      });

      test('should preserve original when copying', () {
        final original = ErrorMetric(
          error: Exception('Original'),
          operation: 'get',
          timestamp: testTimestamp,
        );

        final copy = original.copyWith(operation: 'save');

        expect(original.operation, equals('get'));
        expect(copy.operation, equals('save'));
      });
    });

    group('operation scenarios', () {
      test('should track error in get operation', () {
        final metric = ErrorMetric(
          error: Exception('Item not found'),
          operation: 'get',
          recoverable: true,
          timestamp: testTimestamp,
        );

        expect(metric.operation, equals('get'));
        expect(metric.recoverable, isTrue);
      });

      test('should track error in save operation', () {
        final metric = ErrorMetric(
          error: Exception('Validation failed'),
          operation: 'save',
          recoverable: true,
          timestamp: testTimestamp,
        );

        expect(metric.operation, equals('save'));
      });

      test('should track error in sync operation', () {
        final metric = ErrorMetric(
          error: Exception('Network unavailable'),
          stackTrace: testStackTrace,
          operation: 'sync',
          recoverable: false,
          timestamp: testTimestamp,
        );

        expect(metric.operation, equals('sync'));
        expect(metric.stackTrace, isNotNull);
        expect(metric.recoverable, isFalse);
      });

      test('should track error in delete operation', () {
        final metric = ErrorMetric(
          error: Exception('Permission denied'),
          operation: 'delete',
          recoverable: false,
          timestamp: testTimestamp,
        );

        expect(metric.operation, equals('delete'));
      });
    });

    group('recoverable vs fatal errors', () {
      test('should track recoverable error', () {
        final metric = ErrorMetric(
          error: Exception('Temporary network issue'),
          operation: 'sync',
          recoverable: true,
          timestamp: testTimestamp,
        );

        expect(metric.recoverable, isTrue);
      });

      test('should track fatal error', () {
        final metric = ErrorMetric(
          error: StateError('Critical failure'),
          stackTrace: testStackTrace,
          operation: 'initialize',
          recoverable: false,
          timestamp: testTimestamp,
        );

        expect(metric.recoverable, isFalse);
        expect(metric.stackTrace, isNotNull);
      });
    });

    group('stack trace handling', () {
      test('should include stack trace when provided', () {
        final metric = ErrorMetric(
          error: Exception('Error with trace'),
          stackTrace: testStackTrace,
          timestamp: testTimestamp,
        );

        expect(metric.stackTrace, isNotNull);
        expect(metric.stackTrace, equals(testStackTrace));
      });

      test('should handle null stack trace', () {
        final metric = ErrorMetric(
          error: Exception('Error without trace'),
          timestamp: testTimestamp,
        );

        expect(metric.stackTrace, isNull);
      });
    });

    group('toString', () {
      test('should include error info', () {
        final metric = ErrorMetric(
          error: Exception('Test error'),
          timestamp: testTimestamp,
        );

        expect(metric.toString(), contains('Exception'));
      });

      test('should include operation when present', () {
        final metric = ErrorMetric(
          error: Exception('Test'),
          operation: 'save',
          timestamp: testTimestamp,
        );

        expect(metric.toString(), contains('save'));
      });
    });
  });
}
