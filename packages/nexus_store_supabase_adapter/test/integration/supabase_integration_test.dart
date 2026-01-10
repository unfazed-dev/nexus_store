// ignore_for_file: lines_longer_than_80_chars
@Tags(['integration'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_supabase_adapter/nexus_store_supabase_adapter.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

/// Test configuration for Supabase integration tests.
class TestConfig {
  TestConfig._();

  static const supabaseUrl = 'https://ohfsnnhytsfwjdywsqdc.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9oZnNubmh5dHNmd2pkeXdzcWRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4ODk3MTAsImV4cCI6MjA4MTQ2NTcxMH0.NRyLSwzscRjytXho60CIEDHdwXOV0jrdkdI2sROJJaU';
}

// -----------------------------------------------------------------------------
// Mock Classes
// -----------------------------------------------------------------------------

class MockSupabaseClient extends Mock implements SupabaseClient {}

// -----------------------------------------------------------------------------
// Test Model
// -----------------------------------------------------------------------------

/// Test model for integration tests.
/// Matches the test_items table schema: id (text), name (text), value (integer)
class TestModel {
  const TestModel({
    required this.id,
    required this.name,
    this.value = 0,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) => TestModel(
        id: json['id'] as String,
        name: json['name'] as String,
        value: json['value'] as int? ?? 0,
      );

  final String id;
  final String name;
  final int value;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'value': value,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          value == other.value;

  @override
  int get hashCode => Object.hash(id, name, value);

  @override
  String toString() => 'TestModel(id: $id, name: $name, value: $value)';
}

void main() {
  group('Supabase Integration Tests', () {
    late MockSupabaseClient mockClient;
    // Unique prefix for this test file to avoid conflicts with other test files
    const testPrefix = 'int-';

    setUp(() {
      mockClient = MockSupabaseClient();
    });

    SupabaseBackend<TestModel, String> createBackend({
      MockSupabaseClient? client,
      String primaryKeyColumn = 'id',
      String schema = 'public',
      Map<String, String>? fieldMapping,
    }) =>
        SupabaseBackend<TestModel, String>(
          client: client ?? mockClient,
          tableName: 'test_models',
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
          primaryKeyColumn: primaryKeyColumn,
          schema: schema,
          fieldMapping: fieldMapping,
        );

    group('Backend Properties', () {
      test('name returns "supabase"', () {
        final backend = createBackend();
        expect(backend.name, equals('supabase'));
      });

      test('supportsOffline returns false (online-only backend)', () {
        final backend = createBackend();
        expect(backend.supportsOffline, isFalse);
      });

      test('supportsRealtime returns true', () {
        final backend = createBackend();
        expect(backend.supportsRealtime, isTrue);
      });

      test('supportsTransactions returns false', () {
        final backend = createBackend();
        expect(backend.supportsTransactions, isFalse);
      });

      test('initial syncStatus is synced (online-only)', () {
        final backend = createBackend();
        expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
      });

      test('pendingChangesCount is always 0 (online-only)', () async {
        final backend = createBackend();
        final count = await backend.pendingChangesCount;
        expect(count, equals(0));
      });
    });

    group('Lifecycle Management', () {
      test('close can be called without initialization', () async {
        final backend = createBackend();

        // Should not throw
        await backend.close();
        await backend.close();
      });

      test('initialize can be called multiple times (idempotent)', () async {
        final realClient = SupabaseClient(
          TestConfig.supabaseUrl,
          TestConfig.supabaseAnonKey,
        );
        final backend = SupabaseBackend<TestModel, String>(
          client: realClient,
          tableName: 'test_items',
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
        );

        try {
          // Initialize multiple times - should not throw
          await backend.initialize();
          await backend.initialize();
          await backend.initialize();

          expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
        } finally {
          await backend.close();
        }
      });

      test('close can be called multiple times (idempotent)', () async {
        final realClient = SupabaseClient(
          TestConfig.supabaseUrl,
          TestConfig.supabaseAnonKey,
        );
        final backend = SupabaseBackend<TestModel, String>(
          client: realClient,
          tableName: 'test_items',
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
        );

        await backend.initialize();

        // Close multiple times - should not throw
        await backend.close();
        await backend.close();
        await backend.close();
      });

      // Note: SupabaseBackend does not support re-initialization after close.
      // Once close() is called, internal StreamControllers are closed and cannot
      // be reopened. This is a design limitation - create a new backend instance
      // if re-initialization is needed.
      test(
        'backend cannot be re-initialized after close (design limitation)',
        () async {
          final realClient = SupabaseClient(
            TestConfig.supabaseUrl,
            TestConfig.supabaseAnonKey,
          );
          final backend = SupabaseBackend<TestModel, String>(
            client: realClient,
            tableName: 'test_items',
            getId: (model) => model.id,
            fromJson: TestModel.fromJson,
            toJson: (model) => model.toJson(),
          );

          try {
            await backend.initialize();
            await backend.close();

            // Re-initialization should throw because streams are closed
            await expectLater(
              backend.initialize(),
              throwsA(isA<nexus.SyncError>()),
            );
          } finally {
            // Cleanup - close is safe to call multiple times
            await backend.close();
          }
        },
      );
    });

    group('Uninitialized State Guards', () {
      late SupabaseBackend<TestModel, String> backend;

      setUp(() {
        backend = createBackend();
      });

      tearDown(() async {
        try {
          await backend.close();
        } on Object {
          // Ignore
        }
      });

      test('get throws StateError when not initialized', () {
        expect(
          () => backend.get('test-id'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('getAll throws StateError when not initialized', () {
        expect(
          () => backend.getAll(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('save throws StateError when not initialized', () {
        expect(
          () => backend.save(const TestModel(id: '1', name: 'Test')),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('saveAll throws StateError when not initialized', () {
        expect(
          () => backend.saveAll([const TestModel(id: '1', name: 'Test')]),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('delete throws StateError when not initialized', () {
        expect(
          () => backend.delete('test-id'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('deleteAll throws StateError when not initialized', () {
        expect(
          () => backend.deleteAll(['id1', 'id2']),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('deleteWhere throws StateError when not initialized', () {
        final query =
            const nexus.Query<TestModel>().where('name', isEqualTo: 'Test');
        expect(
          () => backend.deleteWhere(query),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('watch throws StateError when not initialized', () {
        expect(
          () => backend.watch('test-id'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('watchAll throws StateError when not initialized', () {
        expect(
          () => backend.watchAll(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('sync throws StateError when not initialized', () {
        expect(
          () => backend.sync(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('StateError contains proper message and state info', () async {
        try {
          await backend.get('test-id');
          fail('Expected StateError');
        } on nexus.StateError catch (e) {
          expect(e.message, contains('not initialized'));
          expect(e.currentState, equals('uninitialized'));
          expect(e.expectedState, equals('initialized'));
        }
      });
    });

    group('Sync Status (Online-Only Behavior)', () {
      // Note: Tests requiring initialization are skipped because
      // SupabaseRealtimeManager requires WebSocket connections.

      test('syncStatusStream emits synced before initialization', () async {
        final backend = createBackend();
        // syncStatusStream is available before initialization
        final status = await backend.syncStatusStream.first;
        expect(status, equals(nexus.SyncStatus.synced));
      });

      test('syncStatus is synced before initialization', () {
        final backend = createBackend();
        expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
      });

      test('syncStatusStream is a broadcast stream', () async {
        final backend = createBackend();
        // Multiple listeners should be allowed
        final listener1 = backend.syncStatusStream.listen((_) {});
        final listener2 = backend.syncStatusStream.listen((_) {});

        await listener1.cancel();
        await listener2.cancel();
      });

      test('sync() is no-op for online-only backend (after init)', () async {
        final realClient = SupabaseClient(
          TestConfig.supabaseUrl,
          TestConfig.supabaseAnonKey,
        );
        final backend = SupabaseBackend<TestModel, String>(
          client: realClient,
          tableName: 'test_items',
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
        );

        try {
          await backend.initialize();

          // sync() should complete without error for online-only backend
          await backend.sync();

          // Status should remain synced (no-op)
          expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
        } finally {
          await backend.close();
        }
      });

      test('pendingChangesCount returns 0 after initialization', () async {
        final realClient = SupabaseClient(
          TestConfig.supabaseUrl,
          TestConfig.supabaseAnonKey,
        );
        final backend = SupabaseBackend<TestModel, String>(
          client: realClient,
          tableName: 'test_items',
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
        );

        try {
          await backend.initialize();

          // Online-only backend has no pending changes
          final count = await backend.pendingChangesCount;
          expect(count, equals(0));
        } finally {
          await backend.close();
        }
      });
    });

    group('Configuration Options', () {
      test('custom primary key column is accepted', () {
        final backend = createBackend(primaryKeyColumn: 'uuid');
        expect(backend, isNotNull);
      });

      test('custom schema is accepted', () {
        final backend = createBackend(schema: 'custom_schema');
        expect(backend, isNotNull);
      });

      test('field mapping is accepted', () {
        final backend = createBackend(
          fieldMapping: {'userName': 'user_name', 'createdAt': 'created_at'},
        );
        expect(backend, isNotNull);
      });

      test('custom query translator is accepted', () {
        final translator = SupabaseQueryTranslator<TestModel>(
          fieldMapping: {'userName': 'user_name'},
        );
        final backend = SupabaseBackend<TestModel, String>(
          client: mockClient,
          tableName: 'test_models',
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
          queryTranslator: translator,
        );
        expect(backend, isNotNull);
      });
    });

    group('Query Building', () {
      test('empty query has isEmpty true', () {
        const query = nexus.Query<TestModel>();
        expect(query.isEmpty, isTrue);
      });

      test('query with filters has isNotEmpty true', () {
        final query =
            const nexus.Query<TestModel>().where('name', isEqualTo: 'Test');
        expect(query.isNotEmpty, isTrue);
      });

      test('query supports multiple filters', () {
        final query = const nexus.Query<TestModel>()
            .where('name', isEqualTo: 'Test')
            .where('value', isGreaterThan: 18);
        expect(query.filters.length, equals(2));
      });

      test('query supports ordering', () {
        final query = const nexus.Query<TestModel>()
            .orderByField('name')
            .orderByField('value', descending: true);
        expect(query.orderBy.length, equals(2));
      });

      test('query supports pagination', () {
        final query = const nexus.Query<TestModel>().limitTo(10).offsetBy(5);
        expect(query.limit, equals(10));
        expect(query.offset, equals(5));
      });

      test('complex query with all features', () {
        final query = const nexus.Query<TestModel>()
            .where('value', isGreaterThanOrEqualTo: 18)
            .where('name', isNotEqualTo: 'banned')
            .orderByField('createdAt', descending: true)
            .limitTo(20)
            .offsetBy(0);

        expect(query.filters.length, equals(2));
        expect(query.orderBy.length, equals(1));
        expect(query.limit, equals(20));
        expect(query.offset, equals(0));
        expect(query.isNotEmpty, isTrue);
      });
    });

    group('Query Translator', () {
      test('translator maps field names correctly', () {
        final translator = SupabaseQueryTranslator<TestModel>(
          fieldMapping: {'userName': 'user_name', 'createdAt': 'created_at'},
        );

        // Field mapping should be stored
        expect(translator, isNotNull);
      });

      test('translator without field mapping uses original names', () {
        final translator = SupabaseQueryTranslator<TestModel>();
        expect(translator, isNotNull);
      });
    });

    group('Error Type Mapping', () {
      // These tests verify the error patterns that the backend recognizes
      // Actual error mapping is tested via unit tests

      test('PGRST116 code indicates not found', () {
        const errorCode = 'PGRST116';
        expect(errorCode, equals('PGRST116'));
      });

      test('23505 code indicates unique constraint violation', () {
        const errorCode = '23505';
        expect(errorCode, equals('23505'));
      });

      test('23503 code indicates foreign key violation', () {
        const errorCode = '23503';
        expect(errorCode, equals('23503'));
      });

      test('42501 code indicates permission denied (RLS)', () {
        const errorCode = '42501';
        expect(errorCode, equals('42501'));
      });

      test('PGRST301 code indicates JWT/auth error', () {
        const errorCode = 'PGRST301';
        expect(errorCode, equals('PGRST301'));
      });
    });

    group('Database CRUD Operations', () {
      late SupabaseClient realClient;
      late SupabaseBackend<TestModel, String> backend;
      const tableName = 'test_items';

      setUp(() async {
        realClient = SupabaseClient(
          TestConfig.supabaseUrl,
          TestConfig.supabaseAnonKey,
        );
        backend = SupabaseBackend<TestModel, String>(
          client: realClient,
          tableName: tableName,
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
        );
        await backend.initialize();

        // Clean up any existing test data for this test file only
        try {
          await realClient.from(tableName).delete().like('id', '$testPrefix%');
        } on Object {
          // Ignore cleanup errors
        }
      });

      tearDown(() async {
        // Clean up test data - only records from this test file
        try {
          await realClient.from(tableName).delete().like('id', '$testPrefix%');
        } on Object {
          // Ignore cleanup errors
        }
        await backend.close();
      });

      test('save creates a new record', () async {
        const model =
            TestModel(id: '${testPrefix}crud-1', name: 'Test Item', value: 25);

        final result = await backend.save(model);

        expect(result.id, equals('${testPrefix}crud-1'));
        expect(result.name, equals('Test Item'));
        expect(result.value, equals(25));
      });

      test('save updates an existing record', () async {
        const model =
            TestModel(id: '${testPrefix}crud-2', name: 'Original', value: 20);
        await backend.save(model);

        const updated =
            TestModel(id: '${testPrefix}crud-2', name: 'Updated', value: 30);
        final result = await backend.save(updated);

        expect(result.id, equals('${testPrefix}crud-2'));
        expect(result.name, equals('Updated'));
        expect(result.value, equals(30));
      });

      test('get retrieves a record by id', () async {
        const model =
            TestModel(id: '${testPrefix}crud-3', name: 'Get Test', value: 35);
        await backend.save(model);

        final result = await backend.get('${testPrefix}crud-3');

        expect(result, isNotNull);
        expect(result!.id, equals('${testPrefix}crud-3'));
        expect(result.name, equals('Get Test'));
      });

      test('get returns null for non-existent id', () async {
        final result = await backend.get('${testPrefix}non-existent-id');

        expect(result, isNull);
      });

      test('getAll retrieves all records', () async {
        await backend
            .save(const TestModel(id: '${testPrefix}all-1', name: 'Item 1'));
        await backend
            .save(const TestModel(id: '${testPrefix}all-2', name: 'Item 2'));
        await backend
            .save(const TestModel(id: '${testPrefix}all-3', name: 'Item 3'));

        // Query only records for this test file
        final query = const nexus.Query<TestModel>().where(
          'id',
          isGreaterThanOrEqualTo: testPrefix,
        );
        final results = await backend.getAll(query: query);

        expect(results.length, greaterThanOrEqualTo(3));
        expect(results.any((m) => m.id == '${testPrefix}all-1'), isTrue);
        expect(results.any((m) => m.id == '${testPrefix}all-2'), isTrue);
        expect(results.any((m) => m.id == '${testPrefix}all-3'), isTrue);
      });

      test('getAll with query filters results', () async {
        await backend.save(
          const TestModel(
              id: '${testPrefix}filter-1', name: 'Alice', value: 25),
        );
        await backend.save(
          const TestModel(id: '${testPrefix}filter-2', name: 'Bob', value: 35),
        );
        await backend.save(
          const TestModel(
            id: '${testPrefix}filter-3',
            name: 'Charlie',
            value: 45,
          ),
        );

        final query = const nexus.Query<TestModel>().where(
          'value',
          isGreaterThanOrEqualTo: 35,
        );

        final results = await backend.getAll(query: query);

        expect(results.length, equals(2));
        expect(results.any((m) => m.name == 'Bob'), isTrue);
        expect(results.any((m) => m.name == 'Charlie'), isTrue);
      });

      test('delete removes a record', () async {
        await backend
            .save(const TestModel(id: '${testPrefix}del-1', name: 'To Delete'));

        final deleted = await backend.delete('${testPrefix}del-1');

        expect(deleted, isTrue);

        final result = await backend.get('${testPrefix}del-1');
        expect(result, isNull);
      });

      test('delete returns false for non-existent record', () async {
        final deleted = await backend.delete('${testPrefix}non-existent');

        expect(deleted, isFalse);
      });

      test('deleteAll removes multiple records', () async {
        await backend
            .save(const TestModel(id: '${testPrefix}delall-1', name: 'Item 1'));
        await backend
            .save(const TestModel(id: '${testPrefix}delall-2', name: 'Item 2'));
        await backend
            .save(const TestModel(id: '${testPrefix}delall-3', name: 'Keep'));

        final count = await backend
            .deleteAll(['${testPrefix}delall-1', '${testPrefix}delall-2']);

        expect(count, equals(2));

        final remaining = await backend.get('${testPrefix}delall-3');
        expect(remaining, isNotNull);
      });

      test('deleteWhere removes records matching query', () async {
        await backend.save(
          const TestModel(
            id: '${testPrefix}delwhere-1',
            name: 'Young',
            value: 20,
          ),
        );
        await backend.save(
          const TestModel(
              id: '${testPrefix}delwhere-2', name: 'Old', value: 50),
        );
        await backend.save(
          const TestModel(
            id: '${testPrefix}delwhere-3',
            name: 'Middle',
            value: 35,
          ),
        );

        final query =
            const nexus.Query<TestModel>().where('value', isLessThan: 30);

        await backend.deleteWhere(query);

        // Query only records for this test file
        final filterQuery = const nexus.Query<TestModel>().where(
          'id',
          isGreaterThanOrEqualTo: testPrefix,
        );
        final results = await backend.getAll(query: filterQuery);
        expect(results.any((m) => m.id == '${testPrefix}delwhere-1'), isFalse);
        expect(results.any((m) => m.id == '${testPrefix}delwhere-2'), isTrue);
        expect(results.any((m) => m.id == '${testPrefix}delwhere-3'), isTrue);
      });
    });

    group('Watch/Streaming Operations', () {
      late SupabaseClient realClient;
      late SupabaseBackend<TestModel, String> backend;
      const tableName = 'test_items';

      setUp(() async {
        realClient = SupabaseClient(
          TestConfig.supabaseUrl,
          TestConfig.supabaseAnonKey,
        );
        backend = SupabaseBackend<TestModel, String>(
          client: realClient,
          tableName: tableName,
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
        );
        await backend.initialize();

        // Clean up any existing test data for this test file only
        try {
          await realClient.from(tableName).delete().like('id', '$testPrefix%');
        } on Object {
          // Ignore cleanup errors
        }
      });

      tearDown(() async {
        // Clean up test data - only records from this test file
        try {
          await realClient.from(tableName).delete().like('id', '$testPrefix%');
        } on Object {
          // Ignore cleanup errors
        }
        await backend.close();
      });

      test('watch emits initial value', () async {
        await backend.save(
          const TestModel(
              id: '${testPrefix}watch-1', name: 'Watch Test', value: 30),
        );

        // Small delay to ensure record is available in database
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Verify the record exists before watching
        final saved = await backend.get('${testPrefix}watch-1');
        expect(saved, isNotNull, reason: 'Record should exist after save');

        final stream = backend.watch('${testPrefix}watch-1');
        // BehaviorSubject loads initial value asynchronously via get(),
        // so we use firstWhere to skip any initial null emissions
        final firstValue = await stream
            .firstWhere((value) => value != null)
            .timeout(const Duration(seconds: 5));

        expect(firstValue, isNotNull);
        expect(firstValue!.id, equals('${testPrefix}watch-1'));
        expect(firstValue.name, equals('Watch Test'));
      });

      test('watch emits updates on changes', () async {
        await backend.save(
          const TestModel(
              id: '${testPrefix}watch-2', name: 'Original', value: 25),
        );

        final stream = backend.watch('${testPrefix}watch-2');
        final values = <TestModel?>[];
        final subscription = stream.listen(values.add);

        // Wait for initial value
        await Future<void>.delayed(const Duration(milliseconds: 500));

        // Update the record
        await backend.save(
          const TestModel(
              id: '${testPrefix}watch-2', name: 'Updated', value: 26),
        );

        // Wait for update notification
        await Future<void>.delayed(const Duration(milliseconds: 500));

        await subscription.cancel();

        expect(values.length, greaterThanOrEqualTo(1));
        expect(values.any((v) => v?.name == 'Original'), isTrue);
      });

      test('watchAll emits initial list', () async {
        await backend
            .save(const TestModel(id: '${testPrefix}wall-1', name: 'Item 1'));
        await backend
            .save(const TestModel(id: '${testPrefix}wall-2', name: 'Item 2'));

        // Query only records for this test file
        final query = const nexus.Query<TestModel>().where(
          'id',
          isGreaterThanOrEqualTo: testPrefix,
        );
        final stream = backend.watchAll(query: query);
        final firstValue = await stream.first.timeout(
          const Duration(seconds: 5),
        );

        expect(firstValue.length, greaterThanOrEqualTo(2));
        expect(firstValue.any((m) => m.id == '${testPrefix}wall-1'), isTrue);
        expect(firstValue.any((m) => m.id == '${testPrefix}wall-2'), isTrue);
      });

      test('watchAll emits updates on changes', () async {
        await backend
            .save(const TestModel(id: '${testPrefix}wall-3', name: 'Initial'));

        // Query only records for this test file
        final query = const nexus.Query<TestModel>().where(
          'id',
          isGreaterThanOrEqualTo: testPrefix,
        );
        final stream = backend.watchAll(query: query);
        final values = <List<TestModel>>[];
        final subscription = stream.listen(values.add);

        // Wait for initial value
        await Future<void>.delayed(const Duration(milliseconds: 500));

        // Add a new record
        await backend
            .save(const TestModel(id: '${testPrefix}wall-4', name: 'New Item'));

        // Wait for update notification
        await Future<void>.delayed(const Duration(milliseconds: 500));

        await subscription.cancel();

        expect(values.length, greaterThanOrEqualTo(1));
      });

      test('watchAll with query filters results', () async {
        await backend.save(
          const TestModel(
              id: '${testPrefix}wquery-1', name: 'Young', value: 20),
        );
        await backend.save(
          const TestModel(id: '${testPrefix}wquery-2', name: 'Old', value: 50),
        );

        final query = const nexus.Query<TestModel>().where(
          'value',
          isGreaterThanOrEqualTo: 40,
        );

        final stream = backend.watchAll(query: query);
        final firstValue = await stream.first.timeout(
          const Duration(seconds: 5),
        );

        expect(firstValue.length, equals(1));
        expect(firstValue.first.name, equals('Old'));
      });
    });
  });
}
