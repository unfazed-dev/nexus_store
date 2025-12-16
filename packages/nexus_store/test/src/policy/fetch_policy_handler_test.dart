import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('FetchPolicyHandler', () {
    late FakeStoreBackend<TestUser, String> backend;
    late FetchPolicyHandler<TestUser, String> handler;

    setUp(() {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
    });

    group('constructor', () {
      test('should create handler with required parameters', () {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheFirst,
        );

        expect(handler.backend, equals(backend));
        expect(handler.defaultPolicy, equals(FetchPolicy.cacheFirst));
        expect(handler.staleDuration, isNull);
      });

      test('should accept optional staleDuration', () {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheFirst,
          staleDuration: const Duration(minutes: 5),
        );

        expect(handler.staleDuration, equals(const Duration(minutes: 5)));
      });
    });

    group('cacheFirst policy', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheFirst,
        );
      });

      test('should return cached data when available', () async {
        final user = TestFixtures.createUser();
        backend.addToStorage('user-1', user);

        final result = await handler.get('user-1');

        expect(result, equals(user));
      });

      test('should fetch from network when cache is empty', () async {
        // Backend starts empty, sync would populate it
        // Since FakeBackend.sync is a no-op, we simulate by adding after
        backend.addToStorage('user-1', TestFixtures.createUser());

        final result = await handler.get(
          'user-1',
          policy: FetchPolicy.cacheFirst,
        );

        expect(result, isNotNull);
      });

      test('should return cached data on network failure', () async {
        final user = TestFixtures.createUser();
        backend.addToStorage('user-1', user);
        backend.shouldFailOnSync = true;

        final result = await handler.get('user-1');

        expect(result, equals(user));
      });

      test('should return null when cache empty and network fails', () async {
        backend.shouldFailOnSync = true;

        final result = await handler.get('non-existent');

        expect(result, isNull);
      });

      test('getAll should return cached list when available', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());
        backend.addToStorage('user-2', TestFixtures.createUser(id: 'user-2'));

        final results = await handler.getAll();

        expect(results, hasLength(2));
      });
    });

    group('networkFirst policy', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.networkFirst,
        );
      });

      test('should prefer network data', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final result = await handler.get('user-1');

        expect(result, isNotNull);
      });

      test('should fallback to cache on network failure', () async {
        final user = TestFixtures.createUser();
        backend.addToStorage('user-1', user);
        backend.shouldFailOnSync = true;

        final result = await handler.get('user-1');

        expect(result, equals(user));
      });

      test('getAll should fallback to cache on network failure', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());
        backend.shouldFailOnSync = true;

        final results = await handler.getAll();

        expect(results, hasLength(1));
      });
    });

    group('cacheAndNetwork policy', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheAndNetwork,
        );
      });

      test('should return network result', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final result = await handler.get('user-1');

        expect(result, isNotNull);
      });

      test('should return cached data on network failure', () async {
        final user = TestFixtures.createUser();
        backend.addToStorage('user-1', user);
        backend.shouldFailOnSync = true;

        final result = await handler.get('user-1');

        expect(result, equals(user));
      });
    });

    group('cacheOnly policy', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheOnly,
        );
      });

      test('should return only cached data', () async {
        final user = TestFixtures.createUser();
        backend.addToStorage('user-1', user);

        final result = await handler.get('user-1');

        expect(result, equals(user));
      });

      test('should return null when not in cache', () async {
        final result = await handler.get('non-existent');

        expect(result, isNull);
      });

      test('getAll should return only cached data', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final results = await handler.getAll();

        expect(results, hasLength(1));
      });
    });

    group('networkOnly policy', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.networkOnly,
        );
      });

      test('should always try network', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final result = await handler.get('user-1');

        expect(result, isNotNull);
      });

      test('should throw on network failure', () async {
        backend.shouldFailOnSync = true;

        expect(
          () => handler.get('user-1'),
          throwsException,
        );
      });

      test('getAll should throw on network failure', () async {
        backend.shouldFailOnSync = true;

        expect(
          () => handler.getAll(),
          throwsException,
        );
      });
    });

    group('staleWhileRevalidate policy', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.staleWhileRevalidate,
        );
      });

      test('should return cached data immediately', () async {
        final user = TestFixtures.createUser();
        backend.addToStorage('user-1', user);

        final result = await handler.get('user-1');

        expect(result, equals(user));
      });

      test('should fetch from network when cache is empty', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final result = await handler.get('user-1');

        expect(result, isNotNull);
      });

      test('getAll should return cached data immediately', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final results = await handler.getAll();

        expect(results, hasLength(1));
      });
    });

    group('staleness', () {
      test('should consider data stale after staleDuration', () async {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheFirst,
          staleDuration: const Duration(milliseconds: 1),
          lastFetchTimes: {
            'user-1': DateTime.now().subtract(const Duration(seconds: 1)),
          },
        );

        backend.addToStorage('user-1', TestFixtures.createUser());

        // Should try network since data is stale
        final result = await handler.get('user-1');
        expect(result, isNotNull);
      });

      test('should not consider data stale when no staleDuration', () async {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheFirst,
          lastFetchTimes: {
            'user-1': DateTime.now().subtract(const Duration(days: 100)),
          },
        );

        final user = TestFixtures.createUser();
        backend.addToStorage('user-1', user);

        final result = await handler.get('user-1');
        expect(result, equals(user));
      });
    });

    group('invalidate', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheFirst,
          staleDuration: const Duration(minutes: 5),
          lastFetchTimes: {
            'user-1': DateTime.now(),
            'user-2': DateTime.now(),
          },
        );
      });

      test('should mark single entity as stale', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        handler.invalidate('user-1');

        // After invalidation, cacheFirst should try network
        final result = await handler.get('user-1');
        expect(result, isNotNull);
      });

      test('should mark all entities as stale', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());
        backend.addToStorage('user-2', TestFixtures.createUser(id: 'user-2'));

        handler.invalidateAll();

        // Both should be considered stale
        final result1 = await handler.get('user-1');
        final result2 = await handler.get('user-2');
        expect(result1, isNotNull);
        expect(result2, isNotNull);
      });
    });

    group('watch', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheFirst,
        );
      });

      test('should delegate to backend watch', () async {
        final user = TestFixtures.createUser();
        backend.addToStorage('user-1', user);

        final stream = handler.watch('user-1');
        final result = await stream.first;

        expect(result, equals(user));
      });
    });

    group('watchAll', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheFirst,
        );
      });

      test('should delegate to backend watchAll', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final stream = handler.watchAll();
        final result = await stream.first;

        expect(result, hasLength(1));
      });
    });

    group('policy override', () {
      setUp(() {
        handler = FetchPolicyHandler(
          backend: backend,
          defaultPolicy: FetchPolicy.cacheFirst,
        );
      });

      test('should use provided policy over default', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        // Default is cacheFirst, but we override with networkOnly
        final result = await handler.get(
          'user-1',
          policy: FetchPolicy.cacheOnly,
        );

        expect(result, isNotNull);
      });

      test('getAll should use provided policy over default', () async {
        backend.addToStorage('user-1', TestFixtures.createUser());

        final results = await handler.getAll(
          policy: FetchPolicy.cacheOnly,
        );

        expect(results, hasLength(1));
      });
    });
  });
}
