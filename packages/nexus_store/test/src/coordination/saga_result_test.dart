import 'package:nexus_store/src/coordination/saga_result.dart';
import 'package:test/test.dart';

void main() {
  group('SagaResult', () {
    group('SagaSuccess', () {
      test('creates success with results list', () {
        final result = SagaResult<int>.success([1, 2, 3]);

        expect(result, isA<SagaSuccess<int>>());
        expect((result as SagaSuccess<int>).results, equals([1, 2, 3]));
      });

      test('isSuccess returns true', () {
        final result = SagaResult<String>.success(['a', 'b']);

        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.isPartialFailure, isFalse);
      });

      test('results getter returns list', () {
        final result = SagaResult<int>.success([42]);

        expect(result.results, equals([42]));
      });

      test('error getter returns null', () {
        final result = SagaResult<int>.success([1]);

        expect(result.error, isNull);
      });

      test('equality based on results', () {
        final result1 = SagaResult<int>.success([1, 2]);
        final result2 = SagaResult<int>.success([1, 2]);
        final result3 = SagaResult<int>.success([3, 4]);

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('hashCode consistent with equality', () {
        final result1 = SagaResult<int>.success([1, 2]);
        final result2 = SagaResult<int>.success([1, 2]);

        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('toString contains results', () {
        final result = SagaResult<int>.success([1, 2]);

        expect(result.toString(), contains('SagaSuccess'));
        expect(result.toString(), contains('[1, 2]'));
      });
    });

    group('SagaFailure', () {
      test('creates failure with error and compensated steps', () {
        final error = Exception('step failed');
        final result = SagaResult<int>.failure(
          error,
          failedStep: 'step-3',
          compensatedSteps: ['step-2', 'step-1'],
        );

        expect(result, isA<SagaFailure<int>>());
        final failure = result as SagaFailure<int>;
        expect(failure.error, equals(error));
        expect(failure.failedStep, equals('step-3'));
        expect(failure.compensatedSteps, equals(['step-2', 'step-1']));
      });

      test('isFailure returns true', () {
        final result = SagaResult<int>.failure(
          Exception('error'),
          failedStep: 'step-1',
          compensatedSteps: [],
        );

        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.isPartialFailure, isFalse);
      });

      test('results getter returns empty list', () {
        final result = SagaResult<int>.failure(
          Exception('error'),
          failedStep: 'step-1',
          compensatedSteps: [],
        );

        expect(result.results, isEmpty);
      });

      test('error getter returns the error', () {
        final error = Exception('test error');
        final result = SagaResult<int>.failure(
          error,
          failedStep: 'step-1',
          compensatedSteps: [],
        );

        expect(result.error, equals(error));
      });

      test('equality based on error and steps', () {
        final error = Exception('same error');
        final result1 = SagaResult<int>.failure(
          error,
          failedStep: 'step-1',
          compensatedSteps: ['step-0'],
        );
        final result2 = SagaResult<int>.failure(
          error,
          failedStep: 'step-1',
          compensatedSteps: ['step-0'],
        );
        final result3 = SagaResult<int>.failure(
          error,
          failedStep: 'step-2',
          compensatedSteps: ['step-1'],
        );

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('toString contains error and steps info', () {
        final result = SagaResult<int>.failure(
          Exception('test'),
          failedStep: 'step-2',
          compensatedSteps: ['step-1'],
        );

        expect(result.toString(), contains('SagaFailure'));
        expect(result.toString(), contains('step-2'));
      });
    });

    group('SagaPartialFailure', () {
      test('creates partial failure with action error and compensation errors',
          () {
        final actionError = Exception('action failed');
        final compensationErrors = [
          SagaCompensationError(
            stepName: 'step-1',
            error: Exception('comp failed'),
          ),
        ];

        final result = SagaResult<int>.partialFailure(
          actionError,
          failedStep: 'step-3',
          compensationErrors: compensationErrors,
        );

        expect(result, isA<SagaPartialFailure<int>>());
        final partial = result as SagaPartialFailure<int>;
        expect(partial.error, equals(actionError));
        expect(partial.failedStep, equals('step-3'));
        expect(partial.compensationErrors, equals(compensationErrors));
      });

      test('isPartialFailure returns true', () {
        final result = SagaResult<int>.partialFailure(
          Exception('error'),
          failedStep: 'step-1',
          compensationErrors: [],
        );

        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isFalse);
        expect(result.isPartialFailure, isTrue);
      });

      test('results getter returns empty list', () {
        final result = SagaResult<int>.partialFailure(
          Exception('error'),
          failedStep: 'step-1',
          compensationErrors: [],
        );

        expect(result.results, isEmpty);
      });

      test('toString contains error and compensation errors', () {
        final result = SagaResult<int>.partialFailure(
          Exception('action failed'),
          failedStep: 'step-2',
          compensationErrors: [
            SagaCompensationError(
              stepName: 'step-1',
              error: Exception('comp failed'),
            ),
          ],
        );

        expect(result.toString(), contains('SagaPartialFailure'));
        expect(result.toString(), contains('step-2'));
      });
    });

    group('when pattern matching', () {
      test('calls success handler for SagaSuccess', () {
        final result = SagaResult<int>.success([1, 2, 3]);

        final value = result.when(
          success: (results) => 'success: $results',
          failure: (error, failedStep, compensated) => 'failure',
          partialFailure: (error, failedStep, compErrors) => 'partial',
        );

        expect(value, equals('success: [1, 2, 3]'));
      });

      test('calls failure handler for SagaFailure', () {
        final error = Exception('test error');
        final result = SagaResult<int>.failure(
          error,
          failedStep: 'step-1',
          compensatedSteps: ['step-0'],
        );

        final value = result.when(
          success: (results) => 'success',
          failure: (err, failedStep, compensated) =>
              'failure: $failedStep, compensated: $compensated',
          partialFailure: (error, failedStep, compErrors) => 'partial',
        );

        expect(value, equals('failure: step-1, compensated: [step-0]'));
      });

      test('calls partialFailure handler for SagaPartialFailure', () {
        final result = SagaResult<int>.partialFailure(
          Exception('error'),
          failedStep: 'step-2',
          compensationErrors: [
            SagaCompensationError(stepName: 'step-1', error: Exception('comp')),
          ],
        );

        final value = result.when(
          success: (results) => 'success',
          failure: (error, failedStep, compensated) => 'failure',
          partialFailure: (error, failedStep, compErrors) =>
              'partial: ${compErrors.length} errors',
        );

        expect(value, equals('partial: 1 errors'));
      });
    });

    group('maybeWhen pattern matching', () {
      test('calls handler when provided for success', () {
        final result = SagaResult<int>.success([42]);

        final value = result.maybeWhen(
          success: (results) => 'got success',
          orElse: () => 'default',
        );

        expect(value, equals('got success'));
      });

      test('calls orElse when handler not provided', () {
        final result = SagaResult<int>.failure(
          Exception('error'),
          failedStep: 'step-1',
          compensatedSteps: [],
        );

        final value = result.maybeWhen(
          success: (results) => 'success',
          orElse: () => 'default fallback',
        );

        expect(value, equals('default fallback'));
      });

      test('calls failure handler when provided', () {
        final result = SagaResult<int>.failure(
          Exception('error'),
          failedStep: 'step-1',
          compensatedSteps: ['step-0'],
        );

        final value = result.maybeWhen(
          failure: (err, failedStep, compensated) => 'got failure',
          orElse: () => 'default',
        );

        expect(value, equals('got failure'));
      });

      test('calls partialFailure handler when provided', () {
        final result = SagaResult<int>.partialFailure(
          Exception('error'),
          failedStep: 'step-1',
          compensationErrors: [],
        );

        final value = result.maybeWhen(
          partialFailure: (err, failedStep, compErrors) => 'got partial',
          orElse: () => 'default',
        );

        expect(value, equals('got partial'));
      });
    });

    group('SagaCompensationError', () {
      test('creates compensation error with required fields', () {
        final error = SagaCompensationError(
          stepName: 'step-1',
          error: Exception('compensation failed'),
        );

        expect(error.stepName, equals('step-1'));
        expect(error.error, isA<Exception>());
        expect(error.stackTrace, isNull);
      });

      test('creates compensation error with stack trace', () {
        final stackTrace = StackTrace.current;
        final error = SagaCompensationError(
          stepName: 'step-1',
          error: Exception('failed'),
          stackTrace: stackTrace,
        );

        expect(error.stackTrace, equals(stackTrace));
      });

      test('equality based on stepName and error', () {
        final exc = Exception('same error');
        final error1 = SagaCompensationError(stepName: 'step-1', error: exc);
        final error2 = SagaCompensationError(stepName: 'step-1', error: exc);
        final error3 = SagaCompensationError(stepName: 'step-2', error: exc);

        expect(error1, equals(error2));
        expect(error1, isNot(equals(error3)));
      });

      test('toString contains step name and error', () {
        final error = SagaCompensationError(
          stepName: 'step-1',
          error: Exception('test error'),
        );

        expect(error.toString(), contains('step-1'));
        expect(error.toString(), contains('test error'));
      });
    });
  });
}
