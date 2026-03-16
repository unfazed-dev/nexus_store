import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('TransactionCoordinator', () {
    late FakeStoreBackend<TestUser, String> userBackend;
    late FakeStoreBackend<TestProduct, int> productBackend;
    late NexusStore<TestUser, String> userStore;
    late NexusStore<TestProduct, int> productStore;

    setUp(() async {
      userBackend = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
      productBackend = FakeStoreBackend<TestProduct, int>(
        idExtractor: (product) => product.id,
      );

      userStore = NexusStore<TestUser, String>(
        backend: userBackend,
        idExtractor: (user) => user.id,
      );
      productStore = NexusStore<TestProduct, int>(
        backend: productBackend,
        idExtractor: (product) => product.id,
      );

      await userStore.initialize();
      await productStore.initialize();
    });

    tearDown(() async {
      await userStore.dispose();
      await productStore.dispose();
    });

    group('construction', () {
      test('creates coordinator with default settings', () {
        final coordinator = TransactionCoordinator();
        expect(coordinator, isNotNull);
      });

      test('creates coordinator with custom timeout', () {
        final coordinator = TransactionCoordinator(
          timeout: const Duration(seconds: 30),
        );
        expect(coordinator, isNotNull);
      });
    });

    group('successful cross-store commits', () {
      test('saves to multiple stores atomically', () async {
        final user = TestFixtures.createUser();
        final product = TestFixtures.createProduct();

        await TransactionCoordinator.run(
          stores: [userStore, productStore],
          action: (ctx) async {
            await ctx.save(userStore, user);
            await ctx.save(productStore, product);
          },
        );

        expect(await userStore.get('user-1'), equals(user));
        expect(await productStore.get(1), equals(product));
      });

      test('returns result from action callback', () async {
        final user = TestFixtures.createUser();

        final result = await TransactionCoordinator.run(
          stores: [userStore],
          action: (ctx) async {
            await ctx.save(userStore, user);
            return 'done';
          },
        );

        expect(result, equals('done'));
      });

      test('saves multiple items to same store', () async {
        final users = TestFixtures.createUsers(3);

        await TransactionCoordinator.run(
          stores: [userStore],
          action: (ctx) async {
            for (final user in users) {
              await ctx.save(userStore, user);
            }
          },
        );

        final allUsers = await userStore.getAll();
        expect(allUsers.length, equals(3));
      });
    });

    group('failure rollback', () {
      test('rolls back all stores on exception', () async {
        final user = TestFixtures.createUser();
        final product = TestFixtures.createProduct();

        try {
          await TransactionCoordinator.run(
            stores: [userStore, productStore],
            action: (ctx) async {
              await ctx.save(userStore, user);
              await ctx.save(productStore, product);
              throw Exception('Simulated failure');
            },
          );
        } on TransactionError catch (_) {}

        expect(await userStore.get('user-1'), isNull);
        expect(await productStore.get(1), isNull);
      });

      test('rolls back inserts (deletes newly created items)', () async {
        final user = TestFixtures.createUser();

        try {
          await TransactionCoordinator.run(
            stores: [userStore],
            action: (ctx) async {
              await ctx.save(userStore, user);
              throw Exception('Rollback');
            },
          );
        } on TransactionError catch (_) {}

        expect(await userStore.get('user-1'), isNull);
      });

      test('rolls back updates (restores original values)', () async {
        final original = TestFixtures.createUser(name: 'Original');
        await userStore.save(original);

        try {
          await TransactionCoordinator.run(
            stores: [userStore],
            action: (ctx) async {
              final updated = original.copyWith(name: 'Updated');
              await ctx.save(userStore, updated);
              throw Exception('Rollback');
            },
          );
        } on TransactionError catch (_) {}

        final restored = await userStore.get('user-1');
        expect(restored?.name, equals('Original'));
      });

      test('rolls back deletes (restores deleted items)', () async {
        final user = TestFixtures.createUser();
        await userStore.save(user);

        try {
          await TransactionCoordinator.run(
            stores: [userStore],
            action: (ctx) async {
              await ctx.delete(userStore, 'user-1');
              throw Exception('Rollback');
            },
          );
        } on TransactionError catch (_) {}

        expect(await userStore.get('user-1'), equals(user));
      });
    });

    group('partial failure across stores', () {
      test('rolls back first store when second store operation fails',
          () async {
        final user = TestFixtures.createUser();

        productBackend.shouldFailOnSave = true;

        try {
          await TransactionCoordinator.run(
            stores: [userStore, productStore],
            action: (ctx) async {
              await ctx.save(userStore, user);
              await ctx.save(productStore, TestFixtures.createProduct());
            },
          );
        } on TransactionError catch (_) {}

        productBackend.shouldFailOnSave = false;

        // User should be rolled back even though its save succeeded
        expect(await userStore.get('user-1'), isNull);
      });
    });

    group('shared backend transactions', () {
      test('uses single transaction for stores sharing a backend', () async {
        // Two stores on the same backend (same database)
        final sharedBackend = FakeStoreBackend<TestUser, String>(
          idExtractor: (user) => user.id,
        );

        final store1 = NexusStore<TestUser, String>(
          backend: sharedBackend,
          idExtractor: (user) => user.id,
        );
        final store2 = NexusStore<TestUser, String>(
          backend: sharedBackend,
          idExtractor: (user) => user.id,
        );

        await store1.initialize();
        await store2.initialize();

        final user1 = TestFixtures.createUser(id: 'user-1');
        final user2 = TestFixtures.createUser(id: 'user-2');

        await TransactionCoordinator.run(
          stores: [store1, store2],
          action: (ctx) async {
            await ctx.save(store1, user1);
            await ctx.save(store2, user2);
          },
        );

        expect(await store1.get('user-1'), equals(user1));
        expect(await store2.get('user-2'), equals(user2));

        await store1.dispose();
        await store2.dispose();
      });

      test('rolls back shared backend atomically on failure', () async {
        final sharedBackend = FakeStoreBackend<TestUser, String>(
          idExtractor: (user) => user.id,
        );

        final store1 = NexusStore<TestUser, String>(
          backend: sharedBackend,
          idExtractor: (user) => user.id,
        );
        final store2 = NexusStore<TestUser, String>(
          backend: sharedBackend,
          idExtractor: (user) => user.id,
        );

        await store1.initialize();
        await store2.initialize();

        try {
          await TransactionCoordinator.run(
            stores: [store1, store2],
            action: (ctx) async {
              await ctx.save(store1, TestFixtures.createUser(id: 'user-1'));
              await ctx.save(store2, TestFixtures.createUser(id: 'user-2'));
              throw Exception('Rollback');
            },
          );
        } on TransactionError catch (_) {}

        expect(await store1.get('user-1'), isNull);
        expect(await store2.get('user-2'), isNull);

        await store1.dispose();
        await store2.dispose();
      });
    });

    group('non-transactional backend fallback', () {
      test('uses compensation for backends without transaction support',
          () async {
        userBackend.supportsTransactionsForTest = false;

        final user = TestFixtures.createUser();

        try {
          await TransactionCoordinator.run(
            stores: [userStore],
            action: (ctx) async {
              await ctx.save(userStore, user);
              throw Exception('Rollback');
            },
          );
        } on TransactionError catch (_) {}

        // Should still roll back via compensation
        expect(await userStore.get('user-1'), isNull);
      });
    });

    group('NexusStore.crossTransaction static method', () {
      test('provides convenience API for cross-store transactions', () async {
        final user = TestFixtures.createUser();
        final product = TestFixtures.createProduct();

        await NexusStore.crossTransaction(
          stores: [userStore, productStore],
          action: (ctx) async {
            await ctx.save(userStore, user);
            await ctx.save(productStore, product);
          },
        );

        expect(await userStore.get('user-1'), equals(user));
        expect(await productStore.get(1), equals(product));
      });

      test('rolls back all stores on failure', () async {
        final user = TestFixtures.createUser();
        final product = TestFixtures.createProduct();

        try {
          await NexusStore.crossTransaction(
            stores: [userStore, productStore],
            action: (ctx) async {
              await ctx.save(userStore, user);
              await ctx.save(productStore, product);
              throw Exception('Fail');
            },
          );
        } on TransactionError catch (_) {}

        expect(await userStore.get('user-1'), isNull);
        expect(await productStore.get(1), isNull);
      });

      test('returns result from action', () async {
        final result = await NexusStore.crossTransaction(
          stores: [userStore],
          action: (ctx) async {
            await ctx.save(userStore, TestFixtures.createUser());
            return 42;
          },
        );

        expect(result, equals(42));
      });
    });

    group('CrossTransactionContext operations', () {
      test('save returns saved item', () async {
        final user = TestFixtures.createUser();

        await TransactionCoordinator.run(
          stores: [userStore],
          action: (ctx) async {
            final saved = await ctx.save(userStore, user);
            expect(saved, equals(user));
          },
        );
      });

      test('delete returns success boolean', () async {
        final user = TestFixtures.createUser();
        await userStore.save(user);

        await TransactionCoordinator.run(
          stores: [userStore],
          action: (ctx) async {
            final deleted = await ctx.delete(userStore, 'user-1');
            expect(deleted, isTrue);
          },
        );
      });

      test('delete returns false for non-existent item', () async {
        await TransactionCoordinator.run(
          stores: [userStore],
          action: (ctx) async {
            final deleted = await ctx.delete(userStore, 'non-existent');
            expect(deleted, isFalse);
          },
        );
      });
    });

    group('timeout', () {
      test('throws TransactionError on timeout', () async {
        expect(
          () => TransactionCoordinator.run(
            stores: [userStore],
            timeout: const Duration(milliseconds: 1),
            action: (ctx) async {
              await Future.delayed(const Duration(seconds: 1));
            },
          ),
          throwsA(isA<TransactionError>()),
        );
      });
    });

    group('error details', () {
      test('TransactionError includes wasRolledBack flag', () async {
        Object? caughtError;
        try {
          await TransactionCoordinator.run(
            stores: [userStore],
            action: (ctx) async {
              await ctx.save(userStore, TestFixtures.createUser());
              throw Exception('Test error');
            },
          );
        } on TransactionError catch (e) {
          caughtError = e;
        }

        expect(caughtError, isA<TransactionError>());
        final error = caughtError as TransactionError;
        expect(error.wasRolledBack, isTrue);
        expect(error.message, contains('Cross-store transaction failed'));
      });
    });
  });
}
