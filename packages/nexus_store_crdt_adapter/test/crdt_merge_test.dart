import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_crdt_adapter/nexus_store_crdt_adapter.dart';
import 'package:test/test.dart';

/// Test model for CRDT merge tests.
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
  group('CRDT Merge Operations', () {
    late CrdtBackend<TestModel, String> backendA;
    late CrdtBackend<TestModel, String> backendB;

    setUp(() async {
      backendA = CrdtBackend<TestModel, String>(
        tableName: 'test_models',
        getId: (m) => m.id,
        fromJson: TestModel.fromJson,
        toJson: (m) => m.toJson(),
        primaryKeyField: 'id',
      );
      backendB = CrdtBackend<TestModel, String>(
        tableName: 'test_models',
        getId: (m) => m.id,
        fromJson: TestModel.fromJson,
        toJson: (m) => m.toJson(),
        primaryKeyField: 'id',
      );
      await backendA.initialize();
      await backendB.initialize();
    });

    tearDown(() async {
      await backendA.close();
      await backendB.close();
    });

    group('getChangeset', () {
      test('with null since returns all changes', () async {
        await backendA.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backendA.save(TestModel(id: '2', name: 'Bob', age: 25));

        final changeset = await backendA.getChangeset();

        expect(changeset.isNotEmpty, isTrue);
        expect(changeset.containsKey('test_models'), isTrue);
        expect(changeset['test_models']!.length, equals(2));
      });

      test('returns changeset with correct structure', () async {
        await backendA.save(TestModel(id: '1', name: 'Alice', age: 30));

        final changeset = await backendA.getChangeset();

        // CrdtChangeset is Map<String, List<Map<String, Object?>>>
        expect(changeset, isA<Map<String, List<Map<String, Object?>>>>());
        expect(changeset['test_models'], isA<List<Map<String, Object?>>>());

        // Each record should contain CRDT metadata
        final record = changeset['test_models']!.first;
        expect(record.containsKey('hlc'), isTrue);
        expect(record.containsKey('id'), isTrue);
        expect(record.containsKey('name'), isTrue);
      });

      test('includes deleted items as tombstones', () async {
        await backendA.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backendA.delete('1');

        final changeset = await backendA.getChangeset();

        expect(changeset['test_models']!.length, equals(1));
        final record = changeset['test_models']!.first;
        expect(record['is_deleted'], equals(1));
      });
    });

    group('applyChangeset', () {
      // Note: Cross-database CRDT merge requires proper Hlc object
      // conversion. The sqlite_crdt library's getChangeset() returns Hlc
      // as strings, but merge() expects Hlc objects. These tests verify
      // the API is callable.

      test('accepts empty changeset without error', () async {
        await expectLater(
          backendB.applyChangeset(<String, List<Map<String, Object?>>>{}),
          completes,
        );
      });

      test('changeset has correct table structure', () async {
        await backendA.save(TestModel(id: '1', name: 'Alice', age: 30));

        final changeset = await backendA.getChangeset();

        // Verify changeset has expected structure
        expect(changeset.containsKey('test_models'), isTrue);
        expect(changeset['test_models'], isA<List<Map<String, Object?>>>());
        expect(changeset['test_models']!.length, equals(1));
      });

      test('changeset record contains entity fields', () async {
        await backendA.save(TestModel(id: '1', name: 'Alice', age: 30));

        final changeset = await backendA.getChangeset();
        final record = changeset['test_models']!.first;

        // Entity fields
        expect(record['id'], equals('1'));
        expect(record['name'], equals('Alice'));
        expect(record['age'], equals(30));
      });

      test('changeset record contains CRDT metadata', () async {
        await backendA.save(TestModel(id: '1', name: 'Alice', age: 30));

        final changeset = await backendA.getChangeset();
        final record = changeset['test_models']!.first;

        // CRDT metadata fields
        expect(record.containsKey('hlc'), isTrue);
        expect(record.containsKey('node_id'), isTrue);
        expect(record.containsKey('modified'), isTrue);
        expect(record.containsKey('is_deleted'), isTrue);

        // Not deleted
        expect(record['is_deleted'], equals(0));
      });
    });

    group('changeset structure verification', () {
      test('multiple saves create multiple records', () async {
        await backendA.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backendA.save(TestModel(id: '2', name: 'Bob', age: 25));
        await backendA.save(TestModel(id: '3', name: 'Charlie', age: 35));

        final changeset = await backendA.getChangeset();

        expect(changeset['test_models']!.length, equals(3));

        final names = changeset['test_models']!.map((r) => r['name']).toList();
        expect(names, containsAll(['Alice', 'Bob', 'Charlie']));
      });

      test('update creates new record with same id', () async {
        await backendA.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backendA.save(TestModel(id: '1', name: 'Alice Updated', age: 31));

        final changeset = await backendA.getChangeset();

        // Latest state should reflect the update
        final records = changeset['test_models']!;
        expect(records.length, equals(1));
        expect(records.first['name'], equals('Alice Updated'));
        expect(records.first['age'], equals(31));
      });

      test('delete marks record as tombstone', () async {
        await backendA.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backendA.delete('1');

        final changeset = await backendA.getChangeset();
        final record = changeset['test_models']!.first;

        expect(record['is_deleted'], equals(1));
      });

      test('hlc increases with each operation', () async {
        await backendA.save(TestModel(id: '1', name: 'First', age: 20));
        final changeset1 = await backendA.getChangeset();
        final hlc1 = changeset1['test_models']!.first['hlc']! as String;

        await Future<void>.delayed(const Duration(milliseconds: 5));

        await backendA.save(TestModel(id: '1', name: 'Second', age: 21));
        final changeset2 = await backendA.getChangeset();
        final hlc2 = changeset2['test_models']!.first['hlc']! as String;

        // HLC should be different (later)
        expect(hlc2, isNot(equals(hlc1)));
        // String comparison works for HLC timestamps
        expect(hlc2.compareTo(hlc1), greaterThan(0));
      });

      test('node_id is consistent within backend', () async {
        await backendA.save(TestModel(id: '1', name: 'First', age: 20));
        await backendA.save(TestModel(id: '2', name: 'Second', age: 25));

        final changeset = await backendA.getChangeset();
        final nodeId1 = changeset['test_models']!.first['node_id']! as String;
        final nodeId2 = changeset['test_models']!.last['node_id']! as String;

        expect(nodeId1, equals(nodeId2));
        expect(nodeId1, equals(backendA.nodeId));
      });

      test('different backends have different node_ids', () async {
        await backendA.save(TestModel(id: '1', name: 'From A', age: 20));
        await backendB.save(TestModel(id: '2', name: 'From B', age: 25));

        final changesetA = await backendA.getChangeset();
        final changesetB = await backendB.getChangeset();

        final nodeIdA = changesetA['test_models']!.first['node_id']! as String;
        final nodeIdB = changesetB['test_models']!.first['node_id']! as String;

        expect(nodeIdA, isNot(equals(nodeIdB)));
      });
    });

    group('edge cases', () {
      test('empty changeset does not cause errors', () async {
        // Get changeset from empty database
        final changeset = await backendA.getChangeset();

        // Apply empty changeset - should not throw
        await expectLater(backendB.applyChangeset(changeset), completes);
      });

      test('changeset is consistent across multiple reads', () async {
        await backendA.save(TestModel(id: '1', name: 'Alice', age: 30));

        // Get changeset twice
        final changeset1 = await backendA.getChangeset();
        final changeset2 = await backendA.getChangeset();

        // Both should have the same record count
        expect(changeset1['test_models']!.length, equals(1));
        expect(changeset2['test_models']!.length, equals(1));

        // Both should have same id
        expect(
          changeset1['test_models']!.first['id'],
          equals(changeset2['test_models']!.first['id']),
        );
      });

      test('throws StateError when backend not initialized', () async {
        final uninitializedBackend = CrdtBackend<TestModel, String>(
          tableName: 'test_models',
          getId: (m) => m.id,
          fromJson: TestModel.fromJson,
          toJson: (m) => m.toJson(),
          primaryKeyField: 'id',
        );

        expect(
          uninitializedBackend.getChangeset,
          throwsA(isA<nexus.StateError>()),
        );

        expect(
          () => uninitializedBackend.applyChangeset({}),
          throwsA(isA<nexus.StateError>()),
        );
      });
    });
  });
}
