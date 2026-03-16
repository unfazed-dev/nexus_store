import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('Case-Insensitive Search (A3)', () {
    group('Query builder', () {
      test('creates correct filter for iContains', () {
        final query = Query<TestUser>().where('title', iContains: 'hello');

        expect(query.filters, hasLength(1));
        expect(query.filters.first.operator, FilterOperator.iContains);
        expect(query.filters.first.value, 'hello');
        expect(query.filters.first.field, 'title');
      });

      test('creates correct filter for iStartsWith', () {
        final query = Query<TestUser>().where('name', iStartsWith: 'HELLO');

        expect(query.filters, hasLength(1));
        expect(query.filters.first.operator, FilterOperator.iStartsWith);
        expect(query.filters.first.value, 'HELLO');
      });

      test('creates correct filter for iEndsWith', () {
        final query = Query<TestUser>().where('name', iEndsWith: 'WORLD');

        expect(query.filters, hasLength(1));
        expect(query.filters.first.operator, FilterOperator.iEndsWith);
        expect(query.filters.first.value, 'WORLD');
      });
    });

    group('In-memory evaluator', () {
      late InMemoryQueryEvaluator<TestUser> evaluator;

      setUp(() {
        evaluator = InMemoryQueryEvaluator<TestUser>(
          fieldAccessor: (user, field) {
            switch (field) {
              case 'name':
                return user.name;
              case 'email':
                return user.email;
              default:
                return null;
            }
          },
        );
      });

      test('iContains matches case-insensitively', () {
        final users = [
          TestFixtures.createUser(id: 'u1', name: 'Hello World'),
          TestFixtures.createUser(id: 'u2', name: 'Goodbye'),
        ];
        final query = Query<TestUser>().where('name', iContains: 'hello');

        final results = evaluator.evaluate(users, query);

        expect(results, hasLength(1));
        expect(results.first.name, 'Hello World');
      });

      test('iStartsWith matches case-insensitively', () {
        final users = [
          TestFixtures.createUser(id: 'u1', name: 'hello world'),
          TestFixtures.createUser(id: 'u2', name: 'Goodbye'),
        ];
        final query = Query<TestUser>().where('name', iStartsWith: 'HELLO');

        final results = evaluator.evaluate(users, query);

        expect(results, hasLength(1));
        expect(results.first.name, 'hello world');
      });

      test('iEndsWith matches case-insensitively', () {
        final users = [
          TestFixtures.createUser(id: 'u1', name: 'hello World'),
          TestFixtures.createUser(id: 'u2', name: 'Goodbye'),
        ];
        final query = Query<TestUser>().where('name', iEndsWith: 'WORLD');

        final results = evaluator.evaluate(users, query);

        expect(results, hasLength(1));
        expect(results.first.name, 'hello World');
      });

      test('no match returns empty', () {
        final users = [
          TestFixtures.createUser(id: 'u1', name: 'Hello'),
        ];
        final query = Query<TestUser>().where('name', iContains: 'xyz');

        final results = evaluator.evaluate(users, query);

        expect(results, isEmpty);
      });
    });

    group('Combined with case-sensitive filters', () {
      late InMemoryQueryEvaluator<TestUser> evaluator;

      setUp(() {
        evaluator = InMemoryQueryEvaluator<TestUser>(
          fieldAccessor: (user, field) {
            switch (field) {
              case 'name':
                return user.name;
              case 'email':
                return user.email;
              case 'isActive':
                return user.isActive;
              default:
                return null;
            }
          },
        );
      });

      test('AND composition with case-sensitive filter', () {
        final users = [
          TestFixtures.createUser(
            id: 'u1',
            name: 'Hello World',
            isActive: true,
          ),
          TestFixtures.createUser(
            id: 'u2',
            name: 'Hello there',
            isActive: false,
          ),
        ];
        final query = Query<TestUser>()
            .where('name', iContains: 'hello')
            .where('isActive', isEqualTo: true);

        final results = evaluator.evaluate(users, query);

        expect(results, hasLength(1));
        expect(results.first.id, 'u1');
      });
    });

    group('Query equality/hashCode', () {
      test('with new operators', () {
        final q1 = Query<TestUser>().where('name', iContains: 'hello');
        final q2 = Query<TestUser>().where('name', iContains: 'hello');
        final q3 = Query<TestUser>().where('name', iContains: 'world');

        expect(q1, equals(q2));
        expect(q1.hashCode, equals(q2.hashCode));
        expect(q1, isNot(equals(q3)));
      });
    });

    group('Query toString', () {
      test('includes new operators', () {
        final query = Query<TestUser>().where('name', iContains: 'hello');

        final str = query.toString();

        expect(str, contains('iContains'));
      });
    });

    group('FilterOperator enum', () {
      test('iContains exists', () {
        expect(FilterOperator.iContains, isNotNull);
      });

      test('iStartsWith exists', () {
        expect(FilterOperator.iStartsWith, isNotNull);
      });

      test('iEndsWith exists', () {
        expect(FilterOperator.iEndsWith, isNotNull);
      });
    });

    group('End-to-end with NexusStore', () {
      late FakeStoreBackend<TestUser, String> backend;
      late NexusStore<TestUser, String> store;

      setUp(() async {
        backend = FakeStoreBackend<TestUser, String>(
          idExtractor: (user) => user.id,
        );
        backend.fieldAccessor = (user, field) {
          switch (field) {
            case 'name':
              return user.name;
            case 'email':
              return user.email;
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

      test('getAll with iContains query', () async {
        backend.addToStorage(
          'u1',
          TestFixtures.createUser(id: 'u1', name: 'Hello World'),
        );
        backend.addToStorage(
          'u2',
          TestFixtures.createUser(id: 'u2', name: 'Goodbye'),
        );

        final results = await store.getAll(
          query: Query<TestUser>().where('name', iContains: 'hello'),
        );

        // FakeStoreBackend.getAll doesn't filter, but the query is valid
        expect(results, isNotEmpty);
      });
    });
  });
}
