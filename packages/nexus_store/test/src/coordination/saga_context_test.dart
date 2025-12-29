import 'package:nexus_store/src/coordination/saga_context.dart';
import 'package:test/test.dart';

void main() {
  group('SagaContext', () {
    group('construction', () {
      test('creates context with unique id', () {
        final context = SagaContext();

        expect(context.id, isNotEmpty);
      });

      test('creates context with custom id', () {
        final context = SagaContext(id: 'custom-123');

        expect(context.id, equals('custom-123'));
      });

      test('sets startedAt to current time', () {
        final before = DateTime.now();
        final context = SagaContext();
        final after = DateTime.now();

        expect(context.startedAt.isAfter(before.subtract(Duration(seconds: 1))),
            isTrue);
        expect(context.startedAt.isBefore(after.add(Duration(seconds: 1))),
            isTrue);
      });

      test('starts with no completed steps', () {
        final context = SagaContext();

        expect(context.completedSteps, isEmpty);
      });

      test('starts in active state', () {
        final context = SagaContext();

        expect(context.isActive, isTrue);
        expect(context.isCompleted, isFalse);
        expect(context.isFailed, isFalse);
      });
    });

    group('addCompletedStep', () {
      test('adds step to completed list', () {
        final context = SagaContext();

        context.addCompletedStep('step-1', 42);

        expect(context.completedSteps.length, equals(1));
        expect(context.completedSteps.first.name, equals('step-1'));
        expect(context.completedSteps.first.result, equals(42));
      });

      test('tracks multiple steps in order', () {
        final context = SagaContext();

        context.addCompletedStep('step-1', 'a');
        context.addCompletedStep('step-2', 'b');
        context.addCompletedStep('step-3', 'c');

        expect(context.completedSteps.length, equals(3));
        expect(context.completedSteps[0].name, equals('step-1'));
        expect(context.completedSteps[1].name, equals('step-2'));
        expect(context.completedSteps[2].name, equals('step-3'));
      });

      test('throws when not active', () {
        final context = SagaContext();
        context.markCompleted();

        expect(
          () => context.addCompletedStep('step-1', 1),
          throwsStateError,
        );
      });
    });

    group('stepsToCompensate', () {
      test('returns steps in reverse order', () {
        final context = SagaContext();

        context.addCompletedStep('step-1', 1);
        context.addCompletedStep('step-2', 2);
        context.addCompletedStep('step-3', 3);

        final toCompensate = context.stepsToCompensate;

        expect(toCompensate.length, equals(3));
        expect(toCompensate[0].name, equals('step-3'));
        expect(toCompensate[1].name, equals('step-2'));
        expect(toCompensate[2].name, equals('step-1'));
      });

      test('returns empty list when no steps completed', () {
        final context = SagaContext();

        expect(context.stepsToCompensate, isEmpty);
      });
    });

    group('markCompleted', () {
      test('sets isCompleted to true', () {
        final context = SagaContext();

        context.markCompleted();

        expect(context.isCompleted, isTrue);
        expect(context.isActive, isFalse);
      });

      test('sets completedAt timestamp', () {
        final context = SagaContext();

        context.markCompleted();

        expect(context.completedAt, isNotNull);
      });
    });

    group('markFailed', () {
      test('sets isFailed to true', () {
        final context = SagaContext();

        context.markFailed('step-2', Exception('test'));

        expect(context.isFailed, isTrue);
        expect(context.isActive, isFalse);
      });

      test('stores failed step name and error', () {
        final error = Exception('test error');
        final context = SagaContext();

        context.markFailed('failed-step', error);

        expect(context.failedStep, equals('failed-step'));
        expect(context.error, equals(error));
      });

      test('sets completedAt timestamp', () {
        final context = SagaContext();

        context.markFailed('step-1', Exception('fail'));

        expect(context.completedAt, isNotNull);
      });
    });

    group('duration', () {
      test('returns null when still active', () {
        final context = SagaContext();

        expect(context.duration, isNull);
      });

      test('returns duration after completion', () async {
        final context = SagaContext();

        await Future.delayed(Duration(milliseconds: 10));
        context.markCompleted();

        expect(context.duration, isNotNull);
        expect(context.duration!.inMilliseconds, greaterThan(0));
      });
    });

    group('getStepResult', () {
      test('returns result for existing step', () {
        final context = SagaContext();
        context.addCompletedStep('step-1', 42);

        expect(context.getStepResult<int>('step-1'), equals(42));
      });

      test('returns null for non-existent step', () {
        final context = SagaContext();

        expect(context.getStepResult<int>('unknown'), isNull);
      });
    });

    group('hasStep', () {
      test('returns true for completed step', () {
        final context = SagaContext();
        context.addCompletedStep('step-1', 1);

        expect(context.hasStep('step-1'), isTrue);
      });

      test('returns false for non-existent step', () {
        final context = SagaContext();

        expect(context.hasStep('unknown'), isFalse);
      });
    });

    group('toString', () {
      test('includes context id and status', () {
        final context = SagaContext(id: 'test-saga');

        expect(context.toString(), contains('test-saga'));
        expect(context.toString(), contains('active'));
      });
    });
  });

  group('CompletedStep', () {
    test('stores name and result', () {
      final step = CompletedStep('test-step', 'result-value');

      expect(step.name, equals('test-step'));
      expect(step.result, equals('result-value'));
    });

    test('tracks completion timestamp', () {
      final before = DateTime.now();
      final step = CompletedStep('test-step', 42);
      final after = DateTime.now();

      expect(step.completedAt.isAfter(before.subtract(Duration(seconds: 1))),
          isTrue);
      expect(step.completedAt.isBefore(after.add(Duration(seconds: 1))), isTrue);
    });

    test('equality based on name', () {
      final step1 = CompletedStep('same-name', 1);
      final step2 = CompletedStep('same-name', 2);
      final step3 = CompletedStep('different', 1);

      expect(step1, equals(step2));
      expect(step1, isNot(equals(step3)));
    });
  });
}
