// ignore_for_file: unreachable_from_main

import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_drift_adapter/nexus_store_drift_adapter.dart';
import 'package:test/test.dart';

class TestModel {
  TestModel({required this.id, required this.name, this.age});

  final String id;
  final String name;
  final int? age;
}

void main() {
  group('DriftQueryTranslator', () {
    late DriftQueryTranslator<TestModel> translator;

    setUp(() {
      translator = DriftQueryTranslator<TestModel>();
    });

    group('toSelectSql', () {
      test('returns SELECT * FROM table with no query', () {
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: null,
        );

        expect(sql, 'SELECT * FROM users');
        expect(args, isEmpty);
      });

      test('returns SELECT * FROM table with empty query', () {
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: const Query<TestModel>(),
        );

        expect(sql, 'SELECT * FROM users');
        expect(args, isEmpty);
      });
    });

    group('filter translation', () {
      test('translates equals filter', () {
        final query = const Query<TestModel>().where('name', isEqualTo: 'John');

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users WHERE name = ?');
        expect(args, ['John']);
      });

      test('translates notEquals filter', () {
        final query =
            const Query<TestModel>().where('name', isNotEqualTo: 'John');

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users WHERE name != ?');
        expect(args, ['John']);
      });

      test('translates lessThan filter', () {
        final query = const Query<TestModel>().where('age', isLessThan: 30);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users WHERE age < ?');
        expect(args, [30]);
      });

      test('translates lessThanOrEquals filter', () {
        final query =
            const Query<TestModel>().where('age', isLessThanOrEqualTo: 30);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users WHERE age <= ?');
        expect(args, [30]);
      });

      test('translates greaterThan filter', () {
        final query = const Query<TestModel>().where('age', isGreaterThan: 18);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users WHERE age > ?');
        expect(args, [18]);
      });

      test('translates greaterThanOrEquals filter', () {
        final query =
            const Query<TestModel>().where('age', isGreaterThanOrEqualTo: 18);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users WHERE age >= ?');
        expect(args, [18]);
      });

      test('translates whereIn filter', () {
        final query = const Query<TestModel>()
            .where('name', whereIn: ['John', 'Jane', 'Bob']);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users WHERE name IN (?, ?, ?)');
        expect(args, ['John', 'Jane', 'Bob']);
      });

      test('translates whereNotIn filter', () {
        final query =
            const Query<TestModel>().where('name', whereNotIn: ['Admin']);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users WHERE name NOT IN (?)');
        expect(args, ['Admin']);
      });

      test('translates isNull filter', () {
        final query = const Query<TestModel>().where('age', isNull: true);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users WHERE age IS NULL');
        expect(args, isEmpty);
      });

      test('translates isNotNull filter', () {
        final query = const Query<TestModel>().where('age', isNull: false);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users WHERE age IS NOT NULL');
        expect(args, isEmpty);
      });

      test('translates contains filter', () {
        // Contains operator is created via QueryFilter directly
        final query = const Query<TestModel>().copyWith(
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

        expect(sql, 'SELECT * FROM users WHERE name LIKE ?');
        expect(args, ['%john%']);
      });

      test('translates startsWith filter', () {
        final query = const Query<TestModel>().copyWith(
          filters: [
            const QueryFilter(
              field: 'name',
              operator: FilterOperator.startsWith,
              value: 'John',
            ),
          ],
        );

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users WHERE name LIKE ?');
        expect(args, ['John%']);
      });

      test('translates endsWith filter', () {
        final query = const Query<TestModel>().copyWith(
          filters: [
            const QueryFilter(
              field: 'name',
              operator: FilterOperator.endsWith,
              value: 'son',
            ),
          ],
        );

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users WHERE name LIKE ?');
        expect(args, ['%son']);
      });

      test('translates multiple filters with AND', () {
        final query = const Query<TestModel>()
            .where('name', isEqualTo: 'John')
            .where('age', isGreaterThan: 18);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users WHERE name = ? AND age > ?');
        expect(args, ['John', 18]);
      });

      test('handles empty whereIn as always false', () {
        final query =
            const Query<TestModel>().where('name', whereIn: <String>[]);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users WHERE 1 = 0');
        expect(args, isEmpty);
      });

      test('handles empty whereNotIn as always true', () {
        final query =
            const Query<TestModel>().where('name', whereNotIn: <String>[]);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users WHERE 1 = 1');
        expect(args, isEmpty);
      });
    });

    group('orderBy translation', () {
      test('translates ascending orderBy', () {
        final query = const Query<TestModel>().orderByField('name');

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users ORDER BY name ASC');
        expect(args, isEmpty);
      });

      test('translates descending orderBy', () {
        final query =
            const Query<TestModel>().orderByField('name', descending: true);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users ORDER BY name DESC');
        expect(args, isEmpty);
      });

      test('translates multiple orderBy', () {
        final query = const Query<TestModel>()
            .orderByField('name')
            .orderByField('age', descending: true);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users ORDER BY name ASC, age DESC');
        expect(args, isEmpty);
      });
    });

    group('pagination translation', () {
      test('translates limit', () {
        final query = const Query<TestModel>().limitTo(10);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users LIMIT 10');
        expect(args, isEmpty);
      });

      test('translates offset', () {
        final query = const Query<TestModel>().offsetBy(5);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users OFFSET 5');
        expect(args, isEmpty);
      });

      test('translates limit and offset together', () {
        final query = const Query<TestModel>().limitTo(10).offsetBy(20);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users LIMIT 10 OFFSET 20');
        expect(args, isEmpty);
      });
    });

    group('complex queries', () {
      test('translates filter + orderBy + pagination', () {
        final query = const Query<TestModel>()
            .where('age', isGreaterThan: 18)
            .orderByField('name')
            .limitTo(10)
            .offsetBy(5);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(
          sql,
          'SELECT * FROM users WHERE age > ? '
          'ORDER BY name ASC LIMIT 10 OFFSET 5',
        );
        expect(args, [18]);
      });
    });

    group('toDeleteSql', () {
      test('generates DELETE with WHERE clause', () {
        final query = const Query<TestModel>().where('name', isEqualTo: 'John');

        final (sql, args) = translator.toDeleteSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'DELETE FROM users WHERE name = ?');
        expect(args, ['John']);
      });

      test('generates DELETE without WHERE for empty filters', () {
        final (sql, args) = translator.toDeleteSql(
          tableName: 'users',
          query: const Query<TestModel>(),
        );

        expect(sql, 'DELETE FROM users');
        expect(args, isEmpty);
      });
    });

    group('field mapping', () {
      test('maps field names using fieldMapping', () {
        final translatorWithMapping = DriftQueryTranslator<TestModel>(
          fieldMapping: {'name': 'user_name', 'age': 'user_age'},
        );

        final query = const Query<TestModel>()
            .where('name', isEqualTo: 'John')
            .orderByField('age', descending: true);

        final (sql, args) = translatorWithMapping.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(
          sql,
          'SELECT * FROM users WHERE user_name = ? ORDER BY user_age DESC',
        );
        expect(args, ['John']);
      });
    });

    group('QueryTranslator interface', () {
      test('translate returns query string without table name', () {
        final query = const Query<TestModel>()
            .where('name', isEqualTo: 'John')
            .orderByField('name')
            .limitTo(10);

        final result = translator.translate(query);

        expect(result, 'WHERE name = ? ORDER BY name ASC LIMIT 10');
      });

      test('translate with offset only', () {
        final query = const Query<TestModel>().offsetBy(10);

        final result = translator.translate(query);

        expect(result, 'OFFSET 10');
      });

      test('translate with limit and offset', () {
        final query = const Query<TestModel>().limitTo(5).offsetBy(10);

        final result = translator.translate(query);

        expect(result, 'LIMIT 5 OFFSET 10');
      });

      test('translate with orderBy and offset', () {
        final query =
            const Query<TestModel>().orderByField('name').offsetBy(5);

        final result = translator.translate(query);

        expect(result, 'ORDER BY name ASC OFFSET 5');
      });

      test('translate empty query returns empty string', () {
        const query = Query<TestModel>();

        final result = translator.translate(query);

        expect(result, '');
      });

      test('translateFilters returns WHERE clause content', () {
        final result = translator.translateFilters([
          const QueryFilter(
            field: 'name',
            operator: FilterOperator.equals,
            value: 'John',
          ),
        ]);

        expect(result, 'name = ?');
      });

      test('translateOrderBy returns ORDER BY clause content', () {
        final result = translator.translateOrderBy([
          const QueryOrderBy(field: 'name'),
          const QueryOrderBy(field: 'age', descending: true),
        ]);

        expect(result, 'name ASC, age DESC');
      });
    });

    group('DriftQueryExtension', () {
      test('toSql generates SELECT statement from Query', () {
        final query = const Query<TestModel>().where('name', isEqualTo: 'John');

        final (sql, args) = query.toSql('users');

        expect(sql, 'SELECT * FROM users WHERE name = ?');
        expect(args, ['John']);
      });

      test('toSql with fieldMapping', () {
        final query = const Query<TestModel>()
            .where('name', isEqualTo: 'John')
            .orderByField('age');

        final (sql, args) = query.toSql(
          'users',
          fieldMapping: {'name': 'user_name', 'age': 'user_age'},
        );

        expect(
          sql,
          'SELECT * FROM users WHERE user_name = ? ORDER BY user_age ASC',
        );
        expect(args, ['John']);
      });

      test('toSql with empty query', () {
        const query = Query<TestModel>();

        final (sql, args) = query.toSql('users');

        expect(sql, 'SELECT * FROM users');
        expect(args, isEmpty);
      });
    });

    group('arrayContains and arrayContainsAny', () {
      test('translates arrayContains filter', () {
        final query =
            const Query<TestModel>().where('tags', arrayContains: 'admin');

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users WHERE tags LIKE ?');
        expect(args, ['%admin%']);
      });

      test('translates arrayContainsAny filter', () {
        final query = const Query<TestModel>()
            .where('tags', arrayContainsAny: ['admin', 'user']);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(
          sql,
          contains('EXISTS (SELECT 1 FROM json_each(tags)'),
        );
        expect(args, ['admin', 'user']);
      });

      test('handles empty arrayContainsAny as always false', () {
        final query =
            const Query<TestModel>().where('tags', arrayContainsAny: []);

        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, 'SELECT * FROM users WHERE 1 = 0');
        expect(args, isEmpty);
      });
    });
  });
}
