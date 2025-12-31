import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_bloc_binding/nexus_store_bloc_binding.dart';
import 'package:test/test.dart';

import '../fixtures/mock_store.dart';
import '../fixtures/test_entities.dart';

void main() {
  late MockNexusStore<TestUser, String> mockStore;
  late StreamController<List<TestUser>> watchAllController;

  setUpAll(registerFallbackValues);

  setUp(() {
    mockStore = MockNexusStore<TestUser, String>();
    watchAllController = StreamController<List<TestUser>>.broadcast();

    // Default stubs
    when(() => mockStore.watchAll(query: any(named: 'query')))
        .thenAnswer((_) => watchAllController.stream);
    when(() =>
        mockStore.save(any(),
            policy: any(named: 'policy'), tags: any(named: 'tags'))).thenAnswer(
        (invocation) async => invocation.positionalArguments[0] as TestUser);
    when(() => mockStore.saveAll(any(),
            policy: any(named: 'policy'), tags: any(named: 'tags')))
        .thenAnswer((invocation) async =>
            invocation.positionalArguments[0] as List<TestUser>);
    when(() => mockStore.delete(any(), policy: any(named: 'policy')))
        .thenAnswer((_) async => true);
    when(() => mockStore.deleteAll(any(), policy: any(named: 'policy')))
        .thenAnswer((_) async => 1);
  });

  tearDown(() async {
    await watchAllController.close();
  });

  group('NexusStoreBloc', () {
    group('constructor', () {
      test('should start with initial state', () {
        final bloc = NexusStoreBloc<TestUser, String>(mockStore);
        expect(bloc.state, isA<NexusStoreInitial<TestUser>>());
        bloc.close();
      });

      test('should expose the underlying store', () {
        final bloc = NexusStoreBloc<TestUser, String>(mockStore);
        expect(bloc.store, same(mockStore));
        bloc.close();
      });
    });

    group('LoadAll event', () {
      blocTest<NexusStoreBloc<TestUser, String>, NexusStoreState<TestUser>>(
        'emits loading then loaded when watchAll emits data',
        build: () => NexusStoreBloc<TestUser, String>(mockStore),
        act: (bloc) async {
          bloc.add(const LoadAll<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
          watchAllController.add(TestFixtures.sampleUsers);
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusStoreLoading<TestUser>>(),
          isA<NexusStoreLoaded<TestUser>>()
              .having((s) => s.data.length, 'data.length', 3),
        ],
      );

      blocTest<NexusStoreBloc<TestUser, String>, NexusStoreState<TestUser>>(
        'emits loading then error when watchAll emits error',
        build: () => NexusStoreBloc<TestUser, String>(mockStore),
        act: (bloc) async {
          bloc.add(const LoadAll<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
          watchAllController.addError(Exception('Network error'));
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusStoreLoading<TestUser>>(),
          isA<NexusStoreError<TestUser>>().having(
              (s) => s.error.toString(), 'error', contains('Network error')),
        ],
      );

      blocTest<NexusStoreBloc<TestUser, String>, NexusStoreState<TestUser>>(
        'preserves previous data during loading on reload',
        build: () => NexusStoreBloc<TestUser, String>(mockStore),
        seed: () => NexusStoreLoaded<TestUser>(data: TestFixtures.sampleUsers),
        act: (bloc) async {
          bloc.add(const LoadAll<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusStoreLoading<TestUser>>()
              .having((s) => s.previousData?.length, 'previousData.length', 3),
        ],
      );

      blocTest<NexusStoreBloc<TestUser, String>, NexusStoreState<TestUser>>(
        'passes query to watchAll',
        build: () => NexusStoreBloc<TestUser, String>(mockStore),
        act: (bloc) async {
          const query = Query<TestUser>();
          bloc.add(const LoadAll<TestUser, String>(query: query));
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          verify(() => mockStore.watchAll(query: any(named: 'query')))
              .called(1);
        },
      );
    });

    group('Save event', () {
      blocTest<NexusStoreBloc<TestUser, String>, NexusStoreState<TestUser>>(
        'calls store.save with the item',
        build: () => NexusStoreBloc<TestUser, String>(mockStore),
        act: (bloc) async {
          bloc.add(Save<TestUser, String>(TestFixtures.sampleUser));
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          verify(() => mockStore.save(
                TestFixtures.sampleUser,
                policy: any(named: 'policy'),
                tags: any(named: 'tags'),
              )).called(1);
        },
      );

      blocTest<NexusStoreBloc<TestUser, String>, NexusStoreState<TestUser>>(
        'calls store.save with policy and tags',
        build: () => NexusStoreBloc<TestUser, String>(mockStore),
        act: (bloc) async {
          bloc.add(Save<TestUser, String>(
            TestFixtures.sampleUser,
            policy: WritePolicy.cacheOnly,
            tags: {'tag1'},
          ));
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          verify(() => mockStore.save(
                TestFixtures.sampleUser,
                policy: WritePolicy.cacheOnly,
                tags: {'tag1'},
              )).called(1);
        },
      );
    });

    group('SaveAll event', () {
      blocTest<NexusStoreBloc<TestUser, String>, NexusStoreState<TestUser>>(
        'calls store.saveAll with the items',
        build: () => NexusStoreBloc<TestUser, String>(mockStore),
        act: (bloc) async {
          bloc.add(SaveAll<TestUser, String>(TestFixtures.sampleUsers));
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          verify(() => mockStore.saveAll(
                TestFixtures.sampleUsers,
                policy: any(named: 'policy'),
                tags: any(named: 'tags'),
              )).called(1);
        },
      );
    });

    group('Delete event', () {
      blocTest<NexusStoreBloc<TestUser, String>, NexusStoreState<TestUser>>(
        'calls store.delete with the id',
        build: () => NexusStoreBloc<TestUser, String>(mockStore),
        act: (bloc) async {
          bloc.add(const Delete<TestUser, String>('user-1'));
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          verify(() => mockStore.delete('user-1', policy: any(named: 'policy')))
              .called(1);
        },
      );

      blocTest<NexusStoreBloc<TestUser, String>, NexusStoreState<TestUser>>(
        'calls store.delete with policy',
        build: () => NexusStoreBloc<TestUser, String>(mockStore),
        act: (bloc) async {
          bloc.add(const Delete<TestUser, String>(
            'user-1',
            policy: WritePolicy.cacheOnly,
          ));
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          verify(() =>
                  mockStore.delete('user-1', policy: WritePolicy.cacheOnly))
              .called(1);
        },
      );
    });

    group('DeleteAll event', () {
      blocTest<NexusStoreBloc<TestUser, String>, NexusStoreState<TestUser>>(
        'calls store.deleteAll with the ids',
        build: () => NexusStoreBloc<TestUser, String>(mockStore),
        act: (bloc) async {
          bloc.add(const DeleteAll<TestUser, String>(['user-1', 'user-2']));
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          verify(() => mockStore.deleteAll(['user-1', 'user-2'],
              policy: any(named: 'policy'))).called(1);
        },
      );
    });

    group('Refresh event', () {
      blocTest<NexusStoreBloc<TestUser, String>, NexusStoreState<TestUser>>(
        'cancels current subscription and loads fresh data',
        build: () => NexusStoreBloc<TestUser, String>(mockStore),
        act: (bloc) async {
          // First load
          bloc.add(const LoadAll<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
          watchAllController.add([TestFixtures.sampleUser]);
          await Future<void>.delayed(Duration.zero);

          // Refresh
          bloc.add(const Refresh<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
          watchAllController.add(TestFixtures.sampleUsers);
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusStoreLoading<TestUser>>(),
          isA<NexusStoreLoaded<TestUser>>()
              .having((s) => s.data.length, 'data.length', 1),
          isA<NexusStoreLoading<TestUser>>()
              .having((s) => s.previousData?.length, 'previousData.length', 1),
          isA<NexusStoreLoaded<TestUser>>()
              .having((s) => s.data.length, 'data.length', 3),
        ],
      );
    });

    group('close', () {
      test('cancels stream subscription on close', () async {
        final bloc = NexusStoreBloc<TestUser, String>(mockStore);
        bloc.add(const LoadAll<TestUser, String>());

        await Future<void>.delayed(Duration.zero);

        // Verify subscription is active
        expect(watchAllController.hasListener, isTrue);

        await bloc.close();

        // Give time for cleanup
        await Future<void>.delayed(Duration.zero);

        // Subscription should be cancelled
        expect(watchAllController.hasListener, isFalse);
      });
    });

    group('error handling', () {
      blocTest<NexusStoreBloc<TestUser, String>, NexusStoreState<TestUser>>(
        'emits error state on save failure',
        build: () {
          when(() => mockStore.save(any(),
              policy: any(named: 'policy'),
              tags: any(named: 'tags'))).thenThrow(Exception('Save failed'));
          return NexusStoreBloc<TestUser, String>(mockStore);
        },
        seed: () => NexusStoreLoaded<TestUser>(data: TestFixtures.sampleUsers),
        act: (bloc) async {
          bloc.add(Save<TestUser, String>(TestFixtures.sampleUser));
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusStoreError<TestUser>>()
              .having((s) => s.previousData?.length, 'previousData.length', 3),
        ],
      );

      blocTest<NexusStoreBloc<TestUser, String>, NexusStoreState<TestUser>>(
        'emits error state on delete failure',
        build: () {
          when(() => mockStore.delete(any(), policy: any(named: 'policy')))
              .thenThrow(Exception('Delete failed'));
          return NexusStoreBloc<TestUser, String>(mockStore);
        },
        seed: () => NexusStoreLoaded<TestUser>(data: TestFixtures.sampleUsers),
        act: (bloc) async {
          bloc.add(const Delete<TestUser, String>('user-1'));
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusStoreError<TestUser>>()
              .having((s) => s.previousData?.length, 'previousData.length', 3),
        ],
      );

      blocTest<NexusStoreBloc<TestUser, String>, NexusStoreState<TestUser>>(
        'preserves previous data in error state from stream error',
        build: () => NexusStoreBloc<TestUser, String>(mockStore),
        act: (bloc) async {
          bloc.add(const LoadAll<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
          watchAllController.add(TestFixtures.sampleUsers);
          await Future<void>.delayed(Duration.zero);
          watchAllController.addError(Exception('Stream error'));
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusStoreLoading<TestUser>>(),
          isA<NexusStoreLoaded<TestUser>>(),
          isA<NexusStoreError<TestUser>>()
              .having((s) => s.previousData?.length, 'previousData.length', 3),
        ],
      );
    });

    group('stream updates', () {
      blocTest<NexusStoreBloc<TestUser, String>, NexusStoreState<TestUser>>(
        'updates state on subsequent stream emissions',
        build: () => NexusStoreBloc<TestUser, String>(mockStore),
        act: (bloc) async {
          bloc.add(const LoadAll<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
          watchAllController.add([TestFixtures.sampleUser]);
          await Future<void>.delayed(Duration.zero);
          watchAllController.add(TestFixtures.sampleUsers);
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusStoreLoading<TestUser>>(),
          isA<NexusStoreLoaded<TestUser>>()
              .having((s) => s.data.length, 'data.length', 1),
          isA<NexusStoreLoaded<TestUser>>()
              .having((s) => s.data.length, 'data.length', 3),
        ],
      );
    });
  });
}
