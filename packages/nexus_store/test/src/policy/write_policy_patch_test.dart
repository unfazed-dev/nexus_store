import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  late FakeStoreBackend<TestUser, String> backend;
  late WritePolicyHandler<TestUser, String> handler;

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

    handler = WritePolicyHandler<TestUser, String>(
      backend: backend,
      defaultPolicy: WritePolicy.cacheAndNetwork,
    );

    // Seed data
    backend.addToStorage(
      'user-1',
      TestFixtures.createUser(id: 'user-1', name: 'Alice', isActive: true),
    );
  });

  group('WritePolicyHandler.patch', () {
    test('patch with cacheAndNetwork policy', () async {
      final result = await handler.patch(
        'user-1',
        {'name': 'Updated'},
        policy: WritePolicy.cacheAndNetwork,
      );

      expect(result, isNotNull);
      expect(result!.name, equals('Updated'));
    });

    test('patch with networkFirst policy', () async {
      final result = await handler.patch(
        'user-1',
        {'name': 'Updated'},
        policy: WritePolicy.networkFirst,
      );

      expect(result, isNotNull);
      expect(result!.name, equals('Updated'));
    });

    test('patch with cacheFirst policy', () async {
      final result = await handler.patch(
        'user-1',
        {'name': 'Updated'},
        policy: WritePolicy.cacheFirst,
      );

      expect(result, isNotNull);
      expect(result!.name, equals('Updated'));
    });

    test('patch with cacheOnly policy', () async {
      final result = await handler.patch(
        'user-1',
        {'name': 'Updated'},
        policy: WritePolicy.cacheOnly,
      );

      expect(result, isNotNull);
      expect(result!.name, equals('Updated'));
    });

    test('patch uses default policy when none specified', () async {
      final result = await handler.patch('user-1', {'name': 'Updated'});

      expect(result, isNotNull);
      expect(result!.name, equals('Updated'));
    });
  });

  group('WritePolicyHandler.patch error paths', () {
    test('cacheAndNetwork rethrows StoreError when sync fails', () async {
      backend.shouldFailOnSync = true;
      backend.errorToThrow = const SyncError(
        message: 'Sync failed',
      );

      expect(
        () => handler.patch(
          'user-1',
          {'name': 'Updated'},
          policy: WritePolicy.cacheAndNetwork,
        ),
        throwsA(isA<StoreError>()),
      );
    });

    test('networkFirst throws when sync fails', () async {
      backend.shouldFailOnSync = true;
      backend.errorToThrow = Exception('Network unavailable');

      expect(
        () => handler.patch(
          'user-1',
          {'name': 'Updated'},
          policy: WritePolicy.networkFirst,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('cacheFirst returns result even when background sync fails', () async {
      backend.shouldFailOnSync = true;
      backend.errorToThrow = Exception('Background sync failed');

      final result = await handler.patch(
        'user-1',
        {'name': 'Updated'},
        policy: WritePolicy.cacheFirst,
      );

      expect(result, isNotNull);
      expect(result!.name, equals('Updated'));

      // Allow background sync to complete (and fail silently)
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  });
}
