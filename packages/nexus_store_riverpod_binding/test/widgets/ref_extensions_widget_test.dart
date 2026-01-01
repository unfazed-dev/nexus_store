import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store_riverpod_binding/nexus_store_riverpod_binding.dart';

import '../helpers/mocks.dart';
import '../helpers/test_fixtures.dart';

void main() {
  setUpAll(registerFallbackValues);

  group('NexusStoreWidgetRefX', () {
    group('watchStoreAll', () {
      testWidgets('returns AsyncValue from StreamProvider', (tester) async {
        final users = TestFixtures.sampleUsers;
        final controller = StreamController<List<TestUser>>.broadcast();
        final provider = StreamProvider<List<TestUser>>(
          (ref) => controller.stream,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: _WatchStoreAllTestWidget(provider: provider),
            ),
          ),
        );

        expect(find.text('loading'), findsOneWidget);

        controller.add(users);
        await tester.pumpAndSettle();

        expect(find.text('count: 3'), findsOneWidget);

        await controller.close();
      });
    });

    group('watchStoreItem', () {
      testWidgets('returns AsyncValue from provider', (tester) async {
        final user = TestFixtures.sampleUser;
        final controller = StreamController<TestUser?>.broadcast();
        final provider = StreamProvider.family<TestUser?, String>(
          (ref, id) => controller.stream,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: _WatchStoreItemTestWidget(
                provider: provider,
                id: 'user-1',
              ),
            ),
          ),
        );

        expect(find.text('loading'), findsOneWidget);

        controller.add(user);
        await tester.pumpAndSettle();

        expect(find.text('name: John Doe'), findsOneWidget);

        await controller.close();
      });

      testWidgets('handles null item', (tester) async {
        final controller = StreamController<TestUser?>.broadcast();
        final provider = StreamProvider.family<TestUser?, String>(
          (ref, id) => controller.stream,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: _WatchStoreItemTestWidget(
                provider: provider,
                id: 'user-1',
              ),
            ),
          ),
        );

        controller.add(null);
        await tester.pumpAndSettle();

        expect(find.text('name: null'), findsOneWidget);

        await controller.close();
      });
    });
  });
}

class _WatchStoreAllTestWidget extends ConsumerWidget {
  const _WatchStoreAllTestWidget({required this.provider});

  final StreamProvider<List<TestUser>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use explicit extension to avoid conflicts
    final users = NexusStoreWidgetRefX(ref).watchStoreAll(provider);
    return users.when(
      data: (data) => Text('count: ${data.length}'),
      loading: () => const Text('loading'),
      error: (e, st) => Text('error: $e'),
    );
  }
}

class _WatchStoreItemTestWidget extends ConsumerWidget {
  const _WatchStoreItemTestWidget({
    required this.provider,
    required this.id,
  });

  final StreamProviderFamily<TestUser?, String> provider;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use explicit extension to avoid conflicts
    final user = NexusStoreWidgetRefX(ref).watchStoreItem(provider(id));
    return user.when(
      data: (data) => Text('name: ${data?.name ?? 'null'}'),
      loading: () => const Text('loading'),
      error: (e, st) => Text('error: $e'),
    );
  }
}
