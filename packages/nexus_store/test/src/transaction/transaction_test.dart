import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('Transaction', () {
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

    group('basic operations', () {
      test('transaction with single save commits', () async {
        final user = TestFixtures.createUser();

        await store.transaction((tx) async {
          await tx.save(user);
        });

        final saved = await store.get('user-1');
        expect(saved, equals(user));
      });

      test('transaction with multiple saves commits atomically', () async {
        final users = TestFixtures.createUsers(3);

        await store.transaction((tx) async {
          await tx.saveAll(users);
        });

        final results = await store.getAll();
        expect(results.length, equals(3));
      });

      test('transaction with failure rolls back all operations', () async {
        final user1 = TestFixtures.createUser(id: 'user-1');
        final user2 = TestFixtures.createUser(id: 'user-2');

        try {
          await store.transaction((tx) async {
            await tx.save(user1);
            await tx.save(user2);
            throw Exception('Simulated failure');
          });
        } catch (_) {}

        expect(await store.get('user-1'), isNull);
        expect(await store.get('user-2'), isNull);
      });

      test('transaction returns callback result', () async {
        final user = TestFixtures.createUser();

        final result = await store.transaction((tx) async {
          await tx.save(user);
          return user.id;
        });

        expect(result, equals('user-1'));
      });
    });

    group('delete operations', () {
      test('transaction delete removes item on commit', () async {
        final user = TestFixtures.createUser();
        await store.save(user);

        await store.transaction((tx) async {
          await tx.delete('user-1');
        });

        expect(await store.get('user-1'), isNull);
      });

      test('transaction delete restores item on rollback', () async {
        final user = TestFixtures.createUser();
        await store.save(user);

        try {
          await store.transaction((tx) async {
            await tx.delete('user-1');
            throw Exception('Rollback');
          });
        } catch (_) {}

        final restored = await store.get('user-1');
        expect(restored, equals(user));
      });

      test('transaction deleteAll removes multiple items on commit', () async {
        final users = TestFixtures.createUsers(3);
        for (final user in users) {
          await store.save(user);
        }

        await store.transaction((tx) async {
          await tx.deleteAll(['user-0', 'user-1', 'user-2']);
        });

        expect(await store.get('user-0'), isNull);
        expect(await store.get('user-1'), isNull);
        expect(await store.get('user-2'), isNull);
      });
    });

    group('update operations', () {
      test('transaction update restores original on rollback', () async {
        final originalUser = TestFixtures.createUser(name: 'Original');
        await store.save(originalUser);

        try {
          await store.transaction((tx) async {
            final updatedUser = originalUser.copyWith(name: 'Updated');
            await tx.save(updatedUser);
            throw Exception('Rollback');
          });
        } catch (_) {}

        final restored = await store.get('user-1');
        expect(restored?.name, equals('Original'));
      });
    });

    group('nested transactions (savepoints)', () {
      test('nested transaction rollback affects inner scope only', () async {
        final outerUser = TestFixtures.createUser(id: 'outer');
        final innerUser = TestFixtures.createUser(id: 'inner');

        await store.transaction((outerTx) async {
          await outerTx.save(outerUser);

          try {
            await store.transaction((innerTx) async {
              await innerTx.save(innerUser);
              throw Exception('Inner failure');
            });
          } catch (_) {
            // Inner rolled back, outer continues
          }
        });

        expect(await store.get('outer'), equals(outerUser));
        expect(await store.get('inner'), isNull);
      });

      test('nested transaction success commits with outer', () async {
        final outerUser = TestFixtures.createUser(id: 'outer');
        final innerUser = TestFixtures.createUser(id: 'inner');

        await store.transaction((outerTx) async {
          await outerTx.save(outerUser);

          await store.transaction((innerTx) async {
            await innerTx.save(innerUser);
          });
        });

        expect(await store.get('outer'), equals(outerUser));
        expect(await store.get('inner'), equals(innerUser));
      });
    });

    group('context isolation', () {
      test('transaction context is isolated per transaction', () async {
        final user1 = TestFixtures.createUser(id: 'user-1');
        final user2 = TestFixtures.createUser(id: 'user-2');

        // Two transactions should not interfere
        await store.transaction((tx) async {
          await tx.save(user1);
        });

        await store.transaction((tx) async {
          await tx.save(user2);
        });

        expect(await store.get('user-1'), isNotNull);
        expect(await store.get('user-2'), isNotNull);
      });

      test('first transaction rollback does not affect second', () async {
        final user1 = TestFixtures.createUser(id: 'user-1');
        final user2 = TestFixtures.createUser(id: 'user-2');

        try {
          await store.transaction((tx) async {
            await tx.save(user1);
            throw Exception('Rollback first');
          });
        } catch (_) {}

        await store.transaction((tx) async {
          await tx.save(user2);
        });

        expect(await store.get('user-1'), isNull);
        expect(await store.get('user-2'), isNotNull);
      });
    });

    group('error handling', () {
      test('throws TransactionError with wasRolledBack flag', () async {
        try {
          await store.transaction((tx) async {
            await tx.save(TestFixtures.createUser());
            throw Exception('Test error');
          });
          fail('Should have thrown');
        } on TransactionError catch (e) {
          expect(e.wasRolledBack, isTrue);
          expect(e.message, contains('Transaction failed'));
        }
      });

      test('prevents operations on committed transaction', () async {
        Transaction<TestUser, String>? capturedTx;

        await store.transaction((tx) async {
          capturedTx = tx;
          await tx.save(TestFixtures.createUser());
        });

        expect(
          () => capturedTx!.save(TestFixtures.createUser(id: 'user-2')),
          throwsA(isA<TransactionError>()),
        );
      });

      test('prevents operations on rolled back transaction', () async {
        Transaction<TestUser, String>? capturedTx;

        try {
          await store.transaction((tx) async {
            capturedTx = tx;
            throw Exception('Force rollback');
          });
        } catch (_) {}

        expect(
          () => capturedTx!.save(TestFixtures.createUser()),
          throwsA(isA<TransactionError>()),
        );
      });
    });

    group('mixed operations', () {
      test('transaction with saves and deletes commits correctly', () async {
        final existingUser = TestFixtures.createUser(id: 'existing');
        await store.save(existingUser);

        final newUser = TestFixtures.createUser(id: 'new');

        await store.transaction((tx) async {
          await tx.save(newUser);
          await tx.delete('existing');
        });

        expect(await store.get('new'), equals(newUser));
        expect(await store.get('existing'), isNull);
      });

      test('transaction with saves and deletes rolls back correctly', () async {
        final existingUser = TestFixtures.createUser(id: 'existing');
        await store.save(existingUser);

        final newUser = TestFixtures.createUser(id: 'new');

        try {
          await store.transaction((tx) async {
            await tx.save(newUser);
            await tx.delete('existing');
            throw Exception('Rollback');
          });
        } catch (_) {}

        expect(await store.get('new'), isNull);
        expect(await store.get('existing'), equals(existingUser));
      });
    });
  });

  group('TransactionOperation', () {
    test('SaveOperation isInsert when no original value', () {
      final op = SaveOperation<TestUser, String>(
        item: TestFixtures.createUser(),
        id: 'user-1',
        originalValue: null,
        timestamp: DateTime.now(),
      );
      expect(op.isInsert, isTrue);
      expect(op.isUpdate, isFalse);
    });

    test('SaveOperation isUpdate when has original value', () {
      final op = SaveOperation<TestUser, String>(
        item: TestFixtures.createUser(),
        id: 'user-1',
        originalValue: TestFixtures.createUser(name: 'Original'),
        timestamp: DateTime.now(),
      );
      expect(op.isInsert, isFalse);
      expect(op.isUpdate, isTrue);
    });

    test('DeleteOperation hadValue when original exists', () {
      final op = DeleteOperation<TestUser, String>(
        id: 'user-1',
        originalValue: TestFixtures.createUser(),
        timestamp: DateTime.now(),
      );
      expect(op.hadValue, isTrue);
    });

    test('DeleteOperation hadValue is false when no original', () {
      final op = DeleteOperation<TestUser, String>(
        id: 'user-1',
        originalValue: null,
        timestamp: DateTime.now(),
      );
      expect(op.hadValue, isFalse);
    });
  });

  group('TransactionContext', () {
    test('creates with unique id and timestamp', () {
      final context = TransactionContext<TestUser, String>(id: 'tx-1');
      expect(context.id, equals('tx-1'));
      expect(context.startedAt, isNotNull);
      expect(context.isActive, isTrue);
    });

    test('isNested when has parent context', () {
      final parent = TransactionContext<TestUser, String>(id: 'parent');
      final child = TransactionContext<TestUser, String>(
        id: 'child',
        parentContext: parent,
      );
      expect(parent.isNested, isFalse);
      expect(child.isNested, isTrue);
    });

    test('depth tracks nesting level', () {
      final parent = TransactionContext<TestUser, String>(id: 'parent');
      final child = TransactionContext<TestUser, String>(
        id: 'child',
        parentContext: parent,
      );
      final grandchild = TransactionContext<TestUser, String>(
        id: 'grandchild',
        parentContext: child,
      );
      expect(parent.depth, equals(0));
      expect(child.depth, equals(1));
      expect(grandchild.depth, equals(2));
    });

    test('createSavepoint marks position in operations', () {
      final context = TransactionContext<TestUser, String>(id: 'tx-1');
      context.operations.add(SaveOperation(
        item: TestFixtures.createUser(id: 'user-1'),
        id: 'user-1',
        timestamp: DateTime.now(),
      ));
      final savepoint = context.createSavepoint();
      context.operations.add(SaveOperation(
        item: TestFixtures.createUser(id: 'user-2'),
        id: 'user-2',
        timestamp: DateTime.now(),
      ));

      expect(savepoint, equals(1));
      expect(context.operations.length, equals(2));
      expect(context.savepoints, contains(1));
    });

    test('rollbackToSavepoint removes operations after savepoint', () {
      final context = TransactionContext<TestUser, String>(id: 'tx-1');
      context.operations.add(SaveOperation(
        item: TestFixtures.createUser(id: 'user-1'),
        id: 'user-1',
        timestamp: DateTime.now(),
      ));
      final savepoint = context.createSavepoint();
      context.operations.add(SaveOperation(
        item: TestFixtures.createUser(id: 'user-2'),
        id: 'user-2',
        timestamp: DateTime.now(),
      ));
      context.operations.add(SaveOperation(
        item: TestFixtures.createUser(id: 'user-3'),
        id: 'user-3',
        timestamp: DateTime.now(),
      ));

      final rolledBack = context.rollbackToSavepoint(savepoint);

      expect(rolledBack.length, equals(2));
      expect(context.operations.length, equals(1));
    });

    test('isActive is false after commit', () {
      final context = TransactionContext<TestUser, String>(id: 'tx-1');
      context.isCommitted = true;
      expect(context.isActive, isFalse);
    });

    test('isActive is false after rollback', () {
      final context = TransactionContext<TestUser, String>(id: 'tx-1');
      context.isRolledBack = true;
      expect(context.isActive, isFalse);
    });
  });
}
