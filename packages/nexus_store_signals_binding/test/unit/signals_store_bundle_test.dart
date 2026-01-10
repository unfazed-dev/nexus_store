import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_signals_binding/nexus_store_signals_binding.dart';
import 'package:signals/signals.dart';

import '../fixtures/mock_store.dart';
import '../fixtures/test_entities.dart';

void main() {
  setUpAll(registerFallbackValues);

  group('SignalsStoreConfig', () {
    test('stores name and store reference', () {
      final mockStore = MockNexusStore<TestUser, String>();

      final config = SignalsStoreConfig<TestUser, String>(
        name: 'users',
        store: mockStore,
      );

      expect(config.name, equals('users'));
      expect(config.store, same(mockStore));
      expect(config.computedSignals, isEmpty);
    });

    test('stores computed signals map', () {
      final mockStore = MockNexusStore<TestUser, String>();

      final config = SignalsStoreConfig<TestUser, String>(
        name: 'users',
        store: mockStore,
        computedSignals: {
          'activeCount': (list) => computed(() => list.value.length),
        },
      );

      expect(config.computedSignals.keys, contains('activeCount'));
    });
  });

  group('SignalsStoreBundle', () {
    late MockNexusStore<TestUser, String> mockStore;
    late StreamController<List<TestUser>> streamController;

    setUp(() {
      mockStore = MockNexusStore<TestUser, String>();
      streamController = StreamController<List<TestUser>>.broadcast();
      when(() => mockStore.watchAll(query: any(named: 'query')))
          .thenAnswer((_) => streamController.stream);
    });

    tearDown(() {
      streamController.close();
    });

    group('create factory', () {
      test('creates bundle with listSignal', () {
        final bundle = SignalsStoreBundle.create(
          config: SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockStore,
          ),
        );
        addTearDown(bundle.dispose);

        expect(bundle.listSignal, isNotNull);
        expect(bundle.name, equals('users'));
      });

      test('creates bundle with stateSignal', () {
        final bundle = SignalsStoreBundle.create(
          config: SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockStore,
          ),
        );
        addTearDown(bundle.dispose);

        expect(bundle.stateSignal, isNotNull);
      });
    });

    group('listSignal', () {
      test('starts with empty list', () {
        final bundle = SignalsStoreBundle.create(
          config: SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockStore,
          ),
        );
        addTearDown(bundle.dispose);

        expect(bundle.listSignal.value, isEmpty);
      });

      test('updates when store emits data', () async {
        final bundle = SignalsStoreBundle.create(
          config: SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockStore,
          ),
        );
        addTearDown(bundle.dispose);

        streamController.add(testUsers);
        await Future<void>.delayed(Duration.zero);

        expect(bundle.listSignal.value, equals(testUsers));
      });
    });

    group('stateSignal', () {
      test('starts with initial state', () {
        final bundle = SignalsStoreBundle.create(
          config: SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockStore,
          ),
        );
        addTearDown(bundle.dispose);

        expect(bundle.stateSignal.value, isA<NexusSignalInitial<TestUser>>());
      });

      test('updates to data state on emission', () async {
        final bundle = SignalsStoreBundle.create(
          config: SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockStore,
          ),
        );
        addTearDown(bundle.dispose);

        streamController.add(testUsers);
        await Future<void>.delayed(Duration.zero);

        expect(bundle.stateSignal.value, isA<NexusSignalData<TestUser>>());
        expect(bundle.stateSignal.value.dataOrNull, equals(testUsers));
      });

      test('updates to error state on error', () async {
        final bundle = SignalsStoreBundle.create(
          config: SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockStore,
          ),
        );
        addTearDown(bundle.dispose);

        streamController.addError(Exception('Test error'));
        await Future<void>.delayed(Duration.zero);

        expect(bundle.stateSignal.value, isA<NexusSignalError<TestUser>>());
        expect(bundle.stateSignal.value.hasError, isTrue);
      });
    });

    group('computed signals', () {
      test('creates named computed signals', () async {
        final bundle = SignalsStoreBundle.create(
          config: SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockStore,
            computedSignals: {
              'activeCount': (list) => computed(
                    () => list.value.where((u) => u.isActive).length,
                  ),
            },
          ),
        );
        addTearDown(bundle.dispose);

        streamController.add(testUsers);
        await Future<void>.delayed(Duration.zero);

        final activeCount = bundle.computed('activeCount');
        expect(activeCount, isNotNull);
        // testUser1 and testUser3 are active
        expect(activeCount!.value as int, equals(2));
      });

      test('returns null for non-existent computed name', () {
        final bundle = SignalsStoreBundle.create(
          config: SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockStore,
          ),
        );
        addTearDown(bundle.dispose);

        expect(bundle.computed('nonexistent'), isNull);
      });

      test('computed signal updates when list changes', () async {
        final bundle = SignalsStoreBundle.create(
          config: SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockStore,
            computedSignals: {
              'count': (list) => computed(() => list.value.length),
            },
          ),
        );
        addTearDown(bundle.dispose);

        streamController.add([testUser1]);
        await Future<void>.delayed(Duration.zero);
        expect(bundle.computed('count')!.value as int, equals(1));

        streamController.add(testUsers);
        await Future<void>.delayed(Duration.zero);
        expect(bundle.computed('count')!.value as int, equals(3));
      });
    });

    group('computedNames', () {
      test('returns list of computed signal names', () {
        final bundle = SignalsStoreBundle.create(
          config: SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockStore,
            computedSignals: {
              'activeCount': (list) => computed(() => list.value.length),
              'sortedByName': (list) => computed(() => list.value),
            },
          ),
        );
        addTearDown(bundle.dispose);

        expect(
          bundle.computedNames,
          containsAll(['activeCount', 'sortedByName']),
        );
      });
    });

    group('dispose', () {
      test('disposes all signals', () {
        final bundle = SignalsStoreBundle.create(
          config: SignalsStoreConfig<TestUser, String>(
            name: 'users',
            store: mockStore,
          ),
        );

        bundle.dispose();

        expect(bundle.listSignal.disposed, isTrue);
      });
    });
  });
}
