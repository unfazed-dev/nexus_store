import 'dart:async';

import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

class TestStore with ReactiveStoreMixin {
  TestStore() {
    counter = createReactiveState(0);
    name = createReactiveState('initial');
  }
  late final ReactiveState<int> counter;
  late final ReactiveState<String> name;
}

void main() {
  group('ReactiveState', () {
    group('constructor', () {
      test('should initialize with given value', () {
        final state = ReactiveState<int>(42);
        expect(state.value, equals(42));
      });
    });

    group('value getter', () {
      test('should return current value', () {
        final state = ReactiveState<String>('test');
        expect(state.value, equals('test'));
      });
    });

    group('value setter', () {
      test('should update the value', () {
        final state = ReactiveState<int>(0);
        state.value = 10;
        expect(state.value, equals(10));
      });

      test('should emit new value to stream', () async {
        final state = ReactiveState<int>(0);
        final values = <int>[];

        state.stream.listen(values.add);
        await _pumpEventQueue();

        state.value = 1;
        state.value = 2;

        await _pumpEventQueue();
        expect(values, equals([0, 1, 2]));

        await state.dispose();
      });
    });

    group('stream', () {
      test('should emit initial value immediately (BehaviorSubject)', () async {
        final state = ReactiveState<int>(42);
        final completer = Completer<int>();

        unawaited(state.stream.first.then(completer.complete));

        final result = await completer.future.timeout(
          const Duration(seconds: 1),
        );
        expect(result, equals(42));

        await state.dispose();
      });

      test('should emit to multiple subscribers', () async {
        final state = ReactiveState<int>(0);
        final values1 = <int>[];
        final values2 = <int>[];

        state.stream.listen(values1.add);
        state.stream.listen(values2.add);
        await _pumpEventQueue();

        state.value = 1;
        await _pumpEventQueue();

        expect(values1, contains(0));
        expect(values1, contains(1));
        expect(values2, contains(0));
        expect(values2, contains(1));

        await state.dispose();
      });
    });

    group('update', () {
      test('should transform current value', () {
        final state = ReactiveState<int>(5);
        state.update((current) => current * 2);
        expect(state.value, equals(10));
      });

      test('should emit transformed value to stream', () async {
        final state = ReactiveState<int>(5);
        final values = <int>[];

        state.stream.listen(values.add);
        await _pumpEventQueue();

        state.update((current) => current + 1);
        await _pumpEventQueue();

        expect(values, equals([5, 6]));

        await state.dispose();
      });
    });

    group('dispose', () {
      test('should close the stream', () async {
        final state = ReactiveState<int>(0);
        expect(state.isClosed, isFalse);

        await state.dispose();

        expect(state.isClosed, isTrue);
      });
    });

    group('isClosed', () {
      test('should return false before dispose', () {
        final state = ReactiveState<int>(0);
        expect(state.isClosed, isFalse);
      });

      test('should return true after dispose', () async {
        final state = ReactiveState<int>(0);
        await state.dispose();
        expect(state.isClosed, isTrue);
      });
    });
  });

  group('ReactiveList', () {
    group('constructor', () {
      test('should initialize with empty list by default', () {
        final list = ReactiveList<String>();
        expect(list.value, isEmpty);
      });

      test('should initialize with provided items', () {
        final list = ReactiveList<int>([1, 2, 3]);
        expect(list.value, equals([1, 2, 3]));
      });
    });

    group('add', () {
      test('should add item to list', () {
        final list = ReactiveList<String>();
        list.add('item');
        expect(list.value, equals(['item']));
      });

      test('should emit updated list to stream', () async {
        final list = ReactiveList<String>();
        final values = <List<String>>[];

        list.stream.listen(values.add);
        await _pumpEventQueue();

        list.add('first');
        list.add('second');
        await _pumpEventQueue();

        expect(values, hasLength(3));
        expect(values[0], isEmpty);
        expect(values[1], equals(['first']));
        expect(values[2], equals(['first', 'second']));

        await list.dispose();
      });
    });

    group('remove', () {
      test('should remove item from list', () {
        final list = ReactiveList<String>(['a', 'b', 'c']);
        list.remove('b');
        expect(list.value, equals(['a', 'c']));
      });

      test('should do nothing if item not found', () {
        final list = ReactiveList<String>(['a', 'b']);
        list.remove('c');
        expect(list.value, equals(['a', 'b']));
      });
    });

    group('removeAt', () {
      test('should remove item at index', () {
        final list = ReactiveList<String>(['a', 'b', 'c']);
        list.removeAt(1);
        expect(list.value, equals(['a', 'c']));
      });
    });

    group('clear', () {
      test('should remove all items', () {
        final list = ReactiveList<String>(['a', 'b', 'c']);
        list.clear();
        expect(list.value, isEmpty);
      });

      test('should emit empty list to stream', () async {
        final list = ReactiveList<String>(['a', 'b']);
        final values = <List<String>>[];

        list.stream.listen(values.add);
        await _pumpEventQueue();

        list.clear();
        await _pumpEventQueue();

        expect(values.last, isEmpty);

        await list.dispose();
      });
    });

    group('length', () {
      test('should return number of items', () {
        final list = ReactiveList<int>([1, 2, 3]);
        expect(list.length, equals(3));
      });
    });

    group('isEmpty/isNotEmpty', () {
      test('should return isEmpty true for empty list', () {
        final list = ReactiveList<int>();
        expect(list.isEmpty, isTrue);
        expect(list.isNotEmpty, isFalse);
      });

      test('should return isNotEmpty true for non-empty list', () {
        final list = ReactiveList<int>([1]);
        expect(list.isEmpty, isFalse);
        expect(list.isNotEmpty, isTrue);
      });
    });

    group('operator []', () {
      test('should return item at index', () {
        final list = ReactiveList<String>(['a', 'b', 'c']);
        expect(list[0], equals('a'));
        expect(list[1], equals('b'));
        expect(list[2], equals('c'));
      });
    });
  });

  group('ReactiveMap', () {
    group('constructor', () {
      test('should initialize with empty map by default', () {
        final map = ReactiveMap<String, int>();
        expect(map.value, isEmpty);
      });

      test('should initialize with provided entries', () {
        final map = ReactiveMap<String, int>({'a': 1, 'b': 2});
        expect(map.value, equals({'a': 1, 'b': 2}));
      });
    });

    group('set', () {
      test('should add key-value pair', () {
        final map = ReactiveMap<String, int>();
        map.set('key', 42);
        expect(map.value, equals({'key': 42}));
      });

      test('should update existing key', () {
        final map = ReactiveMap<String, int>({'key': 1});
        map.set('key', 2);
        expect(map.value, equals({'key': 2}));
      });

      test('should emit updated map to stream', () async {
        final map = ReactiveMap<String, int>();
        final values = <Map<String, int>>[];

        map.stream.listen(values.add);
        await _pumpEventQueue();

        map.set('a', 1);
        map.set('b', 2);
        await _pumpEventQueue();

        expect(values, hasLength(3));
        expect(values[0], isEmpty);
        expect(values[1], equals({'a': 1}));
        expect(values[2], equals({'a': 1, 'b': 2}));

        await map.dispose();
      });
    });

    group('remove', () {
      test('should remove key', () {
        final map = ReactiveMap<String, int>({'a': 1, 'b': 2});
        map.remove('a');
        expect(map.value, equals({'b': 2}));
      });

      test('should do nothing if key not found', () {
        final map = ReactiveMap<String, int>({'a': 1});
        map.remove('b');
        expect(map.value, equals({'a': 1}));
      });
    });

    group('clear', () {
      test('should remove all entries', () {
        final map = ReactiveMap<String, int>({'a': 1, 'b': 2});
        map.clear();
        expect(map.value, isEmpty);
      });
    });

    group('operator []', () {
      test('should return value for key', () {
        final map = ReactiveMap<String, int>({'key': 42});
        expect(map['key'], equals(42));
      });

      test('should return null for missing key', () {
        final map = ReactiveMap<String, int>();
        expect(map['missing'], isNull);
      });
    });

    group('containsKey', () {
      test('should return true for existing key', () {
        final map = ReactiveMap<String, int>({'key': 1});
        expect(map.containsKey('key'), isTrue);
      });

      test('should return false for missing key', () {
        final map = ReactiveMap<String, int>();
        expect(map.containsKey('key'), isFalse);
      });
    });

    group('length', () {
      test('should return number of entries', () {
        final map = ReactiveMap<String, int>({'a': 1, 'b': 2, 'c': 3});
        expect(map.length, equals(3));
      });
    });

    group('isEmpty', () {
      test('should return true for empty map', () {
        final map = ReactiveMap<String, int>();
        expect(map.isEmpty, isTrue);
      });

      test('should return false for non-empty map', () {
        final map = ReactiveMap<String, int>({'a': 1});
        expect(map.isEmpty, isFalse);
      });
    });
  });

  group('ReactiveStoreMixin', () {
    group('createReactiveState', () {
      test('should create reactive state with initial value', () {
        final store = TestStore();
        expect(store.counter.value, equals(0));
        expect(store.name.value, equals('initial'));
      });
    });

    group('disposeReactiveStates', () {
      test('should dispose all created states', () async {
        final store = TestStore();

        expect(store.counter.isClosed, isFalse);
        expect(store.name.isClosed, isFalse);

        await store.disposeReactiveStates();

        expect(store.counter.isClosed, isTrue);
        expect(store.name.isClosed, isTrue);
      });
    });
  });
}

/// Pumps the event queue to allow async operations to complete.
/// More reliable than Duration.zero on slower CI runners.
Future<void> _pumpEventQueue() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
}
