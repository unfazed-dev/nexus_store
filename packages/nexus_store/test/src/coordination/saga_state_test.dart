import 'package:nexus_store/src/coordination/saga_state.dart';
import 'package:test/test.dart';

void main() {
  group('SagaStatus', () {
    group('isTerminal', () {
      test('returns true for completed', () {
        expect(SagaStatus.completed.isTerminal, isTrue);
      });

      test('returns true for failed', () {
        expect(SagaStatus.failed.isTerminal, isTrue);
      });

      test('returns true for partiallyFailed', () {
        expect(SagaStatus.partiallyFailed.isTerminal, isTrue);
      });

      test('returns false for pending', () {
        expect(SagaStatus.pending.isTerminal, isFalse);
      });

      test('returns false for executing', () {
        expect(SagaStatus.executing.isTerminal, isFalse);
      });

      test('returns false for compensating', () {
        expect(SagaStatus.compensating.isTerminal, isFalse);
      });
    });
  });

  group('SagaState', () {
    final startedAt = DateTime(2024, 1, 1, 12, 0, 0);
    final completedAt = DateTime(2024, 1, 1, 12, 5, 0);
    final steps = [
      const SagaStepState(name: 'step1', status: StepStatus.completed),
      const SagaStepState(name: 'step2', status: StepStatus.pending),
    ];

    SagaState createTestState() => SagaState(
          sagaId: 'saga-123',
          status: SagaStatus.executing,
          currentStepIndex: 1,
          steps: steps,
          startedAt: startedAt,
        );

    test('creates state with required fields', () {
      final state = createTestState();

      expect(state.sagaId, equals('saga-123'));
      expect(state.status, equals(SagaStatus.executing));
      expect(state.currentStepIndex, equals(1));
      expect(state.steps, equals(steps));
      expect(state.startedAt, equals(startedAt));
      expect(state.completedAt, isNull);
      expect(state.stepResults, isEmpty);
      expect(state.error, isNull);
      expect(state.failedStep, isNull);
    });

    test('creates state with optional fields', () {
      final state = SagaState(
        sagaId: 'saga-456',
        status: SagaStatus.failed,
        currentStepIndex: 0,
        steps: steps,
        startedAt: startedAt,
        completedAt: completedAt,
        stepResults: {'step1': 'result1'},
        error: 'Something went wrong',
        failedStep: 'step2',
      );

      expect(state.completedAt, equals(completedAt));
      expect(state.stepResults, equals({'step1': 'result1'}));
      expect(state.error, equals('Something went wrong'));
      expect(state.failedStep, equals('step2'));
    });

    group('copyWith', () {
      test('updates sagaId', () {
        final state = createTestState();
        final updated = state.copyWith(sagaId: 'new-saga');

        expect(updated.sagaId, equals('new-saga'));
        expect(updated.status, equals(state.status));
      });

      test('updates status', () {
        final state = createTestState();
        final updated = state.copyWith(status: SagaStatus.completed);

        expect(updated.status, equals(SagaStatus.completed));
        expect(updated.sagaId, equals(state.sagaId));
      });

      test('updates currentStepIndex', () {
        final state = createTestState();
        final updated = state.copyWith(currentStepIndex: 5);

        expect(updated.currentStepIndex, equals(5));
      });

      test('updates steps', () {
        final state = createTestState();
        final newSteps = [
          const SagaStepState(name: 'new-step', status: StepStatus.pending),
        ];
        final updated = state.copyWith(steps: newSteps);

        expect(updated.steps, equals(newSteps));
      });

      test('updates startedAt', () {
        final state = createTestState();
        final newTime = DateTime(2025, 1, 1);
        final updated = state.copyWith(startedAt: newTime);

        expect(updated.startedAt, equals(newTime));
      });

      test('updates completedAt', () {
        final state = createTestState();
        final updated = state.copyWith(completedAt: completedAt);

        expect(updated.completedAt, equals(completedAt));
      });

      test('updates stepResults', () {
        final state = createTestState();
        final updated = state.copyWith(stepResults: {'key': 'value'});

        expect(updated.stepResults, equals({'key': 'value'}));
      });

      test('updates error', () {
        final state = createTestState();
        final updated = state.copyWith(error: 'test error');

        expect(updated.error, equals('test error'));
      });

      test('updates failedStep', () {
        final state = createTestState();
        final updated = state.copyWith(failedStep: 'step2');

        expect(updated.failedStep, equals('step2'));
      });

      test('preserves all fields when no updates provided', () {
        final state = SagaState(
          sagaId: 'saga-789',
          status: SagaStatus.failed,
          currentStepIndex: 2,
          steps: steps,
          startedAt: startedAt,
          completedAt: completedAt,
          stepResults: {'r': 1},
          error: 'err',
          failedStep: 'step1',
        );
        final updated = state.copyWith();

        expect(updated.sagaId, equals(state.sagaId));
        expect(updated.status, equals(state.status));
        expect(updated.currentStepIndex, equals(state.currentStepIndex));
        expect(updated.steps, equals(state.steps));
        expect(updated.startedAt, equals(state.startedAt));
        expect(updated.completedAt, equals(state.completedAt));
        expect(updated.stepResults, equals(state.stepResults));
        expect(updated.error, equals(state.error));
        expect(updated.failedStep, equals(state.failedStep));
      });
    });

    group('equality', () {
      test('equals when sagaId matches', () {
        final state1 = SagaState(
          sagaId: 'saga-same',
          status: SagaStatus.executing,
          currentStepIndex: 0,
          steps: const [],
          startedAt: startedAt,
        );
        final state2 = SagaState(
          sagaId: 'saga-same',
          status: SagaStatus.completed,
          currentStepIndex: 5,
          steps: steps,
          startedAt: completedAt,
        );

        expect(state1, equals(state2));
      });

      test('not equal when sagaId differs', () {
        final state1 = createTestState();
        final state2 = state1.copyWith(sagaId: 'different-saga');

        expect(state1, isNot(equals(state2)));
      });

      test('identical instances are equal', () {
        final state = createTestState();
        expect(state, equals(state));
      });
    });

    group('hashCode', () {
      test('consistent for same sagaId', () {
        final state1 = createTestState();
        final state2 = state1.copyWith(status: SagaStatus.completed);

        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('based on sagaId only', () {
        final state = createTestState();
        expect(state.hashCode, equals('saga-123'.hashCode));
      });
    });

    group('toString', () {
      test('contains sagaId', () {
        final state = createTestState();
        expect(state.toString(), contains('saga-123'));
      });

      test('contains status', () {
        final state = createTestState();
        expect(state.toString(), contains('executing'));
      });

      test('contains step progress', () {
        final state = createTestState();
        expect(state.toString(), contains('1/2'));
      });
    });
  });

  group('SagaStepState', () {
    test('creates state with required fields', () {
      const state = SagaStepState(
        name: 'test-step',
        status: StepStatus.pending,
      );

      expect(state.name, equals('test-step'));
      expect(state.status, equals(StepStatus.pending));
      expect(state.result, isNull);
      expect(state.error, isNull);
      expect(state.startedAt, isNull);
      expect(state.completedAt, isNull);
    });

    test('creates state with optional fields', () {
      final startedAt = DateTime(2024, 1, 1);
      final completedAt = DateTime(2024, 1, 2);
      final state = SagaStepState(
        name: 'test-step',
        status: StepStatus.completed,
        result: {'data': 'value'},
        error: 'some error',
        startedAt: startedAt,
        completedAt: completedAt,
      );

      expect(state.result, equals({'data': 'value'}));
      expect(state.error, equals('some error'));
      expect(state.startedAt, equals(startedAt));
      expect(state.completedAt, equals(completedAt));
    });

    group('copyWith', () {
      test('updates name', () {
        const state = SagaStepState(name: 'old', status: StepStatus.pending);
        final updated = state.copyWith(name: 'new');

        expect(updated.name, equals('new'));
        expect(updated.status, equals(StepStatus.pending));
      });

      test('updates status', () {
        const state = SagaStepState(name: 'step', status: StepStatus.pending);
        final updated = state.copyWith(status: StepStatus.executing);

        expect(updated.status, equals(StepStatus.executing));
      });

      test('updates result', () {
        const state = SagaStepState(name: 'step', status: StepStatus.completed);
        final updated = state.copyWith(result: 'new-result');

        expect(updated.result, equals('new-result'));
      });

      test('updates error', () {
        const state = SagaStepState(name: 'step', status: StepStatus.failed);
        final updated = state.copyWith(error: 'error message');

        expect(updated.error, equals('error message'));
      });

      test('updates startedAt', () {
        const state = SagaStepState(name: 'step', status: StepStatus.executing);
        final time = DateTime(2024, 6, 1);
        final updated = state.copyWith(startedAt: time);

        expect(updated.startedAt, equals(time));
      });

      test('updates completedAt', () {
        const state = SagaStepState(name: 'step', status: StepStatus.completed);
        final time = DateTime(2024, 6, 2);
        final updated = state.copyWith(completedAt: time);

        expect(updated.completedAt, equals(time));
      });

      test('preserves all fields when no updates provided', () {
        final startedAt = DateTime(2024, 1, 1);
        final completedAt = DateTime(2024, 1, 2);
        final state = SagaStepState(
          name: 'step',
          status: StepStatus.completed,
          result: 'res',
          error: 'err',
          startedAt: startedAt,
          completedAt: completedAt,
        );
        final updated = state.copyWith();

        expect(updated.name, equals(state.name));
        expect(updated.status, equals(state.status));
        expect(updated.result, equals(state.result));
        expect(updated.error, equals(state.error));
        expect(updated.startedAt, equals(state.startedAt));
        expect(updated.completedAt, equals(state.completedAt));
      });
    });

    group('equality', () {
      test('equals when name and status match', () {
        const state1 = SagaStepState(name: 'step', status: StepStatus.pending);
        final state2 = SagaStepState(
          name: 'step',
          status: StepStatus.pending,
          result: 'different',
          error: 'different',
          startedAt: DateTime(2024, 1, 1),
        );

        expect(state1, equals(state2));
      });

      test('not equal when name differs', () {
        const state1 = SagaStepState(name: 'step1', status: StepStatus.pending);
        const state2 = SagaStepState(name: 'step2', status: StepStatus.pending);

        expect(state1, isNot(equals(state2)));
      });

      test('not equal when status differs', () {
        const state1 = SagaStepState(name: 'step', status: StepStatus.pending);
        const state2 =
            SagaStepState(name: 'step', status: StepStatus.executing);

        expect(state1, isNot(equals(state2)));
      });

      test('identical instances are equal', () {
        const state = SagaStepState(name: 'step', status: StepStatus.pending);
        expect(state, equals(state));
      });
    });

    group('hashCode', () {
      test('consistent for same name and status', () {
        const state1 = SagaStepState(name: 'step', status: StepStatus.pending);
        final state2 = SagaStepState(
          name: 'step',
          status: StepStatus.pending,
          result: 'different',
        );

        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('based on name and status', () {
        const state = SagaStepState(name: 'step', status: StepStatus.pending);
        expect(
          state.hashCode,
          equals(Object.hash('step', StepStatus.pending)),
        );
      });
    });

    group('toString', () {
      test('contains name', () {
        const state = SagaStepState(name: 'my-step', status: StepStatus.pending);
        expect(state.toString(), contains('my-step'));
      });

      test('contains status', () {
        const state =
            SagaStepState(name: 'step', status: StepStatus.compensating);
        expect(state.toString(), contains('compensating'));
      });
    });
  });

  group('StepStatus', () {
    test('has all expected values', () {
      expect(
        StepStatus.values,
        containsAll([
          StepStatus.pending,
          StepStatus.executing,
          StepStatus.completed,
          StepStatus.failed,
          StepStatus.compensating,
          StepStatus.compensated,
        ]),
      );
    });
  });
}
