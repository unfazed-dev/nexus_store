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
    when(() => mockStore.watch(any())).thenAnswer((_) => watchController.stream);
    when(() => mockStore.save(any(),
            policy: any(named: 'policy'), tags: any(named: 'tags')))
        .thenAnswer(
            (invocation) async => invocation.positionalArguments[0] as TestUser);
    when(() => mockStore.delete(any(), policy: any(named: 'policy')))
        .thenAnswer((_) async => true);
  });

  tearDown(() async {
    await watchController.close();
  });

  group('NexusItemCubit', () {
    group('constructor', () {
      test('should start with initial state', () {
        final cubit = NexusItemCubit<TestUser, String>(mockStore, 'user-1');
        expect(cubit.state, isA<NexusItemInitial<TestUser>>());
        cubit.close();
      });

      test('should expose the id', () {
        final cubit = NexusItemCubit<TestUser, String>(mockStore, 'user-1');
        expect(cubit.id, equals('user-1'));
        cubit.close();
      });

      test('should expose the underlying store', () {
        final cubit = NexusItemCubit<TestUser, String>(mockStore, 'user-1');
        expect(cubit.store, same(mockStore));
        cubit.close();
      });
    });

    group('load', () {
      blocTest<NexusItemCubit<TestUser, String>, NexusItemState<TestUser>>(
        'emits loading then loaded when watch emits data',
        build: () => NexusItemCubit<TestUser, String>(mockStore, 'user-1'),
        act: (cubit) async {
          await cubit.load();
          watchController.add(TestFixtures.sampleUser);
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusItemLoading<TestUser>>(),
          isA<NexusItemLoaded<TestUser>>()
              .having((s) => s.data.id, 'data.id', 'user-1'),
        ],
      );

      blocTest<NexusItemCubit<TestUser, String>, NexusItemState<TestUser>>(
        'emits loading then notFound when watch emits null',
        build: () => NexusItemCubit<TestUser, String>(mockStore, 'user-1'),
        act: (cubit) async {
          await cubit.load();
          watchController.add(null);
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusItemLoading<TestUser>>(),
          isA<NexusItemNotFound<TestUser>>(),
        ],
      );

      blocTest<NexusItemCubit<TestUser, String>, NexusItemState<TestUser>>(
        'emits loading then error when watch emits error',
        build: () => NexusItemCubit<TestUser, String>(mockStore, 'user-1'),
        act: (cubit) async {
          await cubit.load();
          watchController.addError(Exception('Network error'));
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusItemLoading<TestUser>>(),
          isA<NexusItemError<TestUser>>()
              .having((s) => s.error.toString(), 'error', contains('Network error')),
        ],
      );

      blocTest<NexusItemCubit<TestUser, String>, NexusItemState<TestUser>>(
        'preserves previous data during loading on reload',
        build: () => NexusItemCubit<TestUser, String>(mockStore, 'user-1'),
        seed: () => NexusItemLoaded<TestUser>(data: TestFixtures.sampleUser),
        act: (cubit) async {
          await cubit.load();
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusItemLoading<TestUser>>()
              .having((s) => s.previousData?.id, 'previousData.id', 'user-1'),
        ],
      );

      blocTest<NexusItemCubit<TestUser, String>, NexusItemState<TestUser>>(
        'updates data on subsequent stream emissions',
        build: () => NexusItemCubit<TestUser, String>(mockStore, 'user-1'),
        act: (cubit) async {
          await cubit.load();
          watchController.add(TestFixtures.sampleUser);
          await Future<void>.delayed(Duration.zero);
          const updatedUser = TestUser(
            id: 'user-1',
            name: 'Updated User',
            email: 'updated@test.com',
            age: 30,
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

      blocTest<NexusItemCubit<TestUser, String>, NexusItemState<TestUser>>(
        'transitions from loaded to notFound when item is deleted',
        build: () => NexusItemCubit<TestUser, String>(mockStore, 'user-1'),
        act: (cubit) async {
          await cubit.load();
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

      blocTest<NexusItemCubit<TestUser, String>, NexusItemState<TestUser>>(
        'calls watch with the correct id',
        build: () => NexusItemCubit<TestUser, String>(mockStore, 'user-42'),
        act: (cubit) async {
          await cubit.load();
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          verify(() => mockStore.watch('user-42')).called(1);
        },
      );

      blocTest<NexusItemCubit<TestUser, String>, NexusItemState<TestUser>>(
        'cancels previous subscription when load is called again',
        build: () => NexusItemCubit<TestUser, String>(mockStore, 'user-1'),
        act: (cubit) async {
          await cubit.load();
          await cubit.load();
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          verify(() => mockStore.watch('user-1')).called(2);
        },
      );
    });

    group('save', () {
      blocTest<NexusItemCubit<TestUser, String>, NexusItemState<TestUser>>(
        'calls store.save with the item',
        build: () => NexusItemCubit<TestUser, String>(mockStore, 'user-1'),
        act: (cubit) async {
          await cubit.save(TestFixtures.sampleUser);
        },
        verify: (_) {
          verify(() => mockStore.save(
                TestFixtures.sampleUser,
                policy: any(named: 'policy'),
                tags: any(named: 'tags'),
              )).called(1);
        },
      );

      blocTest<NexusItemCubit<TestUser, String>, NexusItemState<TestUser>>(
        'calls store.save with policy and tags',
        build: () => NexusItemCubit<TestUser, String>(mockStore, 'user-1'),
        act: (cubit) async {
          await cubit.save(
            TestFixtures.sampleUser,
            policy: WritePolicy.cacheOnly,
            tags: {'tag1', 'tag2'},
          );
        },
        verify: (_) {
          verify(() => mockStore.save(
                TestFixtures.sampleUser,
                policy: WritePolicy.cacheOnly,
                tags: {'tag1', 'tag2'},
              )).called(1);
        },
      );

      blocTest<NexusItemCubit<TestUser, String>, NexusItemState<TestUser>>(
        'returns the saved item',
        build: () => NexusItemCubit<TestUser, String>(mockStore, 'user-1'),
        act: (cubit) async {
          final result = await cubit.save(TestFixtures.sampleUser);
          expect(result, equals(TestFixtures.sampleUser));
        },
      );
    });

    group('delete', () {
      blocTest<NexusItemCubit<TestUser, String>, NexusItemState<TestUser>>(
        'calls store.delete with the cubit id',
        build: () => NexusItemCubit<TestUser, String>(mockStore, 'user-1'),
        act: (cubit) async {
          await cubit.delete();
        },
        verify: (_) {
          verify(() => mockStore.delete('user-1', policy: any(named: 'policy')))
              .called(1);
        },
      );

      blocTest<NexusItemCubit<TestUser, String>, NexusItemState<TestUser>>(
        'calls store.delete with policy',
        build: () => NexusItemCubit<TestUser, String>(mockStore, 'user-1'),
        act: (cubit) async {
          await cubit.delete(policy: WritePolicy.cacheOnly);
        },
        verify: (_) {
          verify(() =>
                  mockStore.delete('user-1', policy: WritePolicy.cacheOnly))
              .called(1);
        },
      );

      blocTest<NexusItemCubit<TestUser, String>, NexusItemState<TestUser>>(
        'returns delete result',
        build: () => NexusItemCubit<TestUser, String>(mockStore, 'user-1'),
        act: (cubit) async {
          final result = await cubit.delete();
          expect(result, isTrue);
        },
      );
    });

    group('refresh', () {
      blocTest<NexusItemCubit<TestUser, String>, NexusItemState<TestUser>>(
        'cancels current subscription and loads fresh data',
        build: () => NexusItemCubit<TestUser, String>(mockStore, 'user-1'),
        act: (cubit) async {
          // First load
          await cubit.load();
          watchController.add(TestFixtures.sampleUser);
          await Future<void>.delayed(Duration.zero);

          // Refresh
          await cubit.refresh();
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
          isA<NexusItemLoading<TestUser>>()
              .having((s) => s.previousData?.name, 'previousData.name', 'John Doe'),
          isA<NexusItemLoaded<TestUser>>()
              .having((s) => s.data.name, 'data.name', 'Refreshed User'),
        ],
      );
    });

    group('close', () {
      test('cancels stream subscription on close', () async {
        final cubit = NexusItemCubit<TestUser, String>(mockStore, 'user-1');
        await cubit.load();

        // Verify subscription is active
        expect(watchController.hasListener, isTrue);

        await cubit.close();

        // Give time for cleanup
        await Future<void>.delayed(Duration.zero);

        // Subscription should be cancelled
        expect(watchController.hasListener, isFalse);
      });
    });

    group('error handling', () {
      blocTest<NexusItemCubit<TestUser, String>, NexusItemState<TestUser>>(
        'emits error state on save failure',
        build: () {
          when(() => mockStore.save(any(),
                  policy: any(named: 'policy'), tags: any(named: 'tags')))
              .thenThrow(Exception('Save failed'));
          return NexusItemCubit<TestUser, String>(mockStore, 'user-1');
        },
        seed: () => NexusItemLoaded<TestUser>(data: TestFixtures.sampleUser),
        act: (cubit) async {
          try {
            await cubit.save(TestFixtures.sampleUser);
          } catch (_) {
            // Expected error
          }
        },
        expect: () => [
          isA<NexusItemError<TestUser>>()
              .having((s) => s.previousData?.id, 'previousData.id', 'user-1'),
        ],
      );

      blocTest<NexusItemCubit<TestUser, String>, NexusItemState<TestUser>>(
        'emits error state on delete failure',
        build: () {
          when(() => mockStore.delete(any(), policy: any(named: 'policy')))
              .thenThrow(Exception('Delete failed'));
          return NexusItemCubit<TestUser, String>(mockStore, 'user-1');
        },
        seed: () => NexusItemLoaded<TestUser>(data: TestFixtures.sampleUser),
        act: (cubit) async {
          try {
            await cubit.delete();
          } catch (_) {
            // Expected error
          }
        },
        expect: () => [
          isA<NexusItemError<TestUser>>()
              .having((s) => s.previousData?.id, 'previousData.id', 'user-1'),
        ],
      );

      blocTest<NexusItemCubit<TestUser, String>, NexusItemState<TestUser>>(
        'rethrows error after emitting error state on save',
        build: () {
          when(() => mockStore.save(any(),
                  policy: any(named: 'policy'), tags: any(named: 'tags')))
              .thenThrow(Exception('Save failed'));
          return NexusItemCubit<TestUser, String>(mockStore, 'user-1');
        },
        act: (cubit) async {
          await expectLater(
            () => cubit.save(TestFixtures.sampleUser),
            throwsA(isA<Exception>()),
          );
        },
      );

      blocTest<NexusItemCubit<TestUser, String>, NexusItemState<TestUser>>(
        'rethrows error after emitting error state on delete',
        build: () {
          when(() => mockStore.delete(any(), policy: any(named: 'policy')))
              .thenThrow(Exception('Delete failed'));
          return NexusItemCubit<TestUser, String>(mockStore, 'user-1');
        },
        act: (cubit) async {
          await expectLater(
            () => cubit.delete(),
            throwsA(isA<Exception>()),
          );
        },
      );

      blocTest<NexusItemCubit<TestUser, String>, NexusItemState<TestUser>>(
        'preserves previous data in error state from stream error',
        build: () => NexusItemCubit<TestUser, String>(mockStore, 'user-1'),
        act: (cubit) async {
          await cubit.load();
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

    group('lifecycle hooks', () {
      test('onSave is called before save operation', () async {
        var onSaveCalled = false;
        TestUser? savedItem;

        final cubit = _TestableItemCubit(
          mockStore,
          'user-1',
          onSaveCallback: (item) {
            onSaveCalled = true;
            savedItem = item;
          },
        );

        await cubit.save(TestFixtures.sampleUser);

        expect(onSaveCalled, isTrue);
        expect(savedItem, equals(TestFixtures.sampleUser));

        await cubit.close();
      });

      test('onDelete is called before delete operation', () async {
        var onDeleteCalled = false;

        final cubit = _TestableItemCubit(
          mockStore,
          'user-1',
          onDeleteCallback: () {
            onDeleteCalled = true;
          },
        );

        await cubit.delete();

        expect(onDeleteCalled, isTrue);

        await cubit.close();
      });
    });
  });
}

/// Testable cubit to verify lifecycle hooks
class _TestableItemCubit extends NexusItemCubit<TestUser, String> {
  _TestableItemCubit(
    super.store,
    super.id, {
    this.onSaveCallback,
    this.onDeleteCallback,
  });

  final void Function(TestUser)? onSaveCallback;
  final void Function()? onDeleteCallback;

  @override
  void onSave(TestUser item) {
    onSaveCallback?.call(item);
  }

  @override
  void onDelete() {
    onDeleteCallback?.call();
  }
}
