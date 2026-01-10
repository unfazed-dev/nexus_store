/// Integration tests for PowerSyncManager with real PowerSync database.
///
/// These tests verify the full lifecycle of the manager:
/// - initialize() - creates shared database and all backends
/// - getBackend() - retrieves typed backends after initialization
/// - dispose() - closes all backends and the shared database
///
/// ## Requirements
/// 1. **PowerSync native library** (libpowersync.dylib / .so / .dll)
/// 2. **SQLite with extension loading support** (Homebrew SQLite on macOS)
/// 3. **Active Supabase project** with test tables
/// 4. **Valid credentials** in test_config.dart
///
/// ## Running Tests
/// ```bash
/// dart test test/integration/powersync_manager_integration_test.dart
/// # or
/// dart test --tags=integration,manager
/// ```
@Tags(['integration', 'manager'])
@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

import '../test_config.dart';
import '../test_utils/powersync_test_utils.dart';
import 'test_item_model.dart';

/// Second test model for multi-table testing.
class TestNote {
  TestNote({required this.id, required this.content});

  factory TestNote.fromJson(Map<String, dynamic> json) => TestNote(
        id: json['id'] as String,
        content: json['content'] as String,
      );

  final String id;
  final String content;

  Map<String, dynamic> toJson() => {'id': id, 'content': content};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestNote &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          content == other.content;

  @override
  int get hashCode => Object.hash(id, content);
}

/// Tracks whether PowerSync native library is available.
bool _nativeLibraryAvailable = false;
String? _skipReason;

/// Runs a test only if PowerSync native library is available.
void testWithNativeLib(
  String description,
  Future<void> Function() body, {
  Object? skip,
}) {
  test(
    description,
    () async {
      if (!_nativeLibraryAvailable) {
        markTestSkipped(
          _skipReason ?? 'PowerSync native library not available',
        );
        return;
      }
      await body();
    },
    skip: skip,
  );
}

void main() {
  group('PowerSyncManager Integration Tests', () {
    late SupabaseClient supabase;

    setUpAll(() async {
      // Check if PowerSync library and Homebrew SQLite are available
      if (!isHomebrewSqliteAvailable()) {
        _skipReason = 'Homebrew SQLite not installed. Run: brew install sqlite';
        _nativeLibraryAvailable = false;
        return;
      }

      final (available, error) = checkPowerSyncLibraryAvailable();
      if (!available) {
        _skipReason = error;
        _nativeLibraryAvailable = false;
        return;
      }

      // Verify by creating a test database
      final tempDir = Directory.systemTemp;
      final testPath =
          '${tempDir.path}/manager_check_${DateTime.now().microsecondsSinceEpoch}.db';

      try {
        final testDb = createTestPowerSyncDatabase(
          schema: testItemsSchema,
          path: testPath,
        );
        await testDb.initialize();
        await testDb.close();

        // Clean up test database
        final testFile = File(testPath);
        if (testFile.existsSync()) {
          testFile.deleteSync();
        }

        _nativeLibraryAvailable = true;
        // ignore: avoid_catches_without_on_clauses
      } catch (e) {
        _skipReason = 'PowerSync database initialization failed: $e';
        _nativeLibraryAvailable = false;
      }

      // Create Supabase client
      supabase = SupabaseClient(
        TestConfig.supabaseUrl,
        TestConfig.supabaseAnonKey,
      );
    });

    tearDownAll(() {
      supabase.dispose();
    });

    group('Factory', () {
      testWithNativeLib('withSupabase creates manager', () async {
        final manager = PowerSyncManager.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tables: [testItemsConfig],
          databaseAdapterFactory: createTestDatabaseAdapterFactory(),
        );

        expect(manager, isNotNull);
        expect(manager.powerSyncUrl, equals(TestConfig.powersyncUrl));
        expect(manager.isInitialized, isFalse);
      });

      testWithNativeLib('withSupabase with custom dbPath', () async {
        final tempDir = Directory.systemTemp;
        final customPath =
            '${tempDir.path}/manager_custom_${DateTime.now().microsecondsSinceEpoch}.db';

        final manager = PowerSyncManager.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tables: [testItemsConfig],
          dbPath: customPath,
          databaseAdapterFactory: createTestDatabaseAdapterFactory(),
        );

        expect(manager, isNotNull);
        expect(manager.dbPath, equals(customPath));
      });

      testWithNativeLib('withSupabase with multiple tables', () async {
        final notesConfig = PSTableConfig<TestNote, String>(
          tableName: 'test_notes',
          columns: [PSColumn.text('content')],
          fromJson: TestNote.fromJson,
          toJson: (note) => note.toJson(),
          getId: (note) => note.id,
        );

        final manager = PowerSyncManager.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tables: [testItemsConfig, notesConfig],
          databaseAdapterFactory: createTestDatabaseAdapterFactory(),
        );

        expect(manager.tableNames, containsAll(['test_items', 'test_notes']));
        expect(manager.hasTable('test_items'), isTrue);
        expect(manager.hasTable('test_notes'), isTrue);
        expect(manager.hasTable('nonexistent'), isFalse);
      });
    });

    group('Schema Generation', () {
      testWithNativeLib('generateSchema creates combined schema', () async {
        final notesConfig = PSTableConfig<TestNote, String>(
          tableName: 'test_notes',
          columns: [PSColumn.text('content')],
          fromJson: TestNote.fromJson,
          toJson: (note) => note.toJson(),
          getId: (note) => note.id,
        );

        final manager = PowerSyncManager.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tables: [testItemsConfig, notesConfig],
          databaseAdapterFactory: createTestDatabaseAdapterFactory(),
        );

        final schema = manager.generateSchema();

        expect(schema, isA<ps.Schema>());
        expect(schema.tables.length, equals(2));
        expect(
          schema.tables.map((t) => t.name),
          containsAll(['test_items', 'test_notes']),
        );
      });
    });

    group('Initialization', () {
      testWithNativeLib('initialize creates database and backends', () async {
        final manager = PowerSyncManager.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tables: [testItemsConfig],
          databaseAdapterFactory: createTestDatabaseAdapterFactory(),
        );

        expect(manager.isInitialized, isFalse);

        await manager.initialize();

        expect(manager.isInitialized, isTrue);

        // Clean up
        await manager.dispose();
      });

      testWithNativeLib('initialize is idempotent', () async {
        final manager = PowerSyncManager.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tables: [testItemsConfig],
          databaseAdapterFactory: createTestDatabaseAdapterFactory(),
        );

        await manager.initialize();
        await manager.initialize();
        await manager.initialize();

        expect(manager.isInitialized, isTrue);

        await manager.dispose();
      });

      testWithNativeLib('cannot initialize after dispose', () async {
        final manager = PowerSyncManager.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tables: [testItemsConfig],
          databaseAdapterFactory: createTestDatabaseAdapterFactory(),
        );

        await manager.initialize();
        await manager.dispose();

        // Attempting to initialize a disposed manager should throw
        await expectLater(
          manager.initialize(),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('getBackend', () {
      testWithNativeLib('returns backend after initialize', () async {
        final manager = PowerSyncManager.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tables: [testItemsConfig],
          databaseAdapterFactory: createTestDatabaseAdapterFactory(),
        );

        await manager.initialize();

        final backend = manager.getBackend<TestItem, String>('test_items');

        // Due to generic invariance, backends are stored as dynamic
        expect(backend, isA<PowerSyncBackend<dynamic, dynamic>>());
        expect(backend.name, equals('powersync'));

        await manager.dispose();
      });

      testWithNativeLib('throws StateError before initialize', () async {
        final manager = PowerSyncManager.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tables: [testItemsConfig],
          databaseAdapterFactory: createTestDatabaseAdapterFactory(),
        );

        expect(
          () => manager.getBackend<TestItem, String>('test_items'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('not initialized'),
            ),
          ),
        );
      });

      testWithNativeLib('throws ArgumentError for unregistered table',
          () async {
        final manager = PowerSyncManager.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tables: [testItemsConfig],
          databaseAdapterFactory: createTestDatabaseAdapterFactory(),
        );

        await manager.initialize();

        expect(
          () => manager.getBackend<TestNote, String>('test_notes'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('not registered'),
            ),
          ),
        );

        await manager.dispose();
      });

      testWithNativeLib('returns multiple backends for multiple tables',
          () async {
        final notesConfig = PSTableConfig<TestNote, String>(
          tableName: 'test_notes',
          columns: [PSColumn.text('content')],
          fromJson: TestNote.fromJson,
          toJson: (note) => note.toJson(),
          getId: (note) => note.id,
        );

        final manager = PowerSyncManager.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tables: [testItemsConfig, notesConfig],
          databaseAdapterFactory: createTestDatabaseAdapterFactory(),
        );

        await manager.initialize();

        final itemsBackend = manager.getBackend<TestItem, String>('test_items');
        final notesBackend = manager.getBackend<TestNote, String>('test_notes');

        expect(itemsBackend, isNotNull);
        expect(notesBackend, isNotNull);
        expect(itemsBackend, isNot(same(notesBackend)));

        await manager.dispose();
      });
    });

    group('Dispose', () {
      testWithNativeLib('dispose closes all backends and database', () async {
        final manager = PowerSyncManager.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tables: [testItemsConfig],
          databaseAdapterFactory: createTestDatabaseAdapterFactory(),
        );

        await manager.initialize();
        expect(manager.isInitialized, isTrue);

        await manager.dispose();

        // After dispose, accessing backends should throw
        expect(
          () => manager.getBackend<TestItem, String>('test_items'),
          throwsA(isA<StateError>()),
        );
      });

      testWithNativeLib('dispose is idempotent', () async {
        final manager = PowerSyncManager.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tables: [testItemsConfig],
          databaseAdapterFactory: createTestDatabaseAdapterFactory(),
        );

        await manager.initialize();

        // Multiple dispose calls should not throw
        await manager.dispose();
        await manager.dispose();
        await manager.dispose();
      });

      testWithNativeLib('dispose before initialize is safe', () async {
        final manager = PowerSyncManager.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tables: [testItemsConfig],
          databaseAdapterFactory: createTestDatabaseAdapterFactory(),
        );

        // Should not throw
        await manager.dispose();
      });
    });

    group('Backend Operations', () {
      late PowerSyncManager manager;
      late PowerSyncBackend<dynamic, dynamic> backend;
      final createdIds = <String>[];

      setUp(() async {
        if (!_nativeLibraryAvailable) return;

        manager = PowerSyncManager.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tables: [testItemsConfig],
          databaseAdapterFactory: createTestDatabaseAdapterFactory(),
        );

        await manager.initialize();
        backend = manager.getBackend<TestItem, String>('test_items');
      });

      tearDown(() async {
        if (!_nativeLibraryAvailable) return;

        // Clean up test data
        for (final id in createdIds) {
          try {
            await supabase.rest.from('test_items').delete().eq('id', id);
          } on PostgrestException catch (_) {
            // Ignore cleanup errors
          }
        }
        createdIds.clear();

        await manager.dispose();
      });

      testWithNativeLib('backend CRUD operations work', () async {
        final id = generateTestId('manager_crud');
        createdIds.add(id);

        // Save
        final item = TestItem(id: id, name: 'Manager Test', value: 123);
        final saved = await backend.save(item);
        // ignore: avoid_dynamic_calls
        expect(saved.id, equals(id));

        // Get
        final retrieved = await backend.get(id);
        expect(retrieved, isNotNull);
        // ignore: avoid_dynamic_calls
        expect(retrieved!.name, equals('Manager Test'));

        // Update
        final updated =
            await backend.save(TestItem(id: id, name: 'Updated', value: 456));
        // ignore: avoid_dynamic_calls
        expect(updated.name, equals('Updated'));

        // Delete
        final deleted = await backend.delete(id);
        expect(deleted, isTrue);

        // Verify deleted
        final afterDelete = await backend.get(id);
        expect(afterDelete, isNull);
      });
    });
  });
}
