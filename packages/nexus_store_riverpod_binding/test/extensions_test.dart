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
  setUpAll(registerFallbackValues);

  group('NexusStoreRiverpodX', () {
    group('bindToRef', () {
      test('disposes store when ref is disposed', () async {
        final store = MockNexusStore<TestUser, String>();
        when(store.dispose).thenAnswer((_) async {});

        final provider = Provider<NexusStore<TestUser, String>>((ref) {
          store.bindToRef(ref);
          return store;
        });

        final container = ProviderContainer();
        container.read(provider);

        container.dispose();

        verify(store.dispose).called(1);
      });

      test('can be chained with cascade', () async {
        final store = MockNexusStore<TestUser, String>();
        when(store.dispose).thenAnswer((_) async {});
        when(() => store.watchAll(query: any(named: 'query')))
            .thenAnswer((_) => Stream.value([]));

        final provider = Provider<NexusStore<TestUser, String>>((ref) {
          return store..bindToRef(ref);
        });

        final container = ProviderContainer();
        final result = container.read(provider);

        expect(result, same(store));

        container.dispose();
        verify(store.dispose).called(1);
      });
    });

    group('bindToAutoDisposeRef', () {
      test('disposes store when auto-dispose ref is disposed', () async {
        final store = MockNexusStore<TestUser, String>();
        when(store.dispose).thenAnswer((_) async {});

        final provider =
            Provider.autoDispose<NexusStore<TestUser, String>>((ref) {
          store.bindToAutoDisposeRef(ref);
          return store;
        });

        final container = ProviderContainer();
        container.read(provider);

        container.dispose();

        verify(store.dispose).called(1);
      });
    });
  });

  group('NexusStoreRefX', () {
    group('watchStoreAll', () {
      test('returns stream from store.watchAll', () async {
        final users = TestFixtures.sampleUsers;
        final store = MockStoreHelper.withUsers(users);

        final storeProvider = Provider<NexusStore<TestUser, String>>(
          (ref) => store,
        );

        final streamProvider = StreamProvider<List<TestUser>>((ref) {
          return ref.watchStoreAll(storeProvider);
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(streamProvider.future);

        expect(container.read(streamProvider).value, equals(users));
      });

      test('applies query parameter', () async {
        final store = MockNexusStore<TestUser, String>();
        const query = Query<TestUser>();

        when(() => store.watchAll(query: query))
            .thenAnswer((_) => Stream.value([]));

        final storeProvider = Provider<NexusStore<TestUser, String>>(
          (ref) => store,
        );

        final streamProvider = StreamProvider<List<TestUser>>((ref) {
          return ref.watchStoreAll(storeProvider, query: query);
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(streamProvider.future);

        verify(() => store.watchAll(query: query)).called(1);
      });
    });

    group('watchStoreItem', () {
      test('returns stream from store.watch', () async {
        final user = TestFixtures.sampleUser;
        final store = MockStoreHelper.withUser(user.id, user);

        final storeProvider = Provider<NexusStore<TestUser, String>>(
          (ref) => store,
        );

        final streamProvider =
            StreamProvider.family<TestUser?, String>((ref, id) {
          return ref.watchStoreItem(storeProvider, id);
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(streamProvider(user.id).future);

        expect(container.read(streamProvider(user.id)).value, equals(user));
      });
    });

    group('watchStoreAllWithStatus', () {
      test('wraps data in StoreResult', () async {
        final users = TestFixtures.sampleUsers;
        final store = MockStoreHelper.withUsers(users);

        final storeProvider = Provider<NexusStore<TestUser, String>>(
          (ref) => store,
        );

        final streamProvider =
            StreamProvider<StoreResult<List<TestUser>>>((ref) {
          return ref.watchStoreAllWithStatus(storeProvider);
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(streamProvider.future);

        final result = container.read(streamProvider).value!;
        expect(result, isA<StoreResultSuccess<List<TestUser>>>());
      });
    });
  });

  group('NexusStoreKeepAlive', () {
    test('prevents auto-disposal with keepAlive', () async {
      final store = MockNexusStore<TestUser, String>();
      when(store.dispose).thenAnswer((_) async {});

      late NexusStoreKeepAlive<TestUser, String> keepAlive;

      final provider = Provider<NexusStoreKeepAlive<TestUser, String>>((ref) {
        keepAlive = store.withKeepAlive(ref);
        return keepAlive;
      });

      final container = ProviderContainer();
      container.read(provider);

      // Store should not be disposed yet due to keepAlive
      verifyNever(store.dispose);

      container.dispose();

      // Now it should be disposed
      verify(store.dispose).called(1);
    });

    test('allowDispose closes keepAlive link', () async {
      final store = MockNexusStore<TestUser, String>();
      when(store.dispose).thenAnswer((_) async {});

      late NexusStoreKeepAlive<TestUser, String> keepAlive;

      final provider = Provider<NexusStoreKeepAlive<TestUser, String>>((ref) {
        keepAlive = store.withKeepAlive(ref);
        return keepAlive;
      });

      final container = ProviderContainer();
      final result = container.read(provider);

      result.allowDispose();

      // Verify keepAlive link is closed but store isn't disposed yet
      verifyNever(store.dispose);

      container.dispose();
      verify(store.dispose).called(1);
    });

    test('invalidate closes link and invalidates provider', () async {
      final store = MockNexusStore<TestUser, String>();
      when(store.dispose).thenAnswer((_) async {});

      var createCount = 0;
      final provider = Provider<NexusStoreKeepAlive<TestUser, String>>((ref) {
        createCount++;
        return store.withKeepAlive(ref);
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result1 = container.read(provider);
      expect(createCount, equals(1));

      // Invalidate the provider
      result1.invalidate();

      // Read again - should recreate
      container.read(provider);
      expect(createCount, equals(2));
    });
  });

  group('StoreDisposalManager', () {
    test('disposes all registered stores', () async {
      final store1 = MockNexusStore<TestUser, String>();
      final store2 = MockNexusStore<TestUser, String>();

      when(store1.dispose).thenAnswer((_) async {});
      when(store2.dispose).thenAnswer((_) async {});

      final manager = StoreDisposalManager();
      manager.register(store1);
      manager.register(store2);

      await manager.disposeAll();

      verify(store1.dispose).called(1);
      verify(store2.dispose).called(1);
    });

    test('forRef creates manager bound to ref lifecycle', () async {
      final store = MockNexusStore<TestUser, String>();
      when(store.dispose).thenAnswer((_) async {});

      final provider = Provider<StoreDisposalManager>((ref) {
        final manager = StoreDisposalManager.forRef(ref);
        manager.register(store);
        return manager;
      });

      final container = ProviderContainer();
      container.read(provider);

      verifyNever(store.dispose);

      container.dispose();

      verify(store.dispose).called(1);
    });
  });

  group('StoreDisposalConfig', () {
    test('defaults has autoDispose true', () {
      const config = StoreDisposalConfig.defaults;
      expect(config.autoDispose, isTrue);
      expect(config.disposeOnClose, isTrue);
    });

    test('keepAlive has autoDispose false', () {
      const config = StoreDisposalConfig.keepAlive;
      expect(config.autoDispose, isFalse);
    });

    test('can customize config', () {
      const config = StoreDisposalConfig(
        autoDispose: false,
        disposeOnClose: false,
      );
      expect(config.autoDispose, isFalse);
      expect(config.disposeOnClose, isFalse);
    });
  });
}
