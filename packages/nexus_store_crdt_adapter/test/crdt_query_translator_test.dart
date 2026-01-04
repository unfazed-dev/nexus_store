import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_crdt_adapter/src/crdt_query_translator.dart';
import 'package:test/test.dart';

void main() {
  group('CrdtQueryTranslator', () {
    late CrdtQueryTranslator<Map<String, dynamic>> translator;

    setUp(() {
      translator = CrdtQueryTranslator<Map<String, dynamic>>();
    });

    group('toSelectSql', () {
      test('generates SELECT with tombstone filter when no query provided', () {
        final (sql, args) = translator.toSelectSql(tableName: 'users');

        expect(sql, equals('SELECT * FROM users WHERE is_deleted = 0'));
        expect(args, isEmpty);
      });

      test('includes tombstone filter with user filters', () {
        final query = const Query<Map<String, dynamic>>()
            .where('name', isEqualTo: 'John');
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(
          sql,
          equals('SELECT * FROM users WHERE is_deleted = 0 AND name = ?'),
        );
        expect(args, equals(['John']));
      });

      test('can disable tombstone filter when explicitly requested', () {
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          includeTombstoneFilter: false,
        );

        expect(sql, equals('SELECT * FROM users'));
        expect(args, isEmpty);
      });

      test('handles equals filter', () {
        final query =
            const Query<Map<String, dynamic>>().where('age', isEqualTo: 25);
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('age = ?'));
        expect(args, contains(25));
      });

      test('handles notEquals filter', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', isNotEqualTo: 'deleted');
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('status != ?'));
        expect(args, contains('deleted'));
      });

      test('handles lessThan filter', () {
        final query =
            const Query<Map<String, dynamic>>().where('age', isLessThan: 30);
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('age < ?'));
        expect(args, contains(30));
      });

      test('handles lessThanOrEquals filter', () {
        final query = const Query<Map<String, dynamic>>()
            .where('age', isLessThanOrEqualTo: 30);
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('age <= ?'));
        expect(args, contains(30));
      });

      test('handles greaterThan filter', () {
        final query =
            const Query<Map<String, dynamic>>().where('age', isGreaterThan: 18);
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('age > ?'));
        expect(args, contains(18));
      });

      test('handles greaterThanOrEquals filter', () {
        final query = const Query<Map<String, dynamic>>()
            .where('age', isGreaterThanOrEqualTo: 18);
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('age >= ?'));
        expect(args, contains(18));
      });

      test('handles whereIn filter', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', whereIn: ['active', 'pending']);
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('status IN (?, ?)'));
        expect(args, containsAll(['active', 'pending']));
      });

      test('handles empty whereIn filter', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', whereIn: <String>[]);
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('1 = 0'));
      });

      test('handles whereNotIn filter', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', whereNotIn: ['deleted', 'banned']);
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('status NOT IN (?, ?)'));
        expect(args, containsAll(['deleted', 'banned']));
      });

      test('handles isNull filter', () {
        final query = const Query<Map<String, dynamic>>()
            .where('deleted_at', isNull: true);
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('deleted_at IS NULL'));
      });

      test('handles isNotNull filter', () {
        final query =
            const Query<Map<String, dynamic>>().where('email', isNull: false);
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('email IS NOT NULL'));
      });

      test('handles contains filter via QueryFilter', () {
        final query = const Query<Map<String, dynamic>>().copyWith(
          filters: [
            const QueryFilter(
              field: 'name',
              operator: FilterOperator.contains,
              value: 'john',
            ),
          ],
        );
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('name LIKE ?'));
        expect(args, contains('%john%'));
      });

      test('handles startsWith filter via QueryFilter', () {
        final query = const Query<Map<String, dynamic>>().copyWith(
          filters: [
            const QueryFilter(
              field: 'name',
              operator: FilterOperator.startsWith,
              value: 'J',
            ),
          ],
        );
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('name LIKE ?'));
        expect(args, contains('J%'));
      });

      test('handles endsWith filter via QueryFilter', () {
        final query = const Query<Map<String, dynamic>>().copyWith(
          filters: [
            const QueryFilter(
              field: 'email',
              operator: FilterOperator.endsWith,
              value: '@example.com',
            ),
          ],
        );
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('email LIKE ?'));
        expect(args, contains('%@example.com'));
      });

      test('handles arrayContains filter via QueryFilter', () {
        final query = const Query<Map<String, dynamic>>().copyWith(
          filters: [
            const QueryFilter(
              field: 'tags',
              operator: FilterOperator.arrayContains,
              value: 'dart',
            ),
          ],
        );
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('tags LIKE ?'));
        expect(args, contains('%dart%'));
      });

      test('handles arrayContainsAny filter via QueryFilter', () {
        final query = const Query<Map<String, dynamic>>().copyWith(
          filters: [
            const QueryFilter(
              field: 'tags',
              operator: FilterOperator.arrayContainsAny,
              value: ['dart', 'flutter'],
            ),
          ],
        );
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(
          sql,
          contains(
            'EXISTS (SELECT 1 FROM json_each(tags) WHERE value IN (?, ?))',
          ),
        );
        expect(args, containsAll(['dart', 'flutter']));
      });

      test('handles arrayContainsAny with empty list returns always false', () {
        final query = const Query<Map<String, dynamic>>().copyWith(
          filters: [
            const QueryFilter(
              field: 'tags',
              operator: FilterOperator.arrayContainsAny,
              value: <String>[],
            ),
          ],
        );
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('1 = 0'));
      });

      test('handles arrayContainsAny with non-list value returns always false',
          () {
        final query = const Query<Map<String, dynamic>>().copyWith(
          filters: [
            const QueryFilter(
              field: 'tags',
              operator: FilterOperator.arrayContainsAny,
              value: 'not-a-list',
            ),
          ],
        );
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('1 = 0'));
      });

      test('handles multiple filters with AND', () {
        final query = const Query<Map<String, dynamic>>()
            .where('age', isGreaterThan: 18)
            .where('status', isEqualTo: 'active');
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('age > ?'));
        expect(sql, contains('AND'));
        expect(sql, contains('status = ?'));
        expect(args, equals([18, 'active']));
      });

      test('handles ORDER BY ascending', () {
        final query = const Query<Map<String, dynamic>>().orderByField('name');
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('ORDER BY name ASC'));
      });

      test('handles ORDER BY descending', () {
        final query = const Query<Map<String, dynamic>>()
            .orderByField('created_at', descending: true);
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('ORDER BY created_at DESC'));
      });

      test('handles multiple ORDER BY clauses', () {
        final query = const Query<Map<String, dynamic>>()
            .orderByField('last_name')
            .orderByField('first_name');
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('ORDER BY last_name ASC, first_name ASC'));
      });

      test('handles LIMIT', () {
        final query = const Query<Map<String, dynamic>>().limitTo(10);
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('LIMIT 10'));
      });

      test('handles OFFSET', () {
        final query = const Query<Map<String, dynamic>>().offsetBy(20);
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('OFFSET 20'));
      });

      test('handles LIMIT and OFFSET together', () {
        final query =
            const Query<Map<String, dynamic>>().limitTo(10).offsetBy(20);
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('LIMIT 10'));
        expect(sql, contains('OFFSET 20'));
      });

      test('generates complete query with all clauses', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', isEqualTo: 'active')
            .orderByField('created_at', descending: true)
            .limitTo(10)
            .offsetBy(0);
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(
          sql,
          equals(
            'SELECT * FROM users WHERE is_deleted = 0 AND status = ? '
            'ORDER BY created_at DESC LIMIT 10 OFFSET 0',
          ),
        );
        expect(args, equals(['active']));
      });
    });

    group('toDeleteSql', () {
      test('generates DELETE without tombstone filter', () {
        final query =
            const Query<Map<String, dynamic>>().where('id', isEqualTo: '123');
        final (sql, args) = translator.toDeleteSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, equals('DELETE FROM users WHERE id = ?'));
        expect(args, equals(['123']));
      });

      test('handles multiple filters in DELETE', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', isEqualTo: 'inactive')
            .where('age', isLessThan: 18);
        final (sql, args) = translator.toDeleteSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('DELETE FROM users WHERE'));
        expect(sql, contains('status = ?'));
        expect(sql, contains('AND'));
        expect(sql, contains('age < ?'));
      });
    });

    group('field mapping', () {
      test('maps field names to column names', () {
        final mappedTranslator = CrdtQueryTranslator<Map<String, dynamic>>(
          fieldMapping: {
            'userName': 'user_name',
            'createdAt': 'created_at',
          },
        );
        final query = const Query<Map<String, dynamic>>()
            .where('userName', isEqualTo: 'john')
            .orderByField('createdAt', descending: true);
        final (sql, args) = mappedTranslator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('user_name = ?'));
        expect(sql, contains('ORDER BY created_at DESC'));
      });
    });

    group('QueryTranslator interface', () {
      test('translate returns WHERE and ORDER BY clauses', () {
        final query = const Query<Map<String, dynamic>>()
            .where('name', isEqualTo: 'John')
            .orderByField('age');

        final result = translator.translate(query);

        expect(result, contains('WHERE'));
        expect(result, contains('ORDER BY'));
      });

      test('translate includes LIMIT clause when limit is set', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', isEqualTo: 'active')
            .limitTo(25);

        final result = translator.translate(query);

        expect(result, contains('WHERE'));
        expect(result, contains('LIMIT 25'));
      });

      test('translate includes OFFSET clause when offset is set', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', isEqualTo: 'active')
            .offsetBy(50);

        final result = translator.translate(query);

        expect(result, contains('WHERE'));
        expect(result, contains('OFFSET 50'));
      });

      test('translate includes both LIMIT and OFFSET when both are set', () {
        final query = const Query<Map<String, dynamic>>()
            .orderByField('created_at', descending: true)
            .limitTo(10)
            .offsetBy(20);

        final result = translator.translate(query);

        expect(result, contains('ORDER BY created_at DESC'));
        expect(result, contains('LIMIT 10'));
        expect(result, contains('OFFSET 20'));
      });

      test('translateFilters returns WHERE clause conditions', () {
        final query = const Query<Map<String, dynamic>>()
            .where('name', isEqualTo: 'John')
            .where('age', isGreaterThan: 18);

        final result = translator.translateFilters(query.filters);

        expect(result, contains('name = ?'));
        expect(result, contains('age > ?'));
      });

      test('translateOrderBy returns ORDER BY clause', () {
        final query = const Query<Map<String, dynamic>>()
            .orderByField('name')
            .orderByField('age', descending: true);

        final result = translator.translateOrderBy(query.orderBy);

        expect(result, equals('name ASC, age DESC'));
      });
    });

    group('CrdtQueryExtension', () {
      test('toCrdtSql generates SQL with tombstone filter by default', () {
        final query = const Query<Map<String, dynamic>>()
            .where('name', isEqualTo: 'Alice');

        final (sql, args) = query.toCrdtSql('users');

        expect(sql, contains('SELECT * FROM users'));
        expect(sql, contains('is_deleted = 0'));
        expect(sql, contains('name = ?'));
        expect(args, equals(['Alice']));
      });

      test('toCrdtSql can disable tombstone filter', () {
        final query =
            const Query<Map<String, dynamic>>().where('age', isGreaterThan: 18);

        final (sql, args) = query.toCrdtSql(
          'users',
          includeTombstoneFilter: false,
        );

        expect(sql, equals('SELECT * FROM users WHERE age > ?'));
        expect(sql, isNot(contains('is_deleted')));
        expect(args, equals([18]));
      });

      test('toCrdtSql applies field mapping', () {
        final query = const Query<Map<String, dynamic>>()
            .where('userName', isEqualTo: 'john')
            .orderByField('createdAt');

        final (sql, args) = query.toCrdtSql(
          'users',
          fieldMapping: {'userName': 'user_name', 'createdAt': 'created_at'},
        );

        expect(sql, contains('user_name = ?'));
        expect(sql, contains('ORDER BY created_at ASC'));
        expect(args, equals(['john']));
      });
    });
  });
}
