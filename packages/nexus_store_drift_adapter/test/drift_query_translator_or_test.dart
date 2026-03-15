import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_drift_adapter/nexus_store_drift_adapter.dart';
import 'package:test/test.dart';

void main() {
  late DriftQueryTranslator<Map<String, dynamic>> translator;

  setUp(() {
    translator = DriftQueryTranslator<Map<String, dynamic>>();
  });

  group('DriftQueryTranslator OR logic', () {
    group('toSelectSql', () {
      test('generates OR clause for single OR group', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', isEqualTo: 'active')
            .or(
              (q) => q
                  .where('role', isEqualTo: 'admin')
                  .where('role', isEqualTo: 'superadmin'),
            );

        final (sql, args) =
            translator.toSelectSql(tableName: 'users', query: query);

        expect(
          sql,
          equals(
            'SELECT * FROM users WHERE status = ? AND (role = ? OR role = ?)',
          ),
        );
        expect(args, equals(['active', 'admin', 'superadmin']));
      });

      test('generates multiple OR groups', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', isEqualTo: 'active')
            .or(
              (q) => q
                  .where('role', isEqualTo: 'admin')
                  .where('role', isEqualTo: 'mod'),
            )
            .or(
              (q) => q
                  .where('tier', isEqualTo: 'premium')
                  .where('tier', isEqualTo: 'enterprise'),
            );

        final (sql, args) =
            translator.toSelectSql(tableName: 'users', query: query);

        expect(
          sql,
          equals(
            'SELECT * FROM users WHERE status = ? '
            'AND (role = ? OR role = ?) '
            'AND (tier = ? OR tier = ?)',
          ),
        );
        expect(
          args,
          equals(['active', 'admin', 'mod', 'premium', 'enterprise']),
        );
      });

      test('generates OR-only query (no top-level AND filters)', () {
        final query = const Query<Map<String, dynamic>>().or(
          (q) => q
              .where('status', isEqualTo: 'active')
              .where('status', isEqualTo: 'pending'),
        );

        final (sql, args) =
            translator.toSelectSql(tableName: 'users', query: query);

        expect(
          sql,
          equals('SELECT * FROM users WHERE (status = ? OR status = ?)'),
        );
        expect(args, equals(['active', 'pending']));
      });

      test('handles OR with different operators', () {
        final query = const Query<Map<String, dynamic>>().or(
          (q) => q.where('age', isGreaterThan: 65).where('age', isLessThan: 18),
        );

        final (sql, args) =
            translator.toSelectSql(tableName: 'users', query: query);

        expect(sql, equals('SELECT * FROM users WHERE (age > ? OR age < ?)'));
        expect(args, equals([65, 18]));
      });
    });

    group('toCountSql', () {
      test('generates COUNT with OR clause', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', isEqualTo: 'active')
            .or(
              (q) => q
                  .where('role', isEqualTo: 'admin')
                  .where('role', isEqualTo: 'superadmin'),
            );

        final (sql, args) =
            translator.toCountSql(tableName: 'users', query: query);

        expect(
          sql,
          equals(
            'SELECT COUNT(*) AS count FROM users '
            'WHERE status = ? AND (role = ? OR role = ?)',
          ),
        );
        expect(args, equals(['active', 'admin', 'superadmin']));
      });
    });

    group('toDeleteSql', () {
      test('generates DELETE with OR clause', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', isEqualTo: 'active')
            .or(
              (q) => q
                  .where('role', isEqualTo: 'admin')
                  .where('role', isEqualTo: 'superadmin'),
            );

        final (sql, args) =
            translator.toDeleteSql(tableName: 'users', query: query);

        expect(
          sql,
          equals(
            'DELETE FROM users WHERE status = ? AND (role = ? OR role = ?)',
          ),
        );
        expect(args, equals(['active', 'admin', 'superadmin']));
      });
    });

    group('fieldMapping with OR', () {
      test('applies field mapping to OR group conditions', () {
        final mappedTranslator = DriftQueryTranslator<Map<String, dynamic>>(
          fieldMapping: {'role': 'user_role'},
        );

        final query = const Query<Map<String, dynamic>>().or(
          (q) => q
              .where('role', isEqualTo: 'admin')
              .where('role', isEqualTo: 'superadmin'),
        );

        final (sql, args) =
            mappedTranslator.toSelectSql(tableName: 'users', query: query);

        expect(
          sql,
          equals(
            'SELECT * FROM users WHERE (user_role = ? OR user_role = ?)',
          ),
        );
        expect(args, equals(['admin', 'superadmin']));
      });
    });
  });
}
