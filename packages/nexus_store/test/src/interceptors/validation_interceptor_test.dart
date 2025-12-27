import 'package:nexus_store/src/interceptors/interceptor_context.dart';
import 'package:nexus_store/src/interceptors/interceptor_result.dart';
import 'package:nexus_store/src/interceptors/store_operation.dart';
import 'package:nexus_store/src/interceptors/validation_interceptor.dart';
import 'package:test/test.dart';

/// Test model for validation.
class TestUser {
  final String id;
  final String name;
  final String? email;

  TestUser({required this.id, required this.name, this.email});

  @override
  String toString() => 'TestUser(id: $id, name: $name, email: $email)';
}

/// Validation error for testing.
class ValidationError implements Exception {
  final String message;
  final List<String> errors;

  ValidationError(this.message, [this.errors = const []]);

  @override
  String toString() => 'ValidationError: $message';
}

void main() {
  group('ValidationInterceptor', () {
    group('construction', () {
      test('should create with validator function', () {
        final interceptor = ValidationInterceptor<TestUser>(
          validate: (user) => null,
        );

        expect(interceptor, isNotNull);
      });

      test('should apply to save operations by default', () {
        final interceptor = ValidationInterceptor<TestUser>(
          validate: (user) => null,
        );

        expect(
          interceptor.operations,
          equals({StoreOperation.save, StoreOperation.saveAll}),
        );
      });

      test('should allow custom operations', () {
        final interceptor = ValidationInterceptor<TestUser>(
          validate: (user) => null,
          operations: {StoreOperation.save},
        );

        expect(interceptor.operations, equals({StoreOperation.save}));
      });
    });

    group('onRequest for save', () {
      test('should pass valid item', () async {
        final interceptor = ValidationInterceptor<TestUser>(
          validate: (user) => user.name.isNotEmpty ? null : 'Name required',
        );
        final context = InterceptorContext<TestUser, TestUser>(
          operation: StoreOperation.save,
          request: TestUser(id: '1', name: 'John'),
        );

        final result = await interceptor.onRequest(context);

        expect(result, isA<Continue<TestUser>>());
      });

      test('should reject invalid item with error', () async {
        final interceptor = ValidationInterceptor<TestUser>(
          validate: (user) => user.name.isEmpty ? 'Name required' : null,
        );
        final context = InterceptorContext<TestUser, TestUser>(
          operation: StoreOperation.save,
          request: TestUser(id: '1', name: ''),
        );

        final result = await interceptor.onRequest(context);

        expect(result, isA<InterceptorError<TestUser>>());
        final error = result as InterceptorError<TestUser>;
        expect(error.error, isA<ValidationException>());
        expect((error.error as ValidationException).message,
            contains('Name required'));
      });

      test('should use custom error factory', () async {
        final interceptor = ValidationInterceptor<TestUser>(
          validate: (user) => user.name.isEmpty ? 'Name required' : null,
          errorFactory: (msg) => ValidationError(msg),
        );
        final context = InterceptorContext<TestUser, TestUser>(
          operation: StoreOperation.save,
          request: TestUser(id: '1', name: ''),
        );

        final result = await interceptor.onRequest(context);

        expect(result, isA<InterceptorError<TestUser>>());
        final error = result as InterceptorError<TestUser>;
        expect(error.error, isA<ValidationError>());
      });
    });

    group('onRequest for saveAll', () {
      test('should pass all valid items', () async {
        final interceptor = ValidationInterceptor<TestUser>(
          validate: (user) => user.name.isNotEmpty ? null : 'Name required',
        );
        final context = InterceptorContext<List<TestUser>, List<TestUser>>(
          operation: StoreOperation.saveAll,
          request: [
            TestUser(id: '1', name: 'John'),
            TestUser(id: '2', name: 'Jane'),
          ],
        );

        final result = await interceptor.onRequest(context);

        expect(result, isA<Continue<List<TestUser>>>());
      });

      test('should reject if any item is invalid', () async {
        final interceptor = ValidationInterceptor<TestUser>(
          validate: (user) => user.name.isEmpty ? 'Name required' : null,
        );
        final context = InterceptorContext<List<TestUser>, List<TestUser>>(
          operation: StoreOperation.saveAll,
          request: [
            TestUser(id: '1', name: 'John'),
            TestUser(id: '2', name: ''), // Invalid
          ],
        );

        final result = await interceptor.onRequest(context);

        expect(result, isA<InterceptorError<List<TestUser>>>());
      });

      test('should report all validation errors', () async {
        final interceptor = ValidationInterceptor<TestUser>(
          validate: (user) => user.name.isEmpty ? 'Name required' : null,
        );
        final context = InterceptorContext<List<TestUser>, List<TestUser>>(
          operation: StoreOperation.saveAll,
          request: [
            TestUser(id: '1', name: ''), // Invalid
            TestUser(id: '2', name: ''), // Invalid
          ],
        );

        final result = await interceptor.onRequest(context);

        final error = result as InterceptorError<List<TestUser>>;
        final exception = error.error as ValidationException;
        expect(exception.errors, hasLength(2));
      });
    });

    group('complex validation', () {
      test('should validate multiple fields', () async {
        final interceptor = ValidationInterceptor<TestUser>(
          validate: (user) {
            final errors = <String>[];
            if (user.id.isEmpty) errors.add('ID required');
            if (user.name.isEmpty) errors.add('Name required');
            if (user.email != null && !user.email!.contains('@')) {
              errors.add('Invalid email');
            }
            return errors.isEmpty ? null : errors.join(', ');
          },
        );

        final context = InterceptorContext<TestUser, TestUser>(
          operation: StoreOperation.save,
          request: TestUser(id: '', name: '', email: 'invalid'),
        );

        final result = await interceptor.onRequest(context);

        expect(result, isA<InterceptorError<TestUser>>());
        final error = result as InterceptorError<TestUser>;
        final exception = error.error as ValidationException;
        expect(exception.message, contains('ID required'));
        expect(exception.message, contains('Name required'));
        expect(exception.message, contains('Invalid email'));
      });

      test('should pass item when all validations pass', () async {
        final interceptor = ValidationInterceptor<TestUser>(
          validate: (user) {
            if (user.id.isEmpty) return 'ID required';
            if (user.name.isEmpty) return 'Name required';
            if (user.email != null && !user.email!.contains('@')) {
              return 'Invalid email';
            }
            return null;
          },
        );

        final context = InterceptorContext<TestUser, TestUser>(
          operation: StoreOperation.save,
          request: TestUser(id: '1', name: 'John', email: 'john@example.com'),
        );

        final result = await interceptor.onRequest(context);

        expect(result, isA<Continue<TestUser>>());
      });
    });

    group('onResponse and onError', () {
      test('onResponse should do nothing', () async {
        final interceptor = ValidationInterceptor<TestUser>(
          validate: (user) => null,
        );
        final context = InterceptorContext<TestUser, TestUser>(
          operation: StoreOperation.save,
          request: TestUser(id: '1', name: 'John'),
        ).withResponse(TestUser(id: '1', name: 'John'));

        // Should not throw
        await interceptor.onResponse(context);
      });

      test('onError should do nothing', () async {
        final interceptor = ValidationInterceptor<TestUser>(
          validate: (user) => null,
        );
        final context = InterceptorContext<TestUser, TestUser>(
          operation: StoreOperation.save,
          request: TestUser(id: '1', name: 'John'),
        );

        // Should not throw
        await interceptor.onError(context, 'error', StackTrace.current);
      });
    });

    group('ValidationException', () {
      test('should have message', () {
        final exception = ValidationException('Field is required');

        expect(exception.message, equals('Field is required'));
        expect(exception.toString(), contains('Field is required'));
      });

      test('should have errors list', () {
        final exception = ValidationException(
          'Multiple errors',
          errors: ['Error 1', 'Error 2'],
        );

        expect(exception.errors, hasLength(2));
        expect(exception.errors, contains('Error 1'));
      });

      test('should have empty errors list by default', () {
        final exception = ValidationException('Single error');

        expect(exception.errors, isEmpty);
      });
    });
  });
}
