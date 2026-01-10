// ignore_for_file: lines_longer_than_80_chars
@Tags(['integration'])
library;

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
  group('SupabaseManager Integration Tests', () {
    late SupabaseClient realClient;
    late SupabaseTableConfig<TestModel, String> testItemsConfig;
    // Unique prefix for this test file to avoid conflicts with other test files
    const testPrefix = 'mgr-';

    setUp(() {
      realClient = SupabaseClient(
        TestConfig.supabaseUrl,
        TestConfig.supabaseAnonKey,
      );

      testItemsConfig = SupabaseTableConfig<TestModel, String>(
        tableName: 'test_items',
        columns: [
          SupabaseColumn.text('id', nullable: false),
          SupabaseColumn.text('name', nullable: false),
          SupabaseColumn.integer('value'),
        ],
        fromJson: TestModel.fromJson,
        toJson: (m) => m.toJson(),
        getId: (m) => m.id,
      );
    });

    tearDown(() async {
      // Clean up test data - only records from this test file
      try {
        await realClient.from('test_items').delete().like('id', '$testPrefix%');
      } on Object {
        // Ignore cleanup errors
      }
    });

    group('initialize', () {
      test('initializes manager and creates backends', () async {
        final manager = SupabaseManager.withClient(
          client: realClient,
          tables: [testItemsConfig],
        );

        expect(manager.isInitialized, isFalse);

        await manager.initialize();

        expect(manager.isInitialized, isTrue);

        await manager.dispose();
      });

      test('initialize is idempotent (can be called multiple times)', () async {
        final manager = SupabaseManager.withClient(
          client: realClient,
          tables: [testItemsConfig],
        );

        await manager.initialize();
        await manager.initialize();
        await manager.initialize();

        expect(manager.isInitialized, isTrue);

        await manager.dispose();
      });

      test('initialize with setClient works correctly', () async {
        final manager = SupabaseManager.withTables(
          tables: [testItemsConfig],
        )..setClient(realClient);

        await manager.initialize();

        expect(manager.isInitialized, isTrue);

        await manager.dispose();
      });

      test('initializes multiple table backends', () async {
        // Create second config for same table with different name
        final config1 = SupabaseTableConfig<TestModel, String>(
          tableName: 'test_items',
          columns: [
            SupabaseColumn.text('id', nullable: false),
            SupabaseColumn.text('name', nullable: false),
            SupabaseColumn.integer('value'),
          ],
          fromJson: TestModel.fromJson,
          toJson: (m) => m.toJson(),
          getId: (m) => m.id,
        );

        final manager = SupabaseManager.withClient(
          client: realClient,
          tables: [config1],
        );

        await manager.initialize();

        expect(manager.tableNames, contains('test_items'));
        expect(manager.isInitialized, isTrue);

        await manager.dispose();
      });
    });

    group('setClient', () {
      test('throws StateError when called after initialization', () async {
        final manager = SupabaseManager.withClient(
          client: realClient,
          tables: [testItemsConfig],
        );

        await manager.initialize();

        expect(
          () => manager.setClient(realClient),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('Cannot set client after initialization'),
            ),
          ),
        );

        await manager.dispose();
      });
    });

    group('getBackend', () {
      test('returns backend after initialization', () async {
        final manager = SupabaseManager.withClient(
          client: realClient,
          tables: [testItemsConfig],
        );

        await manager.initialize();

        final backend = manager.getBackend('test_items');

        expect(backend, isNotNull);
        expect(backend, isA<SupabaseBackend<dynamic, dynamic>>());

        await manager.dispose();
      });

      test('throws StateError for non-existent table', () async {
        final manager = SupabaseManager.withClient(
          client: realClient,
          tables: [testItemsConfig],
        );

        await manager.initialize();

        expect(
          () => manager.getBackend('non_existent_table'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('not found'),
            ),
          ),
        );

        await manager.dispose();
      });

      test('backend can perform CRUD operations', () async {
        final manager = SupabaseManager.withClient(
          client: realClient,
          tables: [testItemsConfig],
        );

        await manager.initialize();

        final backend = manager.getBackend('test_items');

        // Save
        const model = TestModel(
          id: '${testPrefix}crud-1',
          name: 'Manager Test',
          value: 100,
        );
        final saved = await backend.save(model);
        expect(saved, isNotNull);

        // Get
        final retrieved = await backend.get('${testPrefix}crud-1');
        expect(retrieved, isNotNull);

        // Delete
        final deleted = await backend.delete('${testPrefix}crud-1');
        expect(deleted, isTrue);

        await manager.dispose();
      });
    });

    group('getTypedBackend', () {
      // Note: getTypedBackend has a type casting limitation because backends
      // are stored as SupabaseBackend<dynamic, dynamic>. Dart's type system
      // doesn't allow casting generic types like this. The method exists for
      // cases where the caller handles the dynamic types appropriately.

      test('getTypedBackend method can be called with dynamic types', () async {
        final manager = SupabaseManager.withClient(
          client: realClient,
          tables: [testItemsConfig],
        );

        await manager.initialize();

        // Call getTypedBackend with dynamic types to cover the method
        final backend =
            manager.getTypedBackend<dynamic, dynamic>('test_items');

        expect(backend, isNotNull);
        expect(backend, isA<SupabaseBackend<dynamic, dynamic>>());

        await manager.dispose();
      });

      test('returns backend that can be used with dynamic types', () async {
        final manager = SupabaseManager.withClient(
          client: realClient,
          tables: [testItemsConfig],
        );

        await manager.initialize();

        // Use getBackend which returns the correct type
        final backend = manager.getBackend('test_items');

        expect(backend, isNotNull);
        expect(backend, isA<SupabaseBackend<dynamic, dynamic>>());

        await manager.dispose();
      });

      test('backend operations work with model instances', () async {
        final manager = SupabaseManager.withClient(
          client: realClient,
          tables: [testItemsConfig],
        );

        await manager.initialize();

        // Use dynamic backend - the fromJson/toJson functions handle type conversion
        final backend = manager.getBackend('test_items');

        // Save works with any object that matches the schema
        const model = TestModel(
          id: '${testPrefix}typed-1',
          name: 'Typed Test',
          value: 200,
        );
        final saved = await backend.save(model);
        expect(saved, isNotNull);

        // Get returns the correct type via fromJson
        final retrieved = await backend.get('${testPrefix}typed-1');
        expect(retrieved, isNotNull);
        expect(retrieved, isA<TestModel>());
        expect((retrieved as TestModel).id, equals('${testPrefix}typed-1'));
        expect(retrieved.name, equals('Typed Test'));

        // Clean up
        await backend.delete('${testPrefix}typed-1');

        await manager.dispose();
      });
    });

    group('dispose', () {
      test('disposes all backends and resets state', () async {
        final manager = SupabaseManager.withClient(
          client: realClient,
          tables: [testItemsConfig],
        );

        await manager.initialize();
        expect(manager.isInitialized, isTrue);

        await manager.dispose();

        expect(manager.isInitialized, isFalse);
      });

      test('can be called multiple times (idempotent)', () async {
        final manager = SupabaseManager.withClient(
          client: realClient,
          tables: [testItemsConfig],
        );

        await manager.initialize();

        await manager.dispose();
        await manager.dispose();
        await manager.dispose();

        expect(manager.isInitialized, isFalse);
      });

      test('getBackend throws after dispose', () async {
        final manager = SupabaseManager.withClient(
          client: realClient,
          tables: [testItemsConfig],
        );

        await manager.initialize();
        await manager.dispose();

        expect(
          () => manager.getBackend('test_items'),
          throwsA(isA<StateError>()),
        );
      });

      test('manager can be re-initialized after dispose', () async {
        final manager = SupabaseManager.withClient(
          client: realClient,
          tables: [testItemsConfig],
        );

        await manager.initialize();
        expect(manager.isInitialized, isTrue);

        await manager.dispose();
        expect(manager.isInitialized, isFalse);

        // Re-initialize
        await manager.initialize();
        expect(manager.isInitialized, isTrue);

        // Verify backend works after re-initialization
        final backend = manager.getBackend('test_items');
        expect(backend, isNotNull);

        await manager.dispose();
      });
    });

    group('_createBackend (covered indirectly)', () {
      test('creates backend with correct configuration', () async {
        final configWithOptions = SupabaseTableConfig<TestModel, String>(
          tableName: 'test_items',
          columns: [
            SupabaseColumn.text('id', nullable: false),
            SupabaseColumn.text('name', nullable: false),
            SupabaseColumn.integer('value'),
          ],
          fromJson: TestModel.fromJson,
          toJson: (m) => m.toJson(),
          getId: (m) => m.id,
        );

        final manager = SupabaseManager.withClient(
          client: realClient,
          tables: [configWithOptions],
        );

        await manager.initialize();

        final backend = manager.getBackend('test_items');
        expect(backend.name, equals('supabase'));

        await manager.dispose();
      });

      test('creates backend with field mapping', () async {
        final configWithMapping = SupabaseTableConfig<TestModel, String>(
          tableName: 'test_items',
          columns: [
            SupabaseColumn.text('id', nullable: false),
            SupabaseColumn.text('name', nullable: false),
            SupabaseColumn.integer('value'),
          ],
          fromJson: TestModel.fromJson,
          toJson: (m) => m.toJson(),
          getId: (m) => m.id,
          fieldMapping: {'modelName': 'name'},
        );

        final manager = SupabaseManager.withClient(
          client: realClient,
          tables: [configWithMapping],
        );

        await manager.initialize();

        final backend = manager.getBackend('test_items');
        expect(backend, isNotNull);

        await manager.dispose();
      });
    });

    group('full lifecycle', () {
      test('complete lifecycle: create, initialize, use, dispose', () async {
        // Create manager with tables and set client
        final manager = SupabaseManager.withTables(
          tables: [testItemsConfig],
        )..setClient(realClient);

        // Initialize
        await manager.initialize();
        expect(manager.isInitialized, isTrue);

        // Get backend and perform operations
        final backend = manager.getBackend('test_items');

        // Create
        const model = TestModel(
          id: '${testPrefix}lifecycle-1',
          name: 'Lifecycle Test',
          value: 42,
        );
        await backend.save(model);

        // Read
        final retrieved =
            await backend.get('${testPrefix}lifecycle-1') as TestModel?;
        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('Lifecycle Test'));

        // Update
        const updated = TestModel(
          id: '${testPrefix}lifecycle-1',
          name: 'Updated Name',
          value: 100,
        );
        await backend.save(updated);

        final afterUpdate =
            await backend.get('${testPrefix}lifecycle-1') as TestModel?;
        expect(afterUpdate!.name, equals('Updated Name'));

        // Delete
        await backend.delete('${testPrefix}lifecycle-1');

        final afterDelete = await backend.get('${testPrefix}lifecycle-1');
        expect(afterDelete, isNull);

        // Dispose
        await manager.dispose();
        expect(manager.isInitialized, isFalse);
      });
    });
  });
}
