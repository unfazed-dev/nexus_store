import 'package:nexus_store/src/coordination/saga_step.dart';
import 'package:test/test.dart';

void main() {
  group('SagaStep', () {
    group('construction', () {
      test('creates step with required fields', () {
        final step = SagaStep<int>(
          name: 'test-step',
          action: () async => 42,
          compensation: (result) async {},
        );

        expect(step.name, equals('test-step'));
        expect(step.timeout, isNull);
      });

      test('creates step with optional timeout', () {
        final step = SagaStep<String>(
          name: 'timed-step',
          action: () async => 'result',
          compensation: (result) async {},
          timeout: const Duration(seconds: 5),
        );

        expect(step.name, equals('timed-step'));
        expect(step.timeout, equals(const Duration(seconds: 5)));
      });

      test('action returns expected value', () async {
        final step = SagaStep<int>(
          name: 'action-step',
          action: () async => 100,
          compensation: (result) async {},
        );

        final result = await step.action();
        expect(result, equals(100));
      });

      test('compensation receives action result', () async {
        int? compensationValue;
        final step = SagaStep<int>(
          name: 'compensation-step',
          action: () async => 42,
          compensation: (result) async {
            compensationValue = result;
          },
        );

        final actionResult = await step.action();
        await step.compensation(actionResult);

        expect(compensationValue, equals(42));
      });

      test('equality based on name', () {
        final step1 = SagaStep<int>(
          name: 'same-name',
          action: () async => 1,
          compensation: (r) async {},
        );

        final step2 = SagaStep<int>(
          name: 'same-name',
          action: () async => 2,
          compensation: (r) async {},
        );

        final step3 = SagaStep<int>(
          name: 'different-name',
          action: () async => 1,
          compensation: (r) async {},
        );

        expect(step1, equals(step2));
        expect(step1, isNot(equals(step3)));
      });

      test('hashCode consistent with equality', () {
        final step1 = SagaStep<int>(
          name: 'hash-test',
          action: () async => 1,
          compensation: (r) async {},
        );

        final step2 = SagaStep<int>(
          name: 'hash-test',
          action: () async => 2,
          compensation: (r) async {},
        );

        expect(step1.hashCode, equals(step2.hashCode));
      });

      test('toString contains name and timeout info', () {
        final stepNoTimeout = SagaStep<int>(
          name: 'no-timeout',
          action: () async => 1,
          compensation: (r) async {},
        );

        final stepWithTimeout = SagaStep<int>(
          name: 'with-timeout',
          action: () async => 1,
          compensation: (r) async {},
          timeout: const Duration(seconds: 10),
        );

        expect(stepNoTimeout.toString(), contains('no-timeout'));
        expect(stepWithTimeout.toString(), contains('with-timeout'));
        expect(stepWithTimeout.toString(), contains('10'));
      });
    });

    group('SagaStep.nested', () {
      test('creates step with sub-steps', () {
        final subSteps = [
          SagaStep<int>(
            name: 'sub-step-1',
            action: () async => 1,
            compensation: (r) async {},
          ),
          SagaStep<int>(
            name: 'sub-step-2',
            action: () async => 2,
            compensation: (r) async {},
          ),
        ];

        final nestedStep = SagaStep<int>.nested(
          name: 'nested-saga',
          subSteps: subSteps,
          onNestedSuccess: (results) =>
              results.fold<int>(0, (a, b) => a + (b as int)),
          compensation: (result) async {},
        );

        expect(nestedStep.name, equals('nested-saga'));
        expect(nestedStep.timeout, isNull);
      });

      test('nested step action executes all sub-steps', () async {
        final executedSteps = <String>[];

        final subSteps = [
          SagaStep<int>(
            name: 'sub-step-1',
            action: () async {
              executedSteps.add('sub-step-1');
              return 1;
            },
            compensation: (r) async {},
          ),
          SagaStep<int>(
            name: 'sub-step-2',
            action: () async {
              executedSteps.add('sub-step-2');
              return 2;
            },
            compensation: (r) async {},
          ),
          SagaStep<int>(
            name: 'sub-step-3',
            action: () async {
              executedSteps.add('sub-step-3');
              return 3;
            },
            compensation: (r) async {},
          ),
        ];

        final nestedStep = SagaStep<int>.nested(
          name: 'nested-saga',
          subSteps: subSteps,
          onNestedSuccess: (results) => results.length,
          compensation: (result) async {},
        );

        await nestedStep.action();

        expect(
            executedSteps, equals(['sub-step-1', 'sub-step-2', 'sub-step-3']));
      });

      test('nested step returns extracted result on success', () async {
        final subSteps = [
          SagaStep<int>(
            name: 'sub-step-1',
            action: () async => 10,
            compensation: (r) async {},
          ),
          SagaStep<int>(
            name: 'sub-step-2',
            action: () async => 20,
            compensation: (r) async {},
          ),
        ];

        final nestedStep = SagaStep<int>.nested(
          name: 'nested-saga',
          subSteps: subSteps,
          onNestedSuccess: (results) =>
              results.fold<int>(0, (a, b) => a + (b as int)),
          compensation: (result) async {},
        );

        final result = await nestedStep.action();

        expect(result, equals(30)); // 10 + 20
      });

      test('nested step throws when sub-step fails', () async {
        final subSteps = [
          SagaStep<int>(
            name: 'sub-step-1',
            action: () async => 1,
            compensation: (r) async {},
          ),
          SagaStep<int>(
            name: 'sub-step-2',
            action: () async => throw Exception('Sub-step failed'),
            compensation: (r) async {},
          ),
        ];

        final nestedStep = SagaStep<int>.nested(
          name: 'nested-saga',
          subSteps: subSteps,
          onNestedSuccess: (results) => results.length,
          compensation: (result) async {},
        );

        expect(
          () => nestedStep.action(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Sub-step failed'),
          )),
        );
      });

      test('nested step compensates sub-steps internally on failure', () async {
        final compensatedSteps = <String>[];

        final subSteps = <SagaStep<dynamic>>[
          SagaStep<int>(
            name: 'sub-step-1',
            action: () async => 1,
            compensation: (r) async {
              compensatedSteps.add('sub-step-1');
            },
          ),
          SagaStep<int>(
            name: 'sub-step-2',
            action: () async => 2,
            compensation: (r) async {
              compensatedSteps.add('sub-step-2');
            },
          ),
          SagaStep<int>(
            name: 'sub-step-3',
            action: () async => throw Exception('Third step fails'),
            compensation: (r) async {
              compensatedSteps.add('sub-step-3');
            },
          ),
        ];

        final nestedStep = SagaStep<int>.nested(
          name: 'nested-saga',
          subSteps: subSteps,
          onNestedSuccess: (results) => results.length,
          compensation: (result) async {},
        );

        try {
          await nestedStep.action();
        } catch (_) {
          // Expected failure
        }

        // Should compensate completed sub-steps in reverse order
        expect(compensatedSteps, equals(['sub-step-2', 'sub-step-1']));
      });

      test('nested step with timeout passes to constructor', () {
        final nestedStep = SagaStep<int>.nested(
          name: 'nested-saga',
          subSteps: [],
          onNestedSuccess: (results) => 0,
          compensation: (result) async {},
          timeout: const Duration(seconds: 30),
        );

        expect(nestedStep.timeout, equals(const Duration(seconds: 30)));
      });

      test('nested step throws when sub-step fails with partial failure (line 116)',
          () async {
        // This test covers line 116: partialFailure: (error, _, __) => throw error
        // A partialFailure occurs when a sub-step fails AND its compensation also fails

        final subSteps = <SagaStep<dynamic>>[
          SagaStep<int>(
            name: 'sub-step-1',
            action: () async => 1,
            compensation: (r) async {
              // Compensation also fails
              throw Exception('Compensation failed');
            },
          ),
          SagaStep<int>(
            name: 'sub-step-2',
            action: () async => throw Exception('Sub-step action failed'),
            compensation: (r) async {},
          ),
        ];

        final nestedStep = SagaStep<int>.nested(
          name: 'nested-saga',
          subSteps: subSteps,
          onNestedSuccess: (results) => results.length,
          compensation: (result) async {},
        );

        // When sub-step-2 fails, compensation of sub-step-1 runs and also fails
        // This causes a partialFailure result from the nested coordinator
        // Line 116 throws the error from the partialFailure
        expect(
          () => nestedStep.action(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Sub-step action failed'),
          )),
        );
      });
    });
  });
}
