import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';
import 'package:test/test.dart';

void main() {
  late PowerSyncQueryTranslator<String> translator;

  setUp(() {
    translator = PowerSyncQueryTranslator<String>();
  });

  group('PowerSyncQueryTranslator convenience query SQL', () {
    group('whereBetween SQL generation', () {
      test('should generate >= AND <= WHERE clause', () {
        final query = const Query<String>().whereBetween('age', 18, 65);
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, equals('SELECT * FROM users WHERE age >= ? AND age <= ?'));
        expect(args, equals([18, 65]));
      });

      test('should combine with other filters', () {
        final query = const Query<String>()
            .where('status', isEqualTo: 'active')
            .whereBetween('price', 10.0, 99.99);
        final (sql, args) = translator.toSelectSql(
          tableName: 'products',
          query: query,
        );

        expect(
          sql,
          equals(
            'SELECT * FROM products'
            ' WHERE status = ? AND price >= ? AND price <= ?',
          ),
        );
        expect(args, equals(['active', 10.0, 99.99]));
      });
    });

    group('whereNull/whereNotNull SQL generation', () {
      test('should generate IS NULL clause', () {
        final query = const Query<String>().whereNull('deletedAt');
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, equals('SELECT * FROM users WHERE deletedAt IS NULL'));
        expect(args, isEmpty);
      });

      test('should generate IS NOT NULL clause', () {
        final query = const Query<String>().whereNotNull('email');
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, equals('SELECT * FROM users WHERE email IS NOT NULL'));
        expect(args, isEmpty);
      });
    });

    group('select SQL generation', () {
      test('should generate SELECT with specific fields', () {
        final query = const Query<String>().select({'name', 'email'});
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        // Fields should be sorted for deterministic output
        expect(sql, equals('SELECT email, name FROM users'));
        expect(args, isEmpty);
      });

      test('should generate SELECT with fields and WHERE clause', () {
        final query = const Query<String>()
            .where('status', isEqualTo: 'active')
            .select({'name', 'email'});
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(
          sql,
          equals('SELECT email, name FROM users WHERE status = ?'),
        );
        expect(args, equals(['active']));
      });

      test('should fall back to SELECT * when select fields are empty', () {
        final (sql, _) = translator.toSelectSql(
          tableName: 'users',
          query: const Query<String>(),
        );

        expect(sql, equals('SELECT * FROM users'));
      });

      test('should respect field mapping in select', () {
        final mappedTranslator = PowerSyncQueryTranslator<String>(
          fieldMapping: {'userName': 'user_name', 'emailAddr': 'email_address'},
        );
        final query = const Query<String>().select({'userName', 'emailAddr'});
        final (sql, _) = mappedTranslator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, contains('email_address'));
        expect(sql, contains('user_name'));
      });
    });

    group('distinct SQL generation', () {
      test('should generate SELECT DISTINCT *', () {
        final query = const Query<String>().distinct();
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, equals('SELECT DISTINCT * FROM users'));
        expect(args, isEmpty);
      });

      test('should generate SELECT DISTINCT with specific fields', () {
        final query =
            const Query<String>().select({'name', 'email'}).distinct();
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, equals('SELECT DISTINCT email, name FROM users'));
        expect(args, isEmpty);
      });

      test('should combine DISTINCT with WHERE clause', () {
        final query = const Query<String>()
            .where('status', isEqualTo: 'active')
            .distinct();
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(
          sql,
          equals('SELECT DISTINCT * FROM users WHERE status = ?'),
        );
        expect(args, equals(['active']));
      });

      test('should combine DISTINCT, select, WHERE, ORDER BY, LIMIT', () {
        final query = const Query<String>()
            .where('status', isEqualTo: 'active')
            .select({'name', 'email'})
            .distinct()
            .orderByField('name')
            .limitTo(10);
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(
          sql,
          equals(
            'SELECT DISTINCT email, name FROM users'
            ' WHERE status = ? ORDER BY name ASC LIMIT 10',
          ),
        );
        expect(args, equals(['active']));
      });
    });

    group('count with distinct', () {
      test('should not affect COUNT SQL (COUNT always uses *)', () {
        final query = const Query<String>()
            .where('status', isEqualTo: 'active')
            .distinct();
        final (sql, args) = translator.toCountSql(
          tableName: 'users',
          query: query,
        );

        expect(
          sql,
          equals('SELECT COUNT(*) AS count FROM users WHERE status = ?'),
        );
        expect(args, equals(['active']));
      });
    });
  });
}
