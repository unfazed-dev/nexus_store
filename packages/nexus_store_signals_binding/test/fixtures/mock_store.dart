import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';

import 'test_entities.dart';

/// Mock NexusStore for testing signals binding.
class MockNexusStore<T, ID> extends Mock implements NexusStore<T, ID> {}

/// Fake Query for mocktail fallback.
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
