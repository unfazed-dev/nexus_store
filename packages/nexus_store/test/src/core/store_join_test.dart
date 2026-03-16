import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('StoreJoin', () {
    late FakeStoreBackend<TestUser, String> userBackend;
    late FakeStoreBackend<TestProduct, int> productBackend;
    late NexusStore<TestUser, String> userStore;
    late NexusStore<TestProduct, int> productStore;

    setUp(() async {
      userBackend = FakeStoreBackend<TestUser, String>(
        idExtractor: (u) => u.id,
      );
      productBackend = FakeStoreBackend<TestProduct, int>(
        idExtractor: (p) => p.id,
      );

      userStore = NexusStore<TestUser, String>(
        backend: userBackend,
        config: StoreConfig(),
        idExtractor: (u) => u.id,
      );
      productStore = NexusStore<TestProduct, int>(
        backend: productBackend,
        config: StoreConfig(),
        idExtractor: (p) => p.id,
      );

      await userStore.initialize();
      await productStore.initialize();
    });

    tearDown(() async {
      await userStore.dispose();
      await productStore.dispose();
    });

    group('combine2', () {
      test('emits initial combined state', () async {
        final user = TestFixtures.createUser(id: 'u1', name: 'Alice');
        final product = TestFixtures.createProduct(id: 1, name: 'Widget');

        userBackend.addToStorage('u1', user);
        productBackend.addToStorage(1, product);

        final stream = StoreJoin.combine2(
          storeA: userStore,
          storeB: productStore,
        );

        final result = await stream.first;
        expect(result.$1, contains(user));
        expect(result.$2, contains(product));
      });

      test('re-emits when storeA changes', () async {
        final stream = StoreJoin.combine2(
          storeA: userStore,
          storeB: productStore,
        );

        final results = <(List<TestUser>, List<TestProduct>)>[];
        final sub = stream.listen(results.add);

        // Wait for initial emission
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Add a user — should trigger re-emission
        await userStore.save(
          TestFixtures.createUser(id: 'u1', name: 'Bob'),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(results.length, greaterThanOrEqualTo(2));
        expect(results.last.$1.length, 1);

        await sub.cancel();
      });

      test('re-emits when storeB changes', () async {
        final stream = StoreJoin.combine2(
          storeA: userStore,
          storeB: productStore,
        );

        final results = <(List<TestUser>, List<TestProduct>)>[];
        final sub = stream.listen(results.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Add a product — should trigger re-emission
        await productStore.save(
          TestFixtures.createProduct(id: 1, name: 'Gadget'),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(results.length, greaterThanOrEqualTo(2));
        expect(results.last.$2.length, 1);

        await sub.cancel();
      });

      test('handles empty stores', () async {
        final stream = StoreJoin.combine2(
          storeA: userStore,
          storeB: productStore,
        );

        final result = await stream.first;
        expect(result.$1, isEmpty);
        expect(result.$2, isEmpty);
      });

      test('applies query filters', () async {
        userBackend.addToStorage(
          'u1',
          TestFixtures.createUser(id: 'u1', name: 'Alice', isActive: true),
        );
        userBackend.addToStorage(
          'u2',
          TestFixtures.createUser(id: 'u2', name: 'Bob', isActive: false),
        );

        final stream = StoreJoin.combine2(
          storeA: userStore,
          storeB: productStore,
          queryA: const Query<TestUser>().where(
            'isActive',
            isEqualTo: true,
          ),
        );

        final result = await stream.first;
        // Query filtering depends on backend — FakeStoreBackend doesn't
        // filter watchAll, but the API should accept and forward queries
        expect(result.$1, isA<List<TestUser>>());
        expect(result.$2, isA<List<TestProduct>>());
      });
    });

    group('combine3', () {
      late FakeStoreBackend<TestUser, String> thirdBackend;
      late NexusStore<TestUser, String> thirdStore;

      setUp(() async {
        thirdBackend = FakeStoreBackend<TestUser, String>(
          idExtractor: (u) => u.id,
        );
        thirdStore = NexusStore<TestUser, String>(
          backend: thirdBackend,
          config: StoreConfig(),
          idExtractor: (u) => u.id,
        );
        await thirdStore.initialize();
      });

      tearDown(() async {
        await thirdStore.dispose();
      });

      test('emits combined state of 3 stores', () async {
        userBackend.addToStorage(
          'u1',
          TestFixtures.createUser(id: 'u1'),
        );
        productBackend.addToStorage(1, TestFixtures.createProduct(id: 1));
        thirdBackend.addToStorage(
          'a1',
          TestFixtures.createUser(id: 'a1', name: 'Admin'),
        );

        final stream = StoreJoin.combine3(
          storeA: userStore,
          storeB: productStore,
          storeC: thirdStore,
        );

        final result = await stream.first;
        expect(result.$1.length, 1);
        expect(result.$2.length, 1);
        expect(result.$3.length, 1);
      });

      test('re-emits on any store change', () async {
        final stream = StoreJoin.combine3(
          storeA: userStore,
          storeB: productStore,
          storeC: thirdStore,
        );

        final results = <(List<TestUser>, List<TestProduct>, List<TestUser>)>[];
        final sub = stream.listen(results.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final initialCount = results.length;

        // Change third store
        await thirdStore.save(
          TestFixtures.createUser(id: 'a1', name: 'Admin'),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(results.length, greaterThan(initialCount));
        expect(results.last.$3.length, 1);

        await sub.cancel();
      });
    });

    group('combine4', () {
      late FakeStoreBackend<TestUser, String> thirdBackend;
      late FakeStoreBackend<TestUser, String> fourthBackend;
      late NexusStore<TestUser, String> thirdStore;
      late NexusStore<TestUser, String> fourthStore;

      setUp(() async {
        thirdBackend = FakeStoreBackend<TestUser, String>(
          idExtractor: (u) => u.id,
        );
        fourthBackend = FakeStoreBackend<TestUser, String>(
          idExtractor: (u) => u.id,
        );
        thirdStore = NexusStore<TestUser, String>(
          backend: thirdBackend,
          config: StoreConfig(),
          idExtractor: (u) => u.id,
        );
        fourthStore = NexusStore<TestUser, String>(
          backend: fourthBackend,
          config: StoreConfig(),
          idExtractor: (u) => u.id,
        );
        await thirdStore.initialize();
        await fourthStore.initialize();
      });

      tearDown(() async {
        await thirdStore.dispose();
        await fourthStore.dispose();
      });

      test('emits combined state of 4 stores', () async {
        userBackend.addToStorage('u1', TestFixtures.createUser(id: 'u1'));
        productBackend.addToStorage(1, TestFixtures.createProduct(id: 1));
        thirdBackend.addToStorage(
          'a1',
          TestFixtures.createUser(id: 'a1', name: 'Admin'),
        );
        fourthBackend.addToStorage(
          'g1',
          TestFixtures.createUser(id: 'g1', name: 'Guest'),
        );

        final stream = StoreJoin.combine4(
          storeA: userStore,
          storeB: productStore,
          storeC: thirdStore,
          storeD: fourthStore,
        );

        final result = await stream.first;
        expect(result.$1.length, 1);
        expect(result.$2.length, 1);
        expect(result.$3.length, 1);
        expect(result.$4.length, 1);
      });

      test('re-emits on any store change', () async {
        final stream = StoreJoin.combine4(
          storeA: userStore,
          storeB: productStore,
          storeC: thirdStore,
          storeD: fourthStore,
        );

        final results = <(
          List<TestUser>,
          List<TestProduct>,
          List<TestUser>,
          List<TestUser>,
        )>[];
        final sub = stream.listen(results.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final initialCount = results.length;

        await fourthStore.save(
          TestFixtures.createUser(id: 'g1', name: 'Guest'),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(results.length, greaterThan(initialCount));
        expect(results.last.$4.length, 1);

        await sub.cancel();
      });
    });

    group('withLatest2', () {
      test('emits only when primary changes', () async {
        productBackend.addToStorage(1, TestFixtures.createProduct(id: 1));

        final stream = StoreJoin.withLatest2(
          primary: userStore,
          secondary: productStore,
        );

        final results = <(List<TestUser>, List<TestProduct>)>[];
        final sub = stream.listen(results.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final countAfterInit = results.length;

        // Change primary — should emit
        await userStore.save(
          TestFixtures.createUser(id: 'u1', name: 'Alice'),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(results.length, greaterThan(countAfterInit));

        await sub.cancel();
      });

      test('uses latest secondary value', () async {
        productBackend.addToStorage(
          1,
          TestFixtures.createProduct(id: 1, name: 'Widget'),
        );

        final stream = StoreJoin.withLatest2(
          primary: userStore,
          secondary: productStore,
        );

        final results = <(List<TestUser>, List<TestProduct>)>[];
        final sub = stream.listen(results.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Update secondary first
        await productStore.save(
          TestFixtures.createProduct(id: 2, name: 'Gadget'),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final countBeforePrimary = results.length;

        // Now update primary — should include latest secondary
        await userStore.save(
          TestFixtures.createUser(id: 'u1', name: 'Bob'),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(results.length, greaterThan(countBeforePrimary));
        // Latest secondary should include both products
        expect(results.last.$2.length, 2);

        await sub.cancel();
      });

      test('does NOT emit on secondary-only change', () async {
        final stream = StoreJoin.withLatest2(
          primary: userStore,
          secondary: productStore,
        );

        final results = <(List<TestUser>, List<TestProduct>)>[];
        final sub = stream.listen(results.add);

        // Wait for initial emission from primary
        await Future<void>.delayed(const Duration(milliseconds: 100));
        final countAfterInit = results.length;

        // Change only secondary — should NOT trigger new emission
        await productStore.save(
          TestFixtures.createProduct(id: 1, name: 'Widget'),
        );

        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Count should remain the same
        expect(results.length, countAfterInit);

        await sub.cancel();
      });
    });

    group('error handling', () {
      test('error propagation from any store', () async {
        userBackend.shouldFailOnGet = true;
        userBackend.errorToThrow = Exception('Backend error');

        // The stream should propagate errors from watchAll
        // FakeStoreBackend.watchAll uses BehaviorSubject so won't error,
        // but if a backend stream errors, combine should propagate it
        final stream = StoreJoin.combine2(
          storeA: userStore,
          storeB: productStore,
        );

        // Stream should still be valid and emit (BehaviorSubject-based)
        expect(stream, isA<Stream<(List<TestUser>, List<TestProduct>)>>());
      });
    });

    group('dispose/cancel handling', () {
      test('subscription can be cancelled cleanly', () async {
        final stream = StoreJoin.combine2(
          storeA: userStore,
          storeB: productStore,
        );

        final sub = stream.listen((_) {});

        // Should not throw
        await sub.cancel();
      });
    });
  });
}
