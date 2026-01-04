import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_flutter_widgets/nexus_store_flutter_widgets.dart';
import 'package:nexus_store_riverpod_binding/nexus_store_riverpod_binding.dart';

import '../helpers/mocks.dart';
import '../helpers/test_fixtures.dart';

void main() {
  setUpAll(registerFallbackValues);

  group('createAutoDisposeWatchAllProvider', () {
    test('creates an auto-dispose StreamProvider that emits watchAll data',
        () async {
      final users = TestFixtures.sampleUsers;
      final store = MockStoreHelper.withUsers(users);

      final storeProvider = Provider<NexusStore<TestUser, String>>(
        (ref) => store,
      );
      final watchAllProvider =
          createAutoDisposeWatchAllProvider<TestUser, String>(
        storeProvider,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(watchAllProvider.future);

      final result = container.read(watchAllProvider);
      expect(result.value, equals(users));
    });

    test('applies query parameter to watchAll', () async {
      final store = MockNexusStore<TestUser, String>();
      const query = Query<TestUser>();

      when(() => store.watchAll(query: query))
          .thenAnswer((_) => Stream.value([]));

      final storeProvider = Provider<NexusStore<TestUser, String>>(
        (ref) => store,
      );
      final watchAllProvider =
          createAutoDisposeWatchAllProvider<TestUser, String>(
        storeProvider,
        query: query,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(watchAllProvider.future);

      verify(() => store.watchAll(query: query)).called(1);
    });
  });

  group('createAutoDisposeWatchWithStatusProvider', () {
    test('creates an auto-dispose provider with StoreResult wrapper', () async {
      final users = TestFixtures.sampleUsers;
      final store = MockStoreHelper.withUsers(users);

      final storeProvider = Provider<NexusStore<TestUser, String>>(
        (ref) => store,
      );
      final statusProvider =
          createAutoDisposeWatchWithStatusProvider<TestUser, String>(
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

    test('applies query parameter', () async {
      final store = MockNexusStore<TestUser, String>();
      const query = Query<TestUser>();

      when(() => store.watchAll(query: query))
          .thenAnswer((_) => Stream.value([]));

      final storeProvider = Provider<NexusStore<TestUser, String>>(
        (ref) => store,
      );
      final statusProvider =
          createAutoDisposeWatchWithStatusProvider<TestUser, String>(
        storeProvider,
        query: query,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(statusProvider.future);

      verify(() => store.watchAll(query: query)).called(1);
    });
  });

  group('createAutoDisposeWatchByIdProvider', () {
    test('creates an auto-dispose family provider that watches by ID',
        () async {
      final user = TestFixtures.sampleUser;
      final store = MockStoreHelper.withUser(user.id, user);

      final storeProvider = Provider<NexusStore<TestUser, String>>(
        (ref) => store,
      );
      final watchByIdProvider =
          createAutoDisposeWatchByIdProvider<TestUser, String>(
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
      final watchByIdProvider =
          createAutoDisposeWatchByIdProvider<TestUser, String>(
        storeProvider,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(watchByIdProvider('non-existent').future);

      final result = container.read(watchByIdProvider('non-existent'));
      expect(result.value, isNull);
    });
  });

  group('createAutoDisposeWatchByIdWithStatusProvider', () {
    test('creates an auto-dispose family provider with StoreResult', () async {
      final user = TestFixtures.sampleUser;
      final store = MockStoreHelper.withUser(user.id, user);

      final storeProvider = Provider<NexusStore<TestUser, String>>(
        (ref) => store,
      );
      final statusProvider =
          createAutoDisposeWatchByIdWithStatusProvider<TestUser, String>(
        storeProvider,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(statusProvider(user.id).future);

      final result = container.read(statusProvider(user.id));
      expect(result.hasValue, isTrue);

      final storeResult = result.value!;
      expect(storeResult, isA<StoreResultSuccess<TestUser?>>());
    });
  });
}
