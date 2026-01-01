import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_signals_binding/src/signals/nexus_list_signal.dart';

import 'fixtures/mock_store.dart';
import 'fixtures/test_entities.dart';

void main() {
  setUpAll(() {
    registerFallbackValues();
  });

  group('NexusListSignal', () {
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

    test('provides list value from store', () async {
      final signal = NexusListSignal<TestUser, String>.fromStore(mockStore);

      expect(signal.value, isEmpty);

      controller.add(testUsers);
      await Future<void>.delayed(Duration.zero);

      expect(signal.value, equals(testUsers));
    });

    test('add() delegates to store.save()', () async {
      when(() => mockStore.save(any())).thenAnswer((_) async => testUser1);

      final signal = NexusListSignal<TestUser, String>.fromStore(mockStore);

      await signal.add(testUser1);

      verify(() => mockStore.save(testUser1)).called(1);
    });

    test('remove() delegates to store.delete()', () async {
      when(() => mockStore.delete(any())).thenAnswer((_) async => true);

      final signal = NexusListSignal<TestUser, String>.fromStore(mockStore);

      await signal.remove('1');

      verify(() => mockStore.delete('1')).called(1);
    });

    test('update() gets item, transforms, and saves', () async {
      final updatedUser = testUser1.copyWith(name: 'Updated');
      when(() => mockStore.get(any())).thenAnswer((_) async => testUser1);
      when(() => mockStore.save(any())).thenAnswer((_) async => updatedUser);

      final signal = NexusListSignal<TestUser, String>.fromStore(mockStore);

      await signal.update('1', (user) => user.copyWith(name: 'Updated'));

      verify(() => mockStore.get('1')).called(1);
      final captured = verify(() => mockStore.save(captureAny())).captured;
      expect(captured.length, equals(1));
      expect((captured.first as TestUser).name, equals('Updated'));
    });

    test('update() does nothing if item not found', () async {
      when(() => mockStore.get(any())).thenAnswer((_) async => null);

      final signal = NexusListSignal<TestUser, String>.fromStore(mockStore);

      await signal.update(
          'nonexistent', (user) => user.copyWith(name: 'Updated'));

      verify(() => mockStore.get('nonexistent')).called(1);
      verifyNever(() => mockStore.save(any()));
    });

    test('length returns list length', () async {
      final signal = NexusListSignal<TestUser, String>.fromStore(mockStore);

      expect(signal.length, equals(0));

      controller.add(testUsers);
      await Future<void>.delayed(Duration.zero);

      expect(signal.length, equals(3));
    });

    test('isEmpty and isNotEmpty work correctly', () async {
      final signal = NexusListSignal<TestUser, String>.fromStore(mockStore);

      expect(signal.isEmpty, isTrue);
      expect(signal.isNotEmpty, isFalse);

      controller.add(testUsers);
      await Future<void>.delayed(Duration.zero);

      expect(signal.isEmpty, isFalse);
      expect(signal.isNotEmpty, isTrue);
    });

    test('operator[] returns item at index', () async {
      final signal = NexusListSignal<TestUser, String>.fromStore(mockStore);

      controller.add(testUsers);
      await Future<void>.delayed(Duration.zero);

      expect(signal[0], equals(testUser1));
      expect(signal[1], equals(testUser2));
      expect(signal[2], equals(testUser3));
    });

    test('dispose() cleans up resources', () {
      final signal = NexusListSignal<TestUser, String>.fromStore(mockStore);

      expect(signal.disposed, isFalse);

      signal.dispose();

      expect(signal.disposed, isTrue);
    });

    test('subscribe() notifies on changes', () async {
      final signal = NexusListSignal<TestUser, String>.fromStore(mockStore);
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
      final signal = NexusListSignal<TestUser, String>.fromStore(mockStore);
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
      final signal = NexusListSignal<TestUser, String>.fromStore(mockStore);
      var disposed = false;

      signal.onDispose(() => disposed = true);

      expect(disposed, isFalse);

      signal.dispose();

      expect(disposed, isTrue);
    });

    test('handles stream errors silently', () async {
      final signal = NexusListSignal<TestUser, String>.fromStore(mockStore);

      // Emit an error - should be silently ignored
      controller.addError(Exception('test error'));
      await Future<void>.delayed(Duration.zero);

      // Signal should still have empty list (no crash)
      expect(signal.value, isEmpty);
    });
  });
}
