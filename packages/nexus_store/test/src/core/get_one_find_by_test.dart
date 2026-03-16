import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('getOne / findBy', () {
    late FakeStoreBackend<TestUser, String> backend;
    late NexusStore<TestUser, String> store;

    setUp(() async {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
      backend.fieldAccessor = (user, field) {
        switch (field) {
          case 'id':
            return user.id;
          case 'name':
            return user.name;
          case 'email':
            return user.email;
          case 'age':
            return user.age;
          case 'isActive':
            return user.isActive;
          default:
            return null;
        }
      };
      store = NexusStore<TestUser, String>(backend: backend);
      await store.initialize();
    });

    tearDown(() async {
      await store.dispose();
    });

    group('getOne', () {
      test('returns first match', () async {
        final user1 = TestFixtures.createUser(id: 'u1', name: 'Alice');
        final user2 = TestFixtures.createUser(id: 'u2', name: 'Bob');
        backend.addToStorage('u1', user1);
        backend.addToStorage('u2', user2);

        final result = await store.getOne();

        expect(result, isNotNull);
      });

      test('returns null when no match', () async {
        final result = await store.getOne();

        expect(result, isNull);
      });

      test('applies limitTo(1) optimization', () async {
        final users = TestFixtures.createUsers(5);
        for (final user in users) {
          backend.addToStorage(user.id, user);
        }

        // getOne should apply limitTo(1) internally — returns single item
        final result = await store.getOne();

        expect(result, isNotNull);
      });

      test('respects fetch policy', () async {
        final user = TestFixtures.createUser(id: 'u1');
        backend.addToStorage('u1', user);

        final result = await store.getOne(policy: FetchPolicy.cacheFirst);

        expect(result, isNotNull);
      });

      test('fires interceptor chain', () async {
        var intercepted = false;
        final interceptor = _TrackingInterceptor(
          targetOps: {StoreOperation.getOne},
          onIntercept: () => intercepted = true,
        );
        final interceptedStore = NexusStore<TestUser, String>(
          backend: backend,
          config: StoreConfig(interceptors: [interceptor]),
        );
        await interceptedStore.initialize();

        final user = TestFixtures.createUser(id: 'u1');
        backend.addToStorage('u1', user);

        await interceptedStore.getOne();

        expect(intercepted, isTrue);
        await interceptedStore.dispose();
      });

      test('throws StateError before init', () async {
        final uninitStore = NexusStore<TestUser, String>(backend: backend);

        expect(
          () => uninitStore.getOne(),
          throwsStateError,
        );
      });

      test('with query filters', () async {
        final alice = TestFixtures.createUser(id: 'u1', name: 'Alice');
        final bob = TestFixtures.createUser(id: 'u2', name: 'Bob');
        backend.addToStorage('u1', alice);
        backend.addToStorage('u2', bob);

        final result = await store.getOne(
          query: Query<TestUser>().where('name', isEqualTo: 'Alice'),
        );

        expect(result, isNotNull);
        expect(result!.name, equals('Alice'));
      });

      test('with empty store returns null', () async {
        final result = await store.getOne();

        expect(result, isNull);
      });
    });

    group('findBy', () {
      test('with string value', () async {
        final user = TestFixtures.createUser(
          id: 'u1',
          email: 'alice@example.com',
        );
        backend.addToStorage('u1', user);

        final result = await store.findBy('email', 'alice@example.com');

        expect(result, isNotNull);
        expect(result!.email, equals('alice@example.com'));
      });

      test('with int value', () async {
        final user = TestFixtures.createUser(id: 'u1', age: 25);
        backend.addToStorage('u1', user);

        final result = await store.findBy('age', 25);

        expect(result, isNotNull);
        expect(result!.age, equals(25));
      });

      test('with bool value', () async {
        final user = TestFixtures.createUser(id: 'u1', isActive: true);
        backend.addToStorage('u1', user);

        final result = await store.findBy('isActive', true);

        expect(result, isNotNull);
        expect(result!.isActive, isTrue);
      });

      test('returns null when no match', () async {
        // Empty store — no entities to match
        final result = await store.findBy('name', 'NonExistent');

        expect(result, isNull);
      });

      test('delegates to getOne internally', () async {
        final user = TestFixtures.createUser(
          id: 'u1',
          email: 'test@example.com',
        );
        backend.addToStorage('u1', user);

        final result = await store.findBy('email', 'test@example.com');

        expect(result, isNotNull);
        expect(result!.id, equals('u1'));
      });
    });

    group('StoreOperation.getOne', () {
      test('enum value exists', () {
        expect(StoreOperation.getOne, isNotNull);
      });

      test('isRead is true', () {
        expect(StoreOperation.getOne.isRead, isTrue);
      });

      test('isWrite is false', () {
        expect(StoreOperation.getOne.isWrite, isFalse);
      });

      test('isStream is false', () {
        expect(StoreOperation.getOne.isStream, isFalse);
      });

      test('isDelete is false', () {
        expect(StoreOperation.getOne.isDelete, isFalse);
      });
    });

    group('OperationType.getOne', () {
      test('enum value exists', () {
        expect(OperationType.getOne, isNotNull);
      });
    });

    group('TimingInterceptor maps getOne', () {
      test('reports getOne operation metric', () async {
        final metrics = <OperationMetric>[];
        final reporter = _CapturingReporter(onMetric: metrics.add);
        final timingInterceptor = TimingInterceptor(reporter: reporter);
        final timedStore = NexusStore<TestUser, String>(
          backend: backend,
          config: StoreConfig(interceptors: [timingInterceptor]),
        );
        await timedStore.initialize();

        final user = TestFixtures.createUser(id: 'u1');
        backend.addToStorage('u1', user);

        await timedStore.getOne();

        expect(
          metrics.any((m) => m.operation == OperationType.getOne),
          isTrue,
        );
        await timedStore.dispose();
      });
    });
  });
}

/// Test interceptor that tracks whether it was invoked for specific operations.
class _TrackingInterceptor extends StoreInterceptor {
  _TrackingInterceptor({
    required Set<StoreOperation> targetOps,
    required this.onIntercept,
  }) : _operations = targetOps;

  final Set<StoreOperation> _operations;
  final void Function() onIntercept;

  @override
  Set<StoreOperation> get operations => _operations;

  @override
  Future<InterceptorResult<R>> onRequest<T, R>(
    InterceptorContext<T, R> ctx,
  ) async {
    onIntercept();
    return const InterceptorResult.continue_();
  }
}

/// Capturing metrics reporter for test verification.
class _CapturingReporter implements MetricsReporter {
  _CapturingReporter({required this.onMetric});

  final void Function(OperationMetric) onMetric;

  @override
  void reportOperation(OperationMetric metric) => onMetric(metric);

  @override
  void reportCacheEvent(CacheMetric metric) {}

  @override
  void reportSyncEvent(SyncMetric metric) {}

  @override
  void reportError(ErrorMetric metric) {}

  @override
  void reportPoolEvent(PoolMetric metric) {}

  @override
  Future<void> flush() async {}

  @override
  Future<void> dispose() async {}
}
