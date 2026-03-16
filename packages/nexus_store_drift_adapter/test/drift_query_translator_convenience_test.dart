import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_drift_adapter/nexus_store_drift_adapter.dart';
import 'package:test/test.dart';

void main() {
  late DriftQueryTranslator<String> translator;

  setUp(() {
    translator = DriftQueryTranslator<String>();
  });

  group('DriftQueryTranslator convenience query SQL', () {
    group('whereBetween SQL generation', () {
      test('should generate >= AND <= WHERE clause', () {
        final query = const Query<String>().whereBetween('age', 18, 65);
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(
          sql,
          equals('SELECT * FROM users WHERE age >= ? AND age <= ?'),
        );
        expect(args, equals([18, 65]));
      });
    });

    group('whereNull/whereNotNull SQL generation', () {
      test('should generate IS NULL clause', () {
        final query = const Query<String>().whereNull('deletedAt');
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(
          sql,
          equals('SELECT * FROM users WHERE deletedAt IS NULL'),
        );
        expect(args, isEmpty);
      });

      test('should generate IS NOT NULL clause', () {
        final query = const Query<String>().whereNotNull('email');
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(
          sql,
          equals('SELECT * FROM users WHERE email IS NOT NULL'),
        );
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

        expect(sql, equals('SELECT email, name FROM users'));
        expect(args, isEmpty);
      });

      test('should fall back to SELECT * when no select fields', () {
        final (sql, _) = translator.toSelectSql(
          tableName: 'users',
          query: const Query<String>(),
        );

        expect(sql, equals('SELECT * FROM users'));
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

      test('should generate SELECT DISTINCT with fields', () {
        final query =
            const Query<String>().select({'name', 'email'}).distinct();
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(sql, equals('SELECT DISTINCT email, name FROM users'));
        expect(args, isEmpty);
      });

      test('should combine all clauses', () {
        final query = const Query<String>()
            .where('status', isEqualTo: 'active')
            .select({'name'})
            .distinct()
            .orderByField('name')
            .limitTo(5)
            .offsetBy(10);
        final (sql, args) = translator.toSelectSql(
          tableName: 'users',
          query: query,
        );

        expect(
          sql,
          equals(
            'SELECT DISTINCT name FROM users WHERE status = ?'
            ' ORDER BY name ASC LIMIT 5 OFFSET 10',
          ),
        );
        expect(args, equals(['active']));
      });
    });
  });
}
