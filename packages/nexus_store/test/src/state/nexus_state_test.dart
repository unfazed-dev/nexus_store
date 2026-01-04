import 'dart:async';

import 'package:async/async.dart';
import 'package:nexus_store/src/state/nexus_state.dart';
import 'package:test/test.dart';

void main() {
  group('NexusState', () {
    group('constructor', () {
      test('should initialize with given value', () {
        final state = NexusState<int>(42);
        expect(state.value, equals(42));
      });

      test('should work with nullable types', () {
        final state = NexusState<String?>(null);
        expect(state.value, isNull);
      });

      test('should work with complex types', () {
        final state = NexusState<Map<String, int>>({'a': 1, 'b': 2});
        expect(state.value, equals({'a': 1, 'b': 2}));
      });
    });

    group('value getter', () {
      test('should return current value', () {
        final state = NexusState<String>('test');
        expect(state.value, equals('test'));
      });

      test('should return updated value after setter', () {
        final state = NexusState<int>(0);
        state.value = 10;
        expect(state.value, equals(10));
      });
    });

    group('value setter', () {
      test('should update the value', () {
        final state = NexusState<int>(0);
        state.value = 10;
        expect(state.value, equals(10));
      });

      test('should emit new value to stream', () async {
        final state = NexusState<int>(0);

        await expectLater(
          state.stream,
          emitsInOrder([0, 1, 2]),
        ).timeout(const Duration(seconds: 1), onTimeout: () {
          state.value = 1;
          state.value = 2;
        });

        await state.dispose();
      });

      test('should emit values via StreamQueue', () async {
        final state = NexusState<int>(0);
        final queue = StreamQueue(state.stream);

        expect(await queue.next, equals(0)); // Initial value
        state.value = 1;
        expect(await queue.next, equals(1));
        state.value = 2;
        expect(await queue.next, equals(2));

        await queue.cancel();
        await state.dispose();
      });
    });

    group('stream', () {
      test('should emit initial value immediately (BehaviorSubject)', () async {
        final state = NexusState<int>(42);

        await expectLater(
          state.stream.first,
          completion(equals(42)),
        );

        await state.dispose();
      });

      test('should emit to multiple subscribers', () async {
        final state = NexusState<int>(0);
        final queue1 = StreamQueue(state.stream);
        final queue2 = StreamQueue(state.stream);

        // Both get initial value
        expect(await queue1.next, equals(0));
        expect(await queue2.next, equals(0));

        state.value = 1;

        // Both get updated value
        expect(await queue1.next, equals(1));
        expect(await queue2.next, equals(1));

        await queue1.cancel();
        await queue2.cancel();
        await state.dispose();
      });
    });

    group('update', () {
      test('should transform current value', () {
        final state = NexusState<int>(5);
        state.update((current) => current * 2);
        expect(state.value, equals(10));
      });

      test('should emit transformed value to stream', () async {
        final state = NexusState<int>(5);
        final queue = StreamQueue(state.stream);

        expect(await queue.next, equals(5)); // Initial
        state.update((current) => current + 1);
        expect(await queue.next, equals(6));

        await queue.cancel();
        await state.dispose();
      });

      test('should support chained updates', () {
        final state = NexusState<int>(1);
        state.update((v) => v + 1);
        state.update((v) => v * 2);
        state.update((v) => v - 1);
        expect(state.value, equals(3)); // (1+1)*2-1 = 3
      });
    });

    group('reset', () {
      test('should revert to initial value', () {
        final state = NexusState<int>(42);
        state.value = 100;
        expect(state.value, equals(100));

        state.reset();
        expect(state.value, equals(42));
      });

      test('should emit initial value to stream after reset', () async {
        final state = NexusState<String>('initial');
        final queue = StreamQueue(state.stream);

        expect(await queue.next, equals('initial'));
        state.value = 'changed';
        expect(await queue.next, equals('changed'));
        state.reset();
        expect(await queue.next, equals('initial'));

        await queue.cancel();
        await state.dispose();
      });

      test('should work after multiple updates', () {
        final state = NexusState<int>(0);
        state.value = 1;
        state.value = 2;
        state.value = 3;
        state.reset();
        expect(state.value, equals(0));
      });

      test('should allow updates after reset', () {
        final state = NexusState<int>(0);
        state.value = 100;
        state.reset();
        state.value = 50;
        expect(state.value, equals(50));
      });
    });

    group('emit', () {
      test('should be alias for value setter', () {
        final state = NexusState<int>(0);
        state.emit(42);
        expect(state.value, equals(42));
      });

      test('should emit value to stream', () async {
        final state = NexusState<int>(0);
        final queue = StreamQueue(state.stream);

        expect(await queue.next, equals(0));
        state.emit(1);
        expect(await queue.next, equals(1));
        state.emit(2);
        expect(await queue.next, equals(2));

        await queue.cancel();
        await state.dispose();
      });
    });

    group('dispose', () {
      test('should close the stream', () async {
        final state = NexusState<int>(0);
        expect(state.isClosed, isFalse);

        await state.dispose();

        expect(state.isClosed, isTrue);
      });

      test('should complete stream subscriptions', () async {
        final state = NexusState<int>(0);
        final completer = Completer<void>();

        state.stream.listen(
          null,
          onDone: completer.complete,
        );

        await state.dispose();

        await expectLater(
          completer.future.timeout(const Duration(seconds: 1)),
          completes,
        );
      });
    });

    group('isClosed', () {
      test('should return false before dispose', () {
        final state = NexusState<int>(0);
        expect(state.isClosed, isFalse);
      });

      test('should return true after dispose', () async {
        final state = NexusState<int>(0);
        await state.dispose();
        expect(state.isClosed, isTrue);
      });
    });

    group('initialValue', () {
      test('should expose initial value', () {
        final state = NexusState<int>(42);
        expect(state.initialValue, equals(42));
      });

      test('should not change after updates', () {
        final state = NexusState<int>(42);
        state.value = 100;
        expect(state.initialValue, equals(42));
      });
    });

    group('edge cases', () {
      test('should handle rapid updates', () async {
        final state = NexusState<int>(0);
        final values = <int>[];

        final subscription = state.stream.listen(values.add);

        // Perform rapid updates
        for (var i = 1; i <= 100; i++) {
          state.value = i;
        }

        // Wait for all microtasks to complete
        await Future<void>.delayed(Duration.zero);

        expect(values.length, equals(101)); // Initial + 100 updates
        expect(values.first, equals(0));
        expect(values.last, equals(100));

        await subscription.cancel();
        await state.dispose();
      });

      test('should handle same value updates', () async {
        final state = NexusState<int>(0);
        final queue = StreamQueue(state.stream);

        expect(await queue.next, equals(0)); // Initial
        state.value = 0;
        expect(await queue.next, equals(0)); // Duplicate
        state.value = 0;
        expect(await queue.next, equals(0)); // Another duplicate

        // BehaviorSubject emits all values, even duplicates
        await queue.cancel();
        await state.dispose();
      });

      test('should work with list values', () {
        final state = NexusState<List<int>>([1, 2, 3]);
        state.update((list) => [...list, 4]);
        expect(state.value, equals([1, 2, 3, 4]));
      });
    });
  });
}
