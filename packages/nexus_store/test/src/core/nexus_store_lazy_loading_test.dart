import 'package:nexus_store/src/config/store_config.dart';
import 'package:nexus_store/src/core/nexus_store.dart';
import 'package:nexus_store/src/lazy/lazy_field_state.dart';
import 'package:nexus_store/src/lazy/lazy_load_config.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('StoreConfig lazy loading', () {
    test('lazyLoad field is null by default', () {
      const config = StoreConfig();
      expect(config.lazyLoad, isNull);
    });

    test('lazyLoad field can be configured', () {
      const config = StoreConfig(
        lazyLoad: LazyLoadConfig(
          lazyFields: {'thumbnail', 'fullImage'},
          batchSize: 20,
        ),
      );

      expect(config.lazyLoad, isNotNull);
      expect(config.lazyLoad!.lazyFields, {'thumbnail', 'fullImage'});
      expect(config.lazyLoad!.batchSize, 20);
    });

    test('offlineFirst preset has no lazyLoad configured', () {
      expect(StoreConfig.offlineFirst.lazyLoad, isNull);
    });

    test('onlineOnly preset has no lazyLoad configured', () {
      expect(StoreConfig.onlineOnly.lazyLoad, isNull);
    });
  });

  group('NexusStore lazy loading', () {
    late FakeStoreBackend<TestUser, String> backend;
    late NexusStore<TestUser, String> store;

    setUp(() async {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (e) => e.id,
      );

      // Add test entities
      await backend.save(TestFixtures.createUser(id: 'user-1', name: 'User 1'));
      await backend.save(TestFixtures.createUser(id: 'user-2', name: 'User 2'));
      await backend.save(TestFixtures.createUser(id: 'user-3', name: 'User 3'));

      // Add lazy field data
      backend.addFieldToStorage('user-1', 'thumbnail', 'thumb-data-1');
      backend.addFieldToStorage('user-1', 'fullImage', 'image-data-1');
      backend.addFieldToStorage('user-2', 'thumbnail', 'thumb-data-2');
      backend.addFieldToStorage('user-3', 'thumbnail', 'thumb-data-3');

      store = NexusStore<TestUser, String>(
        backend: backend,
        idExtractor: (e) => e.id,
        config: const StoreConfig(
          lazyLoad: LazyLoadConfig(
            lazyFields: {'thumbnail', 'fullImage'},
          ),
        ),
      );

      await store.initialize();
    });

    tearDown(() async {
      await store.dispose();
    });

    group('loadField', () {
      test('loads a single field value', () async {
        final value = await store.loadField('user-1', 'thumbnail');
        expect(value, 'thumb-data-1');
      });

      test('returns null for non-existent entity', () async {
        final value = await store.loadField('non-existent', 'thumbnail');
        expect(value, isNull);
      });

      test('returns null for non-existent field', () async {
        final value = await store.loadField('user-1', 'nonExistentField');
        expect(value, isNull);
      });

      test('caches loaded field value', () async {
        // Load first time
        final value1 = await store.loadField('user-1', 'thumbnail');
        expect(value1, 'thumb-data-1');

        // Change storage value
        backend.addFieldToStorage('user-1', 'thumbnail', 'updated-thumb');

        // Should return cached value
        final value2 = await store.loadField('user-1', 'thumbnail');
        expect(value2, 'thumb-data-1');
      });

      test('loads different fields independently', () async {
        final thumb = await store.loadField('user-1', 'thumbnail');
        final image = await store.loadField('user-1', 'fullImage');

        expect(thumb, 'thumb-data-1');
        expect(image, 'image-data-1');
      });
    });

    group('loadFieldBatch', () {
      test('loads field for multiple entities', () async {
        final results = await store.loadFieldBatch(
          ['user-1', 'user-2', 'user-3'],
          'thumbnail',
        );

        expect(results['user-1'], 'thumb-data-1');
        expect(results['user-2'], 'thumb-data-2');
        expect(results['user-3'], 'thumb-data-3');
      });

      test('omits entities that dont have the field', () async {
        // user-2 and user-3 don't have fullImage
        final results = await store.loadFieldBatch(
          ['user-1', 'user-2', 'user-3'],
          'fullImage',
        );

        expect(results.length, 1);
        expect(results['user-1'], 'image-data-1');
        expect(results.containsKey('user-2'), isFalse);
        expect(results.containsKey('user-3'), isFalse);
      });

      test('returns empty map for non-existent entities', () async {
        final results = await store.loadFieldBatch(
          ['non-existent-1', 'non-existent-2'],
          'thumbnail',
        );

        expect(results, isEmpty);
      });

      test('uses cached values for already loaded entities', () async {
        // Load user-1 first
        await store.loadField('user-1', 'thumbnail');

        // Change storage
        backend.addFieldToStorage('user-1', 'thumbnail', 'updated');

        // Batch load should use cache for user-1
        final results = await store.loadFieldBatch(
          ['user-1', 'user-2'],
          'thumbnail',
        );

        expect(results['user-1'], 'thumb-data-1'); // Cached
        expect(results['user-2'], 'thumb-data-2'); // Freshly loaded
      });
    });

    group('preloadFields', () {
      test('preloads multiple fields for multiple entities', () async {
        await store.preloadFields(
          ['user-1', 'user-2'],
          {'thumbnail', 'fullImage'},
        );

        // Verify fields are loaded (should use cache)
        final state1 = store.getFieldState('user-1', 'thumbnail');
        final state2 = store.getFieldState('user-1', 'fullImage');
        final state3 = store.getFieldState('user-2', 'thumbnail');

        expect(state1, LazyFieldState.loaded);
        expect(state2, LazyFieldState.loaded);
        expect(state3, LazyFieldState.loaded);
      });

      test('is idempotent', () async {
        // Preload twice
        await store.preloadFields(['user-1'], {'thumbnail'});
        await store.preloadFields(['user-1'], {'thumbnail'});

        // Should still be loaded
        final state = store.getFieldState('user-1', 'thumbnail');
        expect(state, LazyFieldState.loaded);
      });
    });

    group('getFieldState', () {
      test('returns notLoaded for unloaded field', () {
        final state = store.getFieldState('user-1', 'thumbnail');
        expect(state, LazyFieldState.notLoaded);
      });

      test('returns loaded after field is loaded', () async {
        await store.loadField('user-1', 'thumbnail');

        final state = store.getFieldState('user-1', 'thumbnail');
        expect(state, LazyFieldState.loaded);
      });

      test('returns notLoaded for non-existent entity', () {
        final state = store.getFieldState('non-existent', 'thumbnail');
        expect(state, LazyFieldState.notLoaded);
      });
    });

    group('clearFieldCache', () {
      test('clears all cached field values', () async {
        // Load some fields
        await store.loadField('user-1', 'thumbnail');
        await store.loadField('user-2', 'thumbnail');

        // Clear cache
        store.clearFieldCache();

        // States should be reset
        expect(
          store.getFieldState('user-1', 'thumbnail'),
          LazyFieldState.notLoaded,
        );
        expect(
          store.getFieldState('user-2', 'thumbnail'),
          LazyFieldState.notLoaded,
        );
      });
    });

    group('clearFieldCacheForEntity', () {
      test('clears cached fields for specific entity only', () async {
        // Load fields for both entities
        await store.loadField('user-1', 'thumbnail');
        await store.loadField('user-2', 'thumbnail');

        // Clear only user-1
        store.clearFieldCacheForEntity('user-1');

        // user-1 should be reset
        expect(
          store.getFieldState('user-1', 'thumbnail'),
          LazyFieldState.notLoaded,
        );

        // user-2 should still be loaded
        expect(
          store.getFieldState('user-2', 'thumbnail'),
          LazyFieldState.loaded,
        );
      });
    });
  });

  group('NexusStore without lazy loading', () {
    test('loadField throws when lazy loading not configured', () async {
      final backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (e) => e.id,
      );

      final store = NexusStore<TestUser, String>(
        backend: backend,
        idExtractor: (e) => e.id,
        config: const StoreConfig(), // No lazyLoad
      );

      await store.initialize();

      expect(
        () => store.loadField('user-1', 'thumbnail'),
        throwsA(isA<StateError>()),
      );

      await store.dispose();
    });

    test('loadFieldBatch throws when lazy loading not configured', () async {
      final backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (e) => e.id,
      );

      final store = NexusStore<TestUser, String>(
        backend: backend,
        idExtractor: (e) => e.id,
        config: const StoreConfig(), // No lazyLoad
      );

      await store.initialize();

      expect(
        () => store.loadFieldBatch(['user-1'], 'thumbnail'),
        throwsA(isA<StateError>()),
      );

      await store.dispose();
    });
  });
}
