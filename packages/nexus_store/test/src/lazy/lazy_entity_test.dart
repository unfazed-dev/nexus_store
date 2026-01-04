import 'dart:async';

import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('LazyEntity', () {
    late FakeStoreBackend<TestUser, String> backend;
    late FieldLoader<TestUser, String> fieldLoader;

    setUp(() {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
        backendName: 'TestBackend',
      );
      fieldLoader = FieldLoader<TestUser, String>(
        backend: backend,
        config: const LazyLoadConfig(
          lazyFields: {'avatar', 'profileImage'},
        ),
      );
    });

    tearDown(() async {
      await fieldLoader.dispose();
      await backend.close();
    });

    group('creation', () {
      test('wraps entity with lazy field support', () {
        final user = TestFixtures.createUser(id: 'user-1', name: 'Alice');

        final lazyEntity = LazyEntity<TestUser, String>(
          user,
          idExtractor: (u) => u.id,
          fieldLoader: fieldLoader,
          config: const LazyLoadConfig(
            lazyFields: {'avatar', 'profileImage'},
          ),
        );

        expect(lazyEntity.entity, equals(user));
        expect(lazyEntity.id, equals('user-1'));
      });
    });

    group('getField', () {
      test('returns entity field value for non-lazy field', () {
        final user = TestFixtures.createUser(id: 'user-1', name: 'Alice');

        final lazyEntity = LazyEntity<TestUser, String>(
          user,
          idExtractor: (u) => u.id,
          fieldLoader: fieldLoader,
          config: const LazyLoadConfig(
            lazyFields: {'avatar'},
          ),
          fieldGetter: (entity, field) {
            if (field == 'name') return entity.name;
            if (field == 'email') return entity.email;
            return null;
          },
        );

        expect(lazyEntity.getField('name'), equals('Alice'));
      });

      test('returns placeholder for unloaded lazy field', () {
        final user = TestFixtures.createUser(id: 'user-1', name: 'Alice');

        final lazyEntity = LazyEntity<TestUser, String>(
          user,
          idExtractor: (u) => u.id,
          fieldLoader: fieldLoader,
          config: const LazyLoadConfig(
            lazyFields: {'avatar'},
            placeholders: {'avatar': 'default-avatar'},
          ),
          fieldGetter: (entity, field) => null,
        );

        expect(lazyEntity.getField('avatar'), equals('default-avatar'));
      });

      test('returns placeholder for LOADED lazy field (line 79)', () async {
        // Line 79: When a lazy field is loaded, getField still returns placeholder
        // because the loader stores values internally and we can't access them directly
        final user = TestFixtures.createUser(id: 'user-1', name: 'Alice');
        backend.addFieldToStorage('user-1', 'avatar', 'actual-avatar-data');

        final lazyEntity = LazyEntity<TestUser, String>(
          user,
          idExtractor: (u) => u.id,
          fieldLoader: fieldLoader,
          config: const LazyLoadConfig(
            lazyFields: {'avatar'},
            placeholders: {'avatar': 'default-avatar'},
          ),
          fieldGetter: (entity, field) => null,
        );

        // Load the field
        await lazyEntity.loadField('avatar');
        expect(lazyEntity.isFieldLoaded('avatar'), isTrue);

        // getField returns placeholder even for loaded field (line 79)
        // because the implementation note says loader stores values internally
        final value = lazyEntity.getField('avatar');
        expect(value, equals('default-avatar'));
      });
    });

    group('isFieldLoaded', () {
      test('returns false for unloaded lazy field', () {
        final user = TestFixtures.createUser(id: 'user-1', name: 'Alice');

        final lazyEntity = LazyEntity<TestUser, String>(
          user,
          idExtractor: (u) => u.id,
          fieldLoader: fieldLoader,
          config: const LazyLoadConfig(
            lazyFields: {'avatar'},
          ),
        );

        expect(lazyEntity.isFieldLoaded('avatar'), isFalse);
      });

      test('returns true for non-lazy field', () {
        final user = TestFixtures.createUser(id: 'user-1', name: 'Alice');

        final lazyEntity = LazyEntity<TestUser, String>(
          user,
          idExtractor: (u) => u.id,
          fieldLoader: fieldLoader,
          config: const LazyLoadConfig(
            lazyFields: {'avatar'},
          ),
        );

        expect(lazyEntity.isFieldLoaded('name'), isTrue);
      });

      test('returns true after lazy field is loaded', () async {
        final user = TestFixtures.createUser(id: 'user-1', name: 'Alice');
        backend.addFieldToStorage('user-1', 'avatar', 'avatar-data');

        final lazyEntity = LazyEntity<TestUser, String>(
          user,
          idExtractor: (u) => u.id,
          fieldLoader: fieldLoader,
          config: const LazyLoadConfig(
            lazyFields: {'avatar'},
          ),
        );

        await lazyEntity.loadField('avatar');

        expect(lazyEntity.isFieldLoaded('avatar'), isTrue);
      });
    });

    group('loadField', () {
      test('loads field from backend', () async {
        final user = TestFixtures.createUser(id: 'user-1', name: 'Alice');
        backend.addFieldToStorage('user-1', 'avatar', 'avatar-data');

        final lazyEntity = LazyEntity<TestUser, String>(
          user,
          idExtractor: (u) => u.id,
          fieldLoader: fieldLoader,
          config: const LazyLoadConfig(
            lazyFields: {'avatar'},
          ),
        );

        final result = await lazyEntity.loadField('avatar');

        expect(result, equals('avatar-data'));
      });
    });

    group('loadFields', () {
      test('loads multiple lazy fields', () async {
        final user = TestFixtures.createUser(id: 'user-1', name: 'Alice');
        backend.addFieldToStorage('user-1', 'avatar', 'avatar-data');
        backend.addFieldToStorage('user-1', 'profileImage', 'profile-data');

        final lazyEntity = LazyEntity<TestUser, String>(
          user,
          idExtractor: (u) => u.id,
          fieldLoader: fieldLoader,
          config: const LazyLoadConfig(
            lazyFields: {'avatar', 'profileImage'},
          ),
        );

        await lazyEntity.loadFields({'avatar', 'profileImage'});

        expect(lazyEntity.isFieldLoaded('avatar'), isTrue);
        expect(lazyEntity.isFieldLoaded('profileImage'), isTrue);
      });
    });

    group('loadAllLazyFields', () {
      test('loads all configured lazy fields', () async {
        final user = TestFixtures.createUser(id: 'user-1', name: 'Alice');
        backend.addFieldToStorage('user-1', 'avatar', 'avatar-data');
        backend.addFieldToStorage('user-1', 'profileImage', 'profile-data');

        final lazyEntity = LazyEntity<TestUser, String>(
          user,
          idExtractor: (u) => u.id,
          fieldLoader: fieldLoader,
          config: const LazyLoadConfig(
            lazyFields: {'avatar', 'profileImage'},
          ),
        );

        await lazyEntity.loadAllLazyFields();

        expect(lazyEntity.isFieldLoaded('avatar'), isTrue);
        expect(lazyEntity.isFieldLoaded('profileImage'), isTrue);
      });
    });

    group('unloadedFields', () {
      test('returns all lazy fields when none loaded', () {
        final user = TestFixtures.createUser(id: 'user-1', name: 'Alice');

        final lazyEntity = LazyEntity<TestUser, String>(
          user,
          idExtractor: (u) => u.id,
          fieldLoader: fieldLoader,
          config: const LazyLoadConfig(
            lazyFields: {'avatar', 'profileImage'},
          ),
        );

        expect(
          lazyEntity.unloadedFields,
          equals({'avatar', 'profileImage'}),
        );
      });

      test('returns only unloaded lazy fields', () async {
        final user = TestFixtures.createUser(id: 'user-1', name: 'Alice');
        backend.addFieldToStorage('user-1', 'avatar', 'avatar-data');

        final lazyEntity = LazyEntity<TestUser, String>(
          user,
          idExtractor: (u) => u.id,
          fieldLoader: fieldLoader,
          config: const LazyLoadConfig(
            lazyFields: {'avatar', 'profileImage'},
          ),
        );

        await lazyEntity.loadField('avatar');

        expect(lazyEntity.unloadedFields, equals({'profileImage'}));
      });

      test('returns empty set when all loaded', () async {
        final user = TestFixtures.createUser(id: 'user-1', name: 'Alice');
        backend.addFieldToStorage('user-1', 'avatar', 'avatar-data');
        backend.addFieldToStorage('user-1', 'profileImage', 'profile-data');

        final lazyEntity = LazyEntity<TestUser, String>(
          user,
          idExtractor: (u) => u.id,
          fieldLoader: fieldLoader,
          config: const LazyLoadConfig(
            lazyFields: {'avatar', 'profileImage'},
          ),
        );

        await lazyEntity.loadAllLazyFields();

        expect(lazyEntity.unloadedFields, isEmpty);
      });
    });

    group('fieldLoadedStream', () {
      test('emits field name when field is loaded', () async {
        final user = TestFixtures.createUser(id: 'user-1', name: 'Alice');
        backend.addFieldToStorage('user-1', 'avatar', 'avatar-data');

        final lazyEntity = LazyEntity<TestUser, String>(
          user,
          idExtractor: (u) => u.id,
          fieldLoader: fieldLoader,
          config: const LazyLoadConfig(
            lazyFields: {'avatar'},
          ),
        );

        final loadedFields = <String>[];
        final subscription =
            lazyEntity.fieldLoadedStream.listen(loadedFields.add);

        await lazyEntity.loadField('avatar');

        await Future<void>.delayed(Duration.zero);

        expect(loadedFields, contains('avatar'));

        await subscription.cancel();
      });
    });

    group('dispose (lines 138-139)', () {
      test('closes fieldLoadedStream controller', () async {
        final user = TestFixtures.createUser(id: 'user-1', name: 'Alice');

        final lazyEntity = LazyEntity<TestUser, String>(
          user,
          idExtractor: (u) => u.id,
          fieldLoader: fieldLoader,
          config: const LazyLoadConfig(
            lazyFields: {'avatar'},
          ),
        );

        // Subscribe to stream
        var streamDone = false;
        lazyEntity.fieldLoadedStream.listen(
          (_) {},
          onDone: () => streamDone = true,
        );

        // Dispose should close the stream controller (lines 138-139)
        await lazyEntity.dispose();

        // Allow stream to process the close
        await Future<void>.delayed(Duration.zero);

        // The stream should be done
        expect(streamDone, isTrue);
      });

      test('can be called multiple times without error', () async {
        final user = TestFixtures.createUser(id: 'user-1', name: 'Alice');

        final lazyEntity = LazyEntity<TestUser, String>(
          user,
          idExtractor: (u) => u.id,
          fieldLoader: fieldLoader,
          config: const LazyLoadConfig(
            lazyFields: {'avatar'},
          ),
        );

        // Dispose twice - should not throw
        await lazyEntity.dispose();
        await lazyEntity.dispose();
      });
    });
  });
}
