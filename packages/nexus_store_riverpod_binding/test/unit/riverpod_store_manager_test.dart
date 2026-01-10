import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_riverpod_binding/nexus_store_riverpod_binding.dart';

import '../helpers/mocks.dart';
import '../helpers/test_fixtures.dart';

/// Creates a mock store with dispose already stubbed.
MockNexusStore<T, ID> createMockStore<T, ID>() {
  final store = MockNexusStore<T, ID>();
  when(store.dispose).thenAnswer((_) async {});
  return store;
}

/// A second entity for testing multi-store scenarios.
class TestPost {
  const TestPost({required this.id, required this.title});
  final String id;
  final String title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestPost && id == other.id && title == other.title;

  @override
  int get hashCode => Object.hash(id, title);
}

void main() {
  setUpAll(registerFallbackValues);

  group('RiverpodStoreConfig', () {
    test('stores name and create function', () {
      final config = RiverpodStoreConfig<TestUser, String>(
        name: 'users',
        create: (_) => createMockStore<TestUser, String>(),
      );

      expect(config.name, equals('users'));
      expect(config.keepAlive, isFalse);
      expect(config.dependencies, isEmpty);
    });

    test('stores keepAlive option', () {
      final config = RiverpodStoreConfig<TestUser, String>(
        name: 'users',
        create: (_) => createMockStore<TestUser, String>(),
        keepAlive: true,
      );

      expect(config.keepAlive, isTrue);
    });

    test('stores dependencies list', () {
      final config = RiverpodStoreConfig<TestPost, String>(
        name: 'posts',
        create: (_) => createMockStore<TestPost, String>(),
        dependencies: ['users'],
      );

      expect(config.dependencies, equals(['users']));
    });
  });

  group('RiverpodStoreManager', () {
    group('constructor', () {
      test('accepts list of configs', () {
        final manager = RiverpodStoreManager([
          RiverpodStoreConfig<TestUser, String>(
            name: 'users',
            create: (_) => createMockStore<TestUser, String>(),
          ),
          RiverpodStoreConfig<TestPost, String>(
            name: 'posts',
            create: (_) => createMockStore<TestPost, String>(),
          ),
        ]);

        expect(manager.storeNames, containsAll(['users', 'posts']));
      });

      test('throws on duplicate store names', () {
        expect(
          () => RiverpodStoreManager([
            RiverpodStoreConfig<TestUser, String>(
              name: 'users',
              create: (_) => createMockStore<TestUser, String>(),
            ),
            RiverpodStoreConfig<TestPost, String>(
              name: 'users', // Duplicate!
              create: (_) => createMockStore<TestPost, String>(),
            ),
          ]),
          throwsArgumentError,
        );
      });
    });

    group('getBundle', () {
      test('returns bundle for store name', () {
        final manager = RiverpodStoreManager([
          RiverpodStoreConfig<TestUser, String>(
            name: 'users',
            create: (_) => createMockStore<TestUser, String>(),
          ),
        ]);

        final bundle = manager.getBundle('users');
        expect(bundle, isA<StoreProviderBundle<dynamic, dynamic>>());
        expect(bundle.name, equals('users'));
      });

      test('throws StateError for non-existent store', () {
        final manager = RiverpodStoreManager([
          RiverpodStoreConfig<TestUser, String>(
            name: 'users',
            create: (_) => createMockStore<TestUser, String>(),
          ),
        ]);

        expect(
          () => manager.getBundle('posts'),
          throwsStateError,
        );
      });

      test('returns same bundle on multiple calls', () {
        final manager = RiverpodStoreManager([
          RiverpodStoreConfig<TestUser, String>(
            name: 'users',
            create: (_) => createMockStore<TestUser, String>(),
          ),
        ]);

        final bundle1 = manager.getBundle('users');
        final bundle2 = manager.getBundle('users');

        expect(identical(bundle1, bundle2), isTrue);
      });
    });

    group('allStoreProviders', () {
      test('returns providers for all stores', () {
        final manager = RiverpodStoreManager([
          RiverpodStoreConfig<TestUser, String>(
            name: 'users',
            create: (_) => createMockStore<TestUser, String>(),
          ),
          RiverpodStoreConfig<TestPost, String>(
            name: 'posts',
            create: (_) => createMockStore<TestPost, String>(),
          ),
        ]);

        final providers = manager.allStoreProviders;
        expect(providers.length, equals(2));
      });
    });

    group('createOverrides', () {
      test('creates overrides for mocked stores', () {
        final mockUserStore = createMockStore<TestUser, String>();
        final mockPostStore = createMockStore<TestPost, String>();

        final manager = RiverpodStoreManager([
          RiverpodStoreConfig<TestUser, String>(
            name: 'users',
            create: (_) => createMockStore<TestUser, String>(),
          ),
          RiverpodStoreConfig<TestPost, String>(
            name: 'posts',
            create: (_) => createMockStore<TestPost, String>(),
          ),
        ]);

        final overrides = manager.createOverrides({
          'users': mockUserStore,
          'posts': mockPostStore,
        });

        expect(overrides.length, equals(2));

        // Verify overrides work in a container
        final container = ProviderContainer(overrides: overrides);
        addTearDown(container.dispose);

        final userBundle = manager.getBundle('users');
        expect(container.read(userBundle.storeProvider), same(mockUserStore));
      });

      test('throws for non-existent store name', () {
        final manager = RiverpodStoreManager([
          RiverpodStoreConfig<TestUser, String>(
            name: 'users',
            create: (_) => createMockStore<TestUser, String>(),
          ),
        ]);

        expect(
          () => manager.createOverrides({
            'nonexistent': createMockStore<TestUser, String>(),
          }),
          throwsStateError,
        );
      });
    });

    group('storeNames', () {
      test('returns all store names', () {
        final manager = RiverpodStoreManager([
          RiverpodStoreConfig<TestUser, String>(
            name: 'users',
            create: (_) => createMockStore<TestUser, String>(),
          ),
          RiverpodStoreConfig<TestPost, String>(
            name: 'posts',
            create: (_) => createMockStore<TestPost, String>(),
          ),
        ]);

        expect(manager.storeNames, containsAll(['users', 'posts']));
      });
    });

    group('integration', () {
      test('providers share the same store instance', () {
        var createCount = 0;
        final manager = RiverpodStoreManager([
          RiverpodStoreConfig<TestUser, String>(
            name: 'users',
            create: (_) {
              createCount++;
              final store = createMockStore<TestUser, String>();
              when(() => store.watchAll(query: any(named: 'query')))
                  .thenAnswer((_) => Stream.value([]));
              return store;
            },
          ),
        ]);

        final bundle = manager.getBundle('users');

        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Access both store and all providers
        container.read(bundle.storeProvider);
        container.read(bundle.allProvider);

        // Store should only be created once
        expect(createCount, equals(1));
      });
    });
  });
}
