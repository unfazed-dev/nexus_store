import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('StoreError', () {
    test('should be a sealed class with correct subclasses', () {
      // Verify all error types are subclasses of StoreError
      expect(const NotFoundError(id: 'test'), isA<StoreError>());
      expect(const NetworkError(message: 'test'), isA<StoreError>());
      expect(
        TimeoutError(duration: const Duration(seconds: 5)),
        isA<StoreError>(),
      );
      expect(const ValidationError(message: 'test'), isA<StoreError>());
      expect(const ConflictError(message: 'test'), isA<StoreError>());
      expect(const SyncError(message: 'test'), isA<StoreError>());
      expect(const AuthenticationError(message: 'test'), isA<StoreError>());
      expect(const AuthorizationError(message: 'test'), isA<StoreError>());
      expect(const TransactionError(message: 'test'), isA<StoreError>());
      expect(const StateError(message: 'test'), isA<StoreError>());
      expect(const CancellationError(), isA<StoreError>());
      expect(const QuotaExceededError(message: 'test'), isA<StoreError>());
    });
  });

  group('NotFoundError', () {
    test('should have correct properties', () {
      const error = NotFoundError(id: 'user-123', entityType: 'User');

      expect(error.id, equals('user-123'));
      expect(error.entityType, equals('User'));
      expect(error.code, equals('NOT_FOUND'));
      expect(error.errorName, equals('NotFoundError'));
    });

    test('should have correct message with entityType', () {
      const error = NotFoundError(id: 'user-123', entityType: 'User');

      expect(error.message, contains('User'));
      expect(error.message, contains('user-123'));
    });

    test('should have correct message without entityType', () {
      const error = NotFoundError(id: 'user-123');

      expect(error.message, contains('user-123'));
      expect(error.message, contains('Entity'));
    });

    test('should not be retryable', () {
      const error = NotFoundError(id: 'test');
      expect(error.isRetryable, isFalse);
    });
  });

  group('NetworkError', () {
    test('should have correct properties', () {
      const error = NetworkError(
        message: 'Connection failed',
        statusCode: 500,
        url: 'https://api.example.com',
      );

      expect(error.message, equals('Connection failed'));
      expect(error.statusCode, equals(500));
      expect(error.url, equals('https://api.example.com'));
      expect(error.code, equals('NETWORK_ERROR'));
      expect(error.errorName, equals('NetworkError'));
    });

    test('should be retryable when statusCode is null', () {
      const error = NetworkError(message: 'test');
      expect(error.isRetryable, isTrue);
    });

    test('should be retryable when statusCode is 5xx', () {
      const error500 = NetworkError(message: 'test', statusCode: 500);
      const error503 = NetworkError(message: 'test', statusCode: 503);

      expect(error500.isRetryable, isTrue);
      expect(error503.isRetryable, isTrue);
    });

    test('should be retryable when statusCode is 408 (timeout)', () {
      const error = NetworkError(message: 'test', statusCode: 408);
      expect(error.isRetryable, isTrue);
    });

    test('should be retryable when statusCode is 429 (rate limit)', () {
      const error = NetworkError(message: 'test', statusCode: 429);
      expect(error.isRetryable, isTrue);
    });

    test(
        'should not be retryable when statusCode is 4xx '
        '(except 408, 429)', () {
      const error400 = NetworkError(message: 'test', statusCode: 400);
      const error404 = NetworkError(message: 'test', statusCode: 404);

      expect(error400.isRetryable, isFalse);
      expect(error404.isRetryable, isFalse);
    });
  });

  group('TimeoutError', () {
    test('should have correct properties', () {
      final error = TimeoutError(
        duration: const Duration(seconds: 30),
        operation: 'fetch',
      );

      expect(error.duration, equals(const Duration(seconds: 30)));
      expect(error.operation, equals('fetch'));
      expect(error.code, equals('TIMEOUT'));
      expect(error.errorName, equals('TimeoutError'));
    });

    test('should have correct message with operation', () {
      final error = TimeoutError(
        duration: const Duration(seconds: 30),
        operation: 'fetch',
      );

      expect(error.message, contains('fetch'));
      expect(error.message, contains('30'));
    });

    test('should have correct message without operation', () {
      final error = TimeoutError(duration: const Duration(seconds: 30));

      expect(error.message, contains('Operation'));
      expect(error.message, contains('timed out'));
    });

    test('should always be retryable', () {
      final error = TimeoutError(duration: const Duration(seconds: 30));
      expect(error.isRetryable, isTrue);
    });
  });

  group('ValidationError', () {
    test('should have correct properties', () {
      const violation = ValidationViolation(
        field: 'email',
        message: 'Invalid email format',
        value: 'not-an-email',
      );
      const error = ValidationError(
        message: 'Validation failed',
        field: 'email',
        value: 'not-an-email',
        violations: [violation],
      );

      expect(error.message, equals('Validation failed'));
      expect(error.field, equals('email'));
      expect(error.value, equals('not-an-email'));
      expect(error.violations, hasLength(1));
      expect(error.code, equals('VALIDATION_ERROR'));
      expect(error.errorName, equals('ValidationError'));
    });

    test('should not be retryable', () {
      const error = ValidationError(message: 'test');
      expect(error.isRetryable, isFalse);
    });
  });

  group('ValidationViolation', () {
    test('should have correct properties', () {
      const violation = ValidationViolation(
        field: 'age',
        message: 'Must be at least 18',
        value: 15,
        constraint: 'min:18',
      );

      expect(violation.field, equals('age'));
      expect(violation.message, equals('Must be at least 18'));
      expect(violation.value, equals(15));
      expect(violation.constraint, equals('min:18'));
    });

    test('should have readable toString', () {
      const violation = ValidationViolation(
        field: 'email',
        message: 'Invalid format',
      );

      expect(violation.toString(), contains('email'));
      expect(violation.toString(), contains('Invalid format'));
    });
  });

  group('ConflictError', () {
    test('should have correct properties', () {
      const error = ConflictError(
        message: 'Version conflict',
        localVersion: 1,
        remoteVersion: 2,
        conflictedFields: ['name', 'email'],
      );

      expect(error.message, equals('Version conflict'));
      expect(error.localVersion, equals(1));
      expect(error.remoteVersion, equals(2));
      expect(error.conflictedFields, equals(['name', 'email']));
      expect(error.code, equals('CONFLICT'));
      expect(error.errorName, equals('ConflictError'));
    });

    test('should not be retryable', () {
      const error = ConflictError(message: 'test');
      expect(error.isRetryable, isFalse);
    });
  });

  group('SyncError', () {
    test('should have correct properties', () {
      const error = SyncError(
        message: 'Sync failed',
        pendingChanges: 5,
      );

      expect(error.message, equals('Sync failed'));
      expect(error.pendingChanges, equals(5));
      expect(error.code, equals('SYNC_ERROR'));
      expect(error.errorName, equals('SyncError'));
    });

    test('should always be retryable', () {
      const error = SyncError(message: 'test');
      expect(error.isRetryable, isTrue);
    });
  });

  group('AuthenticationError', () {
    test('should have correct properties', () {
      const error = AuthenticationError(message: 'Invalid credentials');

      expect(error.message, equals('Invalid credentials'));
      expect(error.code, equals('AUTHENTICATION_ERROR'));
      expect(error.errorName, equals('AuthenticationError'));
    });

    test('should not be retryable', () {
      const error = AuthenticationError(message: 'test');
      expect(error.isRetryable, isFalse);
    });
  });

  group('AuthorizationError', () {
    test('should have correct properties', () {
      const error = AuthorizationError(
        message: 'Access denied',
        requiredPermission: 'admin:write',
      );

      expect(error.message, equals('Access denied'));
      expect(error.requiredPermission, equals('admin:write'));
      expect(error.code, equals('AUTHORIZATION_ERROR'));
      expect(error.errorName, equals('AuthorizationError'));
    });

    test('should not be retryable', () {
      const error = AuthorizationError(message: 'test');
      expect(error.isRetryable, isFalse);
    });
  });

  group('TransactionError', () {
    test('should have correct properties', () {
      const error = TransactionError(
        message: 'Transaction failed',
        wasRolledBack: true,
      );

      expect(error.message, equals('Transaction failed'));
      expect(error.wasRolledBack, isTrue);
      expect(error.code, equals('TRANSACTION_ERROR'));
      expect(error.errorName, equals('TransactionError'));
    });

    test('should have wasRolledBack false by default', () {
      const error = TransactionError(message: 'test');
      expect(error.wasRolledBack, isFalse);
    });

    test('should not be retryable', () {
      const error = TransactionError(message: 'test');
      expect(error.isRetryable, isFalse);
    });
  });

  group('StateError', () {
    test('should have correct properties', () {
      const error = StateError(
        message: 'Invalid state',
        currentState: 'disposed',
        expectedState: 'initialized',
      );

      expect(error.message, equals('Invalid state'));
      expect(error.currentState, equals('disposed'));
      expect(error.expectedState, equals('initialized'));
      expect(error.code, equals('STATE_ERROR'));
      expect(error.errorName, equals('StateError'));
    });

    test('should not be retryable', () {
      const error = StateError(message: 'test');
      expect(error.isRetryable, isFalse);
    });
  });

  group('CancellationError', () {
    test('should have correct properties', () {
      const error = CancellationError(operation: 'download');

      expect(error.operation, equals('download'));
      expect(error.code, equals('CANCELLED'));
      expect(error.errorName, equals('CancellationError'));
    });

    test('should have correct message with operation', () {
      const error = CancellationError(operation: 'download');

      expect(error.message, contains('download'));
      expect(error.message, contains('cancelled'));
    });

    test('should have correct message without operation', () {
      const error = CancellationError();

      expect(error.message, contains('Operation'));
      expect(error.message, contains('cancelled'));
    });

    test('should not be retryable', () {
      const error = CancellationError();
      expect(error.isRetryable, isFalse);
    });
  });

  group('QuotaExceededError', () {
    test('should have correct properties', () {
      const error = QuotaExceededError(
        message: 'Storage quota exceeded',
        limit: 1000,
        current: 1200,
        quotaType: 'storage',
      );

      expect(error.message, equals('Storage quota exceeded'));
      expect(error.limit, equals(1000));
      expect(error.current, equals(1200));
      expect(error.quotaType, equals('storage'));
      expect(error.code, equals('QUOTA_EXCEEDED'));
      expect(error.errorName, equals('QuotaExceededError'));
    });

    test('should not be retryable', () {
      const error = QuotaExceededError(message: 'test');
      expect(error.isRetryable, isFalse);
    });
  });

  group('StoreError toString', () {
    test('should include error name and message', () {
      const error = NotFoundError(id: 'test');
      final str = error.toString();

      expect(str, contains('NotFoundError'));
      expect(str, contains('not found'));
    });

    test('should include code when present', () {
      const error = NetworkError(message: 'test', code: 'CUSTOM_CODE');
      final str = error.toString();

      expect(str, contains('CUSTOM_CODE'));
    });

    test('should include cause when present', () {
      final cause = Exception('original error');
      final error = NetworkError(message: 'test', cause: cause);
      final str = error.toString();

      expect(str, contains('Caused by'));
      expect(str, contains('original error'));
    });
  });
}
