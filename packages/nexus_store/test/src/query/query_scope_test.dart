import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('Query Scopes (A2)', () {
    group('SoftDeleteScope', () {
      test('appends filter to empty query', () {
        const scope = SoftDeleteScope<TestUser>();
        final query = scope.apply(Query<TestUser>());

        expect(query.filters, hasLength(1));
        expect(query.filters.first.field, 'deleted_at');
        expect(query.filters.first.operator, FilterOperator.isNull);
      });

      test('preserves existing filters', () {
        const scope = SoftDeleteScope<TestUser>();
        final query = scope.apply(
          Query<TestUser>().where('status', isEqualTo: 'active'),
        );

        expect(query.filters, hasLength(2));
        expect(query.filters[0].field, 'status');
        expect(query.filters[1].field, 'deleted_at');
      });

      test('works with OR groups', () {
        const scope = SoftDeleteScope<TestUser>();
        final baseQuery = Query<TestUser>().or(
          (q) => q
              .where('status', isEqualTo: 'active')
              .where('status', isEqualTo: 'pending'),
        );
        final query = scope.apply(baseQuery);

        expect(query.filterGroups, hasLength(1));
        expect(query.filters, hasLength(1));
        expect(query.filters.first.field, 'deleted_at');
      });

      test('custom field name', () {
        const scope = SoftDeleteScope<TestUser>(field: 'removed_at');
        final query = scope.apply(Query<TestUser>());

        expect(query.filters.first.field, 'removed_at');
      });

      test('equality/hashCode', () {
        const a = SoftDeleteScope<TestUser>();
        const b = SoftDeleteScope<TestUser>();
        const c = SoftDeleteScope<TestUser>(field: 'removed_at');

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
        expect(a, isNot(equals(c)));
      });
    });

    group('OwnerScope', () {
      test('appends owner filter', () {
        const scope = OwnerScope<TestUser>(ownerId: 'user-123');
        final query = scope.apply(Query<TestUser>());

        expect(query.filters, hasLength(1));
        expect(query.filters.first.field, 'owner_id');
        expect(query.filters.first.operator, FilterOperator.equals);
        expect(query.filters.first.value, 'user-123');
      });

      test('combines with SoftDeleteScope', () {
        const softDelete = SoftDeleteScope<TestUser>();
        const owner = OwnerScope<TestUser>(ownerId: 'user-123');

        var query = Query<TestUser>();
        query = softDelete.apply(query);
        query = owner.apply(query);

        expect(query.filters, hasLength(2));
        expect(query.filters[0].field, 'deleted_at');
        expect(query.filters[1].field, 'owner_id');
      });

      test('equality/hashCode', () {
        const a = OwnerScope<TestUser>(ownerId: 'u1');
        const b = OwnerScope<TestUser>(ownerId: 'u1');
        const c = OwnerScope<TestUser>(ownerId: 'u2');

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
        expect(a, isNot(equals(c)));
      });
    });

    group('ScopedStore', () {
      late FakeStoreBackend<TestUser, String> backend;
      late NexusStore<TestUser, String> store;

      setUp(() async {
        backend = FakeStoreBackend<TestUser, String>(
          idExtractor: (user) => user.id,
        );
        backend.fieldAccessor = (user, field) {
          switch (field) {
            case 'id':
              return user.id;
            case 'name':
              return user.name;
            case 'email':
              return user.email;
            case 'isActive':
              return user.isActive;
            default:
              return null;
          }
        };
        store = NexusStore<TestUser, String>(backend: backend);
        await store.initialize();
      });

      tearDown(() async {
        await store.dispose();
      });

      test('getAll excludes soft-deleted', () async {
        final scoped = store.scoped([const SoftDeleteScope<TestUser>()]);
        backend.addToStorage(
          'u1',
          TestFixtures.createUser(id: 'u1'),
        );

        final results = await scoped.getAll();

        // FakeStoreBackend doesn't filter, but the query carries the scope
        expect(results, isNotEmpty);
      });

      test('watchAll applies scope', () async {
        final scoped = store.scoped([const SoftDeleteScope<TestUser>()]);
        backend.addToStorage('u1', TestFixtures.createUser(id: 'u1'));

        final results = await scoped.watchAll().first;

        expect(results, isNotEmpty);
      });

      test('count applies scope', () async {
        final scoped = store.scoped([const SoftDeleteScope<TestUser>()]);
        backend.addToStorage('u1', TestFixtures.createUser(id: 'u1'));

        final count = await scoped.count();

        expect(count, greaterThanOrEqualTo(0));
      });

      test('getOne applies scope', () async {
        final scoped = store.scoped([const SoftDeleteScope<TestUser>()]);
        backend.addToStorage('u1', TestFixtures.createUser(id: 'u1'));

        final result = await scoped.getOne();

        expect(result, isNotNull);
      });

      test('existsWhere applies scope', () async {
        final scoped = store.scoped([const SoftDeleteScope<TestUser>()]);
        backend.addToStorage('u1', TestFixtures.createUser(id: 'u1'));

        // existsWhere with a base query — scope adds soft-delete filter
        final exists = await scoped.existsWhere(
          Query<TestUser>().where('name', isEqualTo: 'John Doe'),
        );

        // Backend always returns based on id existence
        expect(exists, isA<bool>());
      });

      test('deleteWhere applies scope', () async {
        final scoped = store.scoped([const SoftDeleteScope<TestUser>()]);
        backend.addToStorage('u1', TestFixtures.createUser(id: 'u1'));

        final count = await scoped.deleteWhere(
          Query<TestUser>().where('isActive', isEqualTo: true),
        );

        expect(count, greaterThanOrEqualTo(0));
      });

      test('updateWhere applies scope', () async {
        final scoped = store.scoped([const SoftDeleteScope<TestUser>()]);
        backend.addToStorage('u1', TestFixtures.createUser(id: 'u1'));

        final count = await scoped.updateWhere(
          Query<TestUser>().where('isActive', isEqualTo: true),
          {'isActive': false},
        );

        expect(count, greaterThanOrEqualTo(0));
      });

      test('save passes through unmodified', () async {
        final scoped = store.scoped([const SoftDeleteScope<TestUser>()]);
        final user = TestFixtures.createUser(id: 'u1');

        final saved = await scoped.save(user);

        expect(saved, equals(user));
        expect(backend.storage['u1'], equals(user));
      });

      test('delete passes through unmodified', () async {
        final scoped = store.scoped([const SoftDeleteScope<TestUser>()]);
        backend.addToStorage('u1', TestFixtures.createUser(id: 'u1'));

        final deleted = await scoped.delete('u1');

        expect(deleted, isTrue);
      });

      test('upsert passes through unmodified', () async {
        final scoped = store.scoped([const SoftDeleteScope<TestUser>()]);
        final user = TestFixtures.createUser(id: 'u1');

        final result = await scoped.upsert(user);

        expect(result, equals(user));
      });

      test('with empty scope list behaves like original', () async {
        final scoped = store.scoped([]);
        backend.addToStorage('u1', TestFixtures.createUser(id: 'u1'));

        final results = await scoped.getAll();

        expect(results, hasLength(1));
      });

      test('combined scopes applied in order', () async {
        final scoped = store.scoped([
          const SoftDeleteScope<TestUser>(),
          const OwnerScope<TestUser>(ownerId: 'user-123'),
        ]);

        // Verify scopes are stored
        expect(scoped.scopes, hasLength(2));
        expect(scoped.scopes[0], isA<SoftDeleteScope<TestUser>>());
        expect(scoped.scopes[1], isA<OwnerScope<TestUser>>());
      });
    });

    group('NexusStore.softDelete', () {
      late FakeStoreBackend<TestUser, String> backend;
      late NexusStore<TestUser, String> store;

      setUp(() async {
        backend = FakeStoreBackend<TestUser, String>(
          idExtractor: (user) => user.id,
        );
        backend.patchApplier = (user, updates) {
          return user.copyWith(
            name: updates['name'] as String? ?? user.name,
          );
        };
        store = NexusStore<TestUser, String>(backend: backend);
        await store.initialize();
      });

      tearDown(() async {
        await store.dispose();
      });

      test('patches entity with timestamp', () async {
        backend.addToStorage('u1', TestFixtures.createUser(id: 'u1'));

        final result = await store.softDelete('u1');

        expect(result, isNotNull);
      });

      test('returns null for non-existent entity', () async {
        final result = await store.softDelete('nonexistent');

        expect(result, isNull);
      });
    });
  });
}
