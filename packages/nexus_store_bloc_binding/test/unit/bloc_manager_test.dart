import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_bloc_binding/nexus_store_bloc_binding.dart';
import 'package:test/test.dart';

import '../fixtures/mock_store.dart';
import '../fixtures/test_entities.dart';

class TestPost {
  const TestPost({required this.id, required this.title, required this.userId});

  final String id;
  final String title;
  final String userId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestPost &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          userId == other.userId;

  @override
  int get hashCode => Object.hash(id, title, userId);
}

class MockPostStore extends Mock implements NexusStore<TestPost, String> {}

void main() {
  setUpAll(() {
    registerFallbackValues();
    registerFallbackValue(FakeQuery<TestPost>());
  });

  group('BlocManager', () {
    late MockNexusStore<TestUser, String> userStore;
    late MockPostStore postStore;
    late StreamController<List<TestUser>> userStreamController;
    late StreamController<List<TestPost>> postStreamController;

    setUp(() {
      userStore = MockNexusStore<TestUser, String>();
      postStore = MockPostStore();
      userStreamController = StreamController<List<TestUser>>.broadcast();
      postStreamController = StreamController<List<TestPost>>.broadcast();

      when(() => userStore.watchAll(query: any(named: 'query')))
          .thenAnswer((_) => userStreamController.stream);
      when(() => postStore.watchAll(query: any(named: 'query')))
          .thenAnswer((_) => postStreamController.stream);
    });

    tearDown(() async {
      await userStreamController.close();
      await postStreamController.close();
    });

    test('should create manager with configs', () {
      final manager = BlocManager([
        BlocStoreConfig<TestUser, String>(
          name: 'users',
          store: userStore,
          autoLoad: false,
        ),
        BlocStoreConfig<TestPost, String>(
          name: 'posts',
          store: postStore,
          autoLoad: false,
        ),
      ]);

      expect(manager.storeNames, containsAll(['users', 'posts']));

      manager.dispose();
    });

    test('should throw on duplicate store names', () {
      expect(
        () => BlocManager([
          BlocStoreConfig<TestUser, String>(
            name: 'users',
            store: userStore,
            autoLoad: false,
          ),
          BlocStoreConfig<TestUser, String>(
            name: 'users',
            store: userStore,
            autoLoad: false,
          ),
        ]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should get bundle by name', () {
      final manager = BlocManager([
        BlocStoreConfig<TestUser, String>(
          name: 'users',
          store: userStore,
          autoLoad: false,
        ),
      ]);

      final bundle = manager.getBundle('users');
      expect(bundle, isNotNull);
      expect(bundle.name, equals('users'));

      manager.dispose();
    });

    test('should throw when getting non-existent bundle', () {
      final manager = BlocManager([
        BlocStoreConfig<TestUser, String>(
          name: 'users',
          store: userStore,
          autoLoad: false,
        ),
      ]);

      expect(
        () => manager.getBundle('posts'),
        throwsA(isA<UnsupportedError>()),
      );

      manager.dispose();
    });

    test('should get all bundles', () {
      final manager = BlocManager([
        BlocStoreConfig<TestUser, String>(
          name: 'users',
          store: userStore,
          autoLoad: false,
        ),
        BlocStoreConfig<TestPost, String>(
          name: 'posts',
          store: postStore,
          autoLoad: false,
        ),
      ]);

      final bundles = manager.allBundles;
      expect(bundles.length, equals(2));
      expect(bundles.map((b) => b.name), containsAll(['users', 'posts']));

      manager.dispose();
    });

    test('should get list cubit by name', () {
      final manager = BlocManager([
        BlocStoreConfig<TestUser, String>(
          name: 'users',
          store: userStore,
          autoLoad: false,
        ),
      ]);

      final cubit = manager.getListCubit('users');
      expect(cubit, isA<NexusStoreCubit<dynamic, dynamic>>());

      manager.dispose();
    });

    test('should get list bloc by name', () {
      final manager = BlocManager([
        BlocStoreConfig<TestUser, String>(
          name: 'users',
          store: userStore,
          useBloc: true,
          autoLoad: false,
        ),
      ]);

      final bloc = manager.getListBloc('users');
      expect(bloc, isA<NexusStoreBloc<dynamic, dynamic>>());

      manager.dispose();
    });

    test('should refresh all stores', () async {
      final manager = BlocManager([
        BlocStoreConfig<TestUser, String>(
          name: 'users',
          store: userStore,
          autoLoad: false,
        ),
        BlocStoreConfig<TestPost, String>(
          name: 'posts',
          store: postStore,
          autoLoad: false,
        ),
      ]);

      await manager.refreshAll();

      // Each store should have load called
      verify(() => userStore.watchAll(query: any(named: 'query'))).called(1);
      verify(() => postStore.watchAll(query: any(named: 'query'))).called(1);

      manager.dispose();
    });

    test('should track isAnyLoading state', () async {
      final manager = BlocManager([
        BlocStoreConfig<TestUser, String>(
          name: 'users',
          store: userStore,
          autoLoad: false,
        ),
      ]);

      // Initially not loading
      expect(manager.isAnyLoading, isFalse);

      // Trigger load
      manager.getListCubit('users');
      await manager.refreshAll();

      // Should be loading now
      expect(manager.isAnyLoading, isTrue);

      // Emit data to complete loading
      userStreamController.add([TestFixtures.sampleUser]);

      // Allow state to propagate
      await Future<void>.delayed(Duration.zero);

      expect(manager.isAnyLoading, isFalse);

      manager.dispose();
    });

    test('should track first error', () async {
      final manager = BlocManager([
        BlocStoreConfig<TestUser, String>(
          name: 'users',
          store: userStore,
          autoLoad: false,
        ),
      ]);

      expect(manager.firstError, isNull);

      // Trigger load then error
      await manager.refreshAll();
      userStreamController.addError(Exception('Test error'));

      await Future<void>.delayed(Duration.zero);

      expect(manager.firstError, isA<Exception>());

      manager.dispose();
    });

    test('should dispose all bundles', () async {
      final manager = BlocManager([
        BlocStoreConfig<TestUser, String>(
          name: 'users',
          store: userStore,
          autoLoad: false,
        ),
        BlocStoreConfig<TestPost, String>(
          name: 'posts',
          store: postStore,
          autoLoad: false,
        ),
      ]);

      // Access bundles to create them
      manager.getBundle('users');
      manager.getBundle('posts');

      manager.dispose();

      // After dispose, getting bundles should throw
      expect(() => manager.getBundle('users'), throwsA(isA<UnsupportedError>()));
    });

    test('should cache bundles', () {
      final manager = BlocManager([
        BlocStoreConfig<TestUser, String>(
          name: 'users',
          store: userStore,
          autoLoad: false,
        ),
      ]);

      final bundle1 = manager.getBundle('users');
      final bundle2 = manager.getBundle('users');

      expect(identical(bundle1, bundle2), isTrue);

      manager.dispose();
    });

    test('should provide isAnyLoadingStream', () async {
      final manager = BlocManager([
        BlocStoreConfig<TestUser, String>(
          name: 'users',
          store: userStore,
          autoLoad: false,
        ),
      ]);

      expect(manager.isAnyLoadingStream, isA<Stream<bool>>());

      final loadingStates = <bool>[];
      final sub = manager.isAnyLoadingStream.listen(loadingStates.add);

      await manager.refreshAll();
      await Future<void>.delayed(Duration.zero);

      userStreamController.add([]);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      manager.dispose();

      // Should have recorded loading state changes
      expect(loadingStates, isNotEmpty);
    });

    test('should provide errorStream', () async {
      final manager = BlocManager([
        BlocStoreConfig<TestUser, String>(
          name: 'users',
          store: userStore,
          autoLoad: false,
        ),
      ]);

      expect(manager.errorStream, isA<Stream<Object?>>());

      final errors = <Object?>[];
      final sub = manager.errorStream.listen(errors.add);

      await manager.refreshAll();
      userStreamController.addError(Exception('Test error'));
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      manager.dispose();

      expect(errors, isNotEmpty);
    });
  });
}
