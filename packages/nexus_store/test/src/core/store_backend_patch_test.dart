import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('StoreBackend.patch', () {
    late FakeStoreBackend<TestUser, String> backend;

    setUp(() {
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

      // Seed data
      backend.addToStorage(
        'user-1',
        TestFixtures.createUser(id: 'user-1', name: 'Alice', isActive: true),
      );
    });

    test('patch returns updated entity', () async {
      final result = await backend.patch('user-1', {'name': 'Alice Updated'});

      expect(result, isNotNull);
      expect(result!.name, equals('Alice Updated'));
    });

    test('patch returns null for non-existent entity', () async {
      final result = await backend.patch('non-existent', {'name': 'Ghost'});

      expect(result, isNull);
    });

    test('patch with empty updates returns entity unchanged', () async {
      final result = await backend.patch('user-1', {});

      expect(result, isNotNull);
      expect(result!.name, equals('Alice'));
    });

    test('patch updates storage in place', () async {
      await backend.patch('user-1', {'name': 'Updated'});

      final stored = await backend.get('user-1');
      expect(stored, isNotNull);
      expect(stored!.name, equals('Updated'));
    });
  });
}
