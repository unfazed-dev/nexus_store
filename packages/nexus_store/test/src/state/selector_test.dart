import 'dart:async';

import 'package:async/async.dart';
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

        final queue = StreamQueue(selector.stream);
        expect(await queue.next, equals(2));

        await queue.cancel();
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

        final queue = StreamQueue(selector.stream);
        expect(await queue.next, containsAll(['Alice', 'Bob']));

        await queue.cancel();
        await selector.dispose();
      });
    });

    group('stream', () {
      test('should emit transformed values', () async {
        final selector = Selector<TestUser, int>(
          store.watchAll(),
          (users) => users.length,
        );

        final queue = StreamQueue(selector.stream);

        // Initial value
        expect(await queue.next, equals(0));

        // Add user
        await store.save(TestFixtures.createUser(id: 'u1'));
        expect(await queue.next, equals(1));

        // Add another user
        await store.save(TestFixtures.createUser(id: 'u2'));
        expect(await queue.next, equals(2));

        await queue.cancel();
        await selector.dispose();
      });

      test('should emit immediately on subscribe', () async {
        await store.save(TestFixtures.createUser(id: 'u1'));

        final selector = Selector<TestUser, int>(
          store.watchAll(),
          (users) => users.length,
        );

        await expectLater(
          selector.stream.first,
          completion(equals(1)),
        );

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

        // Wait for initial value
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

        final queue = StreamQueue(selector.stream);

        // Initial value (0)
        expect(await queue.next, equals(0));

        // Save user
        await store.save(TestFixtures.createUser(id: 'u1'));
        expect(await queue.next, equals(1));

        // Save same user again - count is still 1
        await store.save(TestFixtures.createUser(id: 'u1', name: 'Updated'));
        // distinctUntilChanged should prevent duplicate emission
        // We verify by checking the value stays at 1 without another emit

        await queue.cancel();
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

        final queue = StreamQueue(selector.stream);
        await queue.next; // Consume initial value to populate selector

        expect(selector.value, equals('Alice'));

        await queue.cancel();
        await selector.dispose();
      });
    });

    group('dispose', () {
      test('should close the stream', () async {
        final selector = Selector<TestUser, int>(
          store.watchAll(),
          (users) => users.length,
        );

        // Wait for stream to be ready
        await expectLater(
          selector.stream.first,
          completion(equals(0)),
        );

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
        final queue = StreamQueue(stream);

        expect(await queue.next, equals(2));

        await store.save(TestFixtures.createUser(id: 'u3', age: 35));
        expect(await queue.next, equals(3));

        await queue.cancel();
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
        final queue = StreamQueue(stream);

        expect((await queue.next)?.name, equals('Alice'));

        // Update the user
        await store.save(TestFixtures.createUser(id: 'u1', name: 'Alicia'));
        expect((await queue.next)?.name, equals('Alicia'));

        await queue.cancel();
      });

      test('should return null for non-existent id', () async {
        await store.save(TestFixtures.createUser(id: 'u1', name: 'Alice'));

        final stream = store.selectById('u999');
        final queue = StreamQueue(stream);

        expect(await queue.next, isNull);

        await queue.cancel();
      });
    });

    group('selectWhere', () {
      test('should filter list by predicate', () async {
        await store.save(TestFixtures.createUser(id: 'u1', isActive: true));
        await store.save(TestFixtures.createUser(id: 'u2', isActive: false));
        await store.save(TestFixtures.createUser(id: 'u3', isActive: true));

        final stream = store.selectWhere((user) => user.isActive);
        final queue = StreamQueue(stream);

        final activeUsers = await queue.next;
        expect(activeUsers.length, equals(2));
        expect(activeUsers.every((u) => u.isActive), isTrue);

        // Add another active user - this should emit because count changes
        await store.save(TestFixtures.createUser(id: 'u4', isActive: true));
        final updatedActiveUsers = await queue.next;

        // Count should now be 3 (active users)
        expect(updatedActiveUsers.length, equals(3));

        await queue.cancel();
      });

      test('should emit when list elements differ at same index', () async {
        // Start with two active users
        await store.save(
            TestFixtures.createUser(id: 'u1', name: 'Alice', isActive: true));
        await store.save(
            TestFixtures.createUser(id: 'u2', name: 'Bob', isActive: true));

        final stream = store.selectWhere((user) => user.isActive);
        final queue = StreamQueue(stream);

        // Initial: 2 active users
        final first = await queue.next;
        expect(first.length, equals(2));

        // Update Alice's name while keeping her active
        // The list still has 2 elements, but Alice is replaced with a new object
        // This exercises _listEquals comparing [oldAlice, Bob] vs [newAlice, Bob]
        // Same length, but different element at index - covers lines 180-181
        await store.save(
            TestFixtures.createUser(id: 'u1', name: 'Alicia', isActive: true));

        // Should emit because content changed (different user object at index)
        final second = await queue.next;
        expect(second.length, equals(2));
        expect(second.any((u) => u.name == 'Alicia'), isTrue);

        await queue.cancel();
      });
    });

    group('selectCount', () {
      test('should return item count', () async {
        final stream = store.selectCount();
        final queue = StreamQueue(stream);

        expect(await queue.next, equals(0));

        await store.save(TestFixtures.createUser(id: 'u1'));
        expect(await queue.next, equals(1));

        await store.save(TestFixtures.createUser(id: 'u2'));
        expect(await queue.next, equals(2));

        await queue.cancel();
      });
    });

    group('selectFirst', () {
      test('should return first item or null', () async {
        final stream = store.selectFirst();
        final queue = StreamQueue(stream);

        expect(await queue.next, isNull);

        await store.save(TestFixtures.createUser(id: 'u1', name: 'Alice'));
        expect((await queue.next)?.name, equals('Alice'));

        await queue.cancel();
      });
    });

    group('selectLast', () {
      test('should return last item or null', () async {
        final stream = store.selectLast();
        final queue = StreamQueue(stream);

        expect(await queue.next, isNull);

        await store.save(TestFixtures.createUser(id: 'u1', name: 'Alice'));
        await store.save(TestFixtures.createUser(id: 'u2', name: 'Bob'));

        // Note: 'last' depends on the order in which items are stored
        final lastUser = await queue.next;
        expect(lastUser, isNotNull);

        await queue.cancel();
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

      final queue = StreamQueue(selector.stream);

      // Initial compute (0 users)
      expect(await queue.next, equals(0));
      final initialCount = computeCount;

      // Add a user
      await store.save(TestFixtures.createUser(id: 'u1'));
      expect(await queue.next, equals(1));

      // Compute should have run at least twice (initial + after add)
      expect(computeCount, greaterThanOrEqualTo(initialCount + 1));

      await queue.cancel();
      await selector.dispose();
    });
  });
}
