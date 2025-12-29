import 'package:nexus_store/src/coordination/saga_persistence.dart';
import 'package:nexus_store/src/coordination/saga_state.dart';
import 'package:test/test.dart';

void main() {
  group('SagaState', () {
    test('creates state with required fields', () {
      final state = SagaState(
        sagaId: 'saga-123',
        status: SagaStatus.executing,
        currentStepIndex: 1,
        steps: [
          SagaStepState(name: 'step-1', status: StepStatus.completed),
          SagaStepState(name: 'step-2', status: StepStatus.pending),
        ],
        startedAt: DateTime.now(),
      );

      expect(state.sagaId, equals('saga-123'));
      expect(state.status, equals(SagaStatus.executing));
      expect(state.currentStepIndex, equals(1));
      expect(state.steps.length, equals(2));
    });

    test('stepResults stores and retrieves results', () {
      final state = SagaState(
        sagaId: 'saga-123',
        status: SagaStatus.executing,
        currentStepIndex: 0,
        steps: [],
        startedAt: DateTime.now(),
        stepResults: {'step-1': 42, 'step-2': 'hello'},
      );

      expect(state.stepResults['step-1'], equals(42));
      expect(state.stepResults['step-2'], equals('hello'));
    });

    test('copyWith creates modified copy', () {
      final original = SagaState(
        sagaId: 'saga-123',
        status: SagaStatus.executing,
        currentStepIndex: 0,
        steps: [],
        startedAt: DateTime.now(),
      );

      final modified = original.copyWith(
        status: SagaStatus.completed,
        currentStepIndex: 3,
      );

      expect(modified.sagaId, equals('saga-123'));
      expect(modified.status, equals(SagaStatus.completed));
      expect(modified.currentStepIndex, equals(3));
    });

    test('equality based on sagaId', () {
      final state1 = SagaState(
        sagaId: 'saga-123',
        status: SagaStatus.executing,
        currentStepIndex: 0,
        steps: [],
        startedAt: DateTime.now(),
      );
      final state2 = SagaState(
        sagaId: 'saga-123',
        status: SagaStatus.completed,
        currentStepIndex: 5,
        steps: [],
        startedAt: DateTime.now(),
      );
      final state3 = SagaState(
        sagaId: 'saga-456',
        status: SagaStatus.executing,
        currentStepIndex: 0,
        steps: [],
        startedAt: DateTime.now(),
      );

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });
  });

  group('SagaStepState', () {
    test('creates step state with name and status', () {
      final stepState = SagaStepState(
        name: 'create-order',
        status: StepStatus.completed,
      );

      expect(stepState.name, equals('create-order'));
      expect(stepState.status, equals(StepStatus.completed));
    });

    test('stores result when completed', () {
      final stepState = SagaStepState(
        name: 'step-1',
        status: StepStatus.completed,
        result: {'orderId': '123'},
      );

      expect(stepState.result, equals({'orderId': '123'}));
    });

    test('stores error when failed', () {
      final stepState = SagaStepState(
        name: 'step-1',
        status: StepStatus.failed,
        error: 'Connection timeout',
      );

      expect(stepState.error, equals('Connection timeout'));
    });
  });

  group('SagaStatus', () {
    test('has all expected values', () {
      expect(SagaStatus.values, containsAll([
        SagaStatus.pending,
        SagaStatus.executing,
        SagaStatus.compensating,
        SagaStatus.completed,
        SagaStatus.failed,
        SagaStatus.partiallyFailed,
      ]));
    });

    test('isTerminal returns true for completed states', () {
      expect(SagaStatus.completed.isTerminal, isTrue);
      expect(SagaStatus.failed.isTerminal, isTrue);
      expect(SagaStatus.partiallyFailed.isTerminal, isTrue);
      expect(SagaStatus.executing.isTerminal, isFalse);
      expect(SagaStatus.pending.isTerminal, isFalse);
    });
  });

  group('InMemorySagaPersistence', () {
    late InMemorySagaPersistence persistence;

    setUp(() {
      persistence = InMemorySagaPersistence();
    });

    group('save', () {
      test('saves saga state', () async {
        final state = SagaState(
          sagaId: 'saga-123',
          status: SagaStatus.executing,
          currentStepIndex: 0,
          steps: [],
          startedAt: DateTime.now(),
        );

        await persistence.save(state);

        final loaded = await persistence.load('saga-123');
        expect(loaded, isNotNull);
        expect(loaded!.sagaId, equals('saga-123'));
      });

      test('updates existing saga state', () async {
        final initial = SagaState(
          sagaId: 'saga-123',
          status: SagaStatus.executing,
          currentStepIndex: 0,
          steps: [],
          startedAt: DateTime.now(),
        );
        await persistence.save(initial);

        final updated = initial.copyWith(
          status: SagaStatus.completed,
          currentStepIndex: 5,
        );
        await persistence.save(updated);

        final loaded = await persistence.load('saga-123');
        expect(loaded!.status, equals(SagaStatus.completed));
        expect(loaded.currentStepIndex, equals(5));
      });
    });

    group('load', () {
      test('returns null for non-existent saga', () async {
        final state = await persistence.load('non-existent');

        expect(state, isNull);
      });

      test('returns saved saga state', () async {
        final state = SagaState(
          sagaId: 'saga-123',
          status: SagaStatus.executing,
          currentStepIndex: 2,
          steps: [
            SagaStepState(name: 'step-1', status: StepStatus.completed),
            SagaStepState(name: 'step-2', status: StepStatus.completed),
            SagaStepState(name: 'step-3', status: StepStatus.pending),
          ],
          startedAt: DateTime(2024, 1, 1),
          stepResults: {'step-1': 'result-1'},
        );
        await persistence.save(state);

        final loaded = await persistence.load('saga-123');

        expect(loaded, isNotNull);
        expect(loaded!.currentStepIndex, equals(2));
        expect(loaded.steps.length, equals(3));
        expect(loaded.stepResults['step-1'], equals('result-1'));
      });
    });

    group('delete', () {
      test('removes saga state', () async {
        final state = SagaState(
          sagaId: 'saga-123',
          status: SagaStatus.completed,
          currentStepIndex: 3,
          steps: [],
          startedAt: DateTime.now(),
        );
        await persistence.save(state);

        await persistence.delete('saga-123');

        final loaded = await persistence.load('saga-123');
        expect(loaded, isNull);
      });

      test('does nothing for non-existent saga', () async {
        // Should not throw
        await persistence.delete('non-existent');
      });
    });

    group('getIncomplete', () {
      test('returns only incomplete sagas', () async {
        await persistence.save(SagaState(
          sagaId: 'saga-1',
          status: SagaStatus.executing,
          currentStepIndex: 0,
          steps: [],
          startedAt: DateTime.now(),
        ));
        await persistence.save(SagaState(
          sagaId: 'saga-2',
          status: SagaStatus.completed,
          currentStepIndex: 3,
          steps: [],
          startedAt: DateTime.now(),
        ));
        await persistence.save(SagaState(
          sagaId: 'saga-3',
          status: SagaStatus.compensating,
          currentStepIndex: 2,
          steps: [],
          startedAt: DateTime.now(),
        ));
        await persistence.save(SagaState(
          sagaId: 'saga-4',
          status: SagaStatus.failed,
          currentStepIndex: 1,
          steps: [],
          startedAt: DateTime.now(),
        ));

        final incomplete = await persistence.getIncomplete();

        expect(incomplete.length, equals(2));
        expect(incomplete.any((s) => s.sagaId == 'saga-1'), isTrue);
        expect(incomplete.any((s) => s.sagaId == 'saga-3'), isTrue);
      });

      test('returns empty list when no incomplete sagas', () async {
        await persistence.save(SagaState(
          sagaId: 'saga-1',
          status: SagaStatus.completed,
          currentStepIndex: 3,
          steps: [],
          startedAt: DateTime.now(),
        ));

        final incomplete = await persistence.getIncomplete();

        expect(incomplete, isEmpty);
      });
    });

    group('clear', () {
      test('removes all saga states', () async {
        await persistence.save(SagaState(
          sagaId: 'saga-1',
          status: SagaStatus.executing,
          currentStepIndex: 0,
          steps: [],
          startedAt: DateTime.now(),
        ));
        await persistence.save(SagaState(
          sagaId: 'saga-2',
          status: SagaStatus.completed,
          currentStepIndex: 3,
          steps: [],
          startedAt: DateTime.now(),
        ));

        await persistence.clear();

        expect(await persistence.load('saga-1'), isNull);
        expect(await persistence.load('saga-2'), isNull);
      });
    });
  });
}
