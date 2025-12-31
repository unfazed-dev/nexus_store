import 'dart:async';

import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('Selector', () {
    late FakeStoreBackend<TestUser, String> backend;
    late NexusStore<TestUser, String> store;

    setUp(() async {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
      store = NexusStore<TestUser, String>(
        backend: backend,
        idExtractor: (user) => user.id,
      );
      await store.initialize();
    });

    tearDown(() async {
      await store.dispose();
    });

    group('constructor', () {
      test('should create selector with source stream', () async {
        await store.save(TestFixtures.createUser(id: 'u1'));
        await store.save(TestFixtures.createUser(id: 'u2'));

        final selector = Selector<TestUser, int>(
          store.watchAll(),
          (users) => users.length,
        );

        await Future<void>.delayed(Duration.zero);

        expect(selector.value, equals(2));

        await selector.dispose();
      });

      test('should apply select function correctly', () async {
        await store
            .save(TestFixtures.createUser(id: 'u1', name: 'Alice', age: 25));
        await store
            .save(TestFixtures.createUser(id: 'u2', name: 'Bob', age: 30));

        final selector = Selector<TestUser, List<String>>(
          store.watchAll(),
          (users) => users.map((u) => u.name).toList(),
        );

        await Future<void>.delayed(Duration.zero);

        expect(selector.value, containsAll(['Alice', 'Bob']));

        await selector.dispose();
      });
    });

    group('stream', () {
      test('should emit transformed values', () async {
        final selector = Selector<TestUser, int>(
          store.watchAll(),
          (users) => users.length,
        );

        final values = <int>[];
        final subscription = selector.stream.listen(values.add);

        await Future<void>.delayed(Duration.zero);

        // Initial value
        expect(values.last, equals(0));

        // Add user
        await store.save(TestFixtures.createUser(id: 'u1'));
        await Future<void>.delayed(Duration.zero);
        expect(values.last, equals(1));

        // Add another user
        await store.save(TestFixtures.createUser(id: 'u2'));
        await Future<void>.delayed(Duration.zero);
        expect(values.last, equals(2));

        await subscription.cancel();
        await selector.dispose();
      });

      test('should emit immediately on subscribe', () async {
        await store.save(TestFixtures.createUser(id: 'u1'));

        final selector = Selector<TestUser, int>(
          store.watchAll(),
          (users) => users.length,
        );

        await Future<void>.delayed(Duration.zero);

        final completer = Completer<int>();
        unawaited(selector.stream.first.then(completer.complete));

        final result = await completer.future.timeout(
          const Duration(seconds: 1),
        );

        expect(result, equals(1));

        await selector.dispose();
      });
    });

    group('custom equality', () {
      test('should use custom equality function', () async {
        final selector = Selector<TestUser, List<String>>(
          store.watchAll(),
          (users) => users.map((u) => u.name).toList(),
          equals: (a, b) => a.length == b.length,
        );

        final values = <List<String>>[];
        final subscription = selector.stream.listen(values.add);

        await Future<void>.delayed(Duration.zero);

        // Initial value (empty list)
        expect(values.length, equals(1));

        // Add user - length changes from 0 to 1, should emit
        await store.save(TestFixtures.createUser(id: 'u1', name: 'Alice'));
        await Future<void>.delayed(Duration.zero);
        expect(values.length, equals(2));

        // Update user name - length stays 1, custom equality says equal
        await store.save(TestFixtures.createUser(id: 'u1', name: 'Alicia'));
        await Future<void>.delayed(Duration.zero);
        // Should NOT emit because list length is the same
        expect(values.length, equals(2));

        await subscription.cancel();
        await selector.dispose();
      });

      test('should default to standard equality when equals is null', () async {
        final selector = Selector<TestUser, int>(
          store.watchAll(),
          (users) => users.length,
        );

        final values = <int>[];
        final subscription = selector.stream.listen(values.add);

        await Future<void>.delayed(Duration.zero);

        // Save user
        await store.save(TestFixtures.createUser(id: 'u1'));
        await Future<void>.delayed(Duration.zero);

        // Save same user again - count is still 1
        await store.save(TestFixtures.createUser(id: 'u1', name: 'Updated'));
        await Future<void>.delayed(Duration.zero);

        // Should not emit duplicate 1s
        expect(values.where((v) => v == 1).length, equals(1));

        await subscription.cancel();
        await selector.dispose();
      });
    });

    group('value getter', () {
      test('should return current selected value', () async {
        await store.save(TestFixtures.createUser(id: 'u1', name: 'Alice'));

        final selector = Selector<TestUser, String?>(
          store.watchAll(),
          (users) => users.isEmpty ? null : users.first.name,
        );

        await Future<void>.delayed(Duration.zero);

        expect(selector.value, equals('Alice'));

        await selector.dispose();
      });
    });

    group('dispose', () {
      test('should close the stream', () async {
        final selector = Selector<TestUser, int>(
          store.watchAll(),
          (users) => users.length,
        );

        await Future<void>.delayed(Duration.zero);

        expect(selector.isClosed, isFalse);

        await selector.dispose();

        expect(selector.isClosed, isTrue);
      });
    });
  });

  group('NexusStore selector extensions', () {
    late FakeStoreBackend<TestUser, String> backend;
    late NexusStore<TestUser, String> store;

    setUp(() async {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
      store = NexusStore<TestUser, String>(
        backend: backend,
        idExtractor: (user) => user.id,
      );
      await store.initialize();
    });

    tearDown(() async {
      await store.dispose();
    });

    group('select', () {
      test('should transform store data', () async {
        await store.save(TestFixtures.createUser(id: 'u1', age: 25));
        await store.save(TestFixtures.createUser(id: 'u2', age: 30));

        final stream = store.select((users) => users.length);

        final values = <int>[];
        final subscription = stream.listen(values.add);

        await Future<void>.delayed(Duration.zero);

        expect(values.last, equals(2));

        await store.save(TestFixtures.createUser(id: 'u3', age: 35));
        await Future<void>.delayed(Duration.zero);

        expect(values.last, equals(3));

        await subscription.cancel();
      });

      test('should use custom equality', () async {
        final stream = store.select(
          (users) => users.map((u) => u.name).toList(),
          equals: (a, b) => a.length == b.length,
        );

        final values = <List<String>>[];
        final subscription = stream.listen(values.add);

        await Future<void>.delayed(Duration.zero);

        // Add user
        await store.save(TestFixtures.createUser(id: 'u1', name: 'Alice'));
        await Future<void>.delayed(Duration.zero);

        // Update user name (same count)
        await store.save(TestFixtures.createUser(id: 'u1', name: 'Alicia'));
        await Future<void>.delayed(Duration.zero);

        // Should have 2 emissions: empty list, then list with 1 item
        // (update doesn't trigger because length is same)
        expect(values.length, equals(2));

        await subscription.cancel();
      });
    });

    group('selectById', () {
      test('should return stream of single item', () async {
        await store.save(TestFixtures.createUser(id: 'u1', name: 'Alice'));
        await store.save(TestFixtures.createUser(id: 'u2', name: 'Bob'));

        final stream = store.selectById('u1');

        final values = <TestUser?>[];
        final subscription = stream.listen(values.add);

        await Future<void>.delayed(Duration.zero);

        expect(values.last?.name, equals('Alice'));

        // Update the user
        await store.save(TestFixtures.createUser(id: 'u1', name: 'Alicia'));
        await Future<void>.delayed(Duration.zero);

        expect(values.last?.name, equals('Alicia'));

        await subscription.cancel();
      });

      test('should return null for non-existent id', () async {
        await store.save(TestFixtures.createUser(id: 'u1', name: 'Alice'));

        final stream = store.selectById('u999');

        final values = <TestUser?>[];
        final subscription = stream.listen(values.add);

        await Future<void>.delayed(Duration.zero);

        expect(values.last, isNull);

        await subscription.cancel();
      });
    });

    group('selectWhere', () {
      test('should filter list by predicate', () async {
        await store.save(TestFixtures.createUser(id: 'u1', isActive: true));
        await store.save(TestFixtures.createUser(id: 'u2', isActive: false));
        await store.save(TestFixtures.createUser(id: 'u3', isActive: true));

        final stream = store.selectWhere((user) => user.isActive);

        final values = <List<TestUser>>[];
        final subscription = stream.listen(values.add);

        await Future<void>.delayed(Duration.zero);

        expect(values.last.length, equals(2));
        expect(values.last.every((u) => u.isActive), isTrue);

        // Add inactive user
        await store.save(TestFixtures.createUser(id: 'u4', isActive: false));
        await Future<void>.delayed(Duration.zero);

        // Count should still be 2 (only active users)
        expect(values.last.length, equals(2));

        await subscription.cancel();
      });
    });

    group('selectCount', () {
      test('should return item count', () async {
        final stream = store.selectCount();

        final values = <int>[];
        final subscription = stream.listen(values.add);

        await Future<void>.delayed(Duration.zero);

        expect(values.last, equals(0));

        await store.save(TestFixtures.createUser(id: 'u1'));
        await Future<void>.delayed(Duration.zero);

        expect(values.last, equals(1));

        await store.save(TestFixtures.createUser(id: 'u2'));
        await Future<void>.delayed(Duration.zero);

        expect(values.last, equals(2));

        await subscription.cancel();
      });
    });

    group('selectFirst', () {
      test('should return first item or null', () async {
        final stream = store.selectFirst();

        final values = <TestUser?>[];
        final subscription = stream.listen(values.add);

        await Future<void>.delayed(Duration.zero);

        expect(values.last, isNull);

        await store.save(TestFixtures.createUser(id: 'u1', name: 'Alice'));
        await Future<void>.delayed(Duration.zero);

        expect(values.last?.name, equals('Alice'));

        await subscription.cancel();
      });
    });

    group('selectLast', () {
      test('should return last item or null', () async {
        final stream = store.selectLast();

        final values = <TestUser?>[];
        final subscription = stream.listen(values.add);

        await Future<void>.delayed(Duration.zero);

        expect(values.last, isNull);

        await store.save(TestFixtures.createUser(id: 'u1', name: 'Alice'));
        await store.save(TestFixtures.createUser(id: 'u2', name: 'Bob'));
        await Future<void>.delayed(Duration.zero);

        // Note: 'last' depends on the order in which items are stored
        expect(values.last, isNotNull);

        await subscription.cancel();
      });
    });
  });

  group('Selector memoization', () {
    late FakeStoreBackend<TestUser, String> backend;
    late NexusStore<TestUser, String> store;

    setUp(() async {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
      store = NexusStore<TestUser, String>(
        backend: backend,
        idExtractor: (user) => user.id,
      );
      await store.initialize();
    });

    tearDown(() async {
      await store.dispose();
    });

    test('should not recompute for same result', () async {
      var computeCount = 0;

      final selector = Selector<TestUser, int>(
        store.watchAll(),
        (users) {
          computeCount++;
          return users.length;
        },
      );

      final values = <int>[];
      final subscription = selector.stream.listen(values.add);

      await Future<void>.delayed(Duration.zero);

      // Initial compute
      final initialCount = computeCount;

      // Update user (same count of 0)
      // The compute function runs, but distinctUntilChanged prevents emission
      await Future<void>.delayed(Duration.zero);

      // Add a user
      await store.save(TestFixtures.createUser(id: 'u1'));
      await Future<void>.delayed(Duration.zero);

      // Compute should have run at least twice (initial + after add)
      expect(computeCount, greaterThanOrEqualTo(initialCount + 1));

      // But values should only have 0 and 1 (no duplicates)
      expect(values, equals([0, 1]));

      await subscription.cancel();
      await selector.dispose();
    });
  });
}
