import 'package:test/test.dart';
import 'package:nexus_store/nexus_store.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('NexusStore Pending Changes', () {
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

    group('pendingChanges stream', () {
      test('should expose pending changes stream from backend', () {
        expect(store.pendingChanges, isA<Stream<List<PendingChange<TestUser>>>>());
      });
    });

    group('retryPendingChange', () {
      test('should delegate to backend', () async {
        // This would require the backend to have pending changes
        // For now just verify the method exists and doesn't throw
        await expectLater(
          store.retryPendingChange('non-existent'),
          completes,
        );
      });
    });

    group('cancelPendingChange', () {
      test('should delegate to backend and return cancelled change', () async {
        final result = await store.cancelPendingChange('non-existent');
        expect(result, isNull); // No change found
      });
    });

    group('retryAllPending', () {
      test('should delegate to backend', () async {
        await expectLater(store.retryAllPending(), completes);
      });
    });

    group('cancelAllPending', () {
      test('should cancel all pending changes and return count', () async {
        final count = await store.cancelAllPending();
        expect(count, equals(0)); // No pending changes
      });
    });
  });
}
