import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_powersync_adapter/src/powersync_backend.dart';
import 'package:nexus_store_powersync_adapter/src/powersync_query_translator.dart';
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
}

// Mock classes
class MockPowerSyncDatabase extends Mock implements ps.PowerSyncDatabase {}

void main() {
  group('PowerSyncBackend', () {
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

      test('delete throws StateError before initialize', () async {
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

      test('sync throws StateError before initialize', () async {
        expect(
          () => backend.sync(),
          throwsA(isA<nexus.StateError>()),
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

        expect(
          () => backend.save(TestUser(id: '1', name: 'Test')),
          throwsA(isA<nexus.ValidationError>()),
        );
      });

      test('maps network errors to NetworkError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('network error: connection refused'));

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.NetworkError>()),
        );
      });

      test('maps timeout errors to TimeoutError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('operation timeout'));

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.TimeoutError>()),
        );
      });

      test('maps auth errors to AuthenticationError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('401 unauthorized'));

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.AuthenticationError>()),
        );
      });

      test('maps forbidden errors to AuthorizationError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('403 forbidden'));

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.AuthorizationError>()),
        );
      });

      test('maps unknown errors to SyncError', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('unknown error'));

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.SyncError>()),
        );
      });
    });

    group('sync status', () {
      test('syncStatus returns synced initially after initialize', () async {
        await backend.initialize();
        expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
      });

      test('syncStatusStream emits initial status', () async {
        await backend.initialize();

        expect(
          backend.syncStatusStream,
          emits(nexus.SyncStatus.synced),
        );
      });
    });

    group('query translator', () {
      test('uses custom query translator when provided', () async {
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

      test('uses default query translator when not provided', () async {
        expect(backend, isNotNull);
      });
    });

    group('configuration', () {
      test('uses custom primary key column', () async {
        final backendWithCustomPK = PowerSyncBackend<TestUser, String>(
          db: mockDb,
          tableName: 'users',
          getId: (user) => user.id,
          fromJson: TestUser.fromJson,
          toJson: (user) => user.toJson(),
          primaryKeyColumn: 'user_id',
        );

        expect(backendWithCustomPK, isNotNull);
      });

      test('uses custom field mapping', () async {
        final backendWithMapping = PowerSyncBackend<TestUser, String>(
          db: mockDb,
          tableName: 'users',
          getId: (user) => user.id,
          fromJson: TestUser.fromJson,
          toJson: (user) => user.toJson(),
          fieldMapping: {'userName': 'name'},
        );

        expect(backendWithMapping, isNotNull);
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

      test('retryChange completes without error', () async {
        await expectLater(
          backend.retryChange('non-existent-id'),
          completes,
        );
      });

      test('cancelChange returns null for non-existent change', () async {
        final result = await backend.cancelChange('non-existent-id');
        expect(result, isNull);
      });
    });

    group('conflicts', () {
      setUp(() async {
        await backend.initialize();
      });

      test('conflictsStream is available', () async {
        expect(
          backend.conflictsStream,
          isA<Stream<nexus.ConflictDetails<TestUser>>>(),
        );
      });
    });
  });
}
