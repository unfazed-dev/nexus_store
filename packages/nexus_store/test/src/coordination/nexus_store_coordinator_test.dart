import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('NexusStoreCoordinator', () {
    late FakeStoreBackend<TestUser, String> userBackend;
    late FakeStoreBackend<TestProduct, int> productBackend;
    late NexusStore<TestUser, String> userStore;
    late NexusStore<TestProduct, int> productStore;
    late NexusStoreCoordinator coordinator;

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

      coordinator = NexusStoreCoordinator();
    });

    tearDown(() async {
      await coordinator.dispose();
      await userStore.dispose();
      await productStore.dispose();
    });

    group('construction', () {
      test('creates coordinator with default persistence', () {
        final c = NexusStoreCoordinator();
        expect(c, isNotNull);
      });

      test('creates coordinator with custom persistence', () {
        final persistence = InMemorySagaPersistence();
        final c = NexusStoreCoordinator(persistence: persistence);
        expect(c, isNotNull);
      });
    });

    group('transaction', () {
      test('executes single save successfully', () async {
        final user = TestFixtures.createUser();

        final result = await coordinator.transaction((ctx) async {
          await ctx.save(userStore, user, idExtractor: (u) => u.id);
        });

        expect(result.isSuccess, isTrue);
        expect(await userStore.get('user-1'), equals(user));
      });

      test('executes multiple saves to same store', () async {
        final users = TestFixtures.createUsers(3);

        final result = await coordinator.transaction((ctx) async {
          for (final user in users) {
            await ctx.save(userStore, user, idExtractor: (u) => u.id);
          }
        });

        expect(result.isSuccess, isTrue);
        final allUsers = await userStore.getAll();
        expect(allUsers.length, equals(3));
      });

      test('executes saves to multiple stores', () async {
        final user = TestFixtures.createUser();
        final product = TestFixtures.createProduct();

        final result = await coordinator.transaction((ctx) async {
          await ctx.save(userStore, user, idExtractor: (u) => u.id);
          await ctx.save(productStore, product, idExtractor: (p) => p.id);
        });

        expect(result.isSuccess, isTrue);
        expect(await userStore.get('user-1'), equals(user));
        expect(await productStore.get(1), equals(product));
      });

      test('returns results from steps', () async {
        final user = TestFixtures.createUser();

        final result = await coordinator.transaction((ctx) async {
          await ctx.save(userStore, user, idExtractor: (u) => u.id);
        });

        expect(result.isSuccess, isTrue);
        result.when(
          success: (results) => expect(results.isNotEmpty, isTrue),
          failure: (_, __, ___) => fail('Should not fail'),
          partialFailure: (_, __, ___) => fail('Should not partially fail'),
        );
      });
    });

    group('auto-compensation for save', () {
      test('rolls back save on subsequent failure', () async {
        final user = TestFixtures.createUser();

        final result = await coordinator.transaction((ctx) async {
          await ctx.save(userStore, user, idExtractor: (u) => u.id);
          throw Exception('Simulated failure');
        });

        expect(result.isFailure, isTrue);
        expect(await userStore.get('user-1'), isNull);
      });

      test('rolls back multiple saves on failure', () async {
        final users = TestFixtures.createUsers(3);

        final result = await coordinator.transaction((ctx) async {
          for (final user in users) {
            await ctx.save(userStore, user, idExtractor: (u) => u.id);
          }
          throw Exception('Simulated failure');
        });

        expect(result.isFailure, isTrue);
        expect(await userStore.get('user-0'), isNull);
        expect(await userStore.get('user-1'), isNull);
        expect(await userStore.get('user-2'), isNull);
      });

      test('rolls back saves across multiple stores on failure', () async {
        final user = TestFixtures.createUser();
        final product = TestFixtures.createProduct();

        final result = await coordinator.transaction((ctx) async {
          await ctx.save(userStore, user, idExtractor: (u) => u.id);
          await ctx.save(productStore, product, idExtractor: (p) => p.id);
          throw Exception('Simulated failure');
        });

        expect(result.isFailure, isTrue);
        expect(await userStore.get('user-1'), isNull);
        expect(await productStore.get(1), isNull);
      });

      test('compensation deletes newly created items', () async {
        final user = TestFixtures.createUser();

        // Ensure item doesn't exist before
        expect(await userStore.get('user-1'), isNull);

        final result = await coordinator.transaction((ctx) async {
          await ctx.save(userStore, user, idExtractor: (u) => u.id);
          // Verify it was saved before failure
          expect(await userStore.get('user-1'), equals(user));
          throw Exception('Fail after save');
        });

        expect(result.isFailure, isTrue);
        // Should be deleted by compensation
        expect(await userStore.get('user-1'), isNull);
      });

      test('compensation restores original value for updates', () async {
        final original = TestFixtures.createUser(name: 'Original');
        await userStore.save(original);

        final updated = original.copyWith(name: 'Updated');

        final result = await coordinator.transaction((ctx) async {
          await ctx.save(userStore, updated, idExtractor: (u) => u.id);
          throw Exception('Fail after update');
        });

        expect(result.isFailure, isTrue);
        final restored = await userStore.get('user-1');
        expect(restored?.name, equals('Original'));
      });
    });

    group('delete operations', () {
      test('executes delete successfully', () async {
        final user = TestFixtures.createUser();
        await userStore.save(user);

        final result = await coordinator.transaction((ctx) async {
          await ctx.delete(userStore, 'user-1');
        });

        expect(result.isSuccess, isTrue);
        expect(await userStore.get('user-1'), isNull);
      });

      test('compensation restores deleted item', () async {
        final user = TestFixtures.createUser();
        await userStore.save(user);

        final result = await coordinator.transaction((ctx) async {
          await ctx.delete(userStore, 'user-1');
          throw Exception('Fail after delete');
        });

        expect(result.isFailure, isTrue);
        final restored = await userStore.get('user-1');
        expect(restored, equals(user));
      });
    });

    group('custom steps', () {
      test('executes custom step with manual compensation', () async {
        var compensationCalled = false;

        final result = await coordinator.transaction((ctx) async {
          await ctx.step(
            'custom-step',
            () async => 'result',
            (result) async {
              compensationCalled = true;
            },
          );
        });

        expect(result.isSuccess, isTrue);
        expect(compensationCalled, isFalse);
      });

      test('calls custom compensation on failure', () async {
        var compensationCalled = false;

        final result = await coordinator.transaction((ctx) async {
          await ctx.step(
            'custom-step',
            () async => 'result',
            (result) async {
              compensationCalled = true;
            },
          );
          throw Exception('Fail after step');
        });

        expect(result.isFailure, isTrue);
        expect(compensationCalled, isTrue);
      });

      test('passes result to custom compensation', () async {
        String? compensationResult;

        final result = await coordinator.transaction((ctx) async {
          await ctx.step<String>(
            'custom-step',
            () async => 'step-result',
            (result) async {
              compensationResult = result;
            },
          );
          throw Exception('Fail');
        });

        expect(result.isFailure, isTrue);
        expect(compensationResult, equals('step-result'));
      });

      test('integrates custom steps with auto-compensation', () async {
        final user = TestFixtures.createUser();
        var customCompensationCalled = false;

        final result = await coordinator.transaction((ctx) async {
          await ctx.save(userStore, user, idExtractor: (u) => u.id);
          await ctx.step(
            'custom-step',
            () async => 'custom-result',
            (result) async {
              customCompensationCalled = true;
            },
          );
          throw Exception('Fail');
        });

        expect(result.isFailure, isTrue);
        expect(await userStore.get('user-1'), isNull);
        expect(customCompensationCalled, isTrue);
      });
    });

    group('compensation order', () {
      test('compensates steps in reverse order', () async {
        final compensationOrder = <String>[];

        final result = await coordinator.transaction((ctx) async {
          await ctx.step(
            'step-1',
            () async => '1',
            (result) async {
              compensationOrder.add('step-1');
            },
          );
          await ctx.step(
            'step-2',
            () async => '2',
            (result) async {
              compensationOrder.add('step-2');
            },
          );
          await ctx.step(
            'step-3',
            () async => '3',
            (result) async {
              compensationOrder.add('step-3');
            },
          );
          throw Exception('Fail');
        });

        expect(result.isFailure, isTrue);
        expect(compensationOrder, equals(['step-3', 'step-2', 'step-1']));
      });
    });

    group('partial failure', () {
      test('returns partial failure when compensation fails', () async {
        final result = await coordinator.transaction((ctx) async {
          await ctx.step(
            'step-1',
            () async => '1',
            (result) async {
              throw Exception('Compensation failed');
            },
          );
          throw Exception('Action failed');
        });

        expect(result.isPartialFailure, isTrue);
        result.when(
          success: (_) => fail('Should not succeed'),
          failure: (_, __, ___) => fail('Should not be regular failure'),
          partialFailure: (error, failedStep, compensationErrors) {
            expect(compensationErrors.isNotEmpty, isTrue);
            expect(compensationErrors.first.stepName, equals('step-1'));
          },
        );
      });
    });

    group('events', () {
      test('emits events for transaction lifecycle', () async {
        final events = <SagaEventData>[];
        coordinator.events.listen(events.add);

        await coordinator.transaction((ctx) async {
          await ctx.save(userStore, TestFixtures.createUser(), idExtractor: (u) => u.id);
        });

        await Future.delayed(Duration(milliseconds: 10));

        expect(events.any((e) => e.event == SagaEvent.sagaStarted), isTrue);
        expect(events.any((e) => e.event == SagaEvent.stepStarted), isTrue);
        expect(events.any((e) => e.event == SagaEvent.stepCompleted), isTrue);
        expect(events.any((e) => e.event == SagaEvent.sagaCompleted), isTrue);
      });

      test('handles failure and returns failure result', () async {
        final result = await coordinator.transaction((ctx) async {
          await ctx.save(userStore, TestFixtures.createUser(), idExtractor: (u) => u.id);
          throw Exception('Fail');
        });

        // Verify the result indicates failure
        expect(result.isFailure, isTrue);
        result.when(
          success: (_) => fail('Should not succeed'),
          failure: (error, failedStep, compensatedSteps) {
            expect(error.toString(), contains('Fail'));
            expect(failedStep, equals('transaction-block'));
            expect(compensatedSteps.isNotEmpty, isTrue);
          },
          partialFailure: (_, __, ___) => fail('Should not be partial failure'),
        );
      });
    });

    group('persistence', () {
      test('saves saga state during execution', () async {
        final persistence = InMemorySagaPersistence();
        final c = NexusStoreCoordinator(persistence: persistence);

        await c.transaction((ctx) async {
          await ctx.save(userStore, TestFixtures.createUser(), idExtractor: (u) => u.id);
        });

        // After successful completion, state should be cleaned up
        // but we can verify the persistence is used
        final incomplete = await persistence.getIncomplete();
        expect(incomplete, isEmpty);

        await c.dispose();
      });
    });

    group('named transactions', () {
      test('creates transaction with custom saga id', () async {
        final events = <SagaEventData>[];
        coordinator.events.listen(events.add);

        await coordinator.transaction(
          (ctx) async {
            await ctx.save(userStore, TestFixtures.createUser(), idExtractor: (u) => u.id);
          },
          sagaId: 'custom-saga-id',
        );

        await Future.delayed(Duration(milliseconds: 10));

        final startEvent =
            events.firstWhere((e) => e.event == SagaEvent.sagaStarted);
        expect(startEvent.sagaId, equals('custom-saga-id'));
      });
    });

    group('dispose', () {
      test('disposes cleanly', () async {
        final c = NexusStoreCoordinator();
        await c.dispose();
        // Should not throw
      });

      test('prevents operations after dispose', () async {
        final c = NexusStoreCoordinator();
        await c.dispose();

        expect(
          () => c.transaction((ctx) async {}),
          throwsStateError,
        );
      });
    });
  });

  group('SagaTransactionContext', () {
    late FakeStoreBackend<TestUser, String> backend;
    late NexusStore<TestUser, String> store;
    late NexusStoreCoordinator coordinator;

    setUp(() async {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
      store = NexusStore<TestUser, String>(
        backend: backend,
        idExtractor: (user) => user.id,
      );
      await store.initialize();
      coordinator = NexusStoreCoordinator();
    });

    tearDown(() async {
      await coordinator.dispose();
      await store.dispose();
    });

    test('save returns saved item', () async {
      final user = TestFixtures.createUser();

      await coordinator.transaction((ctx) async {
        final saved = await ctx.save(store, user, idExtractor: (u) => u.id);
        expect(saved, equals(user));
      });
    });

    test('delete returns success boolean', () async {
      final user = TestFixtures.createUser();
      await store.save(user);

      await coordinator.transaction((ctx) async {
        final deleted = await ctx.delete(store, 'user-1');
        expect(deleted, isTrue);
      });
    });

    test('step returns action result', () async {
      await coordinator.transaction((ctx) async {
        final result = await ctx.step<int>(
          'compute',
          () async => 42,
          (result) async {},
        );
        expect(result, equals(42));
      });
    });
  });
}
