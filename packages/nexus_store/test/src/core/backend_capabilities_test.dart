import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';

void main() {
  group('BackendCapabilities', () {
    test('defaults all flags to false', () {
      const capabilities = BackendCapabilities();

      expect(capabilities.supportsOffline, isFalse);
      expect(capabilities.supportsRealtime, isFalse);
      expect(capabilities.supportsTransactions, isFalse);
      expect(capabilities.supportsPagination, isFalse);
      expect(capabilities.supportsFieldOperations, isFalse);
    });

    test('accepts custom flag values', () {
      const capabilities = BackendCapabilities(
        supportsOffline: true,
        supportsRealtime: true,
        supportsTransactions: false,
        supportsPagination: true,
        supportsFieldOperations: false,
      );

      expect(capabilities.supportsOffline, isTrue);
      expect(capabilities.supportsRealtime, isTrue);
      expect(capabilities.supportsTransactions, isFalse);
      expect(capabilities.supportsPagination, isTrue);
      expect(capabilities.supportsFieldOperations, isFalse);
    });

    test('implements value equality', () {
      const a = BackendCapabilities(
        supportsOffline: true,
        supportsRealtime: false,
      );
      const b = BackendCapabilities(
        supportsOffline: true,
        supportsRealtime: false,
      );
      const c = BackendCapabilities(
        supportsOffline: false,
        supportsRealtime: true,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('provides descriptive toString', () {
      const capabilities = BackendCapabilities(
        supportsOffline: true,
        supportsPagination: true,
      );

      final str = capabilities.toString();
      expect(str, contains('BackendCapabilities'));
      expect(str, contains('supportsOffline: true'));
      expect(str, contains('supportsPagination: true'));
    });
  });

  group('NexusStore.capabilities', () {
    test('delegates capability flags from backend', () {
      // FakeStoreBackend has: supportsFieldOperations=true,
      // supportsPagination=true, supportsTransactions=configurable (default true)
      // supportsOffline=false (from StoreBackendDefaults),
      // supportsRealtime=false (from StoreBackendDefaults)
      final backend = FakeStoreBackend<Map<String, dynamic>, String>(
        idExtractor: (item) => item['id'] as String,
      );
      final store = NexusStore<Map<String, dynamic>, String>(
        backend: backend,
      );

      final capabilities = store.capabilities;

      expect(capabilities.supportsOffline, isFalse);
      expect(capabilities.supportsRealtime, isFalse);
      expect(capabilities.supportsTransactions, isTrue);
      expect(capabilities.supportsPagination, isTrue);
      expect(capabilities.supportsFieldOperations, isTrue);
    });

    test('reflects backend with defaults (all false except overrides)', () {
      final backend = MockStoreBackend<String, int>();
      // MockStoreBackend with StoreBackendDefaults mixin — but it's a Mock,
      // so we need to use a minimal fake instead.
      final minimalBackend = _MinimalBackend();
      final store = NexusStore<String, int>(backend: minimalBackend);

      final capabilities = store.capabilities;

      expect(capabilities.supportsOffline, isFalse);
      expect(capabilities.supportsRealtime, isFalse);
      expect(capabilities.supportsTransactions, isFalse);
      expect(capabilities.supportsPagination, isFalse);
      expect(capabilities.supportsFieldOperations, isFalse);

      // Clean up unused mock
      backend.hashCode;
    });
  });
}

/// Minimal backend with all defaults for testing capability introspection.
class _MinimalBackend with StoreBackendDefaults<String, int> {
  @override
  String get name => 'MinimalBackend';

  @override
  Future<String?> get(int id) async => null;

  @override
  Future<List<String>> getAll({Query<String>? query}) async => [];

  @override
  Stream<String?> watch(int id) => const Stream.empty();

  @override
  Stream<List<String>> watchAll({Query<String>? query}) =>
      Stream.value(const []);

  @override
  Future<String> save(String item) async => item;

  @override
  Future<List<String>> saveAll(List<String> items) async => items;

  @override
  Future<bool> delete(int id) async => false;

  @override
  Future<int> deleteAll(List<int> ids) async => 0;

  @override
  Future<int> deleteWhere(Query<String> query) async => 0;
}
