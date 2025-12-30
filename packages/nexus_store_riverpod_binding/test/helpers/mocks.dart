import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';

import 'test_fixtures.dart';

/// Mock NexusStore for testing Riverpod providers.
class MockNexusStore<T, ID> extends Mock implements NexusStore<T, ID> {}

/// Fallback values for mocktail.
class FakeQuery<T> extends Fake implements Query<T> {}

/// Fake TestUser for mocktail fallback.
class FakeTestUser extends Fake implements TestUser {}

/// Register fallback values for mocktail.
void registerFallbackValues() {
  registerFallbackValue(FakeQuery<dynamic>());
  registerFallbackValue(FakeTestUser());
  registerFallbackValue(<TestUser>[]);
  registerFallbackValue(<String>[]);
  registerFallbackValue(<String>{});
}

/// A test helper for creating mock stores with common setups.
class MockStoreHelper {
  MockStoreHelper._();

  /// Creates a mock store that returns the given users from watchAll.
  static MockNexusStore<TestUser, String> withUsers(List<TestUser> users) {
    final store = MockNexusStore<TestUser, String>();
    when(() => store.watchAll(query: any(named: 'query')))
        .thenAnswer((_) => Stream.value(users));
    when(() => store.dispose()).thenAnswer((_) async {});
    return store;
  }

  /// Creates a mock store that returns a stream of user lists.
  static MockNexusStore<TestUser, String> withUserStream(
    Stream<List<TestUser>> stream,
  ) {
    final store = MockNexusStore<TestUser, String>();
    when(() => store.watchAll(query: any(named: 'query')))
        .thenAnswer((_) => stream);
    when(() => store.dispose()).thenAnswer((_) async {});
    return store;
  }

  /// Creates a mock store that returns a specific user by ID.
  static MockNexusStore<TestUser, String> withUser(
    String id,
    TestUser? user,
  ) {
    final store = MockNexusStore<TestUser, String>();
    when(() => store.watch(id)).thenAnswer((_) => Stream.value(user));
    when(() => store.dispose()).thenAnswer((_) async {});
    return store;
  }

  /// Creates a mock store that emits an error.
  static MockNexusStore<TestUser, String> withError(Object error) {
    final store = MockNexusStore<TestUser, String>();
    when(() => store.watchAll(query: any(named: 'query')))
        .thenAnswer((_) => Stream.error(error));
    when(() => store.dispose()).thenAnswer((_) async {});
    return store;
  }

  /// Creates a mock store with a controllable stream.
  static (MockNexusStore<TestUser, String>, StreamController<List<TestUser>>)
      withController() {
    final store = MockNexusStore<TestUser, String>();
    final controller = StreamController<List<TestUser>>.broadcast();
    when(() => store.watchAll(query: any(named: 'query')))
        .thenAnswer((_) => controller.stream);
    when(() => store.dispose()).thenAnswer((_) async {
      await controller.close();
    });
    return (store, controller);
  }
}
