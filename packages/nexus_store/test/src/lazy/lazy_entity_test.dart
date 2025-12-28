import 'dart:async';

import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store/src/lazy/field_loader.dart';
import 'package:nexus_store/src/lazy/lazy_entity.dart';
import 'package:nexus_store/src/lazy/lazy_field_state.dart';
import 'package:nexus_store/src/lazy/lazy_load_config.dart';
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
        final subscription = lazyEntity.fieldLoadedStream.listen(loadedFields.add);

        await lazyEntity.loadField('avatar');

        await Future<void>.delayed(Duration.zero);

        expect(loadedFields, contains('avatar'));

        await subscription.cancel();
      });
    });
  });
}
