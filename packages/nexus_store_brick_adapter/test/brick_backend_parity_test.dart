import 'package:brick_core/query.dart' as brick;
import 'package:brick_offline_first/brick_offline_first.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_brick_adapter/nexus_store_brick_adapter.dart';
import 'package:test/test.dart';

// Mock classes
class MockOfflineFirstRepository extends Mock
    implements OfflineFirstRepository<TestModel> {}

// Test model that extends OfflineFirstModel
class TestModel extends OfflineFirstModel {
  TestModel({required this.id, required this.name, int? primaryKeyId})
      : _primaryKeyId = primaryKeyId;

  final String id;
  final String name;
  final int? _primaryKeyId;

  @override
  int? get primaryKey => _primaryKeyId;

  @override
  set primaryKey(int? value) {
    // Required by SqliteModel
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(TestModel(id: 'fallback', name: 'fallback'));
    registerFallbackValue(const brick.Query());
  });

  group('BrickBackend parity tests', () {
    late MockOfflineFirstRepository mockRepository;
    late BrickBackend<TestModel, String> backend;

    setUp(() async {
      mockRepository = MockOfflineFirstRepository();
      backend = BrickBackend<TestModel, String>(
        repository: mockRepository,
        getId: (model) => model.id,
        primaryKeyField: 'id',
      );
      when(() => mockRepository.initialize()).thenAnswer((_) async {});
      await backend.initialize();
    });

    tearDown(() async {
      await backend.close();
    });

    group('exists', () {
      test('returns true when item exists', () async {
        final testModel = TestModel(id: '1', name: 'Test');
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => [testModel]);

        final result = await backend.exists('1');

        expect(result, isTrue);
      });

      test('returns false when item does not exist', () async {
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => []);

        final result = await backend.exists('nonexistent');

        expect(result, isFalse);
      });
    });

    group('existsWhere', () {
      test('returns true when matches found', () async {
        final testModel = TestModel(id: '1', name: 'Active');
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => [testModel]);

        final query =
            const nexus.Query<TestModel>().where('status', isEqualTo: 'active');
        final result = await backend.existsWhere(query);

        expect(result, isTrue);
      });

      test('returns false when no matches found', () async {
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => []);

        final query = const nexus.Query<TestModel>()
            .where('status', isEqualTo: 'deleted');
        final result = await backend.existsWhere(query);

        expect(result, isFalse);
      });
    });

    group('getByIds', () {
      test('returns matching items', () async {
        final model1 = TestModel(id: '1', name: 'First');
        final model2 = TestModel(id: '2', name: 'Second');
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((inv) async {
          final query =
              inv.namedArguments[const Symbol('query')] as brick.Query?;
          if (query == null) return [];
          // Simulate ID-based lookup
          final where = query.where;
          if (where != null && where.isNotEmpty) {
            final idValue = where.first.value;
            if (idValue == '1') return [model1];
            if (idValue == '2') return [model2];
          }
          return [];
        });

        final result = await backend.getByIds(['1', '2']);

        expect(result.length, 2);
        expect(result[0].name, 'First');
        expect(result[1].name, 'Second');
      });

      test('returns empty list for empty input', () async {
        final result = await backend.getByIds([]);

        expect(result, isEmpty);
      });

      test('skips missing items', () async {
        final model1 = TestModel(id: '1', name: 'First');
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((inv) async {
          final query =
              inv.namedArguments[const Symbol('query')] as brick.Query?;
          if (query == null) return [];
          final where = query.where;
          if (where != null && where.isNotEmpty) {
            final idValue = where.first.value;
            if (idValue == '1') return [model1];
          }
          return [];
        });

        final result = await backend.getByIds(['1', 'missing']);

        expect(result.length, 1);
        expect(result[0].name, 'First');
      });

      test('deduplicates IDs', () async {
        final model1 = TestModel(id: '1', name: 'First');
        var callCount = 0;
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async {
          callCount++;
          return [model1];
        });

        final result = await backend.getByIds(['1', '1', '1']);

        expect(result.length, 1);
        // Only called once due to deduplication
        expect(callCount, 1);
      });
    });

    group('count', () {
      test('returns count of all items', () async {
        final items = [
          TestModel(id: '1', name: 'First'),
          TestModel(id: '2', name: 'Second'),
          TestModel(id: '3', name: 'Third'),
        ];
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => items);

        final result = await backend.count();

        expect(result, 3);
      });

      test('returns count with query filter', () async {
        final items = [TestModel(id: '1', name: 'Active')];
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => items);

        final query =
            const nexus.Query<TestModel>().where('status', isEqualTo: 'active');
        final result = await backend.count(query: query);

        expect(result, 1);
      });

      test('returns zero for empty store', () async {
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => []);

        final result = await backend.count();

        expect(result, 0);
      });
    });

    group('patch', () {
      test('throws UnsupportedError (default implementation)', () async {
        expect(
          () => backend.patch('1', {'name': 'Updated'}),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });

    group('updateWhere', () {
      test('returns 0 for empty updates map', () async {
        final query =
            const nexus.Query<TestModel>().where('status', isEqualTo: 'active');
        final result = await backend.updateWhere(query, {});

        expect(result, 0);
      });
    });
  });
}
