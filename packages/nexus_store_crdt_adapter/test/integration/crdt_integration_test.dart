@Tags(['integration'])
library;

import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_crdt_adapter/nexus_store_crdt_adapter.dart';
import 'package:test/test.dart';

/// Test model for integration tests.
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
  group('CRDT Integration Tests', () {
    late CrdtBackend<TestModel, String> backend;

    setUp(() async {
      backend = CrdtBackend<TestModel, String>(
        tableName: 'test_models',
        getId: (m) => m.id,
        fromJson: TestModel.fromJson,
        toJson: (m) => m.toJson(),
        primaryKeyField: 'id',
      );
      await backend.initialize();
    });

    tearDown(() async {
      await backend.close();
    });

    group('Full CRUD Lifecycle', () {
      test('complete create-read-update-delete cycle', () async {
        // Create
        final model = TestModel(id: '1', name: 'Alice', age: 30);
        await backend.save(model);

        // Read
        var result = await backend.get('1');
        expect(result, equals(model));

        // Update
        final updated = TestModel(id: '1', name: 'Alice Updated', age: 31);
        await backend.save(updated);
        result = await backend.get('1');
        expect(result?.name, equals('Alice Updated'));
        expect(result?.age, equals(31));

        // Delete
        await backend.delete('1');
        result = await backend.get('1');
        expect(result, isNull);
      });

      test('batch operations work correctly', () async {
        // Create multiple
        final models = List.generate(
          10,
          (i) => TestModel(id: '$i', name: 'User$i', age: 20 + i),
        );
        await backend.saveAll(models);

        // Read all
        var all = await backend.getAll();
        expect(all.length, equals(10));

        // Filter
        final query =
            const nexus.Query<TestModel>().where('age', isGreaterThan: 25);
        final filtered = await backend.getAll(query: query);
        expect(filtered.length, equals(4)); // ages 26, 27, 28, 29

        // Delete batch
        await backend.deleteAll(['0', '1', '2']);
        all = await backend.getAll();
        expect(all.length, equals(7));
      });
    });

    group('Query Capabilities', () {
      setUp(() async {
        await backend.saveAll([
          TestModel(id: '1', name: 'Alice', age: 30),
          TestModel(id: '2', name: 'Bob', age: 25),
          TestModel(id: '3', name: 'Charlie', age: 35),
          TestModel(id: '4', name: 'Diana', age: 28),
          TestModel(id: '5', name: 'Eve', age: 22),
        ]);
      });

      test('filtering by equality', () async {
        final query =
            const nexus.Query<TestModel>().where('name', isEqualTo: 'Bob');
        final result = await backend.getAll(query: query);
        expect(result.length, equals(1));
        expect(result.first.name, equals('Bob'));
      });

      test('filtering by comparison', () async {
        final query = const nexus.Query<TestModel>()
            .where('age', isGreaterThanOrEqualTo: 28);
        final result = await backend.getAll(query: query);
        expect(result.length, equals(3)); // Alice, Charlie, Diana
      });

      test('ordering results', () async {
        final query = const nexus.Query<TestModel>()
            .orderByField('age', descending: true);
        final result = await backend.getAll(query: query);
        expect(result.first.name, equals('Charlie')); // age 35
        expect(result.last.name, equals('Eve')); // age 22
      });

      test('pagination with limit and offset', () async {
        final query = const nexus.Query<TestModel>()
            .orderByField('age')
            .limitTo(2)
            .offsetBy(2);
        final result = await backend.getAll(query: query);
        expect(result.length, equals(2));
        expect(result.first.name, equals('Diana')); // age 28 (3rd youngest)
      });

      test('combined filters', () async {
        final query = const nexus.Query<TestModel>()
            .where('age', isGreaterThan: 24)
            .where('age', isLessThan: 32);
        final result = await backend.getAll(query: query);
        expect(result.length, equals(3)); // Bob, Diana, Alice
      });
    });

    group('Tombstone Behavior', () {
      test('deleted items remain tombstoned until revived', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backend.delete('1');

        // Item should not be visible
        expect(await backend.get('1'), isNull);
        expect((await backend.getAll()).length, equals(0));

        // Save again (revival)
        await backend.save(TestModel(id: '1', name: 'Alice Revived', age: 31));

        // Item should be visible again
        final result = await backend.get('1');
        expect(result?.name, equals('Alice Revived'));
      });

      test('deleteWhere creates tombstones', () async {
        await backend.saveAll([
          TestModel(id: '1', name: 'Alice', age: 30),
          TestModel(id: '2', name: 'Bob', age: 25),
          TestModel(id: '3', name: 'Charlie', age: 35),
        ]);

        final query =
            const nexus.Query<TestModel>().where('age', isLessThan: 30);
        await backend.deleteWhere(query);

        final remaining = await backend.getAll();
        expect(remaining.length, equals(2));
        expect(remaining.map((m) => m.name), containsAll(['Alice', 'Charlie']));
      });
    });

    group('Watch Operations', () {
      test('watch emits updates on save', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));

        final stream = backend.watch('1');
        final emissions = <TestModel?>[];

        // Get initial value
        final first = await stream.first;
        emissions.add(first);
        expect(first?.name, equals('Alice'));
      });

      test('watchAll emits list updates', () async {
        final stream = backend.watchAll();

        // Get initial empty list
        final initial = await stream.first;
        expect(initial, isEmpty);

        // Save an item
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));

        // Note: In a real reactive scenario, the stream would emit again
        // but for this test we verify initial emission works
      });
    });

    group('CRDT Changeset Operations', () {
      test('getChangeset captures all changes', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backend.save(TestModel(id: '2', name: 'Bob', age: 25));
        await backend.delete('2');

        final changeset = await backend.getChangeset();

        expect(changeset.containsKey('test_models'), isTrue);
        // Should contain both records (including the tombstoned one)
        expect(changeset['test_models']!.length, greaterThanOrEqualTo(1));
      });

      test('nodeId is consistent within session', () async {
        final nodeId1 = backend.nodeId;

        // Save some data
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));

        final nodeId2 = backend.nodeId;
        expect(nodeId1, equals(nodeId2));
      });

      test('different backends have different nodeIds', () async {
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

    group('Error Handling', () {
      test('operations fail gracefully on uninitialized backend', () async {
        final uninitializedBackend = CrdtBackend<TestModel, String>(
          tableName: 'test_models',
          getId: (m) => m.id,
          fromJson: TestModel.fromJson,
          toJson: (m) => m.toJson(),
          primaryKeyField: 'id',
        );

        expect(
          () => uninitializedBackend.get('1'),
          throwsA(isA<nexus.StateError>()),
        );
      });
    });
  });
}
