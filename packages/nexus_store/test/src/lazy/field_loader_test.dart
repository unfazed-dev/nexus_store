import 'dart:async';

import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store/src/lazy/field_loader.dart';
import 'package:nexus_store/src/lazy/lazy_field_state.dart';
import 'package:nexus_store/src/lazy/lazy_load_config.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('FieldLoader', () {
    late FakeStoreBackend<TestUser, String> backend;
    late FieldLoader<TestUser, String> loader;

    setUp(() {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
        backendName: 'TestBackend',
      );
      loader = FieldLoader<TestUser, String>(
        backend: backend,
        config: const LazyLoadConfig(
          lazyFields: {'avatar', 'profileImage'},
          batchSize: 5,
          batchDelay: Duration(milliseconds: 10),
        ),
      );
    });

    tearDown(() async {
      await loader.dispose();
      await backend.close();
    });

    group('loadField', () {
      test('loads a single field from backend', () async {
        backend.addFieldToStorage('user-1', 'avatar', 'avatar-data');

        final result = await loader.loadField('user-1', 'avatar');

        expect(result, equals('avatar-data'));
      });

      test('returns null for non-existent field', () async {
        final result = await loader.loadField('user-1', 'avatar');

        expect(result, isNull);
      });

      test('caches loaded field value', () async {
        backend.addFieldToStorage('user-1', 'avatar', 'avatar-data');

        await loader.loadField('user-1', 'avatar');

        // Clear backend to verify cache is used
        backend.clearFieldStorage();

        final result = await loader.loadField('user-1', 'avatar');

        expect(result, equals('avatar-data'));
      });

      test('throws when backend fails', () async {
        backend.shouldFailOnGet = true;

        expect(
          () => loader.loadField('user-1', 'avatar'),
          throwsException,
        );
      });
    });

    group('loadFieldBatch', () {
      test('loads field for multiple entities', () async {
        backend.addFieldToStorage('user-1', 'avatar', 'avatar-1');
        backend.addFieldToStorage('user-2', 'avatar', 'avatar-2');
        backend.addFieldToStorage('user-3', 'avatar', 'avatar-3');

        final results = await loader.loadFieldBatch(
          ['user-1', 'user-2', 'user-3'],
          'avatar',
        );

        expect(results['user-1'], equals('avatar-1'));
        expect(results['user-2'], equals('avatar-2'));
        expect(results['user-3'], equals('avatar-3'));
      });

      test('omits entities with null field values', () async {
        backend.addFieldToStorage('user-1', 'avatar', 'avatar-1');
        // user-2 has no avatar

        final results = await loader.loadFieldBatch(
          ['user-1', 'user-2'],
          'avatar',
        );

        expect(results.containsKey('user-1'), isTrue);
        expect(results.containsKey('user-2'), isFalse);
      });

      test('caches loaded values', () async {
        backend.addFieldToStorage('user-1', 'avatar', 'avatar-1');
        backend.addFieldToStorage('user-2', 'avatar', 'avatar-2');

        await loader.loadFieldBatch(['user-1', 'user-2'], 'avatar');

        // Clear backend to verify cache
        backend.clearFieldStorage();

        final value1 = await loader.loadField('user-1', 'avatar');
        final value2 = await loader.loadField('user-2', 'avatar');

        expect(value1, equals('avatar-1'));
        expect(value2, equals('avatar-2'));
      });
    });

    group('getFieldState', () {
      test('returns notLoaded for unloaded field', () {
        final state = loader.getFieldState('user-1', 'avatar');

        expect(state, equals(LazyFieldState.notLoaded));
      });

      test('returns loaded after field is loaded', () async {
        backend.addFieldToStorage('user-1', 'avatar', 'avatar-data');

        await loader.loadField('user-1', 'avatar');

        final state = loader.getFieldState('user-1', 'avatar');

        expect(state, equals(LazyFieldState.loaded));
      });

      test('returns error when loading fails', () async {
        backend.shouldFailOnGet = true;

        try {
          await loader.loadField('user-1', 'avatar');
        } catch (_) {}

        final state = loader.getFieldState('user-1', 'avatar');

        expect(state, equals(LazyFieldState.error));
      });
    });

    group('preloadFields', () {
      test('preloads multiple fields for multiple entities', () async {
        backend.addFieldToStorage('user-1', 'avatar', 'avatar-1');
        backend.addFieldToStorage('user-1', 'profileImage', 'profile-1');
        backend.addFieldToStorage('user-2', 'avatar', 'avatar-2');
        backend.addFieldToStorage('user-2', 'profileImage', 'profile-2');

        await loader.preloadFields(
          ['user-1', 'user-2'],
          {'avatar', 'profileImage'},
        );

        // Verify all fields are cached
        backend.clearFieldStorage();

        expect(
          await loader.loadField('user-1', 'avatar'),
          equals('avatar-1'),
        );
        expect(
          await loader.loadField('user-1', 'profileImage'),
          equals('profile-1'),
        );
        expect(
          await loader.loadField('user-2', 'avatar'),
          equals('avatar-2'),
        );
        expect(
          await loader.loadField('user-2', 'profileImage'),
          equals('profile-2'),
        );
      });
    });

    group('clearCache', () {
      test('clears all cached values', () async {
        backend.addFieldToStorage('user-1', 'avatar', 'avatar-data');

        await loader.loadField('user-1', 'avatar');

        loader.clearCache();

        // Should now be unloaded
        final state = loader.getFieldState('user-1', 'avatar');
        expect(state, equals(LazyFieldState.notLoaded));
      });

      test('clears cache for specific entity', () async {
        backend.addFieldToStorage('user-1', 'avatar', 'avatar-1');
        backend.addFieldToStorage('user-2', 'avatar', 'avatar-2');

        await loader.loadField('user-1', 'avatar');
        await loader.loadField('user-2', 'avatar');

        loader.clearCacheForEntity('user-1');

        expect(
          loader.getFieldState('user-1', 'avatar'),
          equals(LazyFieldState.notLoaded),
        );
        expect(
          loader.getFieldState('user-2', 'avatar'),
          equals(LazyFieldState.loaded),
        );
      });
    });

    group('concurrent loading', () {
      test('deduplicates concurrent requests for same field', () async {
        final completer = Completer<Map<String, dynamic>>();
        var loadCount = 0;

        // Create a custom backend that tracks calls
        final trackingBackend = _TrackingBackend<TestUser, String>(
          onGetField: (id, field) async {
            loadCount++;
            await completer.future;
            return 'avatar-data';
          },
        );

        final trackingLoader = FieldLoader<TestUser, String>(
          backend: trackingBackend,
          config: const LazyLoadConfig(
            lazyFields: {'avatar'},
          ),
        );

        // Start multiple concurrent loads
        final future1 = trackingLoader.loadField('user-1', 'avatar');
        final future2 = trackingLoader.loadField('user-1', 'avatar');
        final future3 = trackingLoader.loadField('user-1', 'avatar');

        // Complete the backend call
        completer.complete({});

        await Future.wait([future1, future2, future3]);

        // Should only have called backend once
        expect(loadCount, equals(1));

        await trackingLoader.dispose();
      });
    });
  });
}

/// A tracking backend for testing concurrent loading behavior.
class _TrackingBackend<T, ID> with StoreBackendDefaults<T, ID> {
  _TrackingBackend({
    this.onGetField,
  });

  final Future<dynamic> Function(ID id, String fieldName)? onGetField;

  @override
  String get name => 'TrackingBackend';

  @override
  bool get supportsFieldOperations => true;

  @override
  Future<dynamic> getField(ID id, String fieldName) async {
    if (onGetField != null) {
      return onGetField!(id, fieldName);
    }
    return null;
  }

  @override
  Future<T?> get(ID id) async => null;

  @override
  Future<List<T>> getAll({query}) async => [];

  @override
  Stream<T?> watch(ID id) => const Stream.empty();

  @override
  Stream<List<T>> watchAll({query}) => const Stream.empty();

  @override
  Future<T> save(T item) async => item;

  @override
  Future<List<T>> saveAll(List<T> items) async => items;

  @override
  Future<bool> delete(ID id) async => false;

  @override
  Future<int> deleteAll(List<ID> ids) async => 0;

  @override
  Future<int> deleteWhere(query) async => 0;
}
