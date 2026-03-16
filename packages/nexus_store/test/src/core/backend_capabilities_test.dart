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

    test('equality detects single-field differences', () {
      const base = BackendCapabilities(
        supportsOffline: true,
        supportsRealtime: true,
        supportsTransactions: true,
        supportsPagination: true,
        supportsFieldOperations: true,
      );

      // Each single-field difference should break equality
      expect(
        base,
        isNot(equals(const BackendCapabilities(
          supportsOffline: false,
          supportsRealtime: true,
          supportsTransactions: true,
          supportsPagination: true,
          supportsFieldOperations: true,
        ))),
      );
      expect(
        base,
        isNot(equals(const BackendCapabilities(
          supportsOffline: true,
          supportsRealtime: false,
          supportsTransactions: true,
          supportsPagination: true,
          supportsFieldOperations: true,
        ))),
      );
      expect(
        base,
        isNot(equals(const BackendCapabilities(
          supportsOffline: true,
          supportsRealtime: true,
          supportsTransactions: false,
          supportsPagination: true,
          supportsFieldOperations: true,
        ))),
      );
      expect(
        base,
        isNot(equals(const BackendCapabilities(
          supportsOffline: true,
          supportsRealtime: true,
          supportsTransactions: true,
          supportsPagination: false,
          supportsFieldOperations: true,
        ))),
      );
      expect(
        base,
        isNot(equals(const BackendCapabilities(
          supportsOffline: true,
          supportsRealtime: true,
          supportsTransactions: true,
          supportsPagination: true,
          supportsFieldOperations: false,
        ))),
      );
    });

    test('equality with non-BackendCapabilities object', () {
      const capabilities = BackendCapabilities(supportsOffline: true);
      expect(capabilities, isNot(equals('not a capabilities object')));
      expect(capabilities, isNot(equals(42)));
      expect(capabilities, isNot(equals(null)));
    });

    test('identical objects are equal', () {
      const capabilities = BackendCapabilities(supportsOffline: true);
      expect(identical(capabilities, capabilities), isTrue);
      expect(capabilities, equals(capabilities));
    });

    test('equal objects have equal hashCodes', () {
      const a = BackendCapabilities(
        supportsOffline: true,
        supportsRealtime: true,
        supportsTransactions: false,
        supportsPagination: true,
        supportsFieldOperations: false,
      );
      const b = BackendCapabilities(
        supportsOffline: true,
        supportsRealtime: true,
        supportsTransactions: false,
        supportsPagination: true,
        supportsFieldOperations: false,
      );
      expect(a.hashCode, equals(b.hashCode));
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

    test('toString shows all fields', () {
      const allTrue = BackendCapabilities(
        supportsOffline: true,
        supportsRealtime: true,
        supportsTransactions: true,
        supportsPagination: true,
        supportsFieldOperations: true,
      );
      final str = allTrue.toString();
      expect(str, contains('supportsOffline: true'));
      expect(str, contains('supportsRealtime: true'));
      expect(str, contains('supportsTransactions: true'));
      expect(str, contains('supportsPagination: true'));
      expect(str, contains('supportsFieldOperations: true'));

      const allFalse = BackendCapabilities();
      final str2 = allFalse.toString();
      expect(str2, contains('supportsOffline: false'));
      expect(str2, contains('supportsRealtime: false'));
      expect(str2, contains('supportsTransactions: false'));
      expect(str2, contains('supportsPagination: false'));
      expect(str2, contains('supportsFieldOperations: false'));
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
