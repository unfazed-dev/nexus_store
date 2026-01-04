import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('NexusRegistry', () {
    late FakeStoreBackend<TestUser, String> userBackend;
    late FakeStoreBackend<TestProduct, int> productBackend;
    late NexusStore<TestUser, String> userStore;
    late NexusStore<TestProduct, int> productStore;

    setUp(() async {
      // Reset registry before each test
      NexusRegistry.reset();

      // Create backends
      userBackend = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
      productBackend = FakeStoreBackend<TestProduct, int>(
        idExtractor: (product) => product.id,
      );

      // Create stores
      userStore = NexusStore<TestUser, String>(
        backend: userBackend,
        idExtractor: (user) => user.id,
      );
      productStore = NexusStore<TestProduct, int>(
        backend: productBackend,
        idExtractor: (product) => product.id,
      );

      await userStore.initialize();
      await productStore.initialize();
    });

    tearDown(() async {
      NexusRegistry.reset();
      await userStore.dispose();
      await productStore.dispose();
    });

    group('register', () {
      test('should register a store', () {
        NexusRegistry.register<TestUser>(userStore);

        // Should not throw when registered
        expect(() => NexusRegistry.get<TestUser, String>(), returnsNormally);
      });

      test('should register multiple stores of different types', () {
        NexusRegistry.register<TestUser>(userStore);
        NexusRegistry.register<TestProduct>(productStore);

        expect(NexusRegistry.get<TestUser, String>(), equals(userStore));
        expect(NexusRegistry.get<TestProduct, int>(), equals(productStore));
      });

      test('should throw when registering same type twice without scope', () {
        NexusRegistry.register<TestUser>(userStore);

        expect(
          () => NexusRegistry.register<TestUser>(userStore),
          throwsStateError,
        );
      });

      test('should allow re-registration with replace flag', () async {
        NexusRegistry.register<TestUser>(userStore);

        // Create another store
        final anotherBackend = FakeStoreBackend<TestUser, String>(
          idExtractor: (user) => user.id,
        );
        final anotherStore = NexusStore<TestUser, String>(
          backend: anotherBackend,
          idExtractor: (user) => user.id,
        );
        await anotherStore.initialize();

        NexusRegistry.register<TestUser>(anotherStore, replace: true);

        expect(NexusRegistry.get<TestUser, String>(), equals(anotherStore));

        await anotherStore.dispose();
      });
    });

    group('get', () {
      test('should return registered store', () {
        NexusRegistry.register<TestUser>(userStore);

        final retrieved = NexusRegistry.get<TestUser, String>();
        expect(retrieved, equals(userStore));
      });

      test('should throw when store not registered', () {
        expect(
          () => NexusRegistry.get<TestUser, String>(),
          throwsStateError,
        );
      });

      test('should throw descriptive error for unregistered type', () {
        expect(
          () => NexusRegistry.get<TestUser, String>(),
          throwsA(
            isStateError.having(
              (e) => e.message,
              'message',
              contains('TestUser'),
            ),
          ),
        );
      });
    });

    group('tryGet', () {
      test('should return registered store', () {
        NexusRegistry.register<TestUser>(userStore);

        final retrieved = NexusRegistry.tryGet<TestUser, String>();
        expect(retrieved, equals(userStore));
      });

      test('should return null when store not registered', () {
        final retrieved = NexusRegistry.tryGet<TestUser, String>();
        expect(retrieved, isNull);
      });
    });

    group('isRegistered', () {
      test('should return true for registered store', () {
        NexusRegistry.register<TestUser>(userStore);

        expect(NexusRegistry.isRegistered<TestUser>(), isTrue);
      });

      test('should return false for unregistered store', () {
        expect(NexusRegistry.isRegistered<TestUser>(), isFalse);
      });

      test('should respect scope', () {
        NexusRegistry.register<TestUser>(userStore, scope: 'tenant-a');

        expect(NexusRegistry.isRegistered<TestUser>(), isFalse);
        expect(NexusRegistry.isRegistered<TestUser>(scope: 'tenant-a'), isTrue);
        expect(
            NexusRegistry.isRegistered<TestUser>(scope: 'tenant-b'), isFalse);
      });
    });

    group('scoped registration', () {
      test('should register same type in different scopes', () async {
        final tenantABackend = FakeStoreBackend<TestUser, String>(
          idExtractor: (user) => user.id,
        );
        final tenantBBackend = FakeStoreBackend<TestUser, String>(
          idExtractor: (user) => user.id,
        );
        final tenantAStore = NexusStore<TestUser, String>(
          backend: tenantABackend,
          idExtractor: (user) => user.id,
        );
        final tenantBStore = NexusStore<TestUser, String>(
          backend: tenantBBackend,
          idExtractor: (user) => user.id,
        );

        await tenantAStore.initialize();
        await tenantBStore.initialize();

        NexusRegistry.register<TestUser>(tenantAStore, scope: 'tenant-a');
        NexusRegistry.register<TestUser>(tenantBStore, scope: 'tenant-b');

        expect(
          NexusRegistry.get<TestUser, String>(scope: 'tenant-a'),
          equals(tenantAStore),
        );
        expect(
          NexusRegistry.get<TestUser, String>(scope: 'tenant-b'),
          equals(tenantBStore),
        );

        await tenantAStore.dispose();
        await tenantBStore.dispose();
      });

      test('should isolate scoped stores from default scope', () {
        NexusRegistry.register<TestUser>(userStore);

        expect(
          () => NexusRegistry.get<TestUser, String>(scope: 'tenant-a'),
          throwsStateError,
        );
      });

      test('should throw when getting scoped store without scope', () async {
        final scopedBackend = FakeStoreBackend<TestUser, String>(
          idExtractor: (user) => user.id,
        );
        final scopedStore = NexusStore<TestUser, String>(
          backend: scopedBackend,
          idExtractor: (user) => user.id,
        );
        await scopedStore.initialize();

        NexusRegistry.register<TestUser>(scopedStore, scope: 'tenant-a');

        expect(
          () => NexusRegistry.get<TestUser, String>(),
          throwsStateError,
        );

        await scopedStore.dispose();
      });
    });

    group('dispose', () {
      test('should dispose single store from registry', () {
        NexusRegistry.register<TestUser>(userStore);
        NexusRegistry.register<TestProduct>(productStore);

        NexusRegistry.unregister<TestUser>();

        expect(NexusRegistry.isRegistered<TestUser>(), isFalse);
        expect(NexusRegistry.isRegistered<TestProduct>(), isTrue);
      });

      test('should dispose scoped store only', () async {
        final scopedBackend = FakeStoreBackend<TestUser, String>(
          idExtractor: (user) => user.id,
        );
        final scopedStore = NexusStore<TestUser, String>(
          backend: scopedBackend,
          idExtractor: (user) => user.id,
        );
        await scopedStore.initialize();

        NexusRegistry.register<TestUser>(userStore);
        NexusRegistry.register<TestUser>(scopedStore, scope: 'tenant-a');

        NexusRegistry.unregister<TestUser>(scope: 'tenant-a');

        expect(NexusRegistry.isRegistered<TestUser>(), isTrue);
        expect(
            NexusRegistry.isRegistered<TestUser>(scope: 'tenant-a'), isFalse);

        await scopedStore.dispose();
      });

      test('should do nothing when disposing unregistered store', () {
        expect(
          () => NexusRegistry.unregister<TestUser>(),
          returnsNormally,
        );
      });
    });

    group('reset', () {
      test('should clear all registered stores', () {
        NexusRegistry.register<TestUser>(userStore);
        NexusRegistry.register<TestProduct>(productStore);

        NexusRegistry.reset();

        expect(NexusRegistry.isRegistered<TestUser>(), isFalse);
        expect(NexusRegistry.isRegistered<TestProduct>(), isFalse);
      });

      test('should clear all scoped stores', () async {
        final scopedBackend = FakeStoreBackend<TestUser, String>(
          idExtractor: (user) => user.id,
        );
        final scopedStore = NexusStore<TestUser, String>(
          backend: scopedBackend,
          idExtractor: (user) => user.id,
        );
        await scopedStore.initialize();

        NexusRegistry.register<TestUser>(userStore);
        NexusRegistry.register<TestUser>(scopedStore, scope: 'tenant-a');

        NexusRegistry.reset();

        expect(NexusRegistry.isRegistered<TestUser>(), isFalse);
        expect(
            NexusRegistry.isRegistered<TestUser>(scope: 'tenant-a'), isFalse);

        await scopedStore.dispose();
      });
    });

    group('registeredTypes', () {
      test('should return empty list when no stores registered', () {
        expect(NexusRegistry.registeredTypes, isEmpty);
      });

      test('should return list of registered types', () {
        NexusRegistry.register<TestUser>(userStore);
        NexusRegistry.register<TestProduct>(productStore);

        final types = NexusRegistry.registeredTypes;
        expect(types, contains(TestUser));
        expect(types, contains(TestProduct));
      });

      test('should include scoped registrations', () async {
        final scopedBackend = FakeStoreBackend<TestUser, String>(
          idExtractor: (user) => user.id,
        );
        final scopedStore = NexusStore<TestUser, String>(
          backend: scopedBackend,
          idExtractor: (user) => user.id,
        );
        await scopedStore.initialize();

        NexusRegistry.register<TestUser>(scopedStore, scope: 'tenant-a');

        expect(NexusRegistry.registeredTypes, contains(TestUser));

        await scopedStore.dispose();
      });
    });

    group('scopes', () {
      test('should return empty list when no scopes used', () {
        NexusRegistry.register<TestUser>(userStore);

        expect(NexusRegistry.scopes, isEmpty);
      });

      test('should return list of used scopes', () async {
        final scopedBackend1 = FakeStoreBackend<TestUser, String>(
          idExtractor: (user) => user.id,
        );
        final scopedBackend2 = FakeStoreBackend<TestUser, String>(
          idExtractor: (user) => user.id,
        );
        final scopedStore1 = NexusStore<TestUser, String>(
          backend: scopedBackend1,
          idExtractor: (user) => user.id,
        );
        final scopedStore2 = NexusStore<TestUser, String>(
          backend: scopedBackend2,
          idExtractor: (user) => user.id,
        );

        await scopedStore1.initialize();
        await scopedStore2.initialize();

        NexusRegistry.register<TestUser>(scopedStore1, scope: 'tenant-a');
        NexusRegistry.register<TestUser>(scopedStore2, scope: 'tenant-b');

        final scopes = NexusRegistry.scopes;
        expect(scopes, contains('tenant-a'));
        expect(scopes, contains('tenant-b'));

        await scopedStore1.dispose();
        await scopedStore2.dispose();
      });
    });

    group('disposeScope', () {
      test('should clear all stores in a scope', () async {
        final userScopedBackend = FakeStoreBackend<TestUser, String>(
          idExtractor: (user) => user.id,
        );
        final productScopedBackend = FakeStoreBackend<TestProduct, int>(
          idExtractor: (product) => product.id,
        );
        final userScopedStore = NexusStore<TestUser, String>(
          backend: userScopedBackend,
          idExtractor: (user) => user.id,
        );
        final productScopedStore = NexusStore<TestProduct, int>(
          backend: productScopedBackend,
          idExtractor: (product) => product.id,
        );

        await userScopedStore.initialize();
        await productScopedStore.initialize();

        NexusRegistry.register<TestUser>(userStore);
        NexusRegistry.register<TestUser>(userScopedStore, scope: 'tenant-a');
        NexusRegistry.register<TestProduct>(productScopedStore,
            scope: 'tenant-a');

        NexusRegistry.disposeScope('tenant-a');

        expect(NexusRegistry.isRegistered<TestUser>(), isTrue);
        expect(
            NexusRegistry.isRegistered<TestUser>(scope: 'tenant-a'), isFalse);
        expect(NexusRegistry.isRegistered<TestProduct>(scope: 'tenant-a'),
            isFalse);

        await userScopedStore.dispose();
        await productScopedStore.dispose();
      });

      test('should do nothing for non-existent scope', () {
        expect(
          () => NexusRegistry.disposeScope('non-existent'),
          returnsNormally,
        );
      });
    });

    group('edge cases', () {
      test('should handle empty scope string', () {
        NexusRegistry.register<TestUser>(userStore, scope: '');

        expect(NexusRegistry.isRegistered<TestUser>(scope: ''), isTrue);
        expect(
          NexusRegistry.get<TestUser, String>(scope: ''),
          equals(userStore),
        );
      });

      test('should handle registration after reset', () {
        NexusRegistry.register<TestUser>(userStore);
        NexusRegistry.reset();
        NexusRegistry.register<TestProduct>(productStore);

        expect(NexusRegistry.isRegistered<TestUser>(), isFalse);
        expect(NexusRegistry.isRegistered<TestProduct>(), isTrue);
      });

      test(
          'error message includes scope when duplicate in scoped registration (line 81)',
          () async {
        // First register with scope
        NexusRegistry.register<TestUser>(userStore, scope: 'my-tenant');

        // Create another store
        final anotherBackend = FakeStoreBackend<TestUser, String>(
          idExtractor: (user) => user.id,
        );
        final anotherStore = NexusStore<TestUser, String>(
          backend: anotherBackend,
          idExtractor: (user) => user.id,
        );
        await anotherStore.initialize();

        // Try to register same type in same scope without replace
        expect(
          () => NexusRegistry.register<TestUser>(anotherStore,
              scope: 'my-tenant'),
          throwsA(
            isStateError.having(
              (e) => e.message,
              'message',
              allOf(
                contains('TestUser'),
                contains("scope 'my-tenant'"), // line 81 coverage
              ),
            ),
          ),
        );

        await anotherStore.dispose();
      });

      test(
          'error message includes scope when getting non-existent scoped store',
          () {
        // Try to get store in a scope that doesn't exist
        expect(
          () => NexusRegistry.get<TestUser, String>(scope: 'nonexistent'),
          throwsA(
            isStateError.having(
              (e) => e.message,
              'message',
              contains("scope 'nonexistent'"),
            ),
          ),
        );
      });
    });
  });
}
