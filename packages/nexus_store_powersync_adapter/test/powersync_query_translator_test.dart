import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_powersync_adapter/src/powersync_query_translator.dart';
import 'package:test/test.dart';

void main() {
  group('PowerSyncQueryTranslator', () {
    late PowerSyncQueryTranslator<Map<String, dynamic>> translator;

    setUp(() {
      translator = PowerSyncQueryTranslator<Map<String, dynamic>>();
    });

    group('toSelectSql', () {
      test('generates basic SELECT without query', () {
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: null,
        );

        expect(sql, equals('SELECT * FROM users'));
        expect(args, isEmpty);
      });

      test('generates SELECT with empty query', () {
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: const Query<Map<String, dynamic>>(),
        );

        expect(sql, equals('SELECT * FROM users'));
        expect(args, isEmpty);
      });

      test('generates SELECT with single equals filter', () {
        final query = const Query<Map<String, dynamic>>()
            .where('name', isEqualTo: 'John');

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, equals('SELECT * FROM users WHERE name = ?'));
        expect(args, equals(['John']));
      });

      test('generates SELECT with multiple filters', () {
        final query = const Query<Map<String, dynamic>>()
            .where('name', isEqualTo: 'John')
            .where('age', isGreaterThan: 18);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, equals('SELECT * FROM users WHERE name = ? AND age > ?'));
        expect(args, equals(['John', 18]));
      });

      test('generates SELECT with ORDER BY', () {
        final query = const Query<Map<String, dynamic>>()
            .orderByField('name');

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, equals('SELECT * FROM users ORDER BY name ASC'));
        expect(args, isEmpty);
      });

      test('generates SELECT with ORDER BY descending', () {
        final query = const Query<Map<String, dynamic>>()
            .orderByField('createdAt', descending: true);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, equals('SELECT * FROM users ORDER BY createdAt DESC'));
        expect(args, isEmpty);
      });

      test('generates SELECT with multiple ORDER BY', () {
        final query = const Query<Map<String, dynamic>>()
            .orderByField('lastName')
            .orderByField('firstName');

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(
          sql,
          equals('SELECT * FROM users ORDER BY lastName ASC, firstName ASC'),
        );
        expect(args, isEmpty);
      });

      test('generates SELECT with LIMIT', () {
        final query = const Query<Map<String, dynamic>>().limitTo(10);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, equals('SELECT * FROM users LIMIT 10'));
        expect(args, isEmpty);
      });

      test('generates SELECT with OFFSET', () {
        final query = const Query<Map<String, dynamic>>().offsetBy(20);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, equals('SELECT * FROM users OFFSET 20'));
        expect(args, isEmpty);
      });

      test('generates SELECT with all clauses', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', isEqualTo: 'active')
            .orderByField('name')
            .limitTo(10)
            .offsetBy(5);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(
          sql,
          equals(
            'SELECT * FROM users WHERE status = ? '
            'ORDER BY name ASC LIMIT 10 OFFSET 5',
          ),
        );
        expect(args, equals(['active']));
      });
    });

    group('filter operators', () {
      test('equals generates = ?', () {
        final query = const Query<Map<String, dynamic>>()
            .where('name', isEqualTo: 'John');

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('name = ?'));
        expect(args, contains('John'));
      });

      test('notEquals generates != ?', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', isNotEqualTo: 'deleted');

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('status != ?'));
        expect(args, contains('deleted'));
      });

      test('lessThan generates < ?', () {
        final query = const Query<Map<String, dynamic>>()
            .where('age', isLessThan: 18);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('age < ?'));
        expect(args, contains(18));
      });

      test('lessThanOrEquals generates <= ?', () {
        final query = const Query<Map<String, dynamic>>()
            .where('age', isLessThanOrEqualTo: 18);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('age <= ?'));
        expect(args, contains(18));
      });

      test('greaterThan generates > ?', () {
        final query = const Query<Map<String, dynamic>>()
            .where('age', isGreaterThan: 18);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('age > ?'));
        expect(args, contains(18));
      });

      test('greaterThanOrEquals generates >= ?', () {
        final query = const Query<Map<String, dynamic>>()
            .where('age', isGreaterThanOrEqualTo: 18);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('age >= ?'));
        expect(args, contains(18));
      });

      test('whereIn generates IN (?, ?)', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', whereIn: ['active', 'pending']);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('status IN (?, ?)'));
        expect(args, equals(['active', 'pending']));
      });

      test('whereIn with empty list generates always-false condition', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', whereIn: <String>[]);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('1 = 0'));
        expect(args, isEmpty);
      });

      test('whereNotIn generates NOT IN (?, ?)', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', whereNotIn: ['deleted', 'archived']);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('status NOT IN (?, ?)'));
        expect(args, equals(['deleted', 'archived']));
      });

      test('whereNotIn with empty list generates always-true condition', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', whereNotIn: <String>[]);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('1 = 1'));
        expect(args, isEmpty);
      });

      test('isNull generates IS NULL', () {
        final query = const Query<Map<String, dynamic>>()
            .where('deletedAt', isNull: true);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('deletedAt IS NULL'));
      });

      test('isNull false generates IS NOT NULL', () {
        final query = const Query<Map<String, dynamic>>()
            .where('deletedAt', isNull: false);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('deletedAt IS NOT NULL'));
      });
    });

    group('string operators', () {
      test('contains generates LIKE %value%', () {
        final query = const Query<Map<String, dynamic>>()
            .where('name', arrayContains: 'john');

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('LIKE ?'));
        expect(args, contains('%john%'));
      });
    });

    group('toDeleteSql', () {
      test('generates DELETE with WHERE clause', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', isEqualTo: 'deleted');

        final (sql, args) = translator.toDeleteSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, equals('DELETE FROM users WHERE status = ?'));
        expect(args, equals(['deleted']));
      });

      test('generates DELETE without WHERE for empty query', () {
        final (sql, args) = translator.toDeleteSql(
          tableName: 'users',
          query: const Query<Map<String, dynamic>>(),
        );

        expect(sql, equals('DELETE FROM users'));
        expect(args, isEmpty);
      });

      test('generates DELETE with multiple conditions', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', isEqualTo: 'deleted')
            .where('age', isLessThan: 18);

        final (sql, args) = translator.toDeleteSql(
          tableName: 'users',
          query: query,
        );

        expect(
          sql,
          equals('DELETE FROM users WHERE status = ? AND age < ?'),
        );
        expect(args, equals(['deleted', 18]));
      });
    });

    group('field mapping', () {
      test('applies field name mapping', () {
        final translatorWithMapping =
            PowerSyncQueryTranslator<Map<String, dynamic>>(
          fieldMapping: {'userName': 'user_name', 'createdAt': 'created_at'},
        );

        final query = const Query<Map<String, dynamic>>()
            .where('userName', isEqualTo: 'john')
            .orderByField('createdAt');

        final (sql, args) = translatorWithMapping.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('user_name = ?'));
        expect(sql, contains('ORDER BY created_at ASC'));
        expect(args, equals(['john']));
      });

      test('uses original name when no mapping exists', () {
        final translatorWithMapping =
            PowerSyncQueryTranslator<Map<String, dynamic>>(
          fieldMapping: {'userName': 'user_name'},
        );

        final query = const Query<Map<String, dynamic>>()
            .where('status', isEqualTo: 'active');

        final (sql, args) = translatorWithMapping.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('status = ?'));
        expect(args, equals(['active']));
      });
    });

    group('QueryTranslator interface', () {
      test('translate returns SQL string', () {
        final query = const Query<Map<String, dynamic>>()
            .where('name', isEqualTo: 'John');

        final result = translator.translate(query);

        expect(result, isA<String>());
        expect(result, contains('WHERE'));
      });

      test('translateFilters returns WHERE clause parts', () {
        final filters = [
          const QueryFilter(
            field: 'name',
            operator: FilterOperator.equals,
            value: 'John',
          ),
        ];

        final result = translator.translateFilters(filters);

        expect(result, contains('name = ?'));
      });

      test('translateOrderBy returns ORDER BY clause', () {
        final orderBy = [
          const QueryOrderBy(field: 'name'),
          const QueryOrderBy(field: 'age', descending: true),
        ];

        final result = translator.translateOrderBy(orderBy);

        expect(result, equals('name ASC, age DESC'));
      });
    });
  });
}
