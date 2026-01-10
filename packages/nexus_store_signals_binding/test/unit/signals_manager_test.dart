import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_signals_binding/nexus_store_signals_binding.dart';

import '../fixtures/mock_store.dart';
import '../fixtures/test_entities.dart';

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

  group('SignalsManager', () {
    late MockNexusStore<TestUser, String> mockUserStore;
    late MockNexusStore<TestPost, String> mockPostStore;
    late StreamController<List<TestUser>> userStreamController;
    late StreamController<List<TestPost>> postStreamController;

    setUp(() {
      mockUserStore = MockNexusStore<TestUser, String>();
      mockPostStore = MockNexusStore<TestPost, String>();
      userStreamController = StreamController<List<TestUser>>.broadcast();
      postStreamController = StreamController<List<TestPost>>.broadcast();

      when(() => mockUserStore.watchAll(query: any(named: 'query')))
          .thenAnswer((_) => userStreamController.stream);
      when(() => mockPostStore.watchAll(query: any(named: 'query')))
          .thenAnswer((_) => postStreamController.stream);
    });

    tearDown(() {
      userStreamController.close();
      postStreamController.close();
    });

    group('constructor', () {
      test('accepts list of configs', () {
        final manager = SignalsManager([
          SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockUserStore,
          ),
          SignalsStoreConfig<TestPost, String>(
            name: 'posts',
            store: mockPostStore,
          ),
        ]);
        addTearDown(manager.dispose);

        expect(manager.storeNames, containsAll(['users', 'posts']));
      });

      test('throws on duplicate store names', () {
        expect(
          () => SignalsManager([
            SignalsStoreConfig<TestUser, String>(
              name: 'users',
              store: mockUserStore,
            ),
            SignalsStoreConfig<TestPost, String>(
              name: 'users', // Duplicate!
              store: mockPostStore,
            ),
          ]),
          throwsArgumentError,
        );
      });
    });

    group('getBundle', () {
      test('returns bundle for store name', () {
        final manager = SignalsManager([
          SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockUserStore,
          ),
        ]);
        addTearDown(manager.dispose);

        final bundle = manager.getBundle('users');
        expect(bundle, isA<SignalsStoreBundle<dynamic, dynamic>>());
        expect(bundle.name, equals('users'));
      });

      test('throws StateError for non-existent store', () {
        final manager = SignalsManager([
          SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockUserStore,
          ),
        ]);
        addTearDown(manager.dispose);

        expect(
          () => manager.getBundle('posts'),
          throwsStateError,
        );
      });

      test('returns same bundle on multiple calls', () {
        final manager = SignalsManager([
          SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockUserStore,
          ),
        ]);
        addTearDown(manager.dispose);

        final bundle1 = manager.getBundle('users');
        final bundle2 = manager.getBundle('users');

        expect(identical(bundle1, bundle2), isTrue);
      });
    });

    group('allBundles', () {
      test('returns all bundles', () {
        final manager = SignalsManager([
          SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockUserStore,
          ),
          SignalsStoreConfig<TestPost, String>(
            name: 'posts',
            store: mockPostStore,
          ),
        ]);
        addTearDown(manager.dispose);

        final bundles = manager.allBundles;
        expect(bundles.length, equals(2));
      });
    });

    group('storeNames', () {
      test('returns all store names', () {
        final manager = SignalsManager([
          SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockUserStore,
          ),
          SignalsStoreConfig<TestPost, String>(
            name: 'posts',
            store: mockPostStore,
          ),
        ]);
        addTearDown(manager.dispose);

        expect(manager.storeNames, containsAll(['users', 'posts']));
      });
    });

    group('getListSignal', () {
      test('returns list signal for store', () async {
        final manager = SignalsManager([
          SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockUserStore,
          ),
        ]);
        addTearDown(manager.dispose);

        final listSignal = manager.getListSignal('users');
        expect(listSignal, isNotNull);

        userStreamController.add(testUsers);
        await Future<void>.delayed(Duration.zero);

        // Cast value to expected type
        expect(listSignal.value as List<TestUser>, equals(testUsers));
      });
    });

    group('getStateSignal', () {
      test('returns state signal for store', () {
        final manager = SignalsManager([
          SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockUserStore,
          ),
        ]);
        addTearDown(manager.dispose);

        final stateSignal = manager.getStateSignal('users');
        expect(stateSignal, isNotNull);
        expect(stateSignal.value, isA<NexusSignalInitial<dynamic>>());
      });
    });

    group('createCrossStoreComputed', () {
      test('creates computed signal across multiple stores', () async {
        final manager = SignalsManager([
          SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockUserStore,
          ),
          SignalsStoreConfig<TestPost, String>(
            name: 'posts',
            store: mockPostStore,
          ),
        ]);
        addTearDown(manager.dispose);

        final crossComputed = manager.createCrossStoreComputed<int>(
          'totalCount',
          (bundles) {
            final userCount = bundles['users']!.listSignal.value.length;
            final postCount = bundles['posts']!.listSignal.value.length;
            return userCount + postCount;
          },
        );

        userStreamController.add(testUsers); // 3 users
        postStreamController.add([
          const TestPost(id: 'p1', title: 'Post 1'),
          const TestPost(id: 'p2', title: 'Post 2'),
        ]); // 2 posts
        await Future<void>.delayed(Duration.zero);

        expect(crossComputed.value, equals(5));
      });
    });

    group('dispose', () {
      test('disposes all bundles', () {
        final manager = SignalsManager([
          SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockUserStore,
          ),
        ]);

        final bundle = manager.getBundle('users');
        manager.dispose();

        expect(bundle.listSignal.disposed, isTrue);
      });
    });
  });
}
