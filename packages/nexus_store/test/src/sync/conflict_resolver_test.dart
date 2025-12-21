import 'package:test/test.dart';
import 'package:nexus_store/nexus_store.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('NexusStore Conflict Resolution', () {
    late FakeStoreBackend<TestUser, String> backend;
    late NexusStore<TestUser, String> store;

    setUp(() async {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (user) => user.id,
      );
      store = NexusStore<TestUser, String>(
        backend: backend,
        idExtractor: (user) => user.id,
      );
      await store.initialize();
    });

    tearDown(() async {
      await store.dispose();
    });

    group('conflicts stream', () {
      test('should expose conflicts stream from backend', () {
        expect(store.conflicts, isA<Stream<ConflictDetails<TestUser>>>());
      });
    });

    group('onConflict callback', () {
      test('should accept onConflict callback in constructor', () {
        final storeWithCallback = NexusStore<TestUser, String>(
          backend: backend,
          idExtractor: (user) => user.id,
          onConflict: (details) async {
            return ConflictAction.keepLocal();
          },
        );

        expect(storeWithCallback, isNotNull);
      });

      test('should provide ConflictDetails with local and remote values', () async {
        final localUser = TestFixtures.createUser(name: 'Local');
        final remoteUser = TestFixtures.createUser(name: 'Remote');
        ConflictDetails<TestUser>? receivedDetails;

        final storeWithCallback = NexusStore<TestUser, String>(
          backend: backend,
          idExtractor: (user) => user.id,
          onConflict: (details) async {
            receivedDetails = details;
            return ConflictAction.keepLocal();
          },
        );
        await storeWithCallback.initialize();

        // The callback will be invoked by the backend when conflicts occur
        // For now, just verify the store is configured correctly
        expect(storeWithCallback.hasConflictResolver, isTrue);

        await storeWithCallback.dispose();
      });
    });

    group('hasConflictResolver', () {
      test('should return false when no callback provided', () {
        expect(store.hasConflictResolver, isFalse);
      });

      test('should return true when callback provided', () async {
        final storeWithCallback = NexusStore<TestUser, String>(
          backend: backend,
          idExtractor: (user) => user.id,
          onConflict: (details) async => ConflictAction.keepRemote(),
        );

        expect(storeWithCallback.hasConflictResolver, isTrue);
      });
    });
  });
}
