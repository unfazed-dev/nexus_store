import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_crdt_adapter/nexus_store_crdt_adapter.dart';
import 'package:test/test.dart';

/// Test model for error handling tests.
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
}

void main() {
  group('CrdtBackend Error Handling', () {
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

    group('uninitialized state guards', () {
      test('get throws StateError when uninitialized', () async {
        expect(
          () => backend.get('1'),
          throwsA(
            isA<nexus.StateError>()
                .having((e) => e.message, 'message',
                    contains('Backend not initialized'))
                .having((e) => e.currentState, 'currentState', 'uninitialized')
                .having((e) => e.expectedState, 'expectedState', 'initialized'),
          ),
        );
      });

      test('getAll throws StateError when uninitialized', () async {
        expect(
          () => backend.getAll(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('save throws StateError when uninitialized', () async {
        expect(
          () => backend.save(TestModel(id: '1', name: 'Test')),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('saveAll throws StateError when uninitialized', () async {
        expect(
          () => backend.saveAll([TestModel(id: '1', name: 'Test')]),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('delete throws StateError when uninitialized', () async {
        expect(
          () => backend.delete('1'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('deleteAll throws StateError when uninitialized', () async {
        expect(
          () => backend.deleteAll(['1']),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('deleteWhere throws StateError when uninitialized', () async {
        expect(
          () => backend.deleteWhere(const nexus.Query<TestModel>()),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('watch throws StateError when uninitialized', () {
        expect(
          () => backend.watch('1'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('watchAll throws StateError when uninitialized', () {
        expect(
          () => backend.watchAll(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('sync throws StateError when uninitialized', () async {
        expect(
          () => backend.sync(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('pendingChangesCount throws StateError when uninitialized',
          () async {
        expect(
          () => backend.pendingChangesCount,
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('nodeId throws StateError when uninitialized', () {
        expect(
          () => backend.nodeId,
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('getAllPaged throws StateError when uninitialized', () async {
        expect(
          () => backend.getAllPaged(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('watchAllPaged throws StateError when uninitialized', () {
        expect(
          () => backend.watchAllPaged(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('getChangeset throws StateError when uninitialized', () async {
        expect(
          () => backend.getChangeset(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('applyChangeset throws StateError when uninitialized', () async {
        expect(
          () => backend.applyChangeset({}),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('retryChange throws StateError when uninitialized', () async {
        expect(
          () => backend.retryChange('change-1'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('cancelChange throws StateError when uninitialized', () async {
        expect(
          () => backend.cancelChange('change-1'),
          throwsA(isA<nexus.StateError>()),
        );
      });
    });

    group('exception mapping', () {
      setUp(() async {
        await backend.initialize();
      });

      test('StoreError passes through unchanged', () async {
        // When a nexus.StoreError is already thrown, it should pass through
        final backendWithBadFromJson = CrdtBackend<TestModel, String>(
          tableName: 'test_models_bad',
          getId: (m) => m.id,
          fromJson: (json) {
            throw nexus.ValidationError(message: 'Custom validation error');
          },
          toJson: (m) => m.toJson(),
          primaryKeyField: 'id',
        );
        await backendWithBadFromJson.initialize();
        await backendWithBadFromJson.save(TestModel(id: '1', name: 'Test'));

        expect(
          () => backendWithBadFromJson.get('1'),
          throwsA(
            isA<nexus.ValidationError>()
                .having((e) => e.message, 'message', 'Custom validation error'),
          ),
        );

        await backendWithBadFromJson.close();
      });

      test('saveAll returns empty list for empty input', () async {
        final result = await backend.saveAll([]);
        expect(result, isEmpty);
      });

      test('deleteAll returns 0 for empty input', () async {
        final result = await backend.deleteAll([]);
        expect(result, equals(0));
      });

      test('deleteWhere returns 0 when no items match', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));

        final query =
            const nexus.Query<TestModel>().where('age', isEqualTo: 999);
        final result = await backend.deleteWhere(query);
        expect(result, equals(0));
      });
    });

    group('supportsPagination', () {
      test('supportsPagination returns true', () {
        expect(backend.supportsPagination, isTrue);
      });
    });

    group('pendingChangesStream', () {
      setUp(() async {
        await backend.initialize();
      });

      test('pendingChangesStream returns stream', () {
        final stream = backend.pendingChangesStream;
        expect(stream, isNotNull);
        expect(stream, isA<Stream<List<nexus.PendingChange<TestModel>>>>());
      });
    });

    group('conflictsStream', () {
      setUp(() async {
        await backend.initialize();
      });

      test('conflictsStream returns stream', () {
        final stream = backend.conflictsStream;
        expect(stream, isNotNull);
        expect(stream, isA<Stream<nexus.ConflictDetails<TestModel>>>());
      });
    });
  });
}
