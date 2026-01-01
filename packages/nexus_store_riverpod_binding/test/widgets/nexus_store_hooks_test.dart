import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_riverpod_binding/nexus_store_riverpod_binding.dart';

import '../helpers/mocks.dart';
import '../helpers/test_fixtures.dart';

void main() {
  setUpAll(registerFallbackValues);

  group('NexusStoreHookWidget', () {
    testWidgets('can be extended and used with hooks', (tester) async {
      final users = TestFixtures.sampleUsers;
      final store = MockStoreHelper.withUsers(users);

      final storeProvider = Provider<NexusStore<TestUser, String>>(
        (ref) => store,
      );
      final usersProvider = StreamProvider<List<TestUser>>((ref) {
        return ref.watch(storeProvider).watchAll();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: _TestHookWidget(provider: usersProvider),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('User 0'), findsOneWidget);
      expect(find.text('User 1'), findsOneWidget);
      expect(find.text('User 2'), findsOneWidget);
    });
  });

  group('NexusStoreWidgetRefHooksX', () {
    group('watchStoreList', () {
      testWidgets('returns AsyncValue from provider', (tester) async {
        final users = TestFixtures.sampleUsers;
        final controller = StreamController<List<TestUser>>.broadcast();
        final provider = StreamProvider<List<TestUser>>(
          (ref) => controller.stream,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: _WatchStoreListWidget(provider: provider),
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
      testWidgets('returns AsyncValue from family provider', (tester) async {
        final user = TestFixtures.sampleUser;
        final controller = StreamController<TestUser?>.broadcast();
        final provider = StreamProvider.family<TestUser?, String>(
          (ref, id) => controller.stream,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: _WatchStoreItemWidget(
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
    });

    group('readStore', () {
      testWidgets('returns store for direct operations', (tester) async {
        final store = MockNexusStore<TestUser, String>();
        when(() => store.save(any())).thenAnswer((_) async => TestFixtures.sampleUser);

        final storeProvider = Provider<NexusStore<TestUser, String>>(
          (ref) => store,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: _ReadStoreWidget(storeProvider: storeProvider),
            ),
          ),
        );

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        verify(() => store.save(any())).called(1);
      });
    });

    group('refreshStoreList', () {
      testWidgets('invalidates and returns new data', (tester) async {
        var callCount = 0;
        final provider = StreamProvider<List<TestUser>>((ref) async* {
          callCount++;
          yield TestFixtures.createUsers(callCount);
        });

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: _RefreshStoreListWidget(provider: provider),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('count: 1'), findsOneWidget);

        await tester.tap(find.text('Refresh'));
        await tester.pumpAndSettle();

        expect(find.text('count: 2'), findsOneWidget);
      });
    });

    group('refreshStoreItem', () {
      testWidgets('invalidates and returns new item', (tester) async {
        var callCount = 0;
        final provider = StreamProvider.family<TestUser?, String>(
          (ref, id) async* {
            callCount++;
            yield TestFixtures.createUser(name: 'User $callCount');
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: _RefreshStoreItemWidget(provider: provider, id: 'user-1'),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('name: User 1'), findsOneWidget);

        await tester.tap(find.text('Refresh'));
        await tester.pumpAndSettle();

        expect(find.text('name: User 2'), findsOneWidget);
      });
    });
  });

  group('useStoreCallback', () {
    testWidgets('memoizes callback based on store', (tester) async {
      final store = MockNexusStore<TestUser, String>();
      when(() => store.save(any())).thenAnswer((_) async => TestFixtures.sampleUser);

      final storeProvider = Provider<NexusStore<TestUser, String>>(
        (ref) => store,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: _UseStoreCallbackWidget(storeProvider: storeProvider),
          ),
        ),
      );

      await tester.tap(find.text('Save User'));
      await tester.pumpAndSettle();

      verify(() => store.save(any())).called(1);
    });
  });

  group('useStoreOperation', () {
    testWidgets('tracks loading state during async operation', (tester) async {
      final completer = Completer<TestUser>();
      final store = MockNexusStore<TestUser, String>();
      when(() => store.save(any())).thenAnswer((_) => completer.future);

      final storeProvider = Provider<NexusStore<TestUser, String>>(
        (ref) => store,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: _UseStoreOperationWidget(storeProvider: storeProvider),
          ),
        ),
      );

      expect(find.text('isLoading: false'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('isLoading: true'), findsOneWidget);

      completer.complete(TestFixtures.sampleUser);
      await tester.pumpAndSettle();

      expect(find.text('isLoading: false'), findsOneWidget);
    });
  });

  group('useStoreDebouncedSearch', () {
    testWidgets('debounces search term updates', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: _UseStoreDebouncedSearchWidget(),
            ),
          ),
        ),
      );

      expect(find.text('search: '), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Still empty because of debounce
      expect(find.text('search: '), findsOneWidget);

      // Wait for debounce delay
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('search: test'), findsOneWidget);
    });

    testWidgets('uses initial value', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: _UseStoreDebouncedSearchWidget(initialValue: 'initial'),
            ),
          ),
        ),
      );

      expect(find.text('search: initial'), findsOneWidget);

      // Pump through the debounce timer to avoid pending timer error
      await tester.pump(const Duration(milliseconds: 350));
    });
  });

  group('useStoreDataWithPrevious', () {
    testWidgets('retains previous data while loading', (tester) async {
      final controller = StreamController<List<TestUser>>.broadcast();
      final provider = StreamProvider<List<TestUser>>(
        (ref) => controller.stream,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: _UseStoreDataWithPreviousWidget(provider: provider),
          ),
        ),
      );

      // Initially loading with no previous data
      expect(find.text('data: null, loading: true, error: null'), findsOneWidget);

      controller.add(TestFixtures.sampleUsers);
      await tester.pumpAndSettle();

      expect(find.text('data: 3, loading: false, error: null'), findsOneWidget);

      await controller.close();
    });

    testWidgets('shows error while retaining previous data', (tester) async {
      final controller = StreamController<List<TestUser>>.broadcast();
      final provider = StreamProvider<List<TestUser>>(
        (ref) => controller.stream,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: _UseStoreDataWithPreviousWidget(provider: provider),
          ),
        ),
      );

      controller.add(TestFixtures.sampleUsers);
      await tester.pumpAndSettle();

      expect(find.text('data: 3, loading: false, error: null'), findsOneWidget);

      controller.addError(Exception('Test error'));
      await tester.pumpAndSettle();

      // Previous data is retained, error is shown
      expect(find.textContaining('data: 3'), findsOneWidget);
      expect(find.textContaining('error: Exception'), findsOneWidget);

      await controller.close();
    });
  });
}

// Test widget implementations

class _TestHookWidget extends NexusStoreHookWidget {
  const _TestHookWidget({required this.provider});

  final StreamProvider<List<TestUser>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(provider);
    return users.when(
      data: (data) => Column(
        children: data.map((u) => Text(u.name)).toList(),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => Text('Error: $e'),
    );
  }
}

class _WatchStoreListWidget extends ConsumerWidget {
  const _WatchStoreListWidget({required this.provider});

  final StreamProvider<List<TestUser>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watchStoreList(provider);
    return users.when(
      data: (data) => Text('count: ${data.length}'),
      loading: () => const Text('loading'),
      error: (e, st) => Text('error: $e'),
    );
  }
}

class _WatchStoreItemWidget extends ConsumerWidget {
  const _WatchStoreItemWidget({
    required this.provider,
    required this.id,
  });

  final StreamProviderFamily<TestUser?, String> provider;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use explicit extension syntax to avoid conflict with NexusStoreWidgetRefX
    final user = NexusStoreWidgetRefHooksX(ref).watchStoreItem(provider, id);
    return user.when(
      data: (data) => Text('name: ${data?.name ?? 'null'}'),
      loading: () => const Text('loading'),
      error: (e, st) => Text('error: $e'),
    );
  }
}

class _ReadStoreWidget extends ConsumerWidget {
  const _ReadStoreWidget({required this.storeProvider});

  final Provider<NexusStore<TestUser, String>> storeProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        final store = ref.readStore(storeProvider);
        store.save(TestFixtures.sampleUser);
      },
      child: const Text('Save'),
    );
  }
}

class _RefreshStoreListWidget extends ConsumerWidget {
  const _RefreshStoreListWidget({required this.provider});

  final StreamProvider<List<TestUser>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(provider);
    return Column(
      children: [
        users.when(
          data: (data) => Text('count: ${data.length}'),
          loading: () => const Text('loading'),
          error: (e, st) => Text('error: $e'),
        ),
        ElevatedButton(
          onPressed: () => ref.refreshStoreList(provider),
          child: const Text('Refresh'),
        ),
      ],
    );
  }
}

class _RefreshStoreItemWidget extends ConsumerWidget {
  const _RefreshStoreItemWidget({
    required this.provider,
    required this.id,
  });

  final StreamProviderFamily<TestUser?, String> provider;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(provider(id));
    return Column(
      children: [
        user.when(
          data: (data) => Text('name: ${data?.name ?? 'null'}'),
          loading: () => const Text('loading'),
          error: (e, st) => Text('error: $e'),
        ),
        ElevatedButton(
          onPressed: () => ref.refreshStoreItem(provider, id),
          child: const Text('Refresh'),
        ),
      ],
    );
  }
}

class _UseStoreCallbackWidget extends HookConsumerWidget {
  const _UseStoreCallbackWidget({required this.storeProvider});

  final Provider<NexusStore<TestUser, String>> storeProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    final saveUser = useStoreCallback<TestUser, String, TestUser, Future<TestUser>>(
      store,
      (store, user) => store.save(user),
    );

    return ElevatedButton(
      onPressed: () => saveUser(TestFixtures.sampleUser),
      child: const Text('Save User'),
    );
  }
}

class _UseStoreOperationWidget extends HookConsumerWidget {
  const _UseStoreOperationWidget({required this.storeProvider});

  final Provider<NexusStore<TestUser, String>> storeProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    final (isLoading, execute) = useStoreOperation();

    return Column(
      children: [
        Text('isLoading: $isLoading'),
        ElevatedButton(
          onPressed: isLoading
              ? null
              : () => execute(() => store.save(TestFixtures.sampleUser)),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _UseStoreDebouncedSearchWidget extends HookConsumerWidget {
  const _UseStoreDebouncedSearchWidget({this.initialValue = ''});

  final String initialValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (searchTerm, setSearchTerm) = useStoreDebouncedSearch(
      initialValue: initialValue,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          child: TextField(onChanged: setSearchTerm),
        ),
        Text('search: $searchTerm'),
      ],
    );
  }
}

class _UseStoreDataWithPreviousWidget extends HookConsumerWidget {
  const _UseStoreDataWithPreviousWidget({required this.provider});

  final StreamProvider<List<TestUser>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(provider);
    final (data, isLoading, error) = useStoreDataWithPrevious(asyncValue);

    return Text(
      'data: ${data?.length}, loading: $isLoading, error: $error',
    );
  }
}
