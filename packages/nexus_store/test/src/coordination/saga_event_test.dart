import 'package:nexus_store/src/coordination/saga_event.dart';
import 'package:test/test.dart';

void main() {
  group('SagaEvent', () {
    test('has all expected values', () {
      expect(
          SagaEvent.values,
          containsAll([
            SagaEvent.sagaStarted,
            SagaEvent.sagaCompleted,
            SagaEvent.sagaFailed,
            SagaEvent.stepStarted,
            SagaEvent.stepCompleted,
            SagaEvent.stepFailed,
            SagaEvent.compensationStarted,
            SagaEvent.compensationCompleted,
            SagaEvent.compensationFailed,
          ]));
    });
  });

  group('SagaEventData', () {
    test('creates event data with required fields', () {
      final timestamp = DateTime.now();
      final eventData = SagaEventData(
        event: SagaEvent.stepStarted,
        sagaId: 'saga-123',
        stepName: 'create-order',
        timestamp: timestamp,
      );

      expect(eventData.event, equals(SagaEvent.stepStarted));
      expect(eventData.sagaId, equals('saga-123'));
      expect(eventData.stepName, equals('create-order'));
      expect(eventData.timestamp, equals(timestamp));
      expect(eventData.error, isNull);
      expect(eventData.duration, isNull);
    });

    test('creates event data with optional fields', () {
      final error = Exception('test error');
      final eventData = SagaEventData(
        event: SagaEvent.stepFailed,
        sagaId: 'saga-123',
        stepName: 'charge-payment',
        timestamp: DateTime.now(),
        error: error,
        duration: const Duration(milliseconds: 500),
      );

      expect(eventData.error, equals(error));
      expect(eventData.duration, equals(const Duration(milliseconds: 500)));
    });

    test('equality based on all fields', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final event1 = SagaEventData(
        event: SagaEvent.stepCompleted,
        sagaId: 'saga-1',
        stepName: 'step-1',
        timestamp: timestamp,
      );
      final event2 = SagaEventData(
        event: SagaEvent.stepCompleted,
        sagaId: 'saga-1',
        stepName: 'step-1',
        timestamp: timestamp,
      );
      final event3 = SagaEventData(
        event: SagaEvent.stepFailed,
        sagaId: 'saga-1',
        stepName: 'step-1',
        timestamp: timestamp,
      );

      expect(event1, equals(event2));
      expect(event1, isNot(equals(event3)));
    });

    test('hashCode consistent with equality', () {
      final timestamp = DateTime(2024, 1, 1);
      final event1 = SagaEventData(
        event: SagaEvent.stepStarted,
        sagaId: 'saga-1',
        stepName: 'step-1',
        timestamp: timestamp,
      );
      final event2 = SagaEventData(
        event: SagaEvent.stepStarted,
        sagaId: 'saga-1',
        stepName: 'step-1',
        timestamp: timestamp,
      );

      expect(event1.hashCode, equals(event2.hashCode));
    });

    test('toString contains event type and step name', () {
      final eventData = SagaEventData(
        event: SagaEvent.compensationCompleted,
        sagaId: 'saga-123',
        stepName: 'refund-payment',
        timestamp: DateTime.now(),
      );

      expect(eventData.toString(), contains('compensationCompleted'));
      expect(eventData.toString(), contains('refund-payment'));
    });

    test('isStepEvent returns true for step events', () {
      expect(
        SagaEventData(
          event: SagaEvent.stepStarted,
          sagaId: 's',
          stepName: 'x',
          timestamp: DateTime.now(),
        ).isStepEvent,
        isTrue,
      );
      expect(
        SagaEventData(
          event: SagaEvent.stepCompleted,
          sagaId: 's',
          stepName: 'x',
          timestamp: DateTime.now(),
        ).isStepEvent,
        isTrue,
      );
      expect(
        SagaEventData(
          event: SagaEvent.stepFailed,
          sagaId: 's',
          stepName: 'x',
          timestamp: DateTime.now(),
        ).isStepEvent,
        isTrue,
      );
    });

    test('isCompensationEvent returns true for compensation events', () {
      expect(
        SagaEventData(
          event: SagaEvent.compensationStarted,
          sagaId: 's',
          stepName: 'x',
          timestamp: DateTime.now(),
        ).isCompensationEvent,
        isTrue,
      );
      expect(
        SagaEventData(
          event: SagaEvent.compensationCompleted,
          sagaId: 's',
          stepName: 'x',
          timestamp: DateTime.now(),
        ).isCompensationEvent,
        isTrue,
      );
      expect(
        SagaEventData(
          event: SagaEvent.compensationFailed,
          sagaId: 's',
          stepName: 'x',
          timestamp: DateTime.now(),
        ).isCompensationEvent,
        isTrue,
      );
    });

    test('isSagaEvent returns true for saga lifecycle events', () {
      expect(
        SagaEventData(
          event: SagaEvent.sagaStarted,
          sagaId: 's',
          timestamp: DateTime.now(),
        ).isSagaEvent,
        isTrue,
      );
      expect(
        SagaEventData(
          event: SagaEvent.sagaCompleted,
          sagaId: 's',
          timestamp: DateTime.now(),
        ).isSagaEvent,
        isTrue,
      );
      expect(
        SagaEventData(
          event: SagaEvent.sagaFailed,
          sagaId: 's',
          timestamp: DateTime.now(),
        ).isSagaEvent,
        isTrue,
      );
    });
  });
}
