import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_signals_binding/src/extensions/store_signal_extension.dart';
import 'package:nexus_store_signals_binding/src/state/nexus_signal_state.dart';
import 'package:nexus_store_signals_binding/src/state/nexus_item_signal_state.dart';
import 'package:signals/signals.dart';

import 'fixtures/mock_store.dart';
import 'fixtures/test_entities.dart';

void main() {
  setUpAll(() {
    registerFallbackValues();
  });

  group('NexusStoreSignalExtension', () {
    late MockNexusStore<TestUser, String> mockStore;

    setUp(() {
      mockStore = MockNexusStore<TestUser, String>();
    });

    group('toSignal', () {
      test('returns a signal with initial empty list', () {
        final controller = StreamController<List<TestUser>>.broadcast();
        when(() => mockStore.watchAll(query: any(named: 'query')))
            .thenAnswer((_) => controller.stream);

        final signal = mockStore.toSignal();

        expect(signal, isA<Signal<List<TestUser>>>());
        expect(signal.value, isEmpty);

        controller.close();
      });

      test('signal updates when store emits data', () async {
        final controller = StreamController<List<TestUser>>.broadcast();
        when(() => mockStore.watchAll(query: any(named: 'query')))
            .thenAnswer((_) => controller.stream);

        final signal = mockStore.toSignal();

        controller.add(testUsers);
        await Future<void>.delayed(Duration.zero);

        expect(signal.value, equals(testUsers));

        controller.close();
      });

      test('signal updates on subsequent emissions', () async {
        final controller = StreamController<List<TestUser>>.broadcast();
        when(() => mockStore.watchAll(query: any(named: 'query')))
            .thenAnswer((_) => controller.stream);

        final signal = mockStore.toSignal();

        controller.add([testUser1]);
        await Future<void>.delayed(Duration.zero);
        expect(signal.value, equals([testUser1]));

        controller.add([testUser1, testUser2]);
        await Future<void>.delayed(Duration.zero);
        expect(signal.value, equals([testUser1, testUser2]));

        controller.close();
      });

      test('returns disposable signal', () {
        final controller = StreamController<List<TestUser>>.broadcast();
        when(() => mockStore.watchAll(query: any(named: 'query')))
            .thenAnswer((_) => controller.stream);

        final signal = mockStore.toSignal();

        expect(() => signal.dispose(), returnsNormally);

        controller.close();
      });

      test('dispose cancels subscription', () async {
        final controller = StreamController<List<TestUser>>.broadcast();
        when(() => mockStore.watchAll(query: any(named: 'query')))
            .thenAnswer((_) => controller.stream);

        final signal = mockStore.toSignal();

        // First emit some data
        controller.add([testUser1]);
        await Future<void>.delayed(Duration.zero);
        expect(signal.value, equals([testUser1]));

        // Dispose the signal
        signal.dispose();

        // Add more data - should not be received
        controller.add([testUser1, testUser2]);
        await Future<void>.delayed(Duration.zero);

        // Value should still be the old value since subscription was cancelled
        expect(signal.value, equals([testUser1]));

        controller.close();
      });

      test('silently ignores stream errors', () async {
        final controller = StreamController<List<TestUser>>.broadcast();
        when(() => mockStore.watchAll(query: any(named: 'query')))
            .thenAnswer((_) => controller.stream);

        final signal = mockStore.toSignal();

        // Emit error - should be silently ignored
        controller.addError(Exception('test error'));
        await Future<void>.delayed(Duration.zero);

        // Signal should remain empty (no crash)
        expect(signal.value, isEmpty);

        controller.close();
      });

      test('accepts query parameter', () async {
        final controller = StreamController<List<TestUser>>.broadcast();
        when(() => mockStore.watchAll(query: any(named: 'query')))
            .thenAnswer((_) => controller.stream);

        final signal = mockStore.toSignal(query: const Query<TestUser>());

        expect(signal.value, isEmpty);

        controller.close();
      });
    });

    group('toItemSignal', () {
      test('returns a signal with initial null value', () {
        final controller = StreamController<TestUser?>.broadcast();
        when(() => mockStore.watch(any())).thenAnswer((_) => controller.stream);

        final signal = mockStore.toItemSignal('1');

        expect(signal, isA<Signal<TestUser?>>());
        expect(signal.value, isNull);

        controller.close();
      });

      test('signal updates when store emits item', () async {
        final controller = StreamController<TestUser?>.broadcast();
        when(() => mockStore.watch(any())).thenAnswer((_) => controller.stream);

        final signal = mockStore.toItemSignal('1');

        controller.add(testUser1);
        await Future<void>.delayed(Duration.zero);

        expect(signal.value, equals(testUser1));

        controller.close();
      });

      test('signal handles null emissions (item not found)', () async {
        final controller = StreamController<TestUser?>.broadcast();
        when(() => mockStore.watch(any())).thenAnswer((_) => controller.stream);

        final signal = mockStore.toItemSignal('nonexistent');

        controller.add(null);
        await Future<void>.delayed(Duration.zero);

        expect(signal.value, isNull);

        controller.close();
      });

      test('silently ignores stream errors', () async {
        final controller = StreamController<TestUser?>.broadcast();
        when(() => mockStore.watch(any())).thenAnswer((_) => controller.stream);

        final signal = mockStore.toItemSignal('1');

        // Emit error - should be silently ignored
        controller.addError(Exception('test error'));
        await Future<void>.delayed(Duration.zero);

        // Signal should remain null (no crash)
        expect(signal.value, isNull);

        controller.close();
      });

      test('dispose cancels subscription', () async {
        final controller = StreamController<TestUser?>.broadcast();
        when(() => mockStore.watch(any())).thenAnswer((_) => controller.stream);

        final signal = mockStore.toItemSignal('1');

        // First emit some data
        controller.add(testUser1);
        await Future<void>.delayed(Duration.zero);
        expect(signal.value, equals(testUser1));

        // Dispose the signal
        signal.dispose();

        // Add more data - should not be received
        controller.add(testUser2);
        await Future<void>.delayed(Duration.zero);

        // Value should still be the old value since subscription was cancelled
        expect(signal.value, equals(testUser1));

        controller.close();
      });
    });

    group('toStateSignal', () {
      test('returns a signal with initial state', () {
        final controller = StreamController<List<TestUser>>.broadcast();
        when(() => mockStore.watchAll(query: any(named: 'query')))
            .thenAnswer((_) => controller.stream);

        final signal = mockStore.toStateSignal();

        expect(signal, isA<Signal<NexusSignalState<TestUser>>>());
        expect(signal.value, isA<NexusSignalInitial<TestUser>>());

        controller.close();
      });

      test('transitions to loading then data state', () async {
        final controller = StreamController<List<TestUser>>.broadcast();
        when(() => mockStore.watchAll(query: any(named: 'query')))
            .thenAnswer((_) => controller.stream);

        final signal = mockStore.toStateSignal();

        // Initial state
        expect(signal.value, isA<NexusSignalInitial<TestUser>>());

        // Emit data
        controller.add(testUsers);
        await Future<void>.delayed(Duration.zero);

        expect(signal.value, isA<NexusSignalData<TestUser>>());
        expect((signal.value as NexusSignalData<TestUser>).data,
            equals(testUsers));

        controller.close();
      });

      test('handles stream errors', () async {
        final controller = StreamController<List<TestUser>>.broadcast();
        when(() => mockStore.watchAll(query: any(named: 'query')))
            .thenAnswer((_) => controller.stream);

        final signal = mockStore.toStateSignal();

        controller.addError(Exception('test error'));
        await Future<void>.delayed(Duration.zero);

        expect(signal.value, isA<NexusSignalError<TestUser>>());
        expect((signal.value as NexusSignalError<TestUser>).error,
            isA<Exception>());

        controller.close();
      });

      test('preserves previous data on error', () async {
        final controller = StreamController<List<TestUser>>.broadcast();
        when(() => mockStore.watchAll(query: any(named: 'query')))
            .thenAnswer((_) => controller.stream);

        final signal = mockStore.toStateSignal();

        // First emit data
        controller.add(testUsers);
        await Future<void>.delayed(Duration.zero);

        // Then emit error
        controller.addError(Exception('test error'));
        await Future<void>.delayed(Duration.zero);

        expect(signal.value, isA<NexusSignalError<TestUser>>());
        final errorState = signal.value as NexusSignalError<TestUser>;
        expect(errorState.previousData, equals(testUsers));

        controller.close();
      });

      test('accepts query parameter', () async {
        final controller = StreamController<List<TestUser>>.broadcast();
        when(() => mockStore.watchAll(query: any(named: 'query')))
            .thenAnswer((_) => controller.stream);

        final signal = mockStore.toStateSignal(query: const Query<TestUser>());

        expect(signal.value, isA<NexusSignalInitial<TestUser>>());

        controller.close();
      });

      test('dispose cancels subscription', () async {
        final controller = StreamController<List<TestUser>>.broadcast();
        when(() => mockStore.watchAll(query: any(named: 'query')))
            .thenAnswer((_) => controller.stream);

        final signal = mockStore.toStateSignal();

        // First emit some data
        controller.add([testUser1]);
        await Future<void>.delayed(Duration.zero);
        expect(signal.value, isA<NexusSignalData<TestUser>>());

        // Dispose the signal
        signal.dispose();

        // Add more data - should not be received
        controller.add([testUser1, testUser2]);
        await Future<void>.delayed(Duration.zero);

        // Value should still be the old value since subscription was cancelled
        final state = signal.value as NexusSignalData<TestUser>;
        expect(state.data, equals([testUser1]));

        controller.close();
      });
    });

    group('toItemStateSignal', () {
      test('returns a signal with initial state', () {
        final controller = StreamController<TestUser?>.broadcast();
        when(() => mockStore.watch(any())).thenAnswer((_) => controller.stream);

        final signal = mockStore.toItemStateSignal('1');

        expect(signal, isA<Signal<NexusItemSignalState<TestUser>>>());
        expect(signal.value, isA<NexusItemSignalInitial<TestUser>>());

        controller.close();
      });

      test('transitions to data state when item found', () async {
        final controller = StreamController<TestUser?>.broadcast();
        when(() => mockStore.watch(any())).thenAnswer((_) => controller.stream);

        final signal = mockStore.toItemStateSignal('1');

        controller.add(testUser1);
        await Future<void>.delayed(Duration.zero);

        expect(signal.value, isA<NexusItemSignalData<TestUser>>());
        expect((signal.value as NexusItemSignalData<TestUser>).data,
            equals(testUser1));

        controller.close();
      });

      test('transitions to notFound state when item is null', () async {
        final controller = StreamController<TestUser?>.broadcast();
        when(() => mockStore.watch(any())).thenAnswer((_) => controller.stream);

        final signal = mockStore.toItemStateSignal('nonexistent');

        controller.add(null);
        await Future<void>.delayed(Duration.zero);

        expect(signal.value, isA<NexusItemSignalNotFound<TestUser>>());

        controller.close();
      });

      test('handles stream errors', () async {
        final controller = StreamController<TestUser?>.broadcast();
        when(() => mockStore.watch(any())).thenAnswer((_) => controller.stream);

        final signal = mockStore.toItemStateSignal('1');

        controller.addError(Exception('test error'));
        await Future<void>.delayed(Duration.zero);

        expect(signal.value, isA<NexusItemSignalError<TestUser>>());

        controller.close();
      });

      test('preserves previous data on error', () async {
        final controller = StreamController<TestUser?>.broadcast();
        when(() => mockStore.watch(any())).thenAnswer((_) => controller.stream);

        final signal = mockStore.toItemStateSignal('1');

        // First emit data
        controller.add(testUser1);
        await Future<void>.delayed(Duration.zero);

        // Then emit error
        controller.addError(Exception('test error'));
        await Future<void>.delayed(Duration.zero);

        expect(signal.value, isA<NexusItemSignalError<TestUser>>());
        final errorState = signal.value as NexusItemSignalError<TestUser>;
        expect(errorState.previousData, equals(testUser1));

        controller.close();
      });

      test('dispose cancels subscription', () async {
        final controller = StreamController<TestUser?>.broadcast();
        when(() => mockStore.watch(any())).thenAnswer((_) => controller.stream);

        final signal = mockStore.toItemStateSignal('1');

        // First emit some data
        controller.add(testUser1);
        await Future<void>.delayed(Duration.zero);
        expect(signal.value, isA<NexusItemSignalData<TestUser>>());

        // Dispose the signal
        signal.dispose();

        // Add more data - should not be received
        controller.add(testUser2);
        await Future<void>.delayed(Duration.zero);

        // Value should still be the old value since subscription was cancelled
        final state = signal.value as NexusItemSignalData<TestUser>;
        expect(state.data, equals(testUser1));

        controller.close();
      });
    });
  });
}
