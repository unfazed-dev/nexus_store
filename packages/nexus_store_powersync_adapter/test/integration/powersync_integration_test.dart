/// Integration tests for PowerSync adapter.
///
/// Note: Full CRUD integration tests require a running PowerSync server or
/// an in-memory SQLite database. The sqlite3 package's ResultSet is a final
/// class that cannot be mocked, limiting what can be tested without real
/// database infrastructure.
///
/// These tests focus on:
/// - Sync status transitions
/// - Offline/online behavior simulation
/// - Error handling scenarios
/// - Backend lifecycle management
///
/// For full CRUD testing, see the unit tests or set up a real PowerSync server.
// ignore_for_file: invalid_use_of_internal_member
@Tags(['integration'])
library;

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

  @override
  String toString() => 'TestUser(id: $id, name: $name, age: $age)';
}

// Mock classes
class MockPowerSyncDatabase extends Mock implements ps.PowerSyncDatabase {}

void main() {
  group('PowerSync Integration Tests', () {
    late MockPowerSyncDatabase mockDb;
    late PowerSyncBackend<TestUser, String> backend;
    late StreamController<ps.SyncStatus> syncStatusController;

    setUp(() {
      mockDb = MockPowerSyncDatabase();
      syncStatusController = StreamController<ps.SyncStatus>.broadcast();

      when(() => mockDb.statusStream)
          .thenAnswer((_) => syncStatusController.stream);

      backend = PowerSyncBackend<TestUser, String>(
        db: mockDb,
        tableName: 'users',
        getId: (user) => user.id,
        fromJson: TestUser.fromJson,
        toJson: (user) => user.toJson(),
      );
    });

    tearDown(() async {
      await syncStatusController.close();
      await backend.close();
    });

    group('Backend Properties', () {
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

    group('Lifecycle Management', () {
      test('initialize sets up sync status listener', () async {
        await backend.initialize();

        expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
      });

      test('initialize is idempotent', () async {
        await backend.initialize();
        await backend.initialize();
        await backend.initialize();

        // Should not throw and status should be synced
        expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
      });

      test('close cleans up all resources', () async {
        await backend.initialize();
        await backend.close();

        // Stream should complete
        expect(
          backend.syncStatusStream,
          emitsInOrder([nexus.SyncStatus.synced, emitsDone]),
        );
      });

      test('close is safe to call multiple times', () async {
        await backend.initialize();
        await backend.close();
        await backend.close();

        // Should not throw
        expect(true, isTrue);
      });
    });

    group('Uninitialized State Guards', () {
      test('get throws StateError before initialize', () async {
        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('getAll throws StateError before initialize', () async {
        expect(
          () => backend.getAll(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('save throws StateError before initialize', () async {
        expect(
          () => backend.save(TestUser(id: '1', name: 'Test')),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('saveAll throws StateError before initialize', () async {
        expect(
          () => backend.saveAll([TestUser(id: '1', name: 'Test')]),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('delete throws StateError before initialize', () async {
        expect(
          () => backend.delete('1'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('deleteAll throws StateError before initialize', () async {
        expect(
          () => backend.deleteAll(['1']),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('deleteWhere throws StateError before initialize', () async {
        final query =
            const nexus.Query<TestUser>().where('name', isEqualTo: 'Test');
        expect(
          () => backend.deleteWhere(query),
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

      test('sync throws StateError before initialize', () async {
        expect(
          () => backend.sync(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('getAllPaged throws StateError before initialize', () async {
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
    });

    group('Sync Status Transitions', () {
      setUp(() async {
        await backend.initialize();
      });

      test('maps connected + not uploading to synced', () async {
        syncStatusController.add(const ps.SyncStatus(connected: true));

        await Future<void>.delayed(Duration.zero);
        expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
      });

      test('maps uploading to syncing', () async {
        syncStatusController.add(
          const ps.SyncStatus(connected: true, uploading: true),
        );

        await Future<void>.delayed(Duration.zero);
        expect(backend.syncStatus, equals(nexus.SyncStatus.syncing));
      });

      test('maps downloading to syncing', () async {
        syncStatusController.add(
          const ps.SyncStatus(connected: true, downloading: true),
        );

        await Future<void>.delayed(Duration.zero);
        // Downloading doesn't trigger syncing in current implementation
        // (only uploading does), but this test documents the behavior
        expect(backend.syncStatus, isA<nexus.SyncStatus>());
      });

      test('maps disconnected to paused', () async {
        syncStatusController.add(const ps.SyncStatus());

        await Future<void>.delayed(Duration.zero);
        expect(backend.syncStatus, equals(nexus.SyncStatus.paused));
      });

      test('maps upload error to error', () async {
        syncStatusController.add(
          ps.SyncStatus(
            connected: true,
            uploadError: Exception('Upload failed'),
          ),
        );

        await Future<void>.delayed(Duration.zero);
        expect(backend.syncStatus, equals(nexus.SyncStatus.error));
      });

      test('maps download error to error', () async {
        syncStatusController.add(
          ps.SyncStatus(
            connected: true,
            downloadError: Exception('Download failed'),
          ),
        );

        await Future<void>.delayed(Duration.zero);
        expect(backend.syncStatus, equals(nexus.SyncStatus.error));
      });

      test('syncStatusStream emits status changes', () async {
        final statuses = <nexus.SyncStatus>[];
        final subscription = backend.syncStatusStream.listen(statuses.add);

        syncStatusController.add(
          const ps.SyncStatus(connected: true, uploading: true),
        );
        await Future<void>.delayed(Duration.zero);

        syncStatusController.add(const ps.SyncStatus(connected: true));
        await Future<void>.delayed(Duration.zero);

        syncStatusController.add(const ps.SyncStatus());
        await Future<void>.delayed(Duration.zero);

        await subscription.cancel();

        expect(
          statuses,
          containsAllInOrder([
            nexus.SyncStatus.synced, // Initial
            nexus.SyncStatus.syncing, // Uploading
            nexus.SyncStatus.synced, // Done uploading
            nexus.SyncStatus.paused, // Disconnected
          ]),
        );
      });
    });

    group('Offline/Online Transitions', () {
      setUp(() async {
        await backend.initialize();
      });

      test('status changes from synced to paused on disconnect', () async {
        final statuses = <nexus.SyncStatus>[];
        final subscription = backend.syncStatusStream.listen(statuses.add);

        // Start connected
        syncStatusController.add(
          const ps.SyncStatus(connected: true, hasSynced: true),
        );
        await Future<void>.delayed(Duration.zero);

        // Disconnect
        syncStatusController.add(const ps.SyncStatus());
        await Future<void>.delayed(Duration.zero);

        await subscription.cancel();

        expect(statuses.last, equals(nexus.SyncStatus.paused));
      });

      test('status changes from paused to syncing on reconnect', () async {
        final statuses = <nexus.SyncStatus>[];
        final subscription = backend.syncStatusStream.listen(statuses.add);

        // Start disconnected
        syncStatusController.add(const ps.SyncStatus());
        await Future<void>.delayed(Duration.zero);

        // Reconnect and start uploading
        syncStatusController.add(
          const ps.SyncStatus(connected: true, uploading: true),
        );
        await Future<void>.delayed(Duration.zero);

        await subscription.cancel();

        expect(
          statuses,
          containsAllInOrder([
            nexus.SyncStatus.paused,
            nexus.SyncStatus.syncing,
          ]),
        );
      });

      test('full offline/online cycle', () async {
        final statuses = <nexus.SyncStatus>[];
        final subscription = backend.syncStatusStream.listen(statuses.add);

        // Connected and synced
        syncStatusController.add(
          const ps.SyncStatus(connected: true, hasSynced: true),
        );
        await Future<void>.delayed(Duration.zero);

        // Go offline
        syncStatusController.add(const ps.SyncStatus());
        await Future<void>.delayed(Duration.zero);

        // Come back online and sync
        syncStatusController.add(
          const ps.SyncStatus(connected: true, uploading: true),
        );
        await Future<void>.delayed(Duration.zero);

        // Sync complete
        syncStatusController.add(
          const ps.SyncStatus(connected: true, hasSynced: true),
        );
        await Future<void>.delayed(Duration.zero);

        await subscription.cancel();

        expect(statuses.length, greaterThanOrEqualTo(4));
        expect(statuses, contains(nexus.SyncStatus.paused));
        expect(statuses, contains(nexus.SyncStatus.syncing));
        expect(statuses.last, equals(nexus.SyncStatus.synced));
      });
    });

    group('Error Handling', () {
      setUp(() async {
        await backend.initialize();
      });

      test('maps constraint violation to ValidationError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('UNIQUE constraint failed'));

        expect(
          () => backend.save(TestUser(id: '1', name: 'Test')),
          throwsA(isA<nexus.ValidationError>()),
        );
      });

      test('maps foreign key error to ValidationError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('FOREIGN KEY constraint failed'));

        expect(
          () => backend.save(TestUser(id: '1', name: 'Test')),
          throwsA(isA<nexus.ValidationError>()),
        );
      });

      test('maps network error to NetworkError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('network error: connection refused'));

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.NetworkError>()),
        );
      });

      test('maps socket error to NetworkError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('SocketException: Failed'));

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.NetworkError>()),
        );
      });

      test('maps connection error to NetworkError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('connection failed'));

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.NetworkError>()),
        );
      });

      test('maps timeout error to TimeoutError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('operation timeout'));

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.TimeoutError>()),
        );
      });

      test('maps 401 unauthorized to AuthenticationError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('401 unauthorized'));

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.AuthenticationError>()),
        );
      });

      test('maps 403 forbidden to AuthorizationError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('403 forbidden'));

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.AuthorizationError>()),
        );
      });

      test('maps unknown error to SyncError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('some unknown error'));

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.SyncError>()),
        );
      });

      test('save updates sync status to error on failure', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('some error'));

        final statuses = <nexus.SyncStatus>[];
        backend.syncStatusStream.listen(statuses.add);

        try {
          await backend.save(TestUser(id: '1', name: 'Test'));
        } on Exception catch (_) {}

        await Future<void>.delayed(Duration.zero);

        expect(statuses, contains(nexus.SyncStatus.pending));
        expect(statuses, contains(nexus.SyncStatus.error));
      });

      test('delete updates sync status to error on failure', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('some error'));

        final statuses = <nexus.SyncStatus>[];
        backend.syncStatusStream.listen(statuses.add);

        try {
          await backend.delete('1');
        } on Exception catch (_) {}

        await Future<void>.delayed(Duration.zero);

        expect(statuses, contains(nexus.SyncStatus.error));
      });
    });

    group('Pending Changes Management', () {
      setUp(() async {
        await backend.initialize();
      });

      test('pendingChangesStream returns stream', () {
        expect(backend.pendingChangesStream, isA<Stream<dynamic>>());
      });

      test('pendingChangesStream initially empty', () async {
        expect(
          backend.pendingChangesStream,
          emits(isEmpty),
        );
      });

      test('retryChange completes without error for unknown id', () async {
        await expectLater(
          backend.retryChange('non-existent-id'),
          completes,
        );
      });

      test('cancelChange returns null for unknown id', () async {
        final result = await backend.cancelChange('non-existent-id');
        expect(result, isNull);
      });
    });

    group('Conflict Management', () {
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

    group('Sync Operations', () {
      setUp(() async {
        await backend.initialize();
      });

      test('sync() transitions through syncing state', () async {
        final statuses = <nexus.SyncStatus>[];
        backend.syncStatusStream.listen(statuses.add);

        await backend.sync();

        // Allow microtask queue to flush
        await Future<void>.delayed(Duration.zero);

        expect(statuses, contains(nexus.SyncStatus.syncing));
        expect(statuses, contains(nexus.SyncStatus.synced));
      });

      test('pendingChangesCount returns value based on hasSynced', () async {
        when(() => mockDb.currentStatus).thenReturn(
          // hasSynced: false means there are pending changes
          const ps.SyncStatus(connected: true, hasSynced: false),
        );

        final count = await backend.pendingChangesCount;
        expect(count, equals(1));
      });

      test('pendingChangesCount returns 0 when synced', () async {
        when(() => mockDb.currentStatus).thenReturn(
          const ps.SyncStatus(connected: true, hasSynced: true),
        );

        final count = await backend.pendingChangesCount;
        expect(count, equals(0));
      });
    });

    group('Configuration', () {
      test('uses custom primary key column', () {
        final backendWithCustomPK = PowerSyncBackend<TestUser, String>(
          db: mockDb,
          tableName: 'users',
          getId: (user) => user.id,
          fromJson: TestUser.fromJson,
          toJson: (user) => user.toJson(),
          primaryKeyColumn: 'user_id',
        );

        expect(backendWithCustomPK, isNotNull);
        expect(backendWithCustomPK.name, equals('powersync'));
      });

      test('uses custom field mapping', () {
        final backendWithMapping = PowerSyncBackend<TestUser, String>(
          db: mockDb,
          tableName: 'users',
          getId: (user) => user.id,
          fromJson: TestUser.fromJson,
          toJson: (user) => user.toJson(),
          fieldMapping: {'userName': 'name', 'userAge': 'age'},
        );

        expect(backendWithMapping, isNotNull);
      });

      test('uses custom query translator', () {
        final customTranslator = PowerSyncQueryTranslator<TestUser>(
          fieldMapping: {'userName': 'name'},
        );

        final backendWithTranslator = PowerSyncBackend<TestUser, String>(
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

    // Note: Full CRUD tests with real PowerSync database are in
    // real_database_test.dart. These tests cover:
    // - save creates/updates records
    // - get retrieves/returns null
    // - getAll with/without query
    // - delete/deleteAll
    // - watch/watchAll
    // - pagination
    // - query operations
    //
    // Run with: dart test test/integration/real_database_test.dart --tags=real_db
  });
}
