import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_signals_binding/src/signals/nexus_signal.dart';

import 'fixtures/mock_store.dart';
import 'fixtures/test_entities.dart';

void main() {
  setUpAll(() {
    registerFallbackValues();
  });

  group('NexusSignal', () {
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

    test('wraps underlying signal value', () {
      final signal = NexusSignal<TestUser, String>.fromStore(mockStore);

      expect(signal.value, isEmpty);

      controller.add(testUsers);

      // Need to wait for stream to propagate
      expectLater(
        Future<void>.delayed(Duration.zero).then((_) => signal.value),
        completion(equals(testUsers)),
      );
    });

    test('peek() returns value without tracking', () async {
      final signal = NexusSignal<TestUser, String>.fromStore(mockStore);

      controller.add(testUsers);
      await Future<void>.delayed(Duration.zero);

      expect(signal.peek(), equals(testUsers));
    });

    test('refresh() calls store sync', () async {
      when(() => mockStore.sync()).thenAnswer((_) async {});

      final signal = NexusSignal<TestUser, String>.fromStore(mockStore);

      await signal.refresh();

      verify(() => mockStore.sync()).called(1);
    });

    test('dispose() cleans up resources', () {
      final signal = NexusSignal<TestUser, String>.fromStore(mockStore);

      expect(signal.disposed, isFalse);

      signal.dispose();

      expect(signal.disposed, isTrue);
    });

    test('subscribe() notifies on changes', () async {
      final signal = NexusSignal<TestUser, String>.fromStore(mockStore);
      final values = <List<TestUser>>[];

      signal.subscribe((value) => values.add(value));

      controller.add([testUser1]);
      await Future<void>.delayed(Duration.zero);

      controller.add([testUser1, testUser2]);
      await Future<void>.delayed(Duration.zero);

      // Values include initial empty list + 2 emissions
      expect(values, hasLength(3));
      expect(values[0], isEmpty); // Initial empty list
      expect(values[1], equals([testUser1]));
      expect(values[2], equals([testUser1, testUser2]));
    });

    test('subscribe() returns unsubscribe function', () async {
      final signal = NexusSignal<TestUser, String>.fromStore(mockStore);
      final values = <List<TestUser>>[];

      final unsubscribe = signal.subscribe((value) => values.add(value));

      controller.add([testUser1]);
      await Future<void>.delayed(Duration.zero);

      // Unsubscribe
      unsubscribe();

      controller.add([testUser1, testUser2]);
      await Future<void>.delayed(Duration.zero);

      // Only 2 values (initial + first emission), not the one after unsubscribe
      expect(values, hasLength(2));
    });

    test('onDispose() callback is invoked on disposal', () {
      final signal = NexusSignal<TestUser, String>.fromStore(mockStore);
      var disposed = false;

      signal.onDispose(() => disposed = true);

      expect(disposed, isFalse);

      signal.dispose();

      expect(disposed, isTrue);
    });

    test('value setter updates signal', () async {
      final signal = NexusSignal<TestUser, String>.fromStore(mockStore);

      expect(signal.value, isEmpty);

      signal.value = testUsers;

      expect(signal.value, equals(testUsers));
    });

    test('handles stream errors silently', () async {
      final signal = NexusSignal<TestUser, String>.fromStore(mockStore);

      // Emit an error - should be silently ignored
      controller.addError(Exception('test error'));
      await Future<void>.delayed(Duration.zero);

      // Signal should still have empty list (no crash)
      expect(signal.value, isEmpty);
    });

    test('store getter returns the underlying store', () {
      final signal = NexusSignal<TestUser, String>.fromStore(mockStore);

      expect(signal.store, equals(mockStore));
    });
  });
}
