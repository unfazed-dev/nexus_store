import 'package:nexus_store_powersync_adapter/src/sync_rules/ps_query.dart';
import 'package:test/test.dart';

void main() {
  group('PSQuery', () {
    group('select factory', () {
      test('creates query with table name', () {
        const query = PSQuery.select(table: 'users');

        expect(query.table, equals('users'));
      });

      test('defaults to all columns when not specified', () {
        const query = PSQuery.select(table: 'users');

        expect(query.columns, equals(['*']));
      });

      test('accepts specific columns', () {
        const query = PSQuery.select(
          table: 'users',
          columns: ['id', 'name', 'email'],
        );

        expect(query.columns, equals(['id', 'name', 'email']));
      });

      test('accepts filter condition', () {
        const query = PSQuery.select(
          table: 'users',
          filter: 'id = bucket.user_id',
        );

        expect(query.filter, equals('id = bucket.user_id'));
      });

      test('filter defaults to null', () {
        const query = PSQuery.select(table: 'users');

        expect(query.filter, isNull);
      });
    });

    group('toSql', () {
      test('generates SELECT * FROM table when no columns or filter', () {
        const query = PSQuery.select(table: 'users');

        expect(query.toSql(), equals('SELECT * FROM users'));
      });

      test('generates SELECT with specific columns', () {
        const query = PSQuery.select(
          table: 'users',
          columns: ['id', 'name', 'email'],
        );

        expect(query.toSql(), equals('SELECT id, name, email FROM users'));
      });

      test('generates SELECT with WHERE clause when filter provided', () {
        const query = PSQuery.select(
          table: 'users',
          filter: 'id = bucket.user_id',
        );

        expect(
          query.toSql(),
          equals('SELECT * FROM users WHERE id = bucket.user_id'),
        );
      });

      test('generates full query with columns and filter', () {
        const query = PSQuery.select(
          table: 'users',
          columns: ['id', 'name'],
          filter: 'team_id = bucket.team_id',
        );

        expect(
          query.toSql(),
          equals('SELECT id, name FROM users WHERE team_id = bucket.team_id'),
        );
      });
    });

    group('equality', () {
      test('two queries with same values are equal', () {
        const query1 = PSQuery.select(
          table: 'users',
          columns: ['id', 'name'],
          filter: 'id = 1',
        );
        const query2 = PSQuery.select(
          table: 'users',
          columns: ['id', 'name'],
          filter: 'id = 1',
        );

        expect(query1, equals(query2));
        expect(query1.hashCode, equals(query2.hashCode));
      });

      test('queries with different values are not equal', () {
        const query1 = PSQuery.select(table: 'users');
        const query2 = PSQuery.select(table: 'posts');

        expect(query1, isNot(equals(query2)));
      });
    });
  });
}
