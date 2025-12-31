import 'dart:convert';

import 'package:nexus_store/src/state/nexus_state.dart';
import 'package:nexus_store/src/state/persisted_state.dart';
import 'package:test/test.dart';

import '../../fixtures/fake_state_storage.dart';

void main() {
  group('PersistedState', () {
    late FakeStateStorage storage;

    setUp(() {
      storage = FakeStateStorage();
    });

    group('create', () {
      test('should create with initial value when storage is empty', () async {
        final state = await PersistedState.create<int>(
          key: 'counter',
          initialValue: 0,
          storage: storage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        expect(state.value, equals(0));
        expect(state.initialValue, equals(0));

        await state.dispose();
      });

      test('should restore value from storage on creation', () async {
        // Pre-populate storage
        storage.seed({'counter': '42'});

        final state = await PersistedState.create<int>(
          key: 'counter',
          initialValue: 0,
          storage: storage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        expect(state.value, equals(42));
        expect(state.initialValue, equals(0)); // Initial is still 0

        await state.dispose();
      });

      test('should use initial value when deserialization fails', () async {
        // Pre-populate with invalid data
        storage.seed({'counter': 'not-a-number'});

        final state = await PersistedState.create<int>(
          key: 'counter',
          initialValue: 0,
          storage: storage,
          serialize: (v) => v.toString(),
          deserialize: (s) {
            final parsed = int.tryParse(s);
            if (parsed == null) throw FormatException('Invalid number');
            return parsed;
          },
        );

        // Should fall back to initial value
        expect(state.value, equals(0));

        await state.dispose();
      });
    });

    group('value', () {
      test('should return current value', () async {
        final state = await PersistedState.create<String>(
          key: 'name',
          initialValue: 'Alice',
          storage: storage,
          serialize: (v) => v,
          deserialize: (s) => s,
        );

        expect(state.value, equals('Alice'));

        await state.dispose();
      });

      test('should update value via setter', () async {
        final state = await PersistedState.create<int>(
          key: 'counter',
          initialValue: 0,
          storage: storage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        state.value = 5;

        expect(state.value, equals(5));

        await state.dispose();
      });
    });

    group('auto-save', () {
      test('should save to storage on value change', () async {
        final state = await PersistedState.create<int>(
          key: 'counter',
          initialValue: 0,
          storage: storage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        state.value = 10;

        // Give time for async save
        await Future<void>.delayed(Duration.zero);

        expect(storage.data['counter'], equals('10'));

        await state.dispose();
      });

      test('should save to storage on emit()', () async {
        final state = await PersistedState.create<int>(
          key: 'counter',
          initialValue: 0,
          storage: storage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        state.emit(15);

        await Future<void>.delayed(Duration.zero);

        expect(storage.data['counter'], equals('15'));

        await state.dispose();
      });

      test('should save to storage on update()', () async {
        final state = await PersistedState.create<int>(
          key: 'counter',
          initialValue: 5,
          storage: storage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        state.update((current) => current + 10);

        await Future<void>.delayed(Duration.zero);

        expect(state.value, equals(15));
        expect(storage.data['counter'], equals('15'));

        await state.dispose();
      });

      test('should save initial value on reset()', () async {
        storage.seed({'counter': '100'});

        final state = await PersistedState.create<int>(
          key: 'counter',
          initialValue: 0,
          storage: storage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        expect(state.value, equals(100));

        state.reset();

        await Future<void>.delayed(Duration.zero);

        expect(state.value, equals(0));
        expect(storage.data['counter'], equals('0'));

        await state.dispose();
      });

      test('should not save restored value on creation', () async {
        storage.seed({'counter': '42'});

        final state = await PersistedState.create<int>(
          key: 'counter',
          initialValue: 0,
          storage: storage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        // No additional save should occur for restored value
        expect(storage.data['counter'], equals('42'));

        await state.dispose();
      });
    });

    group('error handling', () {
      test('should fall back to initial value on storage read error', () async {
        final failingStorage = FailingStateStorage();
        failingStorage.shouldFailRead = true;

        final state = await PersistedState.create<int>(
          key: 'counter',
          initialValue: 99,
          storage: failingStorage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        expect(state.value, equals(99));

        await state.dispose();
      });

      test('should continue working when storage write fails', () async {
        final failingStorage = FailingStateStorage();

        final state = await PersistedState.create<int>(
          key: 'counter',
          initialValue: 0,
          storage: failingStorage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        failingStorage.shouldFailWrite = true;

        // Value should still update in memory
        state.value = 50;
        expect(state.value, equals(50));

        // But storage should not have the value (write failed)
        await Future<void>.delayed(Duration.zero);
        expect(failingStorage.data['counter'], isNull);

        await state.dispose();
      });
    });

    group('stream', () {
      test('should emit current value immediately on subscribe', () async {
        final state = await PersistedState.create<int>(
          key: 'counter',
          initialValue: 7,
          storage: storage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        final values = <int>[];
        final subscription = state.stream.listen(values.add);

        await Future<void>.delayed(Duration.zero);

        expect(values, contains(7));

        await subscription.cancel();
        await state.dispose();
      });

      test('should emit on value change', () async {
        final state = await PersistedState.create<int>(
          key: 'counter',
          initialValue: 0,
          storage: storage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        final values = <int>[];
        final subscription = state.stream.listen(values.add);

        await Future<void>.delayed(Duration.zero);

        state.value = 1;
        state.value = 2;
        state.value = 3;

        await Future<void>.delayed(Duration.zero);

        expect(values, equals([0, 1, 2, 3]));

        await subscription.cancel();
        await state.dispose();
      });

      test('should support multiple subscribers', () async {
        final state = await PersistedState.create<int>(
          key: 'counter',
          initialValue: 0,
          storage: storage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        final values1 = <int>[];
        final values2 = <int>[];

        final sub1 = state.stream.listen(values1.add);
        final sub2 = state.stream.listen(values2.add);

        await Future<void>.delayed(Duration.zero);

        state.value = 10;

        await Future<void>.delayed(Duration.zero);

        expect(values1, contains(10));
        expect(values2, contains(10));

        await sub1.cancel();
        await sub2.cancel();
        await state.dispose();
      });
    });

    group('dispose', () {
      test('should close the stream', () async {
        final state = await PersistedState.create<int>(
          key: 'counter',
          initialValue: 0,
          storage: storage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        expect(state.isClosed, isFalse);

        await state.dispose();

        expect(state.isClosed, isTrue);
      });

      test('should cancel save subscription', () async {
        final state = await PersistedState.create<int>(
          key: 'counter',
          initialValue: 0,
          storage: storage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        await state.dispose();

        // Setting value after dispose should not save (and should not throw)
        // The BehaviorSubject is closed, so this would throw
        expect(() => state.value = 100, throwsStateError);
      });
    });

    group('isClosed', () {
      test('should return false before dispose', () async {
        final state = await PersistedState.create<int>(
          key: 'counter',
          initialValue: 0,
          storage: storage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        expect(state.isClosed, isFalse);

        await state.dispose();
      });

      test('should return true after dispose', () async {
        final state = await PersistedState.create<int>(
          key: 'counter',
          initialValue: 0,
          storage: storage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        await state.dispose();

        expect(state.isClosed, isTrue);
      });
    });

    group('complex types', () {
      test('should work with List types', () async {
        final state = await PersistedState.create<List<String>>(
          key: 'tags',
          initialValue: <String>[],
          storage: storage,
          serialize: (v) => jsonEncode(v),
          deserialize: (s) => (jsonDecode(s) as List).cast<String>(),
        );

        state.value = ['flutter', 'dart'];

        await Future<void>.delayed(Duration.zero);

        expect(storage.data['tags'], equals('["flutter","dart"]'));

        await state.dispose();
      });

      test('should work with Map types', () async {
        final state = await PersistedState.create<Map<String, int>>(
          key: 'scores',
          initialValue: <String, int>{},
          storage: storage,
          serialize: (v) => jsonEncode(v),
          deserialize: (s) => (jsonDecode(s) as Map).cast<String, int>(),
        );

        state.value = {'alice': 100, 'bob': 85};

        await Future<void>.delayed(Duration.zero);

        expect(storage.data['scores'], equals('{"alice":100,"bob":85}'));

        await state.dispose();
      });

      test('should restore complex types from storage', () async {
        storage.seed({'user': '{"name":"Alice","age":30}'});

        final state = await PersistedState.create<Map<String, dynamic>>(
          key: 'user',
          initialValue: <String, dynamic>{},
          storage: storage,
          serialize: (v) => jsonEncode(v),
          deserialize: (s) => jsonDecode(s) as Map<String, dynamic>,
        );

        expect(state.value, equals({'name': 'Alice', 'age': 30}));

        await state.dispose();
      });
    });

    group('key uniqueness', () {
      test('should use unique keys for different states', () async {
        final state1 = await PersistedState.create<int>(
          key: 'counter1',
          initialValue: 1,
          storage: storage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        final state2 = await PersistedState.create<int>(
          key: 'counter2',
          initialValue: 2,
          storage: storage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        state1.value = 10;
        state2.value = 20;

        await Future<void>.delayed(Duration.zero);

        expect(storage.data['counter1'], equals('10'));
        expect(storage.data['counter2'], equals('20'));

        await state1.dispose();
        await state2.dispose();
      });
    });

    group('initialValue getter', () {
      test('should return the initial value', () async {
        final state = await PersistedState.create<int>(
          key: 'counter',
          initialValue: 42,
          storage: storage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        expect(state.initialValue, equals(42));

        state.value = 100;
        expect(state.initialValue, equals(42)); // Unchanged

        await state.dispose();
      });

      test('should return initial value even when restored from storage',
          () async {
        storage.seed({'counter': '999'});

        final state = await PersistedState.create<int>(
          key: 'counter',
          initialValue: 0,
          storage: storage,
          serialize: (v) => v.toString(),
          deserialize: (s) => int.parse(s),
        );

        expect(state.value, equals(999)); // Restored
        expect(state.initialValue, equals(0)); // Initial is still 0

        await state.dispose();
      });
    });
  });

  group('NexusState.persisted', () {
    late FakeStateStorage storage;

    setUp(() {
      storage = FakeStateStorage();
    });

    test('should create a PersistedState via static factory', () async {
      final state = await NexusState.persisted<int>(
        key: 'counter',
        initial: 0,
        storage: storage,
        serialize: (v) => v.toString(),
        deserialize: (s) => int.parse(s),
      );

      expect(state, isA<PersistedState<int>>());
      expect(state.value, equals(0));

      state.value = 10;
      await Future<void>.delayed(Duration.zero);
      expect(storage.data['counter'], equals('10'));

      await state.dispose();
    });

    test('should restore from storage via static factory', () async {
      storage.seed({'name': 'Bob'});

      final state = await NexusState.persisted<String>(
        key: 'name',
        initial: 'Alice',
        storage: storage,
        serialize: (v) => v,
        deserialize: (s) => s,
      );

      expect(state.value, equals('Bob'));
      expect(state.initialValue, equals('Alice'));

      await state.dispose();
    });
  });
}
