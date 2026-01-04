import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_signals_binding/src/lifecycle/signal_scope.dart';

import 'fixtures/mock_store.dart';
import 'fixtures/test_entities.dart';

/// Test class that uses NexusSignalsMixin.
class TestMixinClass with NexusSignalsMixin<TestMixinClass> {}

void main() {
  setUpAll(() {
    registerFallbackValues();
  });

  group('NexusSignalsMixin', () {
    late TestMixinClass testClass;

    setUp(() {
      testClass = TestMixinClass();
    });

    tearDown(() {
      testClass.disposeSignals();
    });

    group('createSignal', () {
      test('creates a signal with initial value', () {
        final signal = testClass.createSignal(42);

        expect(signal.value, equals(42));
      });

      test('signal updates correctly', () {
        final signal = testClass.createSignal('initial');

        signal.value = 'updated';

        expect(signal.value, equals('updated'));
      });

      test('created signal is tracked for disposal', () {
        final signal = testClass.createSignal(0);

        expect(signal.disposed, isFalse);

        testClass.disposeSignals();

        expect(signal.disposed, isTrue);
      });

      test('multiple signals are all tracked', () {
        final signal1 = testClass.createSignal(1);
        final signal2 = testClass.createSignal(2);
        final signal3 = testClass.createSignal(3);

        expect(signal1.disposed, isFalse);
        expect(signal2.disposed, isFalse);
        expect(signal3.disposed, isFalse);

        testClass.disposeSignals();

        expect(signal1.disposed, isTrue);
        expect(signal2.disposed, isTrue);
        expect(signal3.disposed, isTrue);
      });
    });

    group('createComputed', () {
      test('creates a computed signal from function', () {
        final source = testClass.createSignal(5);
        final computed = testClass.createComputed(() => source.value * 2);

        expect(computed.value, equals(10));
      });

      test('computed updates when source changes', () {
        final source = testClass.createSignal(5);
        final computed = testClass.createComputed(() => source.value * 2);

        source.value = 10;

        expect(computed.value, equals(20));
      });

      test('computed is tracked for disposal', () {
        final source = testClass.createSignal(1);
        final computed = testClass.createComputed(() => source.value);

        expect(computed.disposed, isFalse);

        testClass.disposeSignals();

        expect(computed.disposed, isTrue);
      });
    });

    group('createFromStore', () {
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

      test('creates a signal from store with empty initial value', () {
        final signal = testClass.createFromStore(mockStore);

        expect(signal.value, isEmpty);
      });

      test('signal updates when store emits data', () async {
        final signal = testClass.createFromStore(mockStore);

        controller.add(testUsers);
        await Future<void>.delayed(Duration.zero);

        expect(signal.value, equals(testUsers));
      });

      test('signal is tracked for disposal', () {
        final signal = testClass.createFromStore(mockStore);

        expect(signal.disposed, isFalse);

        testClass.disposeSignals();

        expect(signal.disposed, isTrue);
      });

      test('passes query parameter to watchAll', () {
        const query = Query<TestUser>();

        testClass.createFromStore(mockStore, query: query);

        verify(() => mockStore.watchAll(query: query)).called(1);
      });

      test('subscription is cancelled on disposal', () async {
        testClass.createFromStore(mockStore);

        // Verify stream is listening
        expect(controller.hasListener, isTrue);

        testClass.disposeSignals();

        // Give time for cancellation
        await Future<void>.delayed(Duration.zero);

        expect(controller.hasListener, isFalse);
      });
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

      test('creates a signal with null initial value', () {
        final signal = testClass.createItemFromStore(mockStore, '1');

        expect(signal.value, isNull);
      });

      test('signal updates when store emits item', () async {
        final signal = testClass.createItemFromStore(mockStore, '1');

        controller.add(testUser1);
        await Future<void>.delayed(Duration.zero);

        expect(signal.value, equals(testUser1));
      });

      test('signal handles null emission (item not found)', () async {
        final signal = testClass.createItemFromStore(mockStore, 'nonexistent');

        controller.add(null);
        await Future<void>.delayed(Duration.zero);

        expect(signal.value, isNull);
      });

      test('signal is tracked for disposal', () {
        final signal = testClass.createItemFromStore(mockStore, '1');

        expect(signal.disposed, isFalse);

        testClass.disposeSignals();

        expect(signal.disposed, isTrue);
      });

      test('passes correct id to watch', () {
        testClass.createItemFromStore(mockStore, 'user-123');

        verify(() => mockStore.watch('user-123')).called(1);
      });

      test('subscription is cancelled on disposal', () async {
        testClass.createItemFromStore(mockStore, '1');

        expect(controller.hasListener, isTrue);

        testClass.disposeSignals();

        await Future<void>.delayed(Duration.zero);

        expect(controller.hasListener, isFalse);
      });
    });

    group('disposeSignals', () {
      test('disposes all signals created through mixin', () {
        final signal1 = testClass.createSignal(1);
        final computed1 = testClass.createComputed(() => signal1.value * 2);

        expect(signal1.disposed, isFalse);
        expect(computed1.disposed, isFalse);

        testClass.disposeSignals();

        expect(signal1.disposed, isTrue);
        expect(computed1.disposed, isTrue);
      });

      test('can be called multiple times safely', () {
        testClass.createSignal(1);

        expect(() => testClass.disposeSignals(), returnsNormally);
        expect(() => testClass.disposeSignals(), returnsNormally);
      });

      test('disposes store signals and cancels subscriptions', () async {
        final mockStore = MockNexusStore<TestUser, String>();
        final listController = StreamController<List<TestUser>>.broadcast();
        final itemController = StreamController<TestUser?>.broadcast();

        when(() => mockStore.watchAll(query: any(named: 'query')))
            .thenAnswer((_) => listController.stream);
        when(() => mockStore.watch(any()))
            .thenAnswer((_) => itemController.stream);

        final listSignal = testClass.createFromStore(mockStore);
        final itemSignal = testClass.createItemFromStore(mockStore, '1');

        expect(listSignal.disposed, isFalse);
        expect(itemSignal.disposed, isFalse);

        testClass.disposeSignals();

        expect(listSignal.disposed, isTrue);
        expect(itemSignal.disposed, isTrue);

        await Future<void>.delayed(Duration.zero);

        expect(listController.hasListener, isFalse);
        expect(itemController.hasListener, isFalse);

        listController.close();
        itemController.close();
      });
    });

    group('mixed usage', () {
      test('handles combination of signals, computeds, and store signals',
          () async {
        final mockStore = MockNexusStore<TestUser, String>();
        final controller = StreamController<List<TestUser>>.broadcast();
        when(() => mockStore.watchAll(query: any(named: 'query')))
            .thenAnswer((_) => controller.stream);

        final counter = testClass.createSignal(0);
        final doubled = testClass.createComputed(() => counter.value * 2);
        final users = testClass.createFromStore(mockStore);

        expect(counter.value, equals(0));
        expect(doubled.value, equals(0));
        expect(users.value, isEmpty);

        counter.value = 5;
        controller.add(testUsers);
        await Future<void>.delayed(Duration.zero);

        expect(counter.value, equals(5));
        expect(doubled.value, equals(10));
        expect(users.value, equals(testUsers));

        testClass.disposeSignals();

        expect(counter.disposed, isTrue);
        expect(doubled.disposed, isTrue);
        expect(users.disposed, isTrue);

        controller.close();
      });
    });
  });
}
