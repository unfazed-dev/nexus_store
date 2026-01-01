import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_signals_binding/src/lifecycle/signal_scope.dart';

import 'fixtures/mock_store.dart';
import 'fixtures/test_entities.dart';

void main() {
  setUpAll(() {
    registerFallbackValues();
  });

  group('SignalScope', () {
    test('tracks created signals', () {
      final scope = SignalScope();

      final signal1 = scope.createSignal(0);
      final signal2 = scope.createSignal('test');

      expect(scope.signalCount, equals(2));
      expect(signal1.value, equals(0));
      expect(signal2.value, equals('test'));
    });

    test('disposeAll disposes all tracked signals', () {
      final scope = SignalScope();

      final signal1 = scope.createSignal(0);
      final signal2 = scope.createSignal('test');

      expect(signal1.disposed, isFalse);
      expect(signal2.disposed, isFalse);

      scope.disposeAll();

      expect(signal1.disposed, isTrue);
      expect(signal2.disposed, isTrue);
      expect(scope.signalCount, equals(0));
    });

    test('createComputed tracks computed signals', () {
      final scope = SignalScope();

      final source = scope.createSignal(testUsers);
      final count = scope.createComputed(() => source.value.length);

      expect(count.value, equals(3));
      expect(scope.signalCount, equals(2));
    });

    test('disposeAll disposes computed signals', () {
      final scope = SignalScope();

      final source = scope.createSignal(testUsers);
      final count = scope.createComputed(() => source.value.length);

      scope.disposeAll();

      expect(source.disposed, isTrue);
      expect(count.disposed, isTrue);
    });

    test('createFromStore tracks store signals', () {
      final mockStore = MockNexusStore<TestUser, String>();
      final controller = StreamController<List<TestUser>>.broadcast();
      when(() => mockStore.watchAll(query: any(named: 'query')))
          .thenAnswer((_) => controller.stream);

      final scope = SignalScope();
      final storeSignal = scope.createFromStore(mockStore);

      expect(storeSignal.value, isEmpty);
      expect(scope.signalCount, equals(1));

      scope.disposeAll();
      controller.close();
    });

    test('double dispose is safe', () {
      final scope = SignalScope();
      scope.createSignal(0);

      scope.disposeAll();
      expect(() => scope.disposeAll(), returnsNormally);
    });

    test('isDisposed returns correct state', () {
      final scope = SignalScope();
      scope.createSignal(0);

      expect(scope.isDisposed, isFalse);

      scope.disposeAll();

      expect(scope.isDisposed, isTrue);
    });

    group('createItemFromStore', () {
      late MockNexusStore<TestUser, String> mockStore;
      late StreamController<TestUser?> controller;

      setUp(() {
        mockStore = MockNexusStore<TestUser, String>();
        controller = StreamController<TestUser?>.broadcast();
        when(() => mockStore.watch(any())).thenAnswer((_) => controller.stream);
      });

      tearDown(() {
        controller.close();
      });

      test('tracks item signal in scope', () {
        final scope = SignalScope();
        final signal = scope.createItemFromStore(mockStore, '1');

        expect(signal.value, isNull);
        expect(scope.signalCount, equals(1));

        scope.disposeAll();
      });

      test('signal updates when store emits item', () async {
        final scope = SignalScope();
        final signal = scope.createItemFromStore(mockStore, '1');

        controller.add(testUser1);
        await Future<void>.delayed(Duration.zero);

        expect(signal.value, equals(testUser1));

        scope.disposeAll();
      });

      test('signal handles null emission (item not found)', () async {
        final scope = SignalScope();
        final signal = scope.createItemFromStore(mockStore, 'nonexistent');

        controller.add(null);
        await Future<void>.delayed(Duration.zero);

        expect(signal.value, isNull);

        scope.disposeAll();
      });

      test('disposeAll cancels subscription', () async {
        final scope = SignalScope();
        scope.createItemFromStore(mockStore, '1');

        expect(controller.hasListener, isTrue);

        scope.disposeAll();

        await Future<void>.delayed(Duration.zero);

        expect(controller.hasListener, isFalse);
      });

      test('handles stream errors silently', () async {
        final scope = SignalScope();
        final signal = scope.createItemFromStore(mockStore, '1');

        // Emit an error - should be silently ignored
        controller.addError(Exception('test error'));
        await Future<void>.delayed(Duration.zero);

        // Signal should still have null value (no crash)
        expect(signal.value, isNull);

        scope.disposeAll();
      });

      test('passes correct id to store watch', () {
        final scope = SignalScope();
        scope.createItemFromStore(mockStore, 'user-abc');

        verify(() => mockStore.watch('user-abc')).called(1);

        scope.disposeAll();
      });
    });

    group('createFromStore with query', () {
      late MockNexusStore<TestUser, String> mockStore;
      late StreamController<List<TestUser>> controller;

      setUp(() {
        mockStore = MockNexusStore<TestUser, String>();
        controller = StreamController<List<TestUser>>.broadcast();
        when(() => mockStore.watchAll(query: any(named: 'query')))
            .thenAnswer((_) => controller.stream);
      });

      tearDown(() {
        controller.close();
      });

      test('passes query parameter to store watchAll', () {
        const query = Query<TestUser>();
        final scope = SignalScope();

        scope.createFromStore(mockStore, query: query);

        verify(() => mockStore.watchAll(query: query)).called(1);

        scope.disposeAll();
      });

      test('signal updates with query-filtered data', () async {
        const query = Query<TestUser>();
        final scope = SignalScope();
        final signal = scope.createFromStore(mockStore, query: query);

        controller.add([testUser1]);
        await Future<void>.delayed(Duration.zero);

        expect(signal.value, equals([testUser1]));

        scope.disposeAll();
      });

      test('handles stream errors silently', () async {
        final scope = SignalScope();
        final signal = scope.createFromStore(mockStore);

        // Emit an error - should be silently ignored
        controller.addError(Exception('test error'));
        await Future<void>.delayed(Duration.zero);

        // Signal should still have empty list (no crash)
        expect(signal.value, isEmpty);

        scope.disposeAll();
      });
    });
  });
}
