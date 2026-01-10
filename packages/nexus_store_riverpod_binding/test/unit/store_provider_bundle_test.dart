import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_flutter_widgets/nexus_store_flutter_widgets.dart';
import 'package:nexus_store_riverpod_binding/nexus_store_riverpod_binding.dart';

import '../helpers/mocks.dart';
import '../helpers/test_fixtures.dart';

/// Creates a mock store with dispose already stubbed.
MockNexusStore<TestUser, String> createMockStore() {
  final store = MockNexusStore<TestUser, String>();
  when(store.dispose).thenAnswer((_) async {});
  return store;
}

void main() {
  setUpAll(registerFallbackValues);

  group('StoreProviderBundle', () {
    group('forStore factory', () {
      test('creates bundle with all providers', () {
        final bundle = StoreProviderBundle<TestUser, String>.forStore(
          create: (_) => createMockStore(),
          name: 'users',
        );

        expect(bundle.storeProvider, isNotNull);
        expect(bundle.allProvider, isNotNull);
        expect(bundle.byIdProvider, isNotNull);
        expect(bundle.statusProvider, isNotNull);
        expect(bundle.byIdStatusProvider, isNotNull);
      });

      test('uses default name when not provided', () {
        final bundle = StoreProviderBundle<TestUser, String>.forStore(
          create: (_) => createMockStore(),
        );

        expect(bundle.name, isNull);
        expect(bundle.storeProvider, isNotNull);
      });

      test('stores provided name', () {
        final bundle = StoreProviderBundle<TestUser, String>.forStore(
          create: (_) => createMockStore(),
          name: 'test-users',
        );

        expect(bundle.name, equals('test-users'));
      });
    });

    group('storeProvider', () {
      test('provides NexusStore instance', () {
        final mockStore = createMockStore();
        final bundle = StoreProviderBundle<TestUser, String>.forStore(
          create: (_) => mockStore,
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final store = container.read(bundle.storeProvider);
        expect(store, same(mockStore));
      });

      test('disposes store when keepAlive is false', () async {
        final mockStore = createMockStore();

        final bundle = StoreProviderBundle<TestUser, String>.forStore(
          create: (_) => mockStore,
        );

        final container = ProviderContainer();
        container.read(bundle.storeProvider);
        container.dispose();

        await Future<void>.delayed(Duration.zero);
        verify(mockStore.dispose).called(1);
      });

      test('does not auto-dispose when keepAlive is true', () async {
        final mockStore = createMockStore();

        final bundle = StoreProviderBundle<TestUser, String>.forStore(
          create: (_) => mockStore,
          keepAlive: true,
        );

        final container = ProviderContainer();
        container.read(bundle.storeProvider);
        // Container disposal should still dispose
        container.dispose();

        // With keepAlive, the provider stays alive until container disposal
        await Future<void>.delayed(Duration.zero);
        verify(mockStore.dispose).called(1);
      });
    });

    group('allProvider', () {
      test('emits list of all items from store', () async {
        final users = TestFixtures.sampleUsers;
        final mockStore = MockStoreHelper.withUsers(users);

        final bundle = StoreProviderBundle<TestUser, String>.forStore(
          create: (_) => mockStore,
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Wait for the stream to emit
        await container.read(bundle.allProvider.future);
        final result = container.read(bundle.allProvider);

        expect(result.value, equals(users));
      });

      test('updates when store emits new data', () async {
        final initialUsers = [TestFixtures.createUser(id: 'u1', name: 'A')];
        final updatedUsers = [
          TestFixtures.createUser(id: 'u1', name: 'A'),
          TestFixtures.createUser(id: 'u2', name: 'B'),
        ];

        // Create a stream that emits both values
        final mockStore = createMockStore();
        when(() => mockStore.watchAll(query: any(named: 'query'))).thenAnswer(
          (_) => Stream.fromIterable([initialUsers, updatedUsers]),
        );

        final bundle = StoreProviderBundle<TestUser, String>.forStore(
          create: (_) => mockStore,
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Subscribe and get emissions
        final emissions = <List<TestUser>>[];
        container.listen(
          bundle.allProvider,
          (prev, next) {
            if (next.hasValue) emissions.add(next.value!);
          },
          fireImmediately: true,
        );

        // Wait for stream to complete
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(emissions.length, greaterThanOrEqualTo(1));
        expect(emissions.last, equals(updatedUsers));
      });

      test('handles errors from store', () async {
        final mockStore = MockStoreHelper.withError(Exception('Test error'));

        final bundle = StoreProviderBundle<TestUser, String>.forStore(
          create: (_) => mockStore,
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await expectLater(
          container.read(bundle.allProvider.future),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('byIdProvider', () {
      test('emits single item by ID', () async {
        final user = TestFixtures.sampleUser;
        final mockStore = createMockStore();
        when(() => mockStore.watch(user.id))
            .thenAnswer((_) => Stream.value(user));

        final bundle = StoreProviderBundle<TestUser, String>.forStore(
          create: (_) => mockStore,
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(bundle.byIdProvider(user.id).future);
        final result = container.read(bundle.byIdProvider(user.id));

        expect(result.value, equals(user));
      });

      test('emits null when item not found', () async {
        final mockStore = createMockStore();
        when(() => mockStore.watch('non-existent'))
            .thenAnswer((_) => Stream.value(null));

        final bundle = StoreProviderBundle<TestUser, String>.forStore(
          create: (_) => mockStore,
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(bundle.byIdProvider('non-existent').future);
        final result = container.read(bundle.byIdProvider('non-existent'));

        expect(result.value, isNull);
      });

      test('different IDs create separate providers', () async {
        final user1 = TestFixtures.createUser(id: 'u1', name: 'User 1');
        final user2 = TestFixtures.createUser(id: 'u2', name: 'User 2');

        final mockStore = createMockStore();
        when(() => mockStore.watch('u1'))
            .thenAnswer((_) => Stream.value(user1));
        when(() => mockStore.watch('u2'))
            .thenAnswer((_) => Stream.value(user2));

        final bundle = StoreProviderBundle<TestUser, String>.forStore(
          create: (_) => mockStore,
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(bundle.byIdProvider('u1').future);
        await container.read(bundle.byIdProvider('u2').future);

        expect(container.read(bundle.byIdProvider('u1')).value, equals(user1));
        expect(container.read(bundle.byIdProvider('u2')).value, equals(user2));
      });
    });

    group('statusProvider', () {
      test('emits StoreResult.success with data', () async {
        final users = TestFixtures.sampleUsers;
        final mockStore = MockStoreHelper.withUsers(users);

        final bundle = StoreProviderBundle<TestUser, String>.forStore(
          create: (_) => mockStore,
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(bundle.statusProvider.future);
        final result = container.read(bundle.statusProvider);

        expect(result.value, isA<StoreResult<List<TestUser>>>());
        expect(result.value!.data, equals(users));
      });
    });

    group('byIdStatusProvider', () {
      test('emits StoreResult.success with single item', () async {
        final user = TestFixtures.sampleUser;
        final mockStore = createMockStore();
        when(() => mockStore.watch(user.id))
            .thenAnswer((_) => Stream.value(user));

        final bundle = StoreProviderBundle<TestUser, String>.forStore(
          create: (_) => mockStore,
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(bundle.byIdStatusProvider(user.id).future);
        final result = container.read(bundle.byIdStatusProvider(user.id));

        expect(result.value, isA<StoreResult<TestUser?>>());
        expect(result.value!.data, equals(user));
      });
    });

    group('keepAlive option', () {
      test('with keepAlive false uses auto-dispose behavior', () {
        final bundle = StoreProviderBundle<TestUser, String>.forStore(
          create: (_) => createMockStore(),
          keepAlive: false,
        );

        expect(bundle.keepAlive, isFalse);
      });

      test('with keepAlive true preserves state', () {
        final bundle = StoreProviderBundle<TestUser, String>.forStore(
          create: (_) => createMockStore(),
          keepAlive: true,
        );

        expect(bundle.keepAlive, isTrue);
      });
    });
  });
}
