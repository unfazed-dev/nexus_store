// ignore_for_file: unreachable_from_main

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_flutter/nexus_store_flutter.dart';

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
  });
}
