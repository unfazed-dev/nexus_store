import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_bloc_binding/nexus_store_bloc_binding.dart';
import 'package:test/test.dart';

import '../fixtures/mock_store.dart';
import '../fixtures/test_entities.dart';

void main() {
  setUpAll(registerFallbackValues);

  group('NexusStoreCubitX', () {
    late MockNexusStore<TestUser, String> mockStore;
    late StreamController<List<TestUser>> streamController;
    late NexusStoreCubit<TestUser, String> cubit;

    setUp(() {
      mockStore = MockNexusStore<TestUser, String>();
      streamController = StreamController<List<TestUser>>.broadcast();

      when(() => mockStore.watchAll(query: any(named: 'query')))
          .thenAnswer((_) => streamController.stream);

      cubit = NexusStoreCubit<TestUser, String>(mockStore);
    });

    tearDown(() async {
      await cubit.close();
      await streamController.close();
    });

    group('loadDebounced', () {
      test('should debounce multiple rapid load calls', () async {
        // Call load multiple times rapidly
        cubit.loadDebounced(delay: const Duration(milliseconds: 50));
        cubit.loadDebounced(delay: const Duration(milliseconds: 50));
        cubit.loadDebounced(delay: const Duration(milliseconds: 50));

        // Should not have called watchAll yet (debouncing)
        verifyNever(() => mockStore.watchAll(query: any(named: 'query')));

        // Wait for debounce to complete
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Should only call once after debounce
        verify(() => mockStore.watchAll(query: any(named: 'query'))).called(1);
      });

      test('should pass query through debounce', () async {
        const query = Query<TestUser>();

        cubit.loadDebounced(
          query: query,
          delay: const Duration(milliseconds: 50),
        );

        await Future<void>.delayed(const Duration(milliseconds: 100));

        verify(() => mockStore.watchAll(query: query)).called(1);
      });
    });

    group('loadWithRetry', () {
      test('should retry on failure', () async {
        var attempts = 0;

        when(() => mockStore.watchAll(query: any(named: 'query')))
            .thenAnswer((_) {
          attempts++;
          if (attempts < 3) {
            return Stream<List<TestUser>>.error(
              Exception('Attempt $attempts failed'),
            );
          }
          return Stream.value(TestFixtures.sampleUsers);
        });

        await cubit.loadWithRetry(
          maxRetries: 3,
          delay: const Duration(milliseconds: 10),
        );

        // Wait for retries to complete
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(attempts, equals(3));
      });

      test('should give up after max retries', () async {
        when(() => mockStore.watchAll(query: any(named: 'query')))
            .thenAnswer((_) => Stream<List<TestUser>>.error(
                  Exception('Always fails'),
                ));

        await cubit.loadWithRetry(
          maxRetries: 2,
          delay: const Duration(milliseconds: 10),
        );

        // Wait for retries to complete
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(cubit.state, isA<NexusStoreError<TestUser>>());
      });
    });
  });

  group('NexusStoreBlocX', () {
    late MockNexusStore<TestUser, String> mockStore;
    late StreamController<List<TestUser>> streamController;
    late NexusStoreBloc<TestUser, String> bloc;

    setUp(() {
      mockStore = MockNexusStore<TestUser, String>();
      streamController = StreamController<List<TestUser>>.broadcast();

      when(() => mockStore.watchAll(query: any(named: 'query')))
          .thenAnswer((_) => streamController.stream);

      bloc = NexusStoreBloc<TestUser, String>(mockStore);
    });

    tearDown(() async {
      await bloc.close();
      await streamController.close();
    });

    group('addDebounced', () {
      test('should debounce multiple rapid event adds', () async {
        // Add events rapidly
        bloc.addDebounced(
          const LoadAll<TestUser, String>(),
          delay: const Duration(milliseconds: 50),
        );
        bloc.addDebounced(
          const LoadAll<TestUser, String>(),
          delay: const Duration(milliseconds: 50),
        );
        bloc.addDebounced(
          const LoadAll<TestUser, String>(),
          delay: const Duration(milliseconds: 50),
        );

        // Should not have processed event yet (debouncing)
        verifyNever(() => mockStore.watchAll(query: any(named: 'query')));

        // Wait for debounce to complete
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Should only process once after debounce
        verify(() => mockStore.watchAll(query: any(named: 'query'))).called(1);
      });
    });
  });

  group('EventSequences', () {
    test('should create save and refresh sequence', () {
      const sequences = EventSequences<TestUser, String>();
      final events = sequences.saveAndRefresh(TestFixtures.sampleUser);

      expect(events.length, equals(2));
      expect(events[0], isA<Save<TestUser, String>>());
      expect(events[1], isA<Refresh<TestUser, String>>());
    });

    test('should create delete and refresh sequence', () {
      const sequences = EventSequences<TestUser, String>();
      final events = sequences.deleteAndRefresh('user-1');

      expect(events.length, equals(2));
      expect(events[0], isA<Delete<TestUser, String>>());
      expect(events[1], isA<Refresh<TestUser, String>>());
    });

    test('should create batch save sequence', () {
      const sequences = EventSequences<TestUser, String>();
      final events = sequences.batchSave(TestFixtures.sampleUsers);

      expect(events.length, equals(2));
      expect(events[0], isA<SaveAll<TestUser, String>>());
      expect(events[1], isA<Refresh<TestUser, String>>());
    });
  });
}
