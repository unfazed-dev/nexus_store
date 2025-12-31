import 'package:nexus_store/src/interceptors/interceptor_result.dart';
import 'package:test/test.dart';

void main() {
  group('InterceptorResult', () {
    group('Continue', () {
      test('should create without modified response', () {
        const result = InterceptorResult<String>.continue_();

        expect(result, isA<Continue<String>>());
        expect((result as Continue<String>).modifiedResponse, isNull);
      });

      test('should create with modified response', () {
        const result = InterceptorResult<String>.continue_('modified');

        expect(result, isA<Continue<String>>());
        expect(
            (result as Continue<String>).modifiedResponse, equals('modified'));
      });

      test('should support equality without response', () {
        const result1 = InterceptorResult<String>.continue_();
        const result2 = InterceptorResult<String>.continue_();

        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('should support equality with response', () {
        const result1 = InterceptorResult<String>.continue_('value');
        const result2 = InterceptorResult<String>.continue_('value');

        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('should not equal with different responses', () {
        const result1 = InterceptorResult<String>.continue_('value1');
        const result2 = InterceptorResult<String>.continue_('value2');

        expect(result1, isNot(equals(result2)));
      });

      test('should have meaningful toString', () {
        const result = InterceptorResult<String>.continue_('value');
        expect(result.toString(), contains('continue'));
      });
    });

    group('ShortCircuit', () {
      test('should create with response', () {
        const result = InterceptorResult<String>.shortCircuit('final');

        expect(result, isA<ShortCircuit<String>>());
        expect((result as ShortCircuit<String>).response, equals('final'));
      });

      test('should support equality', () {
        const result1 = InterceptorResult<String>.shortCircuit('value');
        const result2 = InterceptorResult<String>.shortCircuit('value');

        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('should not equal with different responses', () {
        const result1 = InterceptorResult<String>.shortCircuit('value1');
        const result2 = InterceptorResult<String>.shortCircuit('value2');

        expect(result1, isNot(equals(result2)));
      });

      test('should have meaningful toString', () {
        const result = InterceptorResult<String>.shortCircuit('value');
        expect(result.toString(), contains('shortCircuit'));
      });
    });

    group('Error', () {
      test('should create with error object', () {
        const result = InterceptorResult<String>.error('Something failed');

        expect(result, isA<InterceptorError<String>>());
        expect((result as InterceptorError<String>).error,
            equals('Something failed'));
      });

      test('should create with exception', () {
        final exception = Exception('Test exception');
        final result = InterceptorResult<String>.error(exception);

        expect(result, isA<InterceptorError<String>>());
        expect((result as InterceptorError<String>).error, equals(exception));
      });

      test('should create with optional stack trace', () {
        final stackTrace = StackTrace.current;
        final result = InterceptorResult<String>.error('error', stackTrace);

        expect(result, isA<InterceptorError<String>>());
        final errorResult = result as InterceptorError<String>;
        expect(errorResult.error, equals('error'));
        expect(errorResult.stackTrace, equals(stackTrace));
      });

      test('should have null stack trace by default', () {
        const result = InterceptorResult<String>.error('error');

        expect((result as InterceptorError<String>).stackTrace, isNull);
      });

      test('should support equality without stack trace', () {
        const result1 = InterceptorResult<String>.error('error');
        const result2 = InterceptorResult<String>.error('error');

        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('should not equal with different errors', () {
        const result1 = InterceptorResult<String>.error('error1');
        const result2 = InterceptorResult<String>.error('error2');

        expect(result1, isNot(equals(result2)));
      });

      test('should have meaningful toString', () {
        const result = InterceptorResult<String>.error('error message');
        expect(result.toString(), contains('error'));
      });
    });

    group('pattern matching', () {
      test('should work with switch statement', () {
        const result = InterceptorResult<String>.continue_('value');

        final message = switch (result) {
          Continue<String>(:final modifiedResponse) =>
            'continue: $modifiedResponse',
          ShortCircuit<String>(:final response) => 'shortCircuit: $response',
          InterceptorError<String>(:final error) => 'error: $error',
        };

        expect(message, equals('continue: value'));
      });

      test('should match Continue', () {
        const result = InterceptorResult<int>.continue_(42);

        expect(result is Continue<int>, isTrue);
        expect(result is ShortCircuit<int>, isFalse);
        expect(result is InterceptorError<int>, isFalse);
      });

      test('should match ShortCircuit', () {
        const result = InterceptorResult<int>.shortCircuit(42);

        expect(result is Continue<int>, isFalse);
        expect(result is ShortCircuit<int>, isTrue);
        expect(result is InterceptorError<int>, isFalse);
      });

      test('should match Error', () {
        const result = InterceptorResult<int>.error('oops');

        expect(result is Continue<int>, isFalse);
        expect(result is ShortCircuit<int>, isFalse);
        expect(result is InterceptorError<int>, isTrue);
      });
    });

    group('type safety', () {
      test('should work with complex types', () {
        const result = InterceptorResult<List<Map<String, int>>>.continue_([
          {'a': 1},
          {'b': 2},
        ]);

        expect(result, isA<Continue<List<Map<String, int>>>>());
        final continueResult = result as Continue<List<Map<String, int>>>;
        expect(continueResult.modifiedResponse, hasLength(2));
      });

      test('should work with nullable types', () {
        const result = InterceptorResult<String?>.continue_(null);

        expect(result, isA<Continue<String?>>());
        expect((result as Continue<String?>).modifiedResponse, isNull);
      });

      test('should work with void-like types', () {
        const result = InterceptorResult<void>.continue_();

        expect(result, isA<Continue<void>>());
      });
    });

    group('immutability', () {
      test('Continue should be const constructible', () {
        const result1 = Continue<String>('value');
        const result2 = Continue<String>('value');

        expect(identical(result1, result2), isTrue);
      });

      test('ShortCircuit should be const constructible', () {
        const result1 = ShortCircuit<String>('value');
        const result2 = ShortCircuit<String>('value');

        expect(identical(result1, result2), isTrue);
      });

      test('InterceptorError should be const constructible', () {
        const result1 = InterceptorError<String>('error');
        const result2 = InterceptorError<String>('error');

        expect(identical(result1, result2), isTrue);
      });
    });
  });
}
