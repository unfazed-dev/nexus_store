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

  group('NexusStoreCubit', () {
    group('constructor', () {
      test('should start with initial state', () {
        final cubit = NexusStoreCubit<TestUser, String>(mockStore);
        expect(cubit.state, isA<NexusStoreInitial<TestUser>>());
        cubit.close();
      });
    });

    group('load', () {
      blocTest<NexusStoreCubit<TestUser, String>, NexusStoreState<TestUser>>(
        'emits loading then loaded when watchAll emits data',
        build: () => NexusStoreCubit<TestUser, String>(mockStore),
        act: (cubit) async {
          await cubit.load();
          watchAllController.add(TestFixtures.sampleUsers);
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusStoreLoading<TestUser>>(),
          isA<NexusStoreLoaded<TestUser>>()
              .having((s) => s.data.length, 'data.length', 3),
        ],
      );

      blocTest<NexusStoreCubit<TestUser, String>, NexusStoreState<TestUser>>(
        'emits loading then error when watchAll emits error',
        build: () => NexusStoreCubit<TestUser, String>(mockStore),
        act: (cubit) async {
          await cubit.load();
          watchAllController.addError(Exception('Network error'));
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusStoreLoading<TestUser>>(),
          isA<NexusStoreError<TestUser>>().having(
              (s) => s.error.toString(), 'error', contains('Network error')),
        ],
      );

      blocTest<NexusStoreCubit<TestUser, String>, NexusStoreState<TestUser>>(
        'preserves previous data during loading on reload',
        build: () => NexusStoreCubit<TestUser, String>(mockStore),
        seed: () => NexusStoreLoaded<TestUser>(data: TestFixtures.sampleUsers),
        act: (cubit) async {
          await cubit.load();
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusStoreLoading<TestUser>>()
              .having((s) => s.previousData?.length, 'previousData.length', 3),
        ],
      );

      blocTest<NexusStoreCubit<TestUser, String>, NexusStoreState<TestUser>>(
        'updates data on subsequent stream emissions',
        build: () => NexusStoreCubit<TestUser, String>(mockStore),
        act: (cubit) async {
          await cubit.load();
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

    group('save', () {
      blocTest<NexusStoreCubit<TestUser, String>, NexusStoreState<TestUser>>(
        'calls store.save with the item',
        build: () => NexusStoreCubit<TestUser, String>(mockStore),
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
    });

    group('saveAll', () {
      blocTest<NexusStoreCubit<TestUser, String>, NexusStoreState<TestUser>>(
        'calls store.saveAll with the items',
        build: () => NexusStoreCubit<TestUser, String>(mockStore),
        act: (cubit) async {
          await cubit.saveAll(TestFixtures.sampleUsers);
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

    group('delete', () {
      blocTest<NexusStoreCubit<TestUser, String>, NexusStoreState<TestUser>>(
        'calls store.delete with the id',
        build: () => NexusStoreCubit<TestUser, String>(mockStore),
        act: (cubit) async {
          await cubit.delete('user-1');
        },
        verify: (_) {
          verify(() => mockStore.delete('user-1', policy: any(named: 'policy')))
              .called(1);
        },
      );
    });

    group('deleteAll', () {
      blocTest<NexusStoreCubit<TestUser, String>, NexusStoreState<TestUser>>(
        'calls store.deleteAll with the ids',
        build: () => NexusStoreCubit<TestUser, String>(mockStore),
        act: (cubit) async {
          await cubit.deleteAll(['user-1', 'user-2']);
        },
        verify: (_) {
          verify(() => mockStore.deleteAll(['user-1', 'user-2'],
              policy: any(named: 'policy'))).called(1);
        },
      );
    });

    group('refresh', () {
      blocTest<NexusStoreCubit<TestUser, String>, NexusStoreState<TestUser>>(
        'cancels current subscription and loads fresh data',
        build: () => NexusStoreCubit<TestUser, String>(mockStore),
        act: (cubit) async {
          // First load
          await cubit.load();
          watchAllController.add([TestFixtures.sampleUser]);
          await Future<void>.delayed(Duration.zero);

          // Refresh
          await cubit.refresh();
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
        final cubit = NexusStoreCubit<TestUser, String>(mockStore);
        await cubit.load();

        // Verify subscription is active
        expect(watchAllController.hasListener, isTrue);

        await cubit.close();

        // Give time for cleanup
        await Future<void>.delayed(Duration.zero);

        // Subscription should be cancelled
        expect(watchAllController.hasListener, isFalse);
      });
    });

    group('error handling', () {
      blocTest<NexusStoreCubit<TestUser, String>, NexusStoreState<TestUser>>(
        'emits error state on save failure',
        build: () {
          when(() => mockStore.save(any(),
              policy: any(named: 'policy'),
              tags: any(named: 'tags'))).thenThrow(Exception('Save failed'));
          return NexusStoreCubit<TestUser, String>(mockStore);
        },
        seed: () => NexusStoreLoaded<TestUser>(data: TestFixtures.sampleUsers),
        act: (cubit) async {
          try {
            await cubit.save(TestFixtures.sampleUser);
          } catch (_) {
            // Expected error
          }
        },
        expect: () => [
          isA<NexusStoreError<TestUser>>()
              .having((s) => s.previousData?.length, 'previousData.length', 3),
        ],
      );

      blocTest<NexusStoreCubit<TestUser, String>, NexusStoreState<TestUser>>(
        'emits error state on delete failure',
        build: () {
          when(() => mockStore.delete(any(), policy: any(named: 'policy')))
              .thenThrow(Exception('Delete failed'));
          return NexusStoreCubit<TestUser, String>(mockStore);
        },
        seed: () => NexusStoreLoaded<TestUser>(data: TestFixtures.sampleUsers),
        act: (cubit) async {
          try {
            await cubit.delete('user-1');
          } catch (_) {
            // Expected error
          }
        },
        expect: () => [
          isA<NexusStoreError<TestUser>>()
              .having((s) => s.previousData?.length, 'previousData.length', 3),
        ],
      );

      blocTest<NexusStoreCubit<TestUser, String>, NexusStoreState<TestUser>>(
        'emits error state on saveAll failure',
        build: () {
          when(() => mockStore.saveAll(any(),
              policy: any(named: 'policy'),
              tags: any(named: 'tags'))).thenThrow(Exception('SaveAll failed'));
          return NexusStoreCubit<TestUser, String>(mockStore);
        },
        seed: () => NexusStoreLoaded<TestUser>(data: TestFixtures.sampleUsers),
        act: (cubit) async {
          try {
            await cubit.saveAll([TestFixtures.sampleUser]);
          } catch (_) {
            // Expected error
          }
        },
        expect: () => [
          isA<NexusStoreError<TestUser>>()
              .having((s) => s.previousData?.length, 'previousData.length', 3),
        ],
      );

      blocTest<NexusStoreCubit<TestUser, String>, NexusStoreState<TestUser>>(
        'emits error state on deleteAll failure',
        build: () {
          when(() => mockStore.deleteAll(any(), policy: any(named: 'policy')))
              .thenThrow(Exception('DeleteAll failed'));
          return NexusStoreCubit<TestUser, String>(mockStore);
        },
        seed: () => NexusStoreLoaded<TestUser>(data: TestFixtures.sampleUsers),
        act: (cubit) async {
          try {
            await cubit.deleteAll(['user-1', 'user-2']);
          } catch (_) {
            // Expected error
          }
        },
        expect: () => [
          isA<NexusStoreError<TestUser>>()
              .having((s) => s.previousData?.length, 'previousData.length', 3),
        ],
      );
    });

    group('store getter', () {
      test('exposes the underlying store', () {
        final cubit = NexusStoreCubit<TestUser, String>(mockStore);
        expect(cubit.store, same(mockStore));
        cubit.close();
      });
    });

    group('load with query', () {
      blocTest<NexusStoreCubit<TestUser, String>, NexusStoreState<TestUser>>(
        'passes query parameter to watchAll',
        build: () => NexusStoreCubit<TestUser, String>(mockStore),
        act: (cubit) async {
          final query =
              const Query<TestUser>().where('name', isEqualTo: 'Alice');
          await cubit.load(query: query);
          watchAllController.add([TestFixtures.sampleUser]);
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          verify(() => mockStore.watchAll(
                query: any(named: 'query', that: isNotNull),
              )).called(1);
        },
      );

      blocTest<NexusStoreCubit<TestUser, String>, NexusStoreState<TestUser>>(
        'refresh preserves the current query',
        build: () => NexusStoreCubit<TestUser, String>(mockStore),
        act: (cubit) async {
          final query =
              const Query<TestUser>().where('name', isEqualTo: 'Alice');
          await cubit.load(query: query);
          watchAllController.add([TestFixtures.sampleUser]);
          await Future<void>.delayed(Duration.zero);

          await cubit.refresh();
          watchAllController.add([TestFixtures.sampleUser]);
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          // watchAll should be called twice, both times with a query
          verify(() => mockStore.watchAll(
                query: any(named: 'query', that: isNotNull),
              )).called(2);
        },
      );
    });

    group('error state with stackTrace', () {
      blocTest<NexusStoreCubit<TestUser, String>, NexusStoreState<TestUser>>(
        'captures stackTrace from stream error',
        build: () => NexusStoreCubit<TestUser, String>(mockStore),
        act: (cubit) async {
          await cubit.load();
          watchAllController.addError(
            Exception('Network error'),
            StackTrace.current,
          );
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          isA<NexusStoreLoading<TestUser>>(),
          isA<NexusStoreError<TestUser>>()
              .having((s) => s.stackTrace, 'stackTrace', isNotNull),
        ],
      );

      blocTest<NexusStoreCubit<TestUser, String>, NexusStoreState<TestUser>>(
        'save error includes stackTrace',
        build: () {
          when(() => mockStore.save(any(),
              policy: any(named: 'policy'),
              tags: any(named: 'tags'))).thenThrow(Exception('Save failed'));
          return NexusStoreCubit<TestUser, String>(mockStore);
        },
        act: (cubit) async {
          try {
            await cubit.save(TestFixtures.sampleUser);
          } catch (_) {
            // Expected error
          }
        },
        expect: () => [
          isA<NexusStoreError<TestUser>>()
              .having((s) => s.stackTrace, 'stackTrace', isNotNull),
        ],
      );
    });

    group('lifecycle hooks', () {
      blocTest<_TestableNexusStoreCubit, NexusStoreState<TestUser>>(
        'onSave is called before save operation',
        build: () => _TestableNexusStoreCubit(mockStore),
        act: (cubit) async {
          await cubit.save(TestFixtures.sampleUser);
        },
        verify: (cubit) {
          expect(cubit.onSaveCalled, isTrue);
          expect(cubit.savedItem, equals(TestFixtures.sampleUser));
        },
      );

      blocTest<_TestableNexusStoreCubit, NexusStoreState<TestUser>>(
        'onDelete is called before delete operation',
        build: () => _TestableNexusStoreCubit(mockStore),
        act: (cubit) async {
          await cubit.delete('user-1');
        },
        verify: (cubit) {
          expect(cubit.onDeleteCalled, isTrue);
          expect(cubit.deletedId, equals('user-1'));
        },
      );
    });
  });
}

/// Testable subclass to verify protected hook calls
class _TestableNexusStoreCubit extends NexusStoreCubit<TestUser, String> {
  _TestableNexusStoreCubit(super.store);

  bool onSaveCalled = false;
  TestUser? savedItem;

  bool onDeleteCalled = false;
  String? deletedId;

  @override
  void onSave(TestUser item) {
    onSaveCalled = true;
    savedItem = item;
    super.onSave(item);
  }

  @override
  void onDelete(String id) {
    onDeleteCalled = true;
    deletedId = id;
    super.onDelete(id);
  }
}
