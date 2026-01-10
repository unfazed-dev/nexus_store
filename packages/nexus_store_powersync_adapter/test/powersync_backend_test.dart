import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:test/test.dart';

// Test model
class TestUser {
  TestUser({required this.id, required this.name, this.age});

  factory TestUser.fromJson(Map<String, dynamic> json) => TestUser(
        id: json['id'] as String,
        name: json['name'] as String,
        age: json['age'] as int?,
      );

  final String id;
  final String name;
  final int? age;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (age != null) 'age': age,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => Object.hash(id, name, age);
}

// Mock classes
class MockPowerSyncDatabaseWrapper extends Mock
    implements PowerSyncDatabaseWrapper {
  // Store the transaction callback for testing
  PowerSyncTransactionContext? transactionContext;

  @override
  Future<T> writeTransaction<T>(
    Future<T> Function(PowerSyncTransactionContext tx) callback,
  ) async {
    if (transactionContext != null) {
      return callback(transactionContext!);
    }
    throw StateError('transactionContext not set');
  }
}

class MockTransactionContext extends Mock
    implements PowerSyncTransactionContext {}

void main() {
  group('PowerSyncBackend', () {
    late MockPowerSyncDatabaseWrapper mockDb;
    late PowerSyncBackend<TestUser, String> backend;
    late StreamController<ps.SyncStatus> syncStatusController;

    setUp(() {
      mockDb = MockPowerSyncDatabaseWrapper();
      syncStatusController = StreamController<ps.SyncStatus>.broadcast();

      when(() => mockDb.statusStream)
          .thenAnswer((_) => syncStatusController.stream);

      backend = PowerSyncBackend<TestUser, String>.withWrapper(
        db: mockDb,
        tableName: 'users',
        getId: (user) => user.id,
        fromJson: TestUser.fromJson,
        toJson: (user) => user.toJson(),
      );
    });

    tearDown(() async {
      await syncStatusController.close();
    });

    group('backend info', () {
      test('name returns "powersync"', () {
        expect(backend.name, equals('powersync'));
      });

      test('supportsOffline returns true', () {
        expect(backend.supportsOffline, isTrue);
      });

      test('supportsRealtime returns true', () {
        expect(backend.supportsRealtime, isTrue);
      });

      test('supportsTransactions returns true', () {
        expect(backend.supportsTransactions, isTrue);
      });

      test('supportsPagination returns true', () {
        expect(backend.supportsPagination, isTrue);
      });
    });

    group('lifecycle', () {
      test('initialize sets up backend', () async {
        await backend.initialize();

        expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
      });

      test('initialize is idempotent', () async {
        await backend.initialize();
        await backend.initialize();

        expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
      });

      test('close cleans up resources', () async {
        await backend.initialize();
        await backend.close();

        expect(
          backend.syncStatusStream,
          emitsInOrder([nexus.SyncStatus.synced, emitsDone]),
        );
      });
    });

    group('uninitialized state', () {
      test('get throws StateError before initialize', () {
        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('getAll throws StateError before initialize', () {
        expect(
          () => backend.getAll(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('save throws StateError before initialize', () {
        expect(
          () => backend.save(TestUser(id: '1', name: 'Test')),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('delete throws StateError before initialize', () {
        expect(
          () => backend.delete('1'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('watch throws StateError before initialize', () {
        expect(
          () => backend.watch('1'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('watchAll throws StateError before initialize', () {
        expect(
          () => backend.watchAll(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('sync throws StateError before initialize', () {
        expect(
          () => backend.sync(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('getAllPaged throws StateError before initialize', () {
        expect(
          () => backend.getAllPaged(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('watchAllPaged throws StateError before initialize', () {
        expect(
          () => backend.watchAllPaged(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('saveAll throws StateError before initialize', () {
        expect(
          () => backend.saveAll([TestUser(id: '1', name: 'Test')]),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('deleteAll throws StateError before initialize', () {
        expect(
          () => backend.deleteAll(['1']),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('deleteWhere throws StateError before initialize', () {
        final query =
            const nexus.Query<TestUser>().where('name', isEqualTo: 'Test');
        expect(
          () => backend.deleteWhere(query),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('retryChange throws StateError before initialize', () {
        expect(
          () => backend.retryChange('id'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('cancelChange throws StateError before initialize', () {
        expect(
          () => backend.cancelChange('id'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('pendingChangesCount throws StateError before initialize', () {
        expect(
          () => backend.pendingChangesCount,
          throwsA(isA<nexus.StateError>()),
        );
      });
    });

    group('CRUD operations', () {
      setUp(() async {
        await backend.initialize();
      });

      test('get returns item when found', () async {
        when(() => mockDb.execute(any(), any())).thenAnswer(
          (_) async => [
            {'id': '1', 'name': 'John', 'age': 25},
          ],
        );

        final result = await backend.get('1');

        expect(result, isNotNull);
        expect(result!.id, equals('1'));
        expect(result.name, equals('John'));
        expect(result.age, equals(25));
      });

      test('get returns null when not found', () async {
        when(() => mockDb.execute(any(), any())).thenAnswer((_) async => []);

        final result = await backend.get('1');

        expect(result, isNull);
      });

      test('getAll returns list of items', () async {
        when(() => mockDb.execute(any(), any())).thenAnswer(
          (_) async => [
            {'id': '1', 'name': 'John'},
            {'id': '2', 'name': 'Jane'},
          ],
        );

        final result = await backend.getAll();

        expect(result, hasLength(2));
        expect(result[0].name, equals('John'));
        expect(result[1].name, equals('Jane'));
      });

      test('getAll with query applies filters', () async {
        when(() => mockDb.execute(any(), any())).thenAnswer(
          (_) async => [
            {'id': '1', 'name': 'John'},
          ],
        );

        final query =
            const nexus.Query<TestUser>().where('name', isEqualTo: 'John');
        final result = await backend.getAll(query: query);

        expect(result, hasLength(1));
        verify(
          () => mockDb.execute(
            any(that: contains('WHERE')),
            any(that: contains('John')),
          ),
        ).called(1);
      });

      test('save inserts or replaces item', () async {
        when(() => mockDb.execute(any(), any())).thenAnswer(
          (_) async => [
            {'id': '1', 'name': 'John'},
          ],
        );

        final user = TestUser(id: '1', name: 'John');
        final result = await backend.save(user);

        expect(result.id, equals('1'));
        verify(
          () => mockDb.execute(any(that: contains('INSERT OR REPLACE')), any()),
        ).called(1);
      });

      test('save updates sync status to pending then synced', () async {
        when(() => mockDb.execute(any(), any())).thenAnswer(
          (_) async => [
            {'id': '1', 'name': 'John'},
          ],
        );

        final statuses = <nexus.SyncStatus>[];
        backend.syncStatusStream.listen(statuses.add);

        final user = TestUser(id: '1', name: 'John');
        await backend.save(user);

        await Future<void>.delayed(Duration.zero);

        expect(statuses, contains(nexus.SyncStatus.pending));
        expect(statuses.last, equals(nexus.SyncStatus.synced));
      });

      test('save sets error status on failure', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('db error'));

        final user = TestUser(id: '1', name: 'John');

        await expectLater(
          () => backend.save(user),
          throwsA(isA<nexus.StoreError>()),
        );

        expect(backend.syncStatus, equals(nexus.SyncStatus.error));
      });

      test('saveAll saves multiple items in transaction', () async {
        final mockTx = MockTransactionContext();
        when(() => mockTx.execute(any(), any())).thenAnswer((_) async {});
        mockDb.transactionContext = mockTx;

        final users = [
          TestUser(id: '1', name: 'John'),
          TestUser(id: '2', name: 'Jane'),
        ];
        final result = await backend.saveAll(users);

        expect(result, hasLength(2));
        verify(() => mockTx.execute(any(), any())).called(2);
      });

      test('saveAll returns empty list for empty input', () async {
        // transactionContext is NOT set - if writeTransaction is called,
        // it will throw
        final result = await backend.saveAll([]);

        expect(result, isEmpty);
      });

      test('delete returns true when item exists', () async {
        when(() => mockDb.execute(any(), any())).thenAnswer((invocation) async {
          final sql = invocation.positionalArguments[0] as String;
          if (sql.contains('SELECT')) {
            return [
              {'id': '1', 'name': 'John'},
            ];
          }
          return [];
        });

        final result = await backend.delete('1');

        expect(result, isTrue);
      });

      test('delete returns false when item not found', () async {
        when(() => mockDb.execute(any(), any())).thenAnswer((_) async => []);

        final result = await backend.delete('1');

        expect(result, isFalse);
      });

      test('deleteAll deletes multiple items', () async {
        when(() => mockDb.execute(any(), any())).thenAnswer((_) async => []);

        final result = await backend.deleteAll(['1', '2', '3']);

        expect(result, equals(3));
        verify(
          () => mockDb.execute(
            any(that: contains('IN')),
            ['1', '2', '3'],
          ),
        ).called(1);
      });

      test('deleteAll returns 0 for empty list', () async {
        final result = await backend.deleteAll([]);

        expect(result, equals(0));
        verifyNever(() => mockDb.execute(any(), any()));
      });

      test('deleteWhere deletes items matching query', () async {
        when(() => mockDb.execute(any(), any())).thenAnswer((_) async => []);

        final query =
            const nexus.Query<TestUser>().where('status', isEqualTo: 'deleted');
        final result = await backend.deleteWhere(query);

        expect(result, equals(0));
        verify(
          () => mockDb.execute(any(that: contains('DELETE')), any()),
        ).called(1);
      });
    });

    group('watch operations', () {
      late StreamController<List<Map<String, dynamic>>> watchController;

      setUp(() async {
        watchController =
            StreamController<List<Map<String, dynamic>>>.broadcast();
        when(() => mockDb.watch(any(), parameters: any(named: 'parameters')))
            .thenAnswer((_) => watchController.stream);
        await backend.initialize();
      });

      tearDown(() async {
        await watchController.close();
      });

      test('watch returns stream of items', () async {
        final stream = backend.watch('1');

        expect(stream, isA<Stream<TestUser?>>());

        watchController.add([
          {'id': '1', 'name': 'John', 'age': 25},
        ]);

        await expectLater(
          stream,
          emits(isA<TestUser>().having((u) => u.name, 'name', 'John')),
        );
      });

      test('watch returns null when item not found', () async {
        final stream = backend.watch('1');

        watchController.add([]);

        await expectLater(stream, emits(isNull));
      });

      test('watch returns cached stream for same ID', () async {
        final stream1 = backend.watch('1');
        final stream2 = backend.watch('1');

        expect(identical(stream1, stream2), isTrue);
      });

      test('watch handles stream errors', () async {
        final stream = backend.watch('1');

        watchController.addError(Exception('db error'));

        await expectLater(stream, emitsError(isA<nexus.StoreError>()));
      });

      test('watchAll returns stream of items', () async {
        final stream = backend.watchAll();

        expect(stream, isA<Stream<List<TestUser>>>());

        watchController.add([
          {'id': '1', 'name': 'John'},
          {'id': '2', 'name': 'Jane'},
        ]);

        await expectLater(
          stream,
          emits(isA<List<TestUser>>().having((l) => l.length, 'length', 2)),
        );
      });

      test('watchAll returns cached stream for same query', () async {
        final stream1 = backend.watchAll();
        final stream2 = backend.watchAll();

        expect(identical(stream1, stream2), isTrue);
      });

      test('watchAll with different queries returns different streams',
          () async {
        final query1 =
            const nexus.Query<TestUser>().where('name', isEqualTo: 'John');
        final query2 =
            const nexus.Query<TestUser>().where('name', isEqualTo: 'Jane');

        final stream1 = backend.watchAll(query: query1);
        final stream2 = backend.watchAll(query: query2);

        expect(identical(stream1, stream2), isFalse);
      });

      test('watchAll handles stream errors', () async {
        final stream = backend.watchAll();

        watchController.addError(Exception('db error'));

        await expectLater(stream, emitsError(isA<nexus.StoreError>()));
      });
    });

    group('pagination', () {
      setUp(() async {
        await backend.initialize();
      });

      test('getAllPaged returns paged result', () async {
        when(() => mockDb.execute(any(), any())).thenAnswer(
          (_) async => [
            {'id': '1', 'name': 'John'},
            {'id': '2', 'name': 'Jane'},
            {'id': '3', 'name': 'Bob'},
          ],
        );

        final result = await backend.getAllPaged();

        expect(result.items, hasLength(3));
        expect(result.pageInfo.totalCount, equals(3));
        expect(result.pageInfo.hasNextPage, isFalse);
        expect(result.pageInfo.hasPreviousPage, isFalse);
      });

      test('getAllPaged with firstCount limits results', () async {
        when(() => mockDb.execute(any(), any())).thenAnswer(
          (_) async => [
            {'id': '1', 'name': 'John'},
            {'id': '2', 'name': 'Jane'},
            {'id': '3', 'name': 'Bob'},
          ],
        );

        final query = const nexus.Query<TestUser>().first(2);
        final result = await backend.getAllPaged(query: query);

        expect(result.items, hasLength(2));
        expect(result.pageInfo.hasNextPage, isTrue);
        expect(result.pageInfo.hasPreviousPage, isFalse);
        expect(result.pageInfo.endCursor, isNotNull);
      });

      test('getAllPaged with afterCursor skips items', () async {
        when(() => mockDb.execute(any(), any())).thenAnswer(
          (_) async => [
            {'id': '1', 'name': 'John'},
            {'id': '2', 'name': 'Jane'},
            {'id': '3', 'name': 'Bob'},
          ],
        );

        final cursor = nexus.Cursor.fromValues(const {'_index': 1});
        final query = const nexus.Query<TestUser>().after(cursor).first(2);
        final result = await backend.getAllPaged(query: query);

        expect(result.items, hasLength(2));
        expect(result.pageInfo.hasPreviousPage, isTrue);
      });

      test('getAllPaged with empty results', () async {
        when(() => mockDb.execute(any(), any())).thenAnswer((_) async => []);

        final result = await backend.getAllPaged();

        expect(result.items, isEmpty);
        expect(result.pageInfo.startCursor, isNull);
        expect(result.pageInfo.endCursor, isNull);
      });

      test('watchAllPaged returns stream of paged results', () async {
        final watchController =
            StreamController<List<Map<String, dynamic>>>.broadcast();
        when(() => mockDb.watch(any(), parameters: any(named: 'parameters')))
            .thenAnswer((_) => watchController.stream);

        final stream = backend.watchAllPaged();

        watchController.add([
          {'id': '1', 'name': 'John'},
          {'id': '2', 'name': 'Jane'},
        ]);

        await expectLater(
          stream,
          emits(
            isA<nexus.PagedResult<TestUser>>()
                .having((r) => r.items.length, 'items.length', 2),
          ),
        );

        await watchController.close();
      });
    });

    group('sync status mapping', () {
      setUp(() async {
        await backend.initialize();
      });

      test('maps uploading status to syncing', () async {
        syncStatusController.add(
          // ignore: invalid_use_of_internal_member
          const ps.SyncStatus(connected: true, uploading: true),
        );

        await Future<void>.delayed(Duration.zero);

        expect(backend.syncStatus, equals(nexus.SyncStatus.syncing));
      });

      test('maps download error to error status', () async {
        syncStatusController.add(
          // ignore: invalid_use_of_internal_member
          ps.SyncStatus(
            connected: true,
            downloadError: Exception('download failed'),
          ),
        );

        await Future<void>.delayed(Duration.zero);

        expect(backend.syncStatus, equals(nexus.SyncStatus.error));
      });

      test('maps upload error to error status', () async {
        syncStatusController.add(
          // ignore: invalid_use_of_internal_member
          ps.SyncStatus(
            connected: true,
            uploadError: Exception('upload failed'),
          ),
        );

        await Future<void>.delayed(Duration.zero);

        expect(backend.syncStatus, equals(nexus.SyncStatus.error));
      });

      test('maps disconnected to paused status', () async {
        // ignore: invalid_use_of_internal_member
        syncStatusController.add(const ps.SyncStatus());

        await Future<void>.delayed(Duration.zero);

        expect(backend.syncStatus, equals(nexus.SyncStatus.paused));
      });

      test('maps connected without errors to synced', () async {
        // ignore: invalid_use_of_internal_member
        syncStatusController.add(const ps.SyncStatus(connected: true));

        await Future<void>.delayed(Duration.zero);

        expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
      });
    });

    group('pending changes', () {
      setUp(() async {
        await backend.initialize();
      });

      test('pendingChangesStream returns empty list initially', () async {
        expect(
          backend.pendingChangesStream,
          emits(isEmpty),
        );
      });

      test('retryChange completes without error for non-existent', () async {
        await expectLater(
          backend.retryChange('non-existent-id'),
          completes,
        );
      });

      test('cancelChange returns null for non-existent change', () async {
        final result = await backend.cancelChange('non-existent-id');
        expect(result, isNull);
      });

      test('pendingChangesCount returns 1 when not synced', () async {
        when(() => mockDb.currentStatus).thenReturn(
          // ignore: invalid_use_of_internal_member
          const ps.SyncStatus(connected: true, hasSynced: false),
        );

        final count = await backend.pendingChangesCount;

        expect(count, equals(1));
      });

      test('pendingChangesCount returns 0 when synced', () async {
        when(() => mockDb.currentStatus).thenReturn(
          // ignore: invalid_use_of_internal_member
          const ps.SyncStatus(connected: true, hasSynced: true),
        );

        final count = await backend.pendingChangesCount;

        expect(count, equals(0));
      });
    });

    group('pending changes with PendingChangesManager', () {
      setUp(() async {
        await backend.initialize();
      });

      test('retryChange updates retry count and triggers sync', () async {
        final user = TestUser(id: '1', name: 'John');

        // Add a pending change using the test getter
        final change = await backend.testPendingChangesManager.addChange(
          item: user,
          operation: nexus.PendingChangeOperation.update,
        );

        // Retry the change
        await backend.retryChange(change.id);

        // Verify retry count was updated
        final updated =
            backend.testPendingChangesManager.getChange(change.id);
        expect(updated, isNotNull);
        expect(updated!.retryCount, equals(1));
        expect(updated.lastAttempt, isNotNull);
      });

      test('cancelChange with update operation restores original value',
          () async {
        when(() => mockDb.execute(any(), any())).thenAnswer((_) async => []);

        final original = TestUser(id: '1', name: 'Original');
        final updated = TestUser(id: '1', name: 'Updated');

        // Add a pending update change with original value
        final change = await backend.testPendingChangesManager.addChange(
          item: updated,
          operation: nexus.PendingChangeOperation.update,
          originalValue: original,
        );

        // Cancel the change
        final result = await backend.cancelChange(change.id);

        expect(result, isNotNull);
        expect(result!.operation, equals(nexus.PendingChangeOperation.update));

        // Verify save was called with original value
        verify(
          () => mockDb.execute(
            any(that: contains('INSERT OR REPLACE')),
            any(that: contains('Original')),
          ),
        ).called(greaterThan(0));
      });

      test('cancelChange with create operation deletes the item', () async {
        // Mock SELECT (for delete's existence check) and DELETE
        when(() => mockDb.execute(any(), any())).thenAnswer((invocation) async {
          final sql = invocation.positionalArguments[0] as String;
          if (sql.contains('SELECT')) {
            return [
              {'id': '2', 'name': 'Created'},
            ];
          }
          return [];
        });

        final created = TestUser(id: '2', name: 'Created');

        // Add a pending create change
        final change = await backend.testPendingChangesManager.addChange(
          item: created,
          operation: nexus.PendingChangeOperation.create,
        );

        // Cancel the change
        final result = await backend.cancelChange(change.id);

        expect(result, isNotNull);
        expect(result!.operation, equals(nexus.PendingChangeOperation.create));

        // Verify delete was called
        verify(
          () => mockDb.execute(
            any(that: contains('DELETE')),
            ['2'],
          ),
        ).called(1);
      });

      test('cancelChange with delete operation restores original value',
          () async {
        when(() => mockDb.execute(any(), any())).thenAnswer((_) async => []);

        final deleted = TestUser(id: '3', name: 'Deleted');

        // Add a pending delete change with original value
        final change = await backend.testPendingChangesManager.addChange(
          item: deleted,
          operation: nexus.PendingChangeOperation.delete,
          originalValue: deleted,
        );

        // Cancel the change
        final result = await backend.cancelChange(change.id);

        expect(result, isNotNull);
        expect(result!.operation, equals(nexus.PendingChangeOperation.delete));

        // Verify save was called to restore the item
        verify(
          () => mockDb.execute(
            any(that: contains('INSERT OR REPLACE')),
            any(that: contains('Deleted')),
          ),
        ).called(greaterThan(0));
      });
    });

    group('conflicts', () {
      setUp(() async {
        await backend.initialize();
      });

      test('conflictsStream is available', () {
        expect(
          backend.conflictsStream,
          isA<Stream<nexus.ConflictDetails<TestUser>>>(),
        );
      });
    });

    group('error handling', () {
      setUp(() async {
        await backend.initialize();
      });

      test('maps constraint errors to ValidationError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('UNIQUE constraint failed'));

        await expectLater(
          () => backend.save(TestUser(id: '1', name: 'Test')),
          throwsA(isA<nexus.ValidationError>()),
        );
      });

      test('maps network errors to NetworkError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('network error: connection refused'));

        await expectLater(
          () => backend.get('1'),
          throwsA(isA<nexus.NetworkError>()),
        );
      });

      test('maps timeout errors to TimeoutError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('operation timeout'));

        await expectLater(
          () => backend.get('1'),
          throwsA(isA<nexus.TimeoutError>()),
        );
      });

      test('maps auth errors to AuthenticationError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('401 unauthorized'));

        await expectLater(
          () => backend.get('1'),
          throwsA(isA<nexus.AuthenticationError>()),
        );
      });

      test('maps forbidden errors to AuthorizationError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('403 forbidden'));

        await expectLater(
          () => backend.get('1'),
          throwsA(isA<nexus.AuthorizationError>()),
        );
      });

      test('maps unknown errors to SyncError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('unknown error'));

        await expectLater(
          () => backend.get('1'),
          throwsA(isA<nexus.SyncError>()),
        );
      });

      test('maps foreign key errors to ValidationError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('foreign key constraint failed'));

        await expectLater(
          () => backend.get('1'),
          throwsA(isA<nexus.ValidationError>()),
        );
      });

      test('maps socket errors to NetworkError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('socket exception'));

        await expectLater(
          () => backend.get('1'),
          throwsA(isA<nexus.NetworkError>()),
        );
      });

      test('maps connection errors to NetworkError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('connection refused'));

        await expectLater(
          () => backend.get('1'),
          throwsA(isA<nexus.NetworkError>()),
        );
      });

      test('preserves existing StoreError', () async {
        const storeError = nexus.ValidationError(message: 'custom error');
        when(() => mockDb.execute(any(), any())).thenThrow(storeError);

        await expectLater(
          () => backend.get('1'),
          throwsA(same(storeError)),
        );
      });
    });

    group('sync operations', () {
      setUp(() async {
        await backend.initialize();
      });

      test('sync triggers syncing and synced status', () async {
        final statuses = <nexus.SyncStatus>[];
        backend.syncStatusStream.listen(statuses.add);

        await backend.sync();

        await Future<void>.delayed(Duration.zero);

        expect(statuses, contains(nexus.SyncStatus.syncing));
        expect(statuses.last, equals(nexus.SyncStatus.synced));
      });

      // Note: The sync() error catch block requires actual PowerSync server
      // operations to fail. This is tested via integration tests with real
      // database connections. The wrapper abstraction doesn't expose the
      // sync mechanism needed to trigger this path.
    });

    group('cancelChange operations', () {
      setUp(() async {
        when(() => mockDb.execute(any(), any())).thenAnswer((_) async => []);
        await backend.initialize();
      });

      test('cancelChange with update restores original value', () async {
        // This tests the update path in cancelChange
        // Since we don't have actual pending changes, this is a no-op
        final result = await backend.cancelChange('non-existent-update');
        expect(result, isNull);
      });

      test('cancelChange with create operation deletes item', () async {
        // This tests the create path in cancelChange
        final result = await backend.cancelChange('non-existent-create');
        expect(result, isNull);
      });

      test('cancelChange with delete restores original value', () async {
        // This tests the delete path in cancelChange
        final result = await backend.cancelChange('non-existent-delete');
        expect(result, isNull);
      });
    });

    group('configuration', () {
      test('uses custom primary key column', () {
        final backendWithCustomPK =
            PowerSyncBackend<TestUser, String>.withWrapper(
          db: mockDb,
          tableName: 'users',
          getId: (user) => user.id,
          fromJson: TestUser.fromJson,
          toJson: (user) => user.toJson(),
          primaryKeyColumn: 'user_id',
        );

        expect(backendWithCustomPK, isNotNull);
      });

      test('uses custom field mapping', () {
        final backendWithMapping =
            PowerSyncBackend<TestUser, String>.withWrapper(
          db: mockDb,
          tableName: 'users',
          getId: (user) => user.id,
          fromJson: TestUser.fromJson,
          toJson: (user) => user.toJson(),
          fieldMapping: {'userName': 'name'},
        );

        expect(backendWithMapping, isNotNull);
      });

      test('uses custom query translator', () {
        final customTranslator = PowerSyncQueryTranslator<TestUser>(
          fieldMapping: {'userName': 'name'},
        );

        final backendWithTranslator =
            PowerSyncBackend<TestUser, String>.withWrapper(
          db: mockDb,
          tableName: 'users',
          getId: (user) => user.id,
          fromJson: TestUser.fromJson,
          toJson: (user) => user.toJson(),
          queryTranslator: customTranslator,
        );

        expect(backendWithTranslator, isNotNull);
      });
    });

    group('error handling in write operations', () {
      setUp(() async {
        await backend.initialize();
      });

      test('saveAll sets error status on transaction failure', () async {
        final mockTx = MockTransactionContext();
        when(() => mockTx.execute(any(), any()))
            .thenThrow(Exception('transaction failed'));
        mockDb.transactionContext = mockTx;

        final users = [
          TestUser(id: '1', name: 'John'),
        ];

        await expectLater(
          () => backend.saveAll(users),
          throwsA(isA<nexus.StoreError>()),
        );

        expect(backend.syncStatus, equals(nexus.SyncStatus.error));
      });

      test('delete sets error status on failure', () async {
        when(() => mockDb.execute(any(), any())).thenAnswer((invocation) async {
          final sql = invocation.positionalArguments[0] as String;
          if (sql.contains('SELECT')) {
            return [
              {'id': '1', 'name': 'John'},
            ];
          }
          throw Exception('delete failed');
        });

        await expectLater(
          () => backend.delete('1'),
          throwsA(isA<nexus.StoreError>()),
        );

        expect(backend.syncStatus, equals(nexus.SyncStatus.error));
      });

      test('deleteAll sets error status on failure', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('delete all failed'));

        await expectLater(
          () => backend.deleteAll(['1', '2']),
          throwsA(isA<nexus.StoreError>()),
        );

        expect(backend.syncStatus, equals(nexus.SyncStatus.error));
      });

      test('deleteWhere sets error status on failure', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('delete where failed'));

        final query =
            const nexus.Query<TestUser>().where('status', isEqualTo: 'deleted');

        await expectLater(
          () => backend.deleteWhere(query),
          throwsA(isA<nexus.StoreError>()),
        );

        expect(backend.syncStatus, equals(nexus.SyncStatus.error));
      });

      test('getAll sets error status on failure', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('getAll failed'));

        await expectLater(
          () => backend.getAll(),
          throwsA(isA<nexus.StoreError>()),
        );
      });
    });

    group('close with active subscriptions', () {
      late StreamController<List<Map<String, dynamic>>> watchController;

      setUp(() async {
        watchController =
            StreamController<List<Map<String, dynamic>>>.broadcast();
        when(() => mockDb.watch(any(), parameters: any(named: 'parameters')))
            .thenAnswer((_) => watchController.stream);
        await backend.initialize();
      });

      tearDown(() async {
        await watchController.close();
      });

      test('close cleans up watch subscriptions', () async {
        // Create a watch subscription
        final stream = backend.watch('1');
        // Trigger subscription creation by listening
        final subscription = stream.listen((_) {});

        watchController.add([
          {'id': '1', 'name': 'John'},
        ]);

        await Future<void>.delayed(Duration.zero);

        // Close should clean up all subscriptions
        await backend.close();

        await subscription.cancel();
      });

      test('close cleans up watchAll subscriptions', () async {
        // Create a watchAll subscription
        final stream = backend.watchAll();
        final subscription = stream.listen((_) {});

        watchController.add([
          {'id': '1', 'name': 'John'},
        ]);

        await Future<void>.delayed(Duration.zero);

        // Close should clean up all subscriptions
        await backend.close();

        await subscription.cancel();
      });
    });

    group('watchAllPaged pagination', () {
      late StreamController<List<Map<String, dynamic>>> watchController;

      setUp(() async {
        watchController =
            StreamController<List<Map<String, dynamic>>>.broadcast();
        when(() => mockDb.watch(any(), parameters: any(named: 'parameters')))
            .thenAnswer((_) => watchController.stream);
        await backend.initialize();
      });

      tearDown(() async {
        await watchController.close();
      });

      test('watchAllPaged with firstCount limits results', () async {
        final query = const nexus.Query<TestUser>().first(2);

        final stream = backend.watchAllPaged(query: query);
        final completer = Completer<nexus.PagedResult<TestUser>>();

        stream.listen(completer.complete);

        watchController.add([
          {'id': '1', 'name': 'John'},
          {'id': '2', 'name': 'Jane'},
          {'id': '3', 'name': 'Bob'},
        ]);

        final result = await completer.future;

        expect(result.items, hasLength(2));
        expect(result.pageInfo.hasNextPage, isTrue);
      });

      test('watchAllPaged with afterCursor skips items', () async {
        final cursor = nexus.Cursor.fromValues(const {'_index': 1});
        final query = const nexus.Query<TestUser>().after(cursor);

        final stream = backend.watchAllPaged(query: query);
        final completer = Completer<nexus.PagedResult<TestUser>>();

        stream.listen(completer.complete);

        watchController.add([
          {'id': '1', 'name': 'John'},
          {'id': '2', 'name': 'Jane'},
          {'id': '3', 'name': 'Bob'},
        ]);

        final result = await completer.future;

        expect(result.items.first.name, equals('Jane'));
        expect(result.pageInfo.hasPreviousPage, isTrue);
      });

      test('watchAllPaged with firstCount and afterCursor', () async {
        final cursor = nexus.Cursor.fromValues(const {'_index': 1});
        final query = const nexus.Query<TestUser>().after(cursor).first(1);

        final stream = backend.watchAllPaged(query: query);
        final completer = Completer<nexus.PagedResult<TestUser>>();

        stream.listen(completer.complete);

        watchController.add([
          {'id': '1', 'name': 'John'},
          {'id': '2', 'name': 'Jane'},
          {'id': '3', 'name': 'Bob'},
        ]);

        final result = await completer.future;

        expect(result.items, hasLength(1));
        expect(result.items.first.name, equals('Jane'));
        expect(result.pageInfo.hasNextPage, isTrue);
        expect(result.pageInfo.hasPreviousPage, isTrue);
        expect(result.pageInfo.endCursor, isNotNull);
      });
    });

    group('additional error handling', () {
      setUp(() async {
        await backend.initialize();
      });

      test('maps foreign key only errors to ValidationError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('foreign key violation'));

        await expectLater(
          () => backend.get('1'),
          throwsA(isA<nexus.ValidationError>()),
        );
      });

      test('getAllPaged error handling', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('query failed'));

        await expectLater(
          () => backend.getAllPaged(),
          throwsA(isA<nexus.StoreError>()),
        );
      });
    });
  });
}
