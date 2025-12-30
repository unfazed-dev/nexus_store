import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_flutter/nexus_store_flutter.dart';
import 'package:nexus_store_riverpod_binding/nexus_store_riverpod_binding.dart';

import 'helpers/mocks.dart';
import 'helpers/test_fixtures.dart';

void main() {
  setUpAll(() {
    registerFallbackValues();
  });

  group('createNexusStoreProvider', () {
    test('creates a provider that returns the store', () {
      final store = MockNexusStore<TestUser, String>();
      when(() => store.dispose()).thenAnswer((_) async {});

      final provider = createNexusStoreProvider<TestUser, String>(
        (ref) => store,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(provider);
      expect(result, same(store));
    });

    test('disposes store when autoDispose is true (default)', () async {
      final store = MockNexusStore<TestUser, String>();
      when(() => store.dispose()).thenAnswer((_) async {});

      final provider = createNexusStoreProvider<TestUser, String>(
        (ref) => store,
        autoDispose: true,
      );

      final container = ProviderContainer();
      container.read(provider);

      container.dispose();

      verify(() => store.dispose()).called(1);
    });

    test('does not dispose store when autoDispose is false', () async {
      final store = MockNexusStore<TestUser, String>();
      when(() => store.dispose()).thenAnswer((_) async {});

      final provider = createNexusStoreProvider<TestUser, String>(
        (ref) => store,
        autoDispose: false,
      );

      final container = ProviderContainer();
      container.read(provider);

      container.dispose();

      verifyNever(() => store.dispose());
    });
  });

  group('createAutoDisposeNexusStoreProvider', () {
    test('creates an auto-dispose provider', () {
      final store = MockNexusStore<TestUser, String>();
      when(() => store.dispose()).thenAnswer((_) async {});

      final provider = createAutoDisposeNexusStoreProvider<TestUser, String>(
        (ref) => store,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(provider);
      expect(result, same(store));
    });

    test('disposes store on container dispose', () async {
      final store = MockNexusStore<TestUser, String>();
      when(() => store.dispose()).thenAnswer((_) async {});

      final provider = createAutoDisposeNexusStoreProvider<TestUser, String>(
        (ref) => store,
      );

      final container = ProviderContainer();
      container.read(provider);

      container.dispose();

      verify(() => store.dispose()).called(1);
    });
  });

  group('createWatchAllProvider', () {
    test('creates a StreamProvider that emits watchAll data', () async {
      final users = TestFixtures.sampleUsers;
      final store = MockStoreHelper.withUsers(users);

      final storeProvider = Provider<NexusStore<TestUser, String>>(
        (ref) => store,
      );
      final watchAllProvider = createWatchAllProvider<TestUser, String>(
        storeProvider,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for stream to emit
      await container.read(watchAllProvider.future);

      final result = container.read(watchAllProvider);
      expect(result.value, equals(users));
    });

    test('applies query parameter to watchAll', () async {
      final store = MockNexusStore<TestUser, String>();
      final query = Query<TestUser>();

      when(() => store.watchAll(query: query))
          .thenAnswer((_) => Stream.value([]));

      final storeProvider = Provider<NexusStore<TestUser, String>>(
        (ref) => store,
      );
      final watchAllProvider = createWatchAllProvider<TestUser, String>(
        storeProvider,
        query: query,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(watchAllProvider.future);

      verify(() => store.watchAll(query: query)).called(1);
    });

    test('emits error when stream errors', () async {
      final error = Exception('Test error');
      final store = MockStoreHelper.withError(error);

      final storeProvider = Provider<NexusStore<TestUser, String>>(
        (ref) => store,
      );
      final watchAllProvider = createWatchAllProvider<TestUser, String>(
        storeProvider,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for error to propagate
      await expectLater(
        container.read(watchAllProvider.future),
        throwsA(equals(error)),
      );

      final result = container.read(watchAllProvider);
      expect(result.hasError, isTrue);
      expect(result.error, equals(error));
    });

    test('emits multiple values as stream updates', () async {
      final (store, controller) = MockStoreHelper.withController();

      final storeProvider = Provider<NexusStore<TestUser, String>>(
        (ref) => store,
      );
      final watchAllProvider = createWatchAllProvider<TestUser, String>(
        storeProvider,
      );

      final container = ProviderContainer();
      addTearDown(() {
        container.dispose();
        controller.close();
      });

      // Start watching
      container.listen(watchAllProvider, (_, __) {});

      // Emit first value
      final users1 = [TestFixtures.createUser(id: '1')];
      controller.add(users1);
      await Future.delayed(Duration.zero);

      expect(container.read(watchAllProvider).value, equals(users1));

      // Emit second value
      final users2 = [
        TestFixtures.createUser(id: '1'),
        TestFixtures.createUser(id: '2'),
      ];
      controller.add(users2);
      await Future.delayed(Duration.zero);

      expect(container.read(watchAllProvider).value, equals(users2));
    });
  });

  group('createWatchByIdProvider', () {
    test('creates a family provider that watches by ID', () async {
      final user = TestFixtures.sampleUser;
      final store = MockStoreHelper.withUser(user.id, user);

      final storeProvider = Provider<NexusStore<TestUser, String>>(
        (ref) => store,
      );
      final watchByIdProvider = createWatchByIdProvider<TestUser, String>(
        storeProvider,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(watchByIdProvider(user.id).future);

      final result = container.read(watchByIdProvider(user.id));
      expect(result.value, equals(user));
    });

    test('returns null for non-existent ID', () async {
      final store = MockStoreHelper.withUser('non-existent', null);

      final storeProvider = Provider<NexusStore<TestUser, String>>(
        (ref) => store,
      );
      final watchByIdProvider = createWatchByIdProvider<TestUser, String>(
        storeProvider,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(watchByIdProvider('non-existent').future);

      final result = container.read(watchByIdProvider('non-existent'));
      expect(result.value, isNull);
    });

    test('different IDs create different providers', () async {
      final user1 = TestFixtures.createUser(id: 'user-1', name: 'User 1');
      final user2 = TestFixtures.createUser(id: 'user-2', name: 'User 2');

      final store = MockNexusStore<TestUser, String>();
      when(() => store.watch('user-1'))
          .thenAnswer((_) => Stream.value(user1));
      when(() => store.watch('user-2'))
          .thenAnswer((_) => Stream.value(user2));

      final storeProvider = Provider<NexusStore<TestUser, String>>(
        (ref) => store,
      );
      final watchByIdProvider = createWatchByIdProvider<TestUser, String>(
        storeProvider,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(watchByIdProvider('user-1').future);
      await container.read(watchByIdProvider('user-2').future);

      expect(container.read(watchByIdProvider('user-1')).value, equals(user1));
      expect(container.read(watchByIdProvider('user-2')).value, equals(user2));
    });
  });

  group('createWatchWithStatusProvider', () {
    test('wraps data in StoreResult.success', () async {
      final users = TestFixtures.sampleUsers;
      final store = MockStoreHelper.withUsers(users);

      final storeProvider = Provider<NexusStore<TestUser, String>>(
        (ref) => store,
      );
      final statusProvider = createWatchWithStatusProvider<TestUser, String>(
        storeProvider,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(statusProvider.future);

      final result = container.read(statusProvider);
      expect(result.hasValue, isTrue);

      final storeResult = result.value!;
      expect(storeResult, isA<StoreResultSuccess<List<TestUser>>>());

      storeResult.when(
        idle: () => fail('Should not be idle'),
        pending: (_) => fail('Should not be pending'),
        success: (data) => expect(data, equals(users)),
        error: (_, __) => fail('Should not be error'),
      );
    });
  });

  group('NexusStoreProviderOptions', () {
    test('defaults has autoDispose true', () {
      const options = NexusStoreProviderOptions();
      expect(options.autoDispose, isTrue);
      expect(options.name, isNull);
    });

    test('can customize options', () {
      const options = NexusStoreProviderOptions(
        autoDispose: false,
        name: 'users',
      );
      expect(options.autoDispose, isFalse);
      expect(options.name, equals('users'));
    });
  });
}
