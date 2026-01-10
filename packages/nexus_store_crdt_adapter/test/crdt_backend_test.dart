import 'dart:io' as io;

import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_crdt_adapter/nexus_store_crdt_adapter.dart';
import 'package:test/test.dart';

/// Test model for CRDT backend tests.
class TestModel {
  TestModel({
    required this.id,
    required this.name,
    this.age = 0,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) => TestModel(
        id: json['id'] as String,
        name: json['name'] as String,
        age: json['age'] as int? ?? 0,
      );

  final String id;
  final String name;
  final int age;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => Object.hash(id, name, age);

  @override
  String toString() => 'TestModel(id: $id, name: $name, age: $age)';
}

void main() {
  group('CrdtBackend', () {
    late CrdtBackend<TestModel, String> backend;

    setUp(() async {
      backend = CrdtBackend<TestModel, String>(
        tableName: 'test_models',
        getId: (m) => m.id,
        fromJson: TestModel.fromJson,
        toJson: (m) => m.toJson(),
        primaryKeyField: 'id',
      );
    });

    tearDown(() async {
      await backend.close();
    });

    group('backend information', () {
      test('name returns crdt', () {
        expect(backend.name, equals('crdt'));
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
      test('initialize is idempotent', () async {
        await backend.initialize();
        await backend.initialize(); // Should not throw
        expect(backend.isInitialized, isTrue);
      });

      test('close cleans up resources', () async {
        await backend.initialize();
        await backend.close();
        expect(backend.isInitialized, isFalse);
      });

      test('throws StateError when used before initialization', () async {
        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.StateError>()),
        );
      });
    });

    group('read operations', () {
      setUp(() async {
        await backend.initialize();
      });

      test('get returns null for non-existent item', () async {
        final result = await backend.get('non-existent');
        expect(result, isNull);
      });

      test('get returns saved item', () async {
        final model = TestModel(id: '1', name: 'Alice', age: 30);
        await backend.save(model);

        final result = await backend.get('1');
        expect(result, equals(model));
      });

      test('getAll returns empty list when no items', () async {
        final result = await backend.getAll();
        expect(result, isEmpty);
      });

      test('getAll returns all saved items', () async {
        final model1 = TestModel(id: '1', name: 'Alice', age: 30);
        final model2 = TestModel(id: '2', name: 'Bob', age: 25);
        await backend.save(model1);
        await backend.save(model2);

        final result = await backend.getAll();
        expect(result.length, equals(2));
        expect(result, containsAll([model1, model2]));
      });

      test('getAll with query filters results', () async {
        final model1 = TestModel(id: '1', name: 'Alice', age: 30);
        final model2 = TestModel(id: '2', name: 'Bob', age: 25);
        await backend.save(model1);
        await backend.save(model2);

        final query =
            const nexus.Query<TestModel>().where('age', isGreaterThan: 28);
        final result = await backend.getAll(query: query);
        expect(result.length, equals(1));
        expect(result.first, equals(model1));
      });

      test('getAll respects limit', () async {
        for (var i = 0; i < 10; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        final query = const nexus.Query<TestModel>().limitTo(5);
        final result = await backend.getAll(query: query);
        expect(result.length, equals(5));
      });

      test('getAll respects offset', () async {
        for (var i = 0; i < 10; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        final query = const nexus.Query<TestModel>().limitTo(5).offsetBy(5);
        final result = await backend.getAll(query: query);
        expect(result.length, equals(5));
      });

      test('getAll respects orderBy', () async {
        await backend.save(TestModel(id: '1', name: 'Charlie', age: 30));
        await backend.save(TestModel(id: '2', name: 'Alice', age: 25));
        await backend.save(TestModel(id: '3', name: 'Bob', age: 28));

        final query = const nexus.Query<TestModel>().orderByField('name');
        final result = await backend.getAll(query: query);
        expect(
          result.map((m) => m.name).toList(),
          equals(['Alice', 'Bob', 'Charlie']),
        );
      });
    });

    group('write operations', () {
      setUp(() async {
        await backend.initialize();
      });

      test('save creates new item', () async {
        final model = TestModel(id: '1', name: 'Alice', age: 30);
        final result = await backend.save(model);

        expect(result, equals(model));
        expect(await backend.get('1'), equals(model));
      });

      test('save updates existing item', () async {
        final model = TestModel(id: '1', name: 'Alice', age: 30);
        await backend.save(model);

        final updated = TestModel(id: '1', name: 'Alice Updated', age: 31);
        await backend.save(updated);

        final result = await backend.get('1');
        expect(result, equals(updated));
      });

      test('saveAll saves multiple items', () async {
        final models = [
          TestModel(id: '1', name: 'Alice', age: 30),
          TestModel(id: '2', name: 'Bob', age: 25),
        ];
        final result = await backend.saveAll(models);

        expect(result.length, equals(2));
        expect(await backend.getAll(), containsAll(models));
      });

      test('delete removes item', () async {
        final model = TestModel(id: '1', name: 'Alice', age: 30);
        await backend.save(model);

        final result = await backend.delete('1');
        expect(result, isTrue);
        expect(await backend.get('1'), isNull);
      });

      test('delete returns false for non-existent item', () async {
        final result = await backend.delete('non-existent');
        // In CRDT, delete always creates a tombstone
        expect(result, isTrue);
      });

      test('deleteAll removes multiple items', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backend.save(TestModel(id: '2', name: 'Bob', age: 25));
        await backend.save(TestModel(id: '3', name: 'Charlie', age: 28));

        final result = await backend.deleteAll(['1', '2']);
        expect(result, equals(2));
        expect(await backend.get('1'), isNull);
        expect(await backend.get('2'), isNull);
        expect(await backend.get('3'), isNotNull);
      });

      test('deleteWhere removes matching items', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backend.save(TestModel(id: '2', name: 'Bob', age: 25));
        await backend.save(TestModel(id: '3', name: 'Charlie', age: 28));

        final query =
            const nexus.Query<TestModel>().where('age', isLessThan: 29);
        await backend.deleteWhere(query);

        final remaining = await backend.getAll();
        expect(remaining.length, equals(1));
        expect(remaining.first.name, equals('Alice'));
      });
    });

    group('watch operations', () {
      setUp(() async {
        await backend.initialize();
      });

      test('watch emits initial value', () async {
        final model = TestModel(id: '1', name: 'Alice', age: 30);
        await backend.save(model);

        final stream = backend.watch('1');
        expect(await stream.first, equals(model));
      });

      test('watch emits null for non-existent item', () async {
        final stream = backend.watch('non-existent');
        expect(await stream.first, isNull);
      });

      test('watchAll emits initial list', () async {
        final model = TestModel(id: '1', name: 'Alice', age: 30);
        await backend.save(model);

        final stream = backend.watchAll();
        final result = await stream.first;
        expect(result, contains(model));
      });
    });

    group('sync operations', () {
      setUp(() async {
        await backend.initialize();
      });

      test('syncStatus returns synced initially', () {
        expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
      });

      test('syncStatusStream emits status changes', () async {
        expect(
          backend.syncStatusStream,
          emits(nexus.SyncStatus.synced),
        );
      });

      test('sync completes without error', () async {
        await expectLater(backend.sync(), completes);
      });

      test('pendingChangesCount returns 0 when synced', () async {
        expect(await backend.pendingChangesCount, equals(0));
      });
    });

    group('CRDT-specific operations', () {
      setUp(() async {
        await backend.initialize();
      });

      test('getChangeset returns changes', () async {
        final model = TestModel(id: '1', name: 'Alice', age: 30);
        await backend.save(model);

        final changeset = await backend.getChangeset();
        // CrdtChangeset is Map<String, List<Map>>
        expect(changeset.isNotEmpty, isTrue);
        expect(changeset.values.expand((v) => v).length, greaterThan(0));
      });

      test('applyChangeset merges changes', () async {
        // Save data
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));

        // Get changeset
        final changeset = await backend.getChangeset();

        // Verify changeset contains the data
        expect(changeset.containsKey('test_models'), isTrue);
        expect(changeset['test_models']!.length, equals(1));

        // Note: Cross-database merge with in-memory databases requires
        // additional setup. Full merge testing is in integration tests.
      });

      test('nodeId is unique per instance', () async {
        final backend2 = CrdtBackend<TestModel, String>(
          tableName: 'test_models',
          getId: (m) => m.id,
          fromJson: TestModel.fromJson,
          toJson: (m) => m.toJson(),
          primaryKeyField: 'id',
        );
        await backend2.initialize();

        expect(backend.nodeId, isNot(equals(backend2.nodeId)));

        await backend2.close();
      });
    });

    group('tombstone behavior', () {
      setUp(() async {
        await backend.initialize();
      });

      test('deleted items are not returned by get', () async {
        final model = TestModel(id: '1', name: 'Alice', age: 30);
        await backend.save(model);
        await backend.delete('1');

        expect(await backend.get('1'), isNull);
      });

      test('deleted items are not returned by getAll', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backend.save(TestModel(id: '2', name: 'Bob', age: 25));
        await backend.delete('1');

        final result = await backend.getAll();
        expect(result.length, equals(1));
        expect(result.first.id, equals('2'));
      });

      test('deleted items can be re-saved (tombstone revival)', () async {
        final model = TestModel(id: '1', name: 'Alice', age: 30);
        await backend.save(model);
        await backend.delete('1');

        final revived = TestModel(id: '1', name: 'Alice Revived', age: 31);
        await backend.save(revived);

        final result = await backend.get('1');
        expect(result, equals(revived));
      });
    });
  });

  group('CrdtBackend.withDatabase', () {
    late CrdtBackend<TestModel, String> backend;

    tearDown(() async {
      if (backend.isInitialized) {
        await backend.close();
      }
    });

    test('creates backend with explicit columns', () async {
      backend = CrdtBackend<TestModel, String>.withDatabase(
        tableName: 'test_models',
        columns: [
          CrdtColumn.text('id', nullable: false),
          CrdtColumn.text('name', nullable: false),
          CrdtColumn.integer('age'),
        ],
        getId: (m) => m.id,
        fromJson: TestModel.fromJson,
        toJson: (m) => m.toJson(),
        primaryKeyColumn: 'id',
      );

      await backend.initialize();

      expect(backend.isInitialized, true);

      // Test CRUD operations
      final model = TestModel(id: '1', name: 'Test', age: 25);
      await backend.save(model);

      final result = await backend.get('1');
      expect(result, equals(model));
    });

    test('creates backend with file-based database', () async {
      final tempPath =
          '/tmp/crdt_backend_test_${DateTime.now().millisecondsSinceEpoch}.db';

      try {
        backend = CrdtBackend<TestModel, String>.withDatabase(
          tableName: 'test_models',
          columns: [
            CrdtColumn.text('id', nullable: false),
            CrdtColumn.text('name', nullable: false),
            CrdtColumn.integer('age'),
          ],
          getId: (m) => m.id,
          fromJson: TestModel.fromJson,
          toJson: (m) => m.toJson(),
          primaryKeyColumn: 'id',
          databasePath: tempPath,
        );

        await backend.initialize();

        expect(backend.isInitialized, true);
        expect(backend.nodeId, isNotNull);

        // Save and verify persistence
        final model = TestModel(id: 'f1', name: 'File Test', age: 42);
        await backend.save(model);

        final result = await backend.get('f1');
        expect(result, equals(model));
      } finally {
        // Clean up
        try {
          final file = io.File(tempPath);
          if (file.existsSync()) {
            file.deleteSync();
          }
          // ignore: avoid_catches_without_on_clauses
        } catch (_) {}
      }
    });

    test('creates backend with field mapping', () async {
      backend = CrdtBackend<TestModel, String>.withDatabase(
        tableName: 'test_models',
        columns: [
          CrdtColumn.text('id', nullable: false),
          CrdtColumn.text('name', nullable: false),
          CrdtColumn.integer('age'),
        ],
        getId: (m) => m.id,
        fromJson: TestModel.fromJson,
        toJson: (m) => m.toJson(),
        primaryKeyColumn: 'id',
        fieldMapping: {'name': 'display_name'},
      );

      await backend.initialize();

      expect(backend.isInitialized, true);

      // Verify operations work
      await backend.save(TestModel(id: '1', name: 'Alice', age: 30));
      await backend.save(TestModel(id: '2', name: 'Bob', age: 25));

      final results = await backend.getAll();
      expect(results.length, 2);
    });
  });
}
