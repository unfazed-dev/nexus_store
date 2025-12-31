import 'dart:async';

import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('ComputedStore', () {
    late FakeStoreBackend<TestUser, String> userBackend;
    late FakeStoreBackend<TestProduct, int> productBackend;
    late NexusStore<TestUser, String> userStore;
    late NexusStore<TestProduct, int> productStore;

    setUp(() async {
      userBackend = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
      productBackend = FakeStoreBackend<TestProduct, int>(
        idExtractor: (product) => product.id,
      );

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
      await userStore.dispose();
      await productStore.dispose();
    });

    group('from2', () {
      test('should combine two stores', () async {
        // Add some data
        await userStore.save(TestFixtures.createUser(id: 'u1', name: 'Alice'));
        await productStore.save(TestFixtures.createProduct(id: 1, price: 10.0));

        final computed = ComputedStore.from2(
          userStore,
          productStore,
          (users, products) => {
            'userCount': users.length,
            'productCount': products.length,
          },
        );

        await Future<void>.delayed(Duration.zero);

        expect(computed.value['userCount'], equals(1));
        expect(computed.value['productCount'], equals(1));

        await computed.dispose();
      });

      test('should recompute when source stores change', () async {
        final computed = ComputedStore.from2(
          userStore,
          productStore,
          (users, products) => users.length + products.length,
        );

        final values = <int>[];
        final subscription = computed.stream.listen(values.add);

        await Future<void>.delayed(Duration.zero);

        // Initial state
        expect(values.last, equals(0));

        // Add user
        await userStore.save(TestFixtures.createUser(id: 'u1'));
        await Future<void>.delayed(Duration.zero);
        expect(values.last, equals(1));

        // Add product
        await productStore.save(TestFixtures.createProduct(id: 1));
        await Future<void>.delayed(Duration.zero);
        expect(values.last, equals(2));

        await subscription.cancel();
        await computed.dispose();
      });

      test('should emit immediately on subscribe (BehaviorSubject)', () async {
        await userStore.save(TestFixtures.createUser(id: 'u1'));
        await userStore.save(TestFixtures.createUser(id: 'u2'));

        final computed = ComputedStore.from2(
          userStore,
          productStore,
          (users, products) => users.length,
        );

        await Future<void>.delayed(Duration.zero);

        final completer = Completer<int>();
        unawaited(computed.stream.first.then(completer.complete));

        final result = await completer.future.timeout(
          const Duration(seconds: 1),
        );

        expect(result, equals(2));

        await computed.dispose();
      });
    });

    group('from3', () {
      late FakeStoreBackend<TestUser, String> thirdBackend;
      late NexusStore<TestUser, String> thirdStore;

      setUp(() async {
        thirdBackend = FakeStoreBackend<TestUser, String>(
          idExtractor: (user) => user.id,
        );
        thirdStore = NexusStore<TestUser, String>(
          backend: thirdBackend,
          idExtractor: (user) => user.id,
        );
        await thirdStore.initialize();
      });

      tearDown(() async {
        await thirdStore.dispose();
      });

      test('should combine three stores', () async {
        await userStore.save(TestFixtures.createUser(id: 'u1'));
        await productStore.save(TestFixtures.createProduct(id: 1));
        await thirdStore.save(TestFixtures.createUser(id: 'u2'));

        final computed = ComputedStore.from3(
          userStore,
          productStore,
          thirdStore,
          (users, products, otherUsers) =>
              users.length + products.length + otherUsers.length,
        );

        await Future<void>.delayed(Duration.zero);

        expect(computed.value, equals(3));

        await computed.dispose();
      });

      test('should recompute when any of three sources change', () async {
        final computed = ComputedStore.from3(
          userStore,
          productStore,
          thirdStore,
          (users, products, otherUsers) =>
              users.length + products.length + otherUsers.length,
        );

        final values = <int>[];
        final subscription = computed.stream.listen(values.add);

        await Future<void>.delayed(Duration.zero);

        // Initial state
        expect(values.last, equals(0));

        // Add to first store
        await userStore.save(TestFixtures.createUser(id: 'u1'));
        await Future<void>.delayed(Duration.zero);
        expect(values.last, equals(1));

        // Add to third store
        await thirdStore.save(TestFixtures.createUser(id: 'u2'));
        await Future<void>.delayed(Duration.zero);
        expect(values.last, equals(2));

        await subscription.cancel();
        await computed.dispose();
      });
    });

    group('fromList', () {
      test('should combine list of stores', () async {
        await userStore.save(TestFixtures.createUser(id: 'u1'));
        await productStore.save(TestFixtures.createProduct(id: 1));

        final computed = ComputedStore.fromList(
          [userStore, productStore],
          (allData) => allData.fold<int>(0, (sum, list) => sum + list.length),
        );

        await Future<void>.delayed(Duration.zero);

        expect(computed.value, equals(2));

        await computed.dispose();
      });

      test('should handle empty list of stores', () async {
        final computed = ComputedStore.fromList<int>(
          [],
          (allData) => allData.length,
        );

        await Future<void>.delayed(Duration.zero);

        expect(computed.value, equals(0));

        await computed.dispose();
      });

      test('should handle single store in list', () async {
        await userStore.save(TestFixtures.createUser(id: 'u1'));

        final computed = ComputedStore.fromList(
          [userStore],
          (allData) => allData.isEmpty ? 0 : allData.first.length,
        );

        await Future<void>.delayed(Duration.zero);

        expect(computed.value, equals(1));

        await computed.dispose();
      });
    });

    group('value getter', () {
      test('should return current computed value', () async {
        await userStore.save(TestFixtures.createUser(id: 'u1'));
        await userStore.save(TestFixtures.createUser(id: 'u2'));

        final computed = ComputedStore.from2(
          userStore,
          productStore,
          (users, products) => 'Users: ${users.length}',
        );

        await Future<void>.delayed(Duration.zero);

        expect(computed.value, equals('Users: 2'));

        await computed.dispose();
      });
    });

    group('stream', () {
      test('should emit to multiple subscribers', () async {
        final computed = ComputedStore.from2(
          userStore,
          productStore,
          (users, products) => users.length,
        );

        final values1 = <int>[];
        final values2 = <int>[];

        computed.stream.listen(values1.add);
        computed.stream.listen(values2.add);

        await Future<void>.delayed(Duration.zero);

        await userStore.save(TestFixtures.createUser(id: 'u1'));
        await Future<void>.delayed(Duration.zero);

        expect(values1, contains(0));
        expect(values1, contains(1));
        expect(values2, contains(0));
        expect(values2, contains(1));

        await computed.dispose();
      });
    });

    group('dispose', () {
      test('should close the stream', () async {
        final computed = ComputedStore.from2(
          userStore,
          productStore,
          (users, products) => users.length,
        );

        await Future<void>.delayed(Duration.zero);

        expect(computed.isClosed, isFalse);

        await computed.dispose();

        expect(computed.isClosed, isTrue);
      });

      test('should cancel source subscriptions', () async {
        final computed = ComputedStore.from2(
          userStore,
          productStore,
          (users, products) => users.length,
        );

        final values = <int>[];
        computed.stream.listen(values.add);

        await Future<void>.delayed(Duration.zero);
        final countBeforeDispose = values.length;

        await computed.dispose();

        // After dispose, adding to source should not trigger recompute
        await userStore.save(TestFixtures.createUser(id: 'u1'));
        await Future<void>.delayed(Duration.zero);

        // Values count should remain the same (stream is closed)
        // The subscription completes when the stream closes
        expect(values.length, equals(countBeforeDispose));
      });
    });

    group('isClosed', () {
      test('should return false before dispose', () async {
        final computed = ComputedStore.from2(
          userStore,
          productStore,
          (users, products) => users.length,
        );

        await Future<void>.delayed(Duration.zero);

        expect(computed.isClosed, isFalse);

        await computed.dispose();
      });

      test('should return true after dispose', () async {
        final computed = ComputedStore.from2(
          userStore,
          productStore,
          (users, products) => users.length,
        );

        await Future<void>.delayed(Duration.zero);
        await computed.dispose();

        expect(computed.isClosed, isTrue);
      });
    });

    group('distinctUntilChanged', () {
      test('should not emit duplicate values', () async {
        final computed = ComputedStore.from2(
          userStore,
          productStore,
          (users, products) => users.length,
        );

        final values = <int>[];
        final subscription = computed.stream.listen(values.add);

        await Future<void>.delayed(Duration.zero);

        // Initial value
        expect(values, equals([0]));

        // Trigger recompute that produces same value
        // (e.g., saving same user again won't change count)
        await userStore.save(TestFixtures.createUser(id: 'u1'));
        await Future<void>.delayed(Duration.zero);
        expect(values, equals([0, 1]));

        // Update user (but count stays same)
        await userStore
            .save(TestFixtures.createUser(id: 'u1', name: 'Updated'));
        await Future<void>.delayed(Duration.zero);

        // Count is still 1, so distinctUntilChanged should prevent duplicate
        expect(values.where((v) => v == 1).length, equals(1));

        await subscription.cancel();
        await computed.dispose();
      });
    });

    group('complex compute functions', () {
      test('should handle compute function returning objects', () async {
        await userStore.save(TestFixtures.createUser(id: 'u1', name: 'Alice'));
        await productStore.save(TestFixtures.createProduct(id: 1, price: 10.0));

        final computed = ComputedStore.from2(
          userStore,
          productStore,
          (users, products) => _DashboardState(
            userCount: users.length,
            productCount: products.length,
            totalRevenue: products.fold(0.0, (sum, p) => sum + p.price),
          ),
        );

        await Future<void>.delayed(Duration.zero);

        expect(computed.value.userCount, equals(1));
        expect(computed.value.productCount, equals(1));
        expect(computed.value.totalRevenue, equals(10.0));

        await computed.dispose();
      });

      test('should handle null values in compute', () async {
        final computed = ComputedStore.from2(
          userStore,
          productStore,
          (users, products) => users.isEmpty ? null : users.first,
        );

        await Future<void>.delayed(Duration.zero);

        expect(computed.value, isNull);

        await userStore.save(TestFixtures.createUser(id: 'u1', name: 'Alice'));
        await Future<void>.delayed(Duration.zero);

        expect(computed.value?.name, equals('Alice'));

        await computed.dispose();
      });
    });
  });
}

/// Test class for complex compute functions.
class _DashboardState {
  const _DashboardState({
    required this.userCount,
    required this.productCount,
    required this.totalRevenue,
  });

  final int userCount;
  final int productCount;
  final double totalRevenue;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _DashboardState &&
          userCount == other.userCount &&
          productCount == other.productCount &&
          totalRevenue == other.totalRevenue;

  @override
  int get hashCode => Object.hash(userCount, productCount, totalRevenue);
}
