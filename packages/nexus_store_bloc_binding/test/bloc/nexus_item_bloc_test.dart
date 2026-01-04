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
  late StreamController<TestUser?> watchController;

  setUpAll(registerFallbackValues);

  setUp(() {
    mockStore = MockNexusStore<TestUser, String>();
    watchController = StreamController<TestUser?>.broadcast();

    // Default stubs
    when(() => mockStore.watch(any()))
        .thenAnswer((_) => watchController.stream);
    when(() =>
        mockStore.save(any(),
            policy: any(named: 'policy'), tags: any(named: 'tags'))).thenAnswer(
        (invocation) async => invocation.positionalArguments[0] as TestUser);
    when(() => mockStore.delete(any(), policy: any(named: 'policy')))
        .thenAnswer((_) async => true);
  });

  tearDown(() async {
    await watchController.close();
  });

  group('NexusItemBloc', () {
    group('constructor', () {
      test('should start with initial state', () {
        final bloc = NexusItemBloc<TestUser, String>(mockStore, 'user-1');
        expect(bloc.state, isA<NexusItemInitial<TestUser>>());
        bloc.close();
      });

      test('should expose the id', () {
        final bloc = NexusItemBloc<TestUser, String>(mockStore, 'user-1');
        expect(bloc.id, equals('user-1'));
        bloc.close();
      });

      test('should expose the underlying store', () {
        final bloc = NexusItemBloc<TestUser, String>(mockStore, 'user-1');
        expect(bloc.store, same(mockStore));
        bloc.close();
      });
    });

    group('LoadItem event', () {
      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'emits loading then loaded when watch emits data',
        build: () => NexusItemBloc<TestUser, String>(mockStore, 'user-1'),
        act: (bloc) async {
          bloc.add(const LoadItem<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
          watchController.add(TestFixtures.sampleUser);
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusItemLoading<TestUser>>(),
          isA<NexusItemLoaded<TestUser>>()
              .having((s) => s.data.id, 'data.id', 'user-1'),
        ],
      );

      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'emits loading then notFound when watch emits null',
        build: () => NexusItemBloc<TestUser, String>(mockStore, 'user-1'),
        act: (bloc) async {
          bloc.add(const LoadItem<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
          watchController.add(null);
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusItemLoading<TestUser>>(),
          isA<NexusItemNotFound<TestUser>>(),
        ],
      );

      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'emits loading then error when watch emits error',
        build: () => NexusItemBloc<TestUser, String>(mockStore, 'user-1'),
        act: (bloc) async {
          bloc.add(const LoadItem<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
          watchController.addError(Exception('Network error'));
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusItemLoading<TestUser>>(),
          isA<NexusItemError<TestUser>>().having(
              (s) => s.error.toString(), 'error', contains('Network error')),
        ],
      );

      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'preserves previous data during loading on reload',
        build: () => NexusItemBloc<TestUser, String>(mockStore, 'user-1'),
        seed: () => NexusItemLoaded<TestUser>(data: TestFixtures.sampleUser),
        act: (bloc) async {
          bloc.add(const LoadItem<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusItemLoading<TestUser>>()
              .having((s) => s.previousData?.id, 'previousData.id', 'user-1'),
        ],
      );

      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'calls watch with the correct id',
        build: () => NexusItemBloc<TestUser, String>(mockStore, 'user-42'),
        act: (bloc) async {
          bloc.add(const LoadItem<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          verify(() => mockStore.watch('user-42')).called(1);
        },
      );
    });

    group('SaveItem event', () {
      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'calls store.save with the item',
        build: () => NexusItemBloc<TestUser, String>(mockStore, 'user-1'),
        act: (bloc) async {
          bloc.add(SaveItem<TestUser, String>(TestFixtures.sampleUser));
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

      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'calls store.save with policy and tags',
        build: () => NexusItemBloc<TestUser, String>(mockStore, 'user-1'),
        act: (bloc) async {
          bloc.add(SaveItem<TestUser, String>(
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

    group('DeleteItem event', () {
      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'calls store.delete with the bloc id',
        build: () => NexusItemBloc<TestUser, String>(mockStore, 'user-1'),
        act: (bloc) async {
          bloc.add(const DeleteItem<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          verify(() => mockStore.delete('user-1', policy: any(named: 'policy')))
              .called(1);
        },
      );

      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'calls store.delete with policy',
        build: () => NexusItemBloc<TestUser, String>(mockStore, 'user-1'),
        act: (bloc) async {
          bloc.add(const DeleteItem<TestUser, String>(
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

    group('RefreshItem event', () {
      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'cancels current subscription and loads fresh data',
        build: () => NexusItemBloc<TestUser, String>(mockStore, 'user-1'),
        act: (bloc) async {
          // First load
          bloc.add(const LoadItem<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
          watchController.add(TestFixtures.sampleUser);
          await Future<void>.delayed(Duration.zero);

          // Refresh
          bloc.add(const RefreshItem<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
          const updatedUser = TestUser(
            id: 'user-1',
            name: 'Refreshed User',
            email: 'refreshed@test.com',
            age: 35,
          );
          watchController.add(updatedUser);
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusItemLoading<TestUser>>(),
          isA<NexusItemLoaded<TestUser>>()
              .having((s) => s.data.name, 'data.name', 'John Doe'),
          isA<NexusItemLoading<TestUser>>().having(
              (s) => s.previousData?.name, 'previousData.name', 'John Doe'),
          isA<NexusItemLoaded<TestUser>>()
              .having((s) => s.data.name, 'data.name', 'Refreshed User'),
        ],
      );
    });

    group('close', () {
      test('cancels stream subscription on close', () async {
        final bloc = NexusItemBloc<TestUser, String>(mockStore, 'user-1');
        bloc.add(const LoadItem<TestUser, String>());

        await Future<void>.delayed(Duration.zero);

        // Verify subscription is active
        expect(watchController.hasListener, isTrue);

        await bloc.close();

        // Give time for cleanup
        await Future<void>.delayed(Duration.zero);

        // Subscription should be cancelled
        expect(watchController.hasListener, isFalse);
      });
    });

    group('error handling', () {
      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'emits error state on save failure',
        build: () {
          when(() => mockStore.save(any(),
              policy: any(named: 'policy'),
              tags: any(named: 'tags'))).thenThrow(Exception('Save failed'));
          return NexusItemBloc<TestUser, String>(mockStore, 'user-1');
        },
        seed: () => NexusItemLoaded<TestUser>(data: TestFixtures.sampleUser),
        act: (bloc) async {
          bloc.add(SaveItem<TestUser, String>(TestFixtures.sampleUser));
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusItemError<TestUser>>()
              .having((s) => s.previousData?.id, 'previousData.id', 'user-1'),
        ],
      );

      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'emits error state on delete failure',
        build: () {
          when(() => mockStore.delete(any(), policy: any(named: 'policy')))
              .thenThrow(Exception('Delete failed'));
          return NexusItemBloc<TestUser, String>(mockStore, 'user-1');
        },
        seed: () => NexusItemLoaded<TestUser>(data: TestFixtures.sampleUser),
        act: (bloc) async {
          bloc.add(const DeleteItem<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusItemError<TestUser>>()
              .having((s) => s.previousData?.id, 'previousData.id', 'user-1'),
        ],
      );

      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'preserves previous data in error state from stream error',
        build: () => NexusItemBloc<TestUser, String>(mockStore, 'user-1'),
        act: (bloc) async {
          bloc.add(const LoadItem<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
          watchController.add(TestFixtures.sampleUser);
          await Future<void>.delayed(Duration.zero);
          watchController.addError(Exception('Stream error'));
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusItemLoading<TestUser>>(),
          isA<NexusItemLoaded<TestUser>>(),
          isA<NexusItemError<TestUser>>()
              .having((s) => s.previousData?.id, 'previousData.id', 'user-1'),
        ],
      );
    });

    group('stream updates', () {
      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'updates state on subsequent stream emissions',
        build: () => NexusItemBloc<TestUser, String>(mockStore, 'user-1'),
        act: (bloc) async {
          bloc.add(const LoadItem<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
          watchController.add(TestFixtures.sampleUser);
          await Future<void>.delayed(Duration.zero);
          const updatedUser = TestUser(
            id: 'user-1',
            name: 'Updated User',
            email: 'updated@test.com',
            age: 40,
          );
          watchController.add(updatedUser);
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusItemLoading<TestUser>>(),
          isA<NexusItemLoaded<TestUser>>()
              .having((s) => s.data.name, 'data.name', 'John Doe'),
          isA<NexusItemLoaded<TestUser>>()
              .having((s) => s.data.name, 'data.name', 'Updated User'),
        ],
      );

      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'transitions from loaded to notFound when item is deleted',
        build: () => NexusItemBloc<TestUser, String>(mockStore, 'user-1'),
        act: (bloc) async {
          bloc.add(const LoadItem<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
          watchController.add(TestFixtures.sampleUser);
          await Future<void>.delayed(Duration.zero);
          watchController.add(null);
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusItemLoading<TestUser>>(),
          isA<NexusItemLoaded<TestUser>>(),
          isA<NexusItemNotFound<TestUser>>(),
        ],
      );
    });

    group('edge cases', () {
      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'LoadItem from NotFound state triggers reload',
        build: () => NexusItemBloc<TestUser, String>(mockStore, 'user-1'),
        seed: () => const NexusItemNotFound<TestUser>(),
        act: (bloc) async {
          bloc.add(const LoadItem<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
          watchController.add(TestFixtures.sampleUser);
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusItemLoading<TestUser>>(),
          isA<NexusItemLoaded<TestUser>>()
              .having((s) => s.data.id, 'data.id', 'user-1'),
        ],
      );

      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'Loading -> NotFound -> Loading state transitions work correctly',
        build: () => NexusItemBloc<TestUser, String>(mockStore, 'user-1'),
        act: (bloc) async {
          // First load - item not found
          bloc.add(const LoadItem<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
          watchController.add(null);
          await Future<void>.delayed(Duration.zero);

          // Reload - item now exists
          bloc.add(const LoadItem<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
          watchController.add(TestFixtures.sampleUser);
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusItemLoading<TestUser>>(),
          isA<NexusItemNotFound<TestUser>>(),
          isA<NexusItemLoading<TestUser>>(),
          isA<NexusItemLoaded<TestUser>>(),
        ],
      );

      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'delete from Initial state',
        build: () => NexusItemBloc<TestUser, String>(mockStore, 'user-1'),
        act: (bloc) async {
          bloc.add(const DeleteItem<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          verify(() => mockStore.delete('user-1', policy: any(named: 'policy')))
              .called(1);
        },
      );

      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'delete from NotFound state',
        build: () => NexusItemBloc<TestUser, String>(mockStore, 'user-1'),
        seed: () => const NexusItemNotFound<TestUser>(),
        act: (bloc) async {
          bloc.add(const DeleteItem<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          verify(() => mockStore.delete('user-1', policy: any(named: 'policy')))
              .called(1);
        },
      );

      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'delete from Error state preserves previousData on new error',
        build: () {
          when(() => mockStore.delete(any(), policy: any(named: 'policy')))
              .thenThrow(Exception('Delete failed'));
          return NexusItemBloc<TestUser, String>(mockStore, 'user-1');
        },
        seed: () => NexusItemError<TestUser>(
          error: Exception('Previous error'),
          previousData: TestFixtures.sampleUser,
        ),
        act: (bloc) async {
          bloc.add(const DeleteItem<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusItemError<TestUser>>()
              .having((s) => s.previousData?.id, 'previousData.id', 'user-1'),
        ],
      );

      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'error state includes stackTrace from stream error',
        build: () => NexusItemBloc<TestUser, String>(mockStore, 'user-1'),
        act: (bloc) async {
          bloc.add(const LoadItem<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
          watchController.addError(
            Exception('Test error'),
            StackTrace.fromString('test stack trace'),
          );
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusItemLoading<TestUser>>(),
          isA<NexusItemError<TestUser>>()
              .having((s) => s.stackTrace, 'stackTrace', isNotNull),
        ],
      );

      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'save error includes stackTrace',
        build: () {
          when(() => mockStore.save(any(),
              policy: any(named: 'policy'),
              tags: any(named: 'tags'))).thenThrow(Exception('Save failed'));
          return NexusItemBloc<TestUser, String>(mockStore, 'user-1');
        },
        act: (bloc) async {
          bloc.add(SaveItem<TestUser, String>(TestFixtures.sampleUser));
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusItemError<TestUser>>()
              .having((s) => s.stackTrace, 'stackTrace', isNotNull),
        ],
      );

      test('multiple LoadItem events cancel previous subscription', () async {
        // Use separate controllers to simulate different streams
        final controller1 = StreamController<TestUser?>.broadcast();
        final controller2 = StreamController<TestUser?>.broadcast();
        var callCount = 0;

        when(() => mockStore.watch(any())).thenAnswer((_) {
          callCount++;
          return callCount == 1 ? controller1.stream : controller2.stream;
        });

        final bloc = NexusItemBloc<TestUser, String>(mockStore, 'user-1');

        // First load
        bloc.add(const LoadItem<TestUser, String>());
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state, isA<NexusItemLoading<TestUser>>());

        // Second load - cancels first subscription
        bloc.add(const LoadItem<TestUser, String>());
        await Future<void>.delayed(Duration.zero);

        // Emit on first controller - should not affect bloc (subscription cancelled)
        controller1.add(TestFixtures.sampleUser);
        await Future<void>.delayed(Duration.zero);
        // State should still be loading (from second LoadItem)
        expect(bloc.state, isA<NexusItemLoading<TestUser>>());

        // Emit on second controller - should update bloc
        const updatedUser = TestUser(
          id: 'user-1',
          name: 'Updated User',
          email: 'updated@test.com',
          age: 40,
        );
        controller2.add(updatedUser);
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state, isA<NexusItemLoaded<TestUser>>());
        expect((bloc.state as NexusItemLoaded<TestUser>).data.name,
            'Updated User');

        // Verify watch was called twice
        verify(() => mockStore.watch('user-1')).called(2);

        await bloc.close();
        await controller1.close();
        await controller2.close();
      });

      blocTest<NexusItemBloc<TestUser, String>, NexusItemState<TestUser>>(
        'RefreshItem without prior LoadItem triggers fresh load',
        build: () => NexusItemBloc<TestUser, String>(mockStore, 'user-1'),
        act: (bloc) async {
          // Refresh without prior LoadItem
          bloc.add(const RefreshItem<TestUser, String>());
          await Future<void>.delayed(Duration.zero);
          watchController.add(TestFixtures.sampleUser);
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusItemLoading<TestUser>>(),
          isA<NexusItemLoaded<TestUser>>()
              .having((s) => s.data.id, 'data.id', 'user-1'),
        ],
      );
    });
  });
}
