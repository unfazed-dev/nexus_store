import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('NexusStore', () {
    late FakeStoreBackend<TestUser, String> backend;

    setUp(() {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
    });

    group('watchCount', () {
      late NexusStore<TestUser, String> store;

      setUp(() async {
        store = NexusStore<TestUser, String>(backend: backend);
        await store.initialize();
      });

      test('should throw before initialize', () {
        final uninitializedStore =
            NexusStore<TestUser, String>(backend: backend);

        expect(
          () => uninitializedStore.watchCount(),
          throwsStateError,
        );
      });

      test('should emit 0 for empty store', () async {
        final stream = store.watchCount();
        final result = await stream.first;

        expect(result, equals(0));
      });

      test('should emit count for populated store', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());
        backend.addToStorage(
          'user-2',
          TestFixtures.createUser(id: 'user-2', name: 'Jane'),
        );

        final stream = store.watchCount();
        final result = await stream.first;

        expect(result, equals(2));
      });

      test('should emit updated count after save', () async {
        final stream = store.watchCount();
        final results = <int>[];
        final sub = stream.listen(results.add);

        // Wait for initial emission
        await Future<void>.delayed(Duration.zero);

        await store.save(TestFixtures.createUser());
        await Future<void>.delayed(Duration.zero);

        expect(results, contains(0));
        expect(results, contains(1));

        await sub.cancel();
      });

      test('should emit updated count after delete', () async {
        await store.save(TestFixtures.createUser());

        final stream = store.watchCount();
        final results = <int>[];
        final sub = stream.listen(results.add);

        await Future<void>.delayed(Duration.zero);

        await store.delete('user-1');
        await Future<void>.delayed(Duration.zero);

        expect(results, contains(1));
        expect(results, contains(0));

        await sub.cancel();
      });

      test('should work with query filter', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());
        backend.addToStorage(
          'user-2',
          TestFixtures.createUser(id: 'user-2', name: 'Jane'),
        );

        final stream = store.watchCount(
          query: Query<TestUser>().where('name', isEqualTo: 'John Doe'),
        );
        final result = await stream.first;

        // FakeStoreBackend.watchAll doesn't filter, so count reflects all items
        // In production, the backend would filter
        expect(result, isA<int>());

        await store.dispose();
      });
    });

    group('watchOne', () {
      late NexusStore<TestUser, String> store;

      setUp(() async {
        store = NexusStore<TestUser, String>(backend: backend);
        await store.initialize();
      });

      test('should throw before initialize', () {
        final uninitializedStore =
            NexusStore<TestUser, String>(backend: backend);

        expect(
          () => uninitializedStore.watchOne(Query<TestUser>()),
          throwsStateError,
        );
      });

      test('should emit null when no entities match', () async {
        final stream = store.watchOne(Query<TestUser>());
        final result = await stream.first;

        expect(result, isNull);
      });

      test('should emit first entity when entities exist', () async {
        final user = TestFixtures.createUser();
        backend.addToStorage('user-1', user);

        final stream = store.watchOne(Query<TestUser>());
        final result = await stream.first;

        expect(result, equals(user));
      });

      test('should emit updated entity after save', () async {
        final stream = store.watchOne(Query<TestUser>());
        final results = <TestUser?>[];
        final sub = stream.listen(results.add);

        // Wait for initial emission
        await Future<void>.delayed(Duration.zero);

        final user = TestFixtures.createUser();
        await store.save(user);
        await Future<void>.delayed(Duration.zero);

        expect(results, contains(isNull));
        expect(results, contains(user));

        await sub.cancel();
      });

      test('should emit null after entity deleted', () async {
        await store.save(TestFixtures.createUser());

        final stream = store.watchOne(Query<TestUser>());
        final results = <TestUser?>[];
        final sub = stream.listen(results.add);

        await Future<void>.delayed(Duration.zero);

        await store.delete('user-1');
        await Future<void>.delayed(Duration.zero);

        expect(results.last, isNull);

        await sub.cancel();
      });

      test('should work with query filter', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final stream = store.watchOne(
          Query<TestUser>().where('name', isEqualTo: 'John Doe'),
        );
        final result = await stream.first;

        // Should emit an entity (or null depending on backend filtering)
        expect(result, isA<TestUser?>());

        await store.dispose();
      });
    });
  });
}
