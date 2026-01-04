// ignore_for_file: unreachable_from_main

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_flutter_widgets/nexus_store_flutter_widgets.dart';

class MockNexusStore<T, ID> extends Mock implements NexusStore<T, ID> {}

class User {
  const User({required this.id, required this.name});

  final String id;
  final String name;

  @override
  String toString() => 'User($id, $name)';
}

class Product {
  const Product({required this.id, required this.title});

  final String id;
  final String title;

  @override
  String toString() => 'Product($id, $title)';
}

void main() {
  group('NexusStoreProvider', () {
    late MockNexusStore<User, String> mockStore;

    setUp(() {
      mockStore = MockNexusStore<User, String>();
    });

    testWidgets('provides store to descendants', (tester) async {
      NexusStore<User, String>? capturedStore;

      await tester.pumpWidget(
        MaterialApp(
          home: NexusStoreProvider<User, String>(
            store: mockStore,
            child: Builder(
              builder: (context) {
                capturedStore = NexusStoreProvider.of<User, String>(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(capturedStore, same(mockStore));
    });

    testWidgets('of() throws when provider not found', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(
                () => NexusStoreProvider.of<User, String>(context),
                throwsFlutterError,
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('maybeOf() returns null when provider not found',
        (tester) async {
      NexusStore<User, String>? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = NexusStoreProvider.maybeOf<User, String>(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, isNull);
    });

    testWidgets('maybeOf() returns store when found', (tester) async {
      NexusStore<User, String>? result;

      await tester.pumpWidget(
        MaterialApp(
          home: NexusStoreProvider<User, String>(
            store: mockStore,
            child: Builder(
              builder: (context) {
                result = NexusStoreProvider.maybeOf<User, String>(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, same(mockStore));
    });

    testWidgets('updateShouldNotify returns true when store changes',
        (tester) async {
      final store1 = MockNexusStore<User, String>();
      final store2 = MockNexusStore<User, String>();
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: NexusStoreProvider<User, String>(
            store: store1,
            child: Builder(
              builder: (context) {
                NexusStoreProvider.of<User, String>(context);
                buildCount++;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(buildCount, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: NexusStoreProvider<User, String>(
            store: store2,
            child: Builder(
              builder: (context) {
                NexusStoreProvider.of<User, String>(context);
                buildCount++;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(buildCount, 2);
    });

    testWidgets('nested providers work correctly', (tester) async {
      final userStore = MockNexusStore<User, String>();
      final productStore = MockNexusStore<Product, String>();

      NexusStore<User, String>? capturedUserStore;
      NexusStore<Product, String>? capturedProductStore;

      await tester.pumpWidget(
        MaterialApp(
          home: NexusStoreProvider<User, String>(
            store: userStore,
            child: NexusStoreProvider<Product, String>(
              store: productStore,
              child: Builder(
                builder: (context) {
                  capturedUserStore =
                      NexusStoreProvider.of<User, String>(context);
                  capturedProductStore =
                      NexusStoreProvider.of<Product, String>(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      expect(capturedUserStore, same(userStore));
      expect(capturedProductStore, same(productStore));
    });
  });

  group('MultiNexusStoreProvider', () {
    testWidgets('nests multiple providers', (tester) async {
      final userStore = MockNexusStore<User, String>();
      final productStore = MockNexusStore<Product, String>();

      NexusStore<User, String>? capturedUserStore;
      NexusStore<Product, String>? capturedProductStore;

      await tester.pumpWidget(
        MaterialApp(
          home: MultiNexusStoreProvider(
            providers: [
              (child) => NexusStoreProvider<User, String>(
                    store: userStore,
                    child: child,
                  ),
              (child) => NexusStoreProvider<Product, String>(
                    store: productStore,
                    child: child,
                  ),
            ],
            child: Builder(
              builder: (context) {
                capturedUserStore =
                    NexusStoreProvider.of<User, String>(context);
                capturedProductStore =
                    NexusStoreProvider.of<Product, String>(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(capturedUserStore, same(userStore));
      expect(capturedProductStore, same(productStore));
    });
  });

  group('BuildContext extensions', () {
    late MockNexusStore<User, String> mockStore;

    setUp(() {
      mockStore = MockNexusStore<User, String>();
    });

    testWidgets('nexusStore() returns store from provider', (tester) async {
      NexusStore<User, String>? result;

      await tester.pumpWidget(
        MaterialApp(
          home: NexusStoreProvider<User, String>(
            store: mockStore,
            child: Builder(
              builder: (context) {
                result = context.nexusStore<User, String>();
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, same(mockStore));
    });

    testWidgets('maybeNexusStore() returns null when not found',
        (tester) async {
      NexusStore<User, String>? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = context.maybeNexusStore<User, String>();
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, isNull);
    });

    testWidgets('watchNexusStore() returns stream from store.watchAll',
        (tester) async {
      final testUsers = [
        const User(id: '1', name: 'Alice'),
        const User(id: '2', name: 'Bob'),
      ];
      when(() => mockStore.watchAll(query: any(named: 'query')))
          .thenAnswer((_) => Stream.value(testUsers));

      Stream<List<User>>? result;

      await tester.pumpWidget(
        MaterialApp(
          home: NexusStoreProvider<User, String>(
            store: mockStore,
            child: Builder(
              builder: (context) {
                result = context.watchNexusStore<User, String>();
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isNotNull);
      await expectLater(result, emits(testUsers));
      verify(() => mockStore.watchAll(query: null)).called(1);
    });

    testWidgets('watchNexusStore() passes query parameter', (tester) async {
      final testUsers = [const User(id: '1', name: 'Alice')];
      when(() => mockStore.watchAll(query: any(named: 'query')))
          .thenAnswer((_) => Stream.value(testUsers));

      await tester.pumpWidget(
        MaterialApp(
          home: NexusStoreProvider<User, String>(
            store: mockStore,
            child: Builder(
              builder: (context) {
                context.watchNexusStore<User, String>(
                  query: const Query<User>().limitTo(10),
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      verify(() => mockStore.watchAll(query: any(named: 'query'))).called(1);
    });

    testWidgets('watchNexusStoreItem() returns stream from store.watch',
        (tester) async {
      const testUser = User(id: '123', name: 'Alice');
      when(() => mockStore.watch('123'))
          .thenAnswer((_) => Stream.value(testUser));

      Stream<User?>? result;

      await tester.pumpWidget(
        MaterialApp(
          home: NexusStoreProvider<User, String>(
            store: mockStore,
            child: Builder(
              builder: (context) {
                result = context.watchNexusStoreItem<User, String>('123');
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isNotNull);
      await expectLater(result, emits(testUser));
      verify(() => mockStore.watch('123')).called(1);
    });

    testWidgets('watchNexusStoreItem() returns null for non-existent item',
        (tester) async {
      when(() => mockStore.watch('non-existent'))
          .thenAnswer((_) => Stream.value(null));

      Stream<User?>? result;

      await tester.pumpWidget(
        MaterialApp(
          home: NexusStoreProvider<User, String>(
            store: mockStore,
            child: Builder(
              builder: (context) {
                result =
                    context.watchNexusStoreItem<User, String>('non-existent');
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isNotNull);
      await expectLater(result, emits(null));
    });
  });
}
