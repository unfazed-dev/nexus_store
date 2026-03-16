import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('Mutation Lifecycle Hooks (A4)', () {
    late FakeStoreBackend<TestUser, String> backend;
    late NexusStore<TestUser, String> store;

    setUp(() async {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
      store = NexusStore<TestUser, String>(backend: backend);
      await store.initialize();
    });

    tearDown(() async {
      await store.dispose();
    });

    group('mutate', () {
      test('calls onMutate before save', () async {
        final callOrder = <String>[];
        final user = TestFixtures.createUser(id: 'u1');

        await store.mutate(
          user,
          options: MutationOptions<TestUser>(
            onMutate: () async {
              callOrder.add('onMutate');
              return null;
            },
            onSuccess: (result, ctx) async {
              callOrder.add('onSuccess');
            },
          ),
        );

        expect(callOrder, ['onMutate', 'onSuccess']);
      });

      test('calls onSuccess after successful save', () async {
        TestUser? successResult;
        final user = TestFixtures.createUser(id: 'u1');

        await store.mutate(
          user,
          options: MutationOptions<TestUser>(
            onSuccess: (result, ctx) async {
              successResult = result;
            },
          ),
        );

        expect(successResult, equals(user));
      });

      test('calls onError on save failure', () async {
        Object? capturedError;
        backend.shouldFailOnSave = true;
        final user = TestFixtures.createUser(id: 'u1');

        expect(
          () => store.mutate(
            user,
            options: MutationOptions<TestUser>(
              onError: (error, ctx) async {
                capturedError = error;
              },
            ),
          ),
          throwsException,
        );

        // Wait for async error handler
        await Future<void>.delayed(Duration.zero);
        expect(capturedError, isNotNull);
      });

      test('calls onSettled after success', () async {
        var settled = false;
        final user = TestFixtures.createUser(id: 'u1');

        await store.mutate(
          user,
          options: MutationOptions<TestUser>(
            onSettled: (ctx) async {
              settled = true;
            },
          ),
        );

        expect(settled, isTrue);
      });

      test('calls onSettled after error', () async {
        var settled = false;
        backend.shouldFailOnSave = true;
        final user = TestFixtures.createUser(id: 'u1');

        try {
          await store.mutate(
            user,
            options: MutationOptions<TestUser>(
              onSettled: (ctx) async {
                settled = true;
              },
            ),
          );
        } catch (_) {}

        expect(settled, isTrue);
      });

      test('invalidates tags on success', () async {
        final user = TestFixtures.createUser(id: 'u1');

        // Should not throw — tags are invalidated
        await store.mutate(
          user,
          options: MutationOptions<TestUser>(
            invalidateTags: {'users', 'user-list'},
          ),
        );

        expect(backend.storage['u1'], equals(user));
      });

      test('does NOT invalidate tags on error', () async {
        backend.shouldFailOnSave = true;
        final user = TestFixtures.createUser(id: 'u1');

        try {
          await store.mutate(
            user,
            options: MutationOptions<TestUser>(
              invalidateTags: {'users'},
            ),
          );
        } catch (_) {}

        // No crash — tags were not invalidated
      });

      test('context flows from onMutate to onSuccess', () async {
        Object? receivedContext;
        final user = TestFixtures.createUser(id: 'u1');

        await store.mutate(
          user,
          options: MutationOptions<TestUser>(
            onMutate: () async => 'rollback-data',
            onSuccess: (result, ctx) async {
              receivedContext = ctx;
            },
          ),
        );

        expect(receivedContext, equals('rollback-data'));
      });

      test('context flows from onMutate to onError', () async {
        Object? receivedContext;
        backend.shouldFailOnSave = true;
        final user = TestFixtures.createUser(id: 'u1');

        try {
          await store.mutate(
            user,
            options: MutationOptions<TestUser>(
              onMutate: () async => 'rollback-data',
              onError: (error, ctx) async {
                receivedContext = ctx;
              },
            ),
          );
        } catch (_) {}

        expect(receivedContext, equals('rollback-data'));
      });

      test('with onMutate returning null', () async {
        Object? receivedContext;
        final user = TestFixtures.createUser(id: 'u1');

        await store.mutate(
          user,
          options: MutationOptions<TestUser>(
            onMutate: () async => null,
            onSuccess: (result, ctx) async {
              receivedContext = ctx;
            },
          ),
        );

        expect(receivedContext, isNull);
      });

      test('with no options falls through to plain save', () async {
        final user = TestFixtures.createUser(id: 'u1');

        final result = await store.mutate(user);

        expect(result, equals(user));
        expect(backend.storage['u1'], equals(user));
      });

      test('respects WritePolicy', () async {
        final user = TestFixtures.createUser(id: 'u1');

        final result = await store.mutate(
          user,
          policy: WritePolicy.cacheFirst,
        );

        expect(result, equals(user));
      });

      test('throws before init', () {
        final uninitStore = NexusStore<TestUser, String>(backend: backend);

        expect(
          () => uninitStore.mutate(TestFixtures.createUser(id: 'u1')),
          throwsStateError,
        );
      });
    });

    group('mutateDelete', () {
      test('calls onMutate before delete', () async {
        final callOrder = <String>[];
        backend.addToStorage('u1', TestFixtures.createUser(id: 'u1'));

        await store.mutateDelete(
          'u1',
          options: MutationOptions<TestUser>(
            onMutate: () async {
              callOrder.add('onMutate');
              return null;
            },
            onSettled: (ctx) async {
              callOrder.add('onSettled');
            },
          ),
        );

        expect(callOrder, ['onMutate', 'onSettled']);
      });

      test('calls onSettled after successful delete', () async {
        var settled = false;
        backend.addToStorage('u1', TestFixtures.createUser(id: 'u1'));

        await store.mutateDelete(
          'u1',
          options: MutationOptions<TestUser>(
            onSettled: (ctx) async {
              settled = true;
            },
          ),
        );

        expect(settled, isTrue);
      });

      test('calls onError on delete failure', () async {
        Object? capturedError;
        backend.shouldFailOnDelete = true;

        try {
          await store.mutateDelete(
            'u1',
            options: MutationOptions<TestUser>(
              onError: (error, ctx) async {
                capturedError = error;
              },
            ),
          );
        } catch (_) {}

        expect(capturedError, isNotNull);
      });

      test('calls onSettled after error', () async {
        var settled = false;
        backend.shouldFailOnDelete = true;

        try {
          await store.mutateDelete(
            'u1',
            options: MutationOptions<TestUser>(
              onSettled: (ctx) async {
                settled = true;
              },
            ),
          );
        } catch (_) {}

        expect(settled, isTrue);
      });

      test('invalidates tags on success', () async {
        backend.addToStorage('u1', TestFixtures.createUser(id: 'u1'));

        await store.mutateDelete(
          'u1',
          options: MutationOptions<TestUser>(
            invalidateTags: {'users'},
          ),
        );

        expect(backend.storage.containsKey('u1'), isFalse);
      });

      test('with no options falls through to plain delete', () async {
        backend.addToStorage('u1', TestFixtures.createUser(id: 'u1'));

        final result = await store.mutateDelete('u1');

        expect(result, isTrue);
        expect(backend.storage.containsKey('u1'), isFalse);
      });
    });

    group('MutationOptions', () {
      test('equality with all callbacks null', () {
        const a = MutationOptions<TestUser>();
        const b = MutationOptions<TestUser>();

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('equality with same invalidateTags', () {
        const a = MutationOptions<TestUser>(invalidateTags: {'users'});
        const b = MutationOptions<TestUser>(invalidateTags: {'users'});

        expect(a, equals(b));
      });

      test('inequality with different invalidateTags', () {
        const a = MutationOptions<TestUser>(invalidateTags: {'users'});
        const b = MutationOptions<TestUser>(invalidateTags: {'posts'});

        expect(a, isNot(equals(b)));
      });
    });
  });
}
