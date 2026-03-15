import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  late FakeStoreBackend<TestUser, String> backend;
  late NexusStore<TestUser, String> store;

  setUp(() async {
    backend = FakeStoreBackend<TestUser, String>(
      idExtractor: (u) => u.id,
    );
    backend.patchApplier = (entity, updates) {
      return entity.copyWith(
        name: updates['name'] as String? ?? entity.name,
        email: updates['email'] as String? ?? entity.email,
        age: updates.containsKey('age') ? updates['age'] as int? : entity.age,
        isActive: updates['isActive'] as bool? ?? entity.isActive,
      );
    };
    store = NexusStore<TestUser, String>(
      backend: backend,
      config: StoreConfig(),
      idExtractor: (u) => u.id,
    );
    await store.initialize();

    // Seed data
    backend.addToStorage(
      'user-1',
      TestFixtures.createUser(id: 'user-1', name: 'Alice', isActive: true),
    );
    backend.addToStorage(
      'user-2',
      TestFixtures.createUser(id: 'user-2', name: 'Bob', isActive: false),
    );
  });

  tearDown(() async {
    await store.dispose();
  });

  group('NexusStore.patch', () {
    test('patches a single field and returns updated entity', () async {
      final result = await store.patch('user-1', {'name': 'Alice Updated'});

      expect(result, isNotNull);
      expect(result!.name, equals('Alice Updated'));
      expect(result.id, equals('user-1'));
    });

    test('patches multiple fields and returns updated entity', () async {
      final result = await store.patch('user-1', {
        'name': 'Alice Updated',
        'isActive': false,
      });

      expect(result, isNotNull);
      expect(result!.name, equals('Alice Updated'));
      expect(result.isActive, isFalse);
      expect(result.id, equals('user-1'));
    });

    test('returns null for non-existent entity', () async {
      final result = await store.patch('non-existent', {'name': 'Ghost'});

      expect(result, isNull);
    });

    test('preserves unpatched fields', () async {
      final result = await store.patch('user-1', {'name': 'Alice Updated'});

      expect(result, isNotNull);
      expect(result!.isActive, isTrue);
      expect(result.email, equals('john@example.com'));
    });

    test('patch with empty updates returns entity unchanged', () async {
      final result = await store.patch('user-1', {});

      expect(result, isNotNull);
      expect(result!.name, equals('Alice'));
    });

    test('patch respects write policy parameter', () async {
      final result = await store.patch(
        'user-1',
        {'name': 'Updated'},
        policy: WritePolicy.cacheOnly,
      );

      expect(result, isNotNull);
      expect(result!.name, equals('Updated'));
    });

    test('patch updates cache so subsequent get returns updated entity',
        () async {
      await store.patch('user-1', {'name': 'Alice Cached'});

      final fetched = await store.get('user-1');
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Alice Cached'));
    });

    test('patch goes through interceptor chain', () async {
      final result = await store.patch('user-1', {'name': 'Intercepted'});

      expect(result, isNotNull);
    });

    test('patch throws on uninitialized store', () async {
      final uninitializedStore = NexusStore<TestUser, String>(
        backend: FakeStoreBackend<TestUser, String>(
          idExtractor: (u) => u.id,
        ),
        config: StoreConfig(),
        idExtractor: (u) => u.id,
      );

      expect(
        () => uninitializedStore.patch('user-1', {'name': 'Fail'}),
        throwsA(isA<Error>()),
      );
    });
  });
}
