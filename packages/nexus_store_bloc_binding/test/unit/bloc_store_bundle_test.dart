import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_bloc_binding/nexus_store_bloc_binding.dart';
import 'package:test/test.dart';

import '../fixtures/mock_store.dart';
import '../fixtures/test_entities.dart';

void main() {
  setUpAll(registerFallbackValues);

  group('BlocStoreConfig', () {
    late MockNexusStore<TestUser, String> mockStore;

    setUp(() {
      mockStore = MockNexusStore<TestUser, String>();
    });

    test('should create config with required parameters', () {
      final config = BlocStoreConfig<TestUser, String>(
        name: 'users',
        store: mockStore,
      );

      expect(config.name, equals('users'));
      expect(config.store, equals(mockStore));
      expect(config.useBloc, isFalse); // Default
      expect(config.autoLoad, isTrue); // Default
    });

    test('should create config with useBloc flag', () {
      final config = BlocStoreConfig<TestUser, String>(
        name: 'users',
        store: mockStore,
        useBloc: true,
      );

      expect(config.useBloc, isTrue);
    });

    test('should create config with autoLoad disabled', () {
      final config = BlocStoreConfig<TestUser, String>(
        name: 'users',
        store: mockStore,
        autoLoad: false,
      );

      expect(config.autoLoad, isFalse);
    });

    test('should create config with custom LoadingStateConfig', () {
      const loadingConfig = LoadingStateConfig(
        showPreviousDataWhileLoading: true,
        debounceMs: 300,
        retryCount: 3,
      );

      final config = BlocStoreConfig<TestUser, String>(
        name: 'users',
        store: mockStore,
        loadingStateConfig: loadingConfig,
      );

      expect(config.loadingStateConfig, equals(loadingConfig));
      expect(config.loadingStateConfig!.showPreviousDataWhileLoading, isTrue);
      expect(config.loadingStateConfig!.debounceMs, equals(300));
      expect(config.loadingStateConfig!.retryCount, equals(3));
    });
  });

  group('LoadingStateConfig', () {
    test('should create config with default values', () {
      const config = LoadingStateConfig();

      expect(config.showPreviousDataWhileLoading, isFalse);
      expect(config.debounceMs, isNull);
      expect(config.retryCount, isNull);
      expect(config.retryDelayMs, equals(1000));
    });

    test('should create config with custom values', () {
      const config = LoadingStateConfig(
        showPreviousDataWhileLoading: true,
        debounceMs: 500,
        retryCount: 5,
        retryDelayMs: 2000,
      );

      expect(config.showPreviousDataWhileLoading, isTrue);
      expect(config.debounceMs, equals(500));
      expect(config.retryCount, equals(5));
      expect(config.retryDelayMs, equals(2000));
    });

    test('should implement equality', () {
      const config1 = LoadingStateConfig(
        showPreviousDataWhileLoading: true,
        debounceMs: 300,
      );
      const config2 = LoadingStateConfig(
        showPreviousDataWhileLoading: true,
        debounceMs: 300,
      );
      const config3 = LoadingStateConfig(
        showPreviousDataWhileLoading: false,
        debounceMs: 300,
      );

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
      expect(config1, isNot(equals(config3)));
    });
  });

  group('BlocStoreBundle', () {
    late MockNexusStore<TestUser, String> mockStore;
    late StreamController<List<TestUser>> streamController;

    setUp(() {
      mockStore = MockNexusStore<TestUser, String>();
      streamController = StreamController<List<TestUser>>.broadcast();

      when(() => mockStore.watchAll(query: any(named: 'query')))
          .thenAnswer((_) => streamController.stream);
    });

    tearDown(() async {
      await streamController.close();
    });

    test('should create bundle with Cubit by default', () {
      final config = BlocStoreConfig<TestUser, String>(
        name: 'users',
        store: mockStore,
      );

      final bundle = BlocStoreBundle.create(config: config);

      expect(bundle.name, equals('users'));
      expect(bundle.listCubit, isNotNull);
      expect(bundle.listCubit, isA<NexusStoreCubit<TestUser, String>>());

      bundle.close();
    });

    test('should create bundle with Bloc when useBloc is true', () {
      final config = BlocStoreConfig<TestUser, String>(
        name: 'users',
        store: mockStore,
        useBloc: true,
      );

      final bundle = BlocStoreBundle.create(config: config);

      expect(bundle.name, equals('users'));
      expect(bundle.listBloc, isNotNull);
      expect(bundle.listBloc, isA<NexusStoreBloc<TestUser, String>>());

      bundle.close();
    });

    test('should auto-load when autoLoad is true', () async {
      final config = BlocStoreConfig<TestUser, String>(
        name: 'users',
        store: mockStore,
        autoLoad: true,
      );

      final bundle = BlocStoreBundle.create(config: config);

      // Wait for the auto-load to trigger
      await Future<void>.delayed(Duration.zero);

      // Verify watchAll was called due to autoLoad
      verify(() => mockStore.watchAll(query: any(named: 'query'))).called(1);

      bundle.close();
    });

    test('should not auto-load when autoLoad is false', () async {
      final config = BlocStoreConfig<TestUser, String>(
        name: 'users',
        store: mockStore,
        autoLoad: false,
      );

      final bundle = BlocStoreBundle.create(config: config);

      // Wait a bit
      await Future<void>.delayed(Duration.zero);

      // Verify watchAll was NOT called
      verifyNever(() => mockStore.watchAll(query: any(named: 'query')));

      bundle.close();
    });

    test('should create item cubit for specific ID', () {
      when(() => mockStore.watch(any())).thenAnswer(
        (_) => Stream.value(TestFixtures.sampleUser),
      );

      final config = BlocStoreConfig<TestUser, String>(
        name: 'users',
        store: mockStore,
        autoLoad: false,
      );

      final bundle = BlocStoreBundle.create(config: config);
      final itemCubit = bundle.itemCubit('user-1');

      expect(itemCubit, isA<NexusItemCubit<TestUser, String>>());

      itemCubit.close();
      bundle.close();
    });

    test('should close all cubits on bundle close', () async {
      when(() => mockStore.watch(any())).thenAnswer(
        (_) => Stream.value(TestFixtures.sampleUser),
      );

      final config = BlocStoreConfig<TestUser, String>(
        name: 'users',
        store: mockStore,
        autoLoad: false,
      );

      final bundle = BlocStoreBundle.create(config: config);
      final itemCubit = bundle.itemCubit('user-1');

      await bundle.close();

      expect(bundle.listCubit.isClosed, isTrue);
      expect(itemCubit.isClosed, isTrue);
    });

    test('should reuse item cubit for same ID', () {
      when(() => mockStore.watch(any())).thenAnswer(
        (_) => Stream.value(TestFixtures.sampleUser),
      );

      final config = BlocStoreConfig<TestUser, String>(
        name: 'users',
        store: mockStore,
        autoLoad: false,
      );

      final bundle = BlocStoreBundle.create(config: config);
      final cubit1 = bundle.itemCubit('user-1');
      final cubit2 = bundle.itemCubit('user-1');

      expect(identical(cubit1, cubit2), isTrue);

      bundle.close();
    });

    test('should create different item cubits for different IDs', () {
      when(() => mockStore.watch(any())).thenAnswer(
        (_) => Stream.value(TestFixtures.sampleUser),
      );

      final config = BlocStoreConfig<TestUser, String>(
        name: 'users',
        store: mockStore,
        autoLoad: false,
      );

      final bundle = BlocStoreBundle.create(config: config);
      final cubit1 = bundle.itemCubit('user-1');
      final cubit2 = bundle.itemCubit('user-2');

      expect(identical(cubit1, cubit2), isFalse);

      bundle.close();
    });

    test('should expose store from bundle', () {
      final config = BlocStoreConfig<TestUser, String>(
        name: 'users',
        store: mockStore,
        autoLoad: false,
      );

      final bundle = BlocStoreBundle.create(config: config);

      expect(bundle.store, equals(mockStore));

      bundle.close();
    });
  });

  group('BlocStoreBundle with Bloc', () {
    late MockNexusStore<TestUser, String> mockStore;
    late StreamController<List<TestUser>> streamController;

    setUp(() {
      mockStore = MockNexusStore<TestUser, String>();
      streamController = StreamController<List<TestUser>>.broadcast();

      when(() => mockStore.watchAll(query: any(named: 'query')))
          .thenAnswer((_) => streamController.stream);
    });

    tearDown(() async {
      await streamController.close();
    });

    test('should auto-load with Bloc when useBloc and autoLoad are true',
        () async {
      final config = BlocStoreConfig<TestUser, String>(
        name: 'users',
        store: mockStore,
        useBloc: true,
        autoLoad: true,
      );

      final bundle = BlocStoreBundle.create(config: config);

      // Wait for the auto-load to trigger
      await Future<void>.delayed(Duration.zero);

      // Verify watchAll was called due to autoLoad via LoadAll event
      verify(() => mockStore.watchAll(query: any(named: 'query'))).called(1);

      bundle.close();
    });

    test('should close bloc on bundle close', () async {
      final config = BlocStoreConfig<TestUser, String>(
        name: 'users',
        store: mockStore,
        useBloc: true,
        autoLoad: false,
      );

      final bundle = BlocStoreBundle.create(config: config);
      final bloc = bundle.listBloc;

      await bundle.close();

      expect(bloc.isClosed, isTrue);
    });
  });
}
