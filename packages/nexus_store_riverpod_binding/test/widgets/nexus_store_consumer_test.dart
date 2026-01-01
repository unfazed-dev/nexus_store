import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store_riverpod_binding/nexus_store_riverpod_binding.dart';

import '../helpers/mocks.dart';
import '../helpers/test_fixtures.dart';

void main() {
  setUpAll(registerFallbackValues);

  group('NexusStoreListConsumer', () {
    late StreamController<List<TestUser>> controller;
    late StreamProvider<List<TestUser>> provider;

    setUp(() {
      controller = StreamController<List<TestUser>>.broadcast();
      provider = StreamProvider<List<TestUser>>((ref) => controller.stream);
    });

    tearDown(() {
      controller.close();
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NexusStoreListConsumer<TestUser>(
              provider: provider,
              builder: (context, data) => Text('Count: ${data.length}'),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows data when stream emits', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NexusStoreListConsumer<TestUser>(
              provider: provider,
              builder: (context, data) => Text('Count: ${data.length}'),
            ),
          ),
        ),
      );

      controller.add(TestFixtures.sampleUsers);
      await tester.pumpAndSettle();

      expect(find.text('Count: 3'), findsOneWidget);
    });

    testWidgets('shows custom loading widget when provided', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NexusStoreListConsumer<TestUser>(
              provider: provider,
              builder: (context, data) => Text('Count: ${data.length}'),
              loading: (context) => const Text('Loading...'),
            ),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows error widget when stream errors', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NexusStoreListConsumer<TestUser>(
              provider: provider,
              builder: (context, data) => Text('Count: ${data.length}'),
            ),
          ),
        ),
      );

      controller.addError(Exception('Test error'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorWidget), findsOneWidget);
    });

    testWidgets('shows custom error widget when provided', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NexusStoreListConsumer<TestUser>(
              provider: provider,
              builder: (context, data) => Text('Count: ${data.length}'),
              error: (context, error, stackTrace) =>
                  const Text('Custom error'),
            ),
          ),
        ),
      );

      controller.addError(Exception('Test error'));
      await tester.pumpAndSettle();

      expect(find.text('Custom error'), findsOneWidget);
    });

    testWidgets('respects skipLoadingOnReload', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NexusStoreListConsumer<TestUser>(
              provider: provider,
              builder: (context, data) => Text('Count: ${data.length}'),
              skipLoadingOnReload: true,
            ),
          ),
        ),
      );

      // Initially shows loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.add(TestFixtures.sampleUsers);
      await tester.pumpAndSettle();

      expect(find.text('Count: 3'), findsOneWidget);
    });

    testWidgets('respects skipLoadingOnRefresh', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NexusStoreListConsumer<TestUser>(
              provider: provider,
              builder: (context, data) => Text('Count: ${data.length}'),
              skipLoadingOnRefresh: true,
            ),
          ),
        ),
      );

      controller.add(TestFixtures.sampleUsers);
      await tester.pumpAndSettle();

      expect(find.text('Count: 3'), findsOneWidget);
    });

    testWidgets('respects skipError', (tester) async {
      // First emit data, then error
      final dataProvider = StreamProvider<List<TestUser>>((ref) async* {
        yield TestFixtures.sampleUsers;
        throw Exception('Error after data');
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NexusStoreListConsumer<TestUser>(
              provider: dataProvider,
              builder: (context, data) => Text('Count: ${data.length}'),
              skipError: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should still show data, not error (due to skipError)
      expect(find.text('Count: 3'), findsOneWidget);
    });
  });

  group('NexusStoreItemConsumer', () {
    late StreamController<TestUser?> controller;
    late StreamProviderFamily<TestUser?, String> provider;

    setUp(() {
      controller = StreamController<TestUser?>.broadcast();
      provider = StreamProvider.family<TestUser?, String>(
        (ref, id) => controller.stream,
      );
    });

    tearDown(() {
      controller.close();
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NexusStoreItemConsumer<TestUser, String>(
              provider: provider,
              id: 'user-1',
              builder: (context, item) => Text(item?.name ?? 'null'),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows item when stream emits', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NexusStoreItemConsumer<TestUser, String>(
              provider: provider,
              id: 'user-1',
              builder: (context, item) => Text(item?.name ?? 'null'),
            ),
          ),
        ),
      );

      controller.add(TestFixtures.sampleUser);
      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('shows custom loading widget when provided', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NexusStoreItemConsumer<TestUser, String>(
              provider: provider,
              id: 'user-1',
              builder: (context, item) => Text(item?.name ?? 'null'),
              loading: (context) => const Text('Loading item...'),
            ),
          ),
        ),
      );

      expect(find.text('Loading item...'), findsOneWidget);
    });

    testWidgets('shows error widget when stream errors', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NexusStoreItemConsumer<TestUser, String>(
              provider: provider,
              id: 'user-1',
              builder: (context, item) => Text(item?.name ?? 'null'),
            ),
          ),
        ),
      );

      controller.addError(Exception('Test error'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorWidget), findsOneWidget);
    });

    testWidgets('shows custom error widget when provided', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NexusStoreItemConsumer<TestUser, String>(
              provider: provider,
              id: 'user-1',
              builder: (context, item) => Text(item?.name ?? 'null'),
              error: (context, error, stackTrace) =>
                  const Text('Item error'),
            ),
          ),
        ),
      );

      controller.addError(Exception('Test error'));
      await tester.pumpAndSettle();

      expect(find.text('Item error'), findsOneWidget);
    });

    testWidgets('shows notFound widget when item is null', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NexusStoreItemConsumer<TestUser, String>(
              provider: provider,
              id: 'user-1',
              builder: (context, item) => Text(item?.name ?? 'null'),
              notFound: (context) => const Text('User not found'),
            ),
          ),
        ),
      );

      controller.add(null);
      await tester.pumpAndSettle();

      expect(find.text('User not found'), findsOneWidget);
    });

    testWidgets('calls builder with null when notFound is not provided',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NexusStoreItemConsumer<TestUser, String>(
              provider: provider,
              id: 'user-1',
              builder: (context, item) => Text(item?.name ?? 'null'),
            ),
          ),
        ),
      );

      controller.add(null);
      await tester.pumpAndSettle();

      expect(find.text('null'), findsOneWidget);
    });
  });

  group('NexusStoreRefreshableConsumer', () {
    late StreamController<List<TestUser>> controller;
    late StreamProvider<List<TestUser>> provider;

    setUp(() {
      controller = StreamController<List<TestUser>>.broadcast();
      provider = StreamProvider<List<TestUser>>((ref) => controller.stream);
    });

    tearDown(() {
      controller.close();
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NexusStoreRefreshableConsumer<TestUser>(
              provider: provider,
              onRefresh: () async {},
              builder: (context, data) => ListView(
                children: data.map((u) => Text(u.name)).toList(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows data wrapped in RefreshIndicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NexusStoreRefreshableConsumer<TestUser>(
                provider: provider,
                onRefresh: () async {},
                builder: (context, data) => ListView(
                  children: data.map((u) => Text(u.name)).toList(),
                ),
              ),
            ),
          ),
        ),
      );

      controller.add(TestFixtures.sampleUsers);
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.text('User 0'), findsOneWidget);
    });

    testWidgets('calls onRefresh when pulled', (tester) async {
      var refreshCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NexusStoreRefreshableConsumer<TestUser>(
                provider: provider,
                onRefresh: () async {
                  refreshCalled = true;
                },
                builder: (context, data) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: data.map((u) => ListTile(title: Text(u.name))).toList(),
                ),
              ),
            ),
          ),
        ),
      );

      controller.add(TestFixtures.sampleUsers);
      await tester.pumpAndSettle();

      // Simulate pull-to-refresh
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(refreshCalled, isTrue);
    });

    testWidgets('shows custom loading widget when provided', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NexusStoreRefreshableConsumer<TestUser>(
              provider: provider,
              onRefresh: () async {},
              builder: (context, data) => ListView(
                children: data.map((u) => Text(u.name)).toList(),
              ),
              loading: (context) => const Text('Custom loading...'),
            ),
          ),
        ),
      );

      expect(find.text('Custom loading...'), findsOneWidget);
    });

    testWidgets('shows error widget when stream errors', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NexusStoreRefreshableConsumer<TestUser>(
              provider: provider,
              onRefresh: () async {},
              builder: (context, data) => ListView(
                children: data.map((u) => Text(u.name)).toList(),
              ),
            ),
          ),
        ),
      );

      controller.addError(Exception('Test error'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorWidget), findsOneWidget);
    });

    testWidgets('shows custom error widget when provided', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NexusStoreRefreshableConsumer<TestUser>(
              provider: provider,
              onRefresh: () async {},
              builder: (context, data) => ListView(
                children: data.map((u) => Text(u.name)).toList(),
              ),
              error: (context, error, stackTrace) =>
                  const Text('Refresh error'),
            ),
          ),
        ),
      );

      controller.addError(Exception('Test error'));
      await tester.pumpAndSettle();

      expect(find.text('Refresh error'), findsOneWidget);
    });
  });
}
