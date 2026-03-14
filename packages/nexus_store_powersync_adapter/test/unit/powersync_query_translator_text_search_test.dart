import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';
import 'package:test/test.dart';

void main() {
  late PowerSyncQueryTranslator<Map<String, dynamic>> translator;

  setUp(() {
    translator = PowerSyncQueryTranslator<Map<String, dynamic>>();
  });

  group('PowerSyncQueryTranslator text search SQL', () {
    test('contains generates LIKE with surrounding wildcards', () {
      final query =
          const Query<Map<String, dynamic>>().where('name', contains: 'john');

      final (sql, args) = translator.toSelectSql(
        tableName: 'users',
        query: query,
      );

      expect(sql, 'SELECT * FROM users WHERE name LIKE ?');
      expect(args, ['%john%']);
    });

    test('startsWith generates LIKE with trailing wildcard', () {
      final query =
          const Query<Map<String, dynamic>>().where('name', startsWith: 'Jo');

      final (sql, args) = translator.toSelectSql(
        tableName: 'users',
        query: query,
      );

      expect(sql, 'SELECT * FROM users WHERE name LIKE ?');
      expect(args, ['Jo%']);
    });

    test('endsWith generates LIKE with leading wildcard', () {
      final query = const Query<Map<String, dynamic>>()
          .where('email', endsWith: '@example.com');

      final (sql, args) = translator.toSelectSql(
        tableName: 'users',
        query: query,
      );

      expect(sql, 'SELECT * FROM users WHERE email LIKE ?');
      expect(args, ['%@example.com']);
    });

    test('text search combined with equality filter', () {
      final query = const Query<Map<String, dynamic>>()
          .where('status', isEqualTo: 'active')
          .where('name', contains: 'john');

      final (sql, args) = translator.toSelectSql(
        tableName: 'users',
        query: query,
      );

      expect(sql, 'SELECT * FROM users WHERE status = ? AND name LIKE ?');
      expect(args, ['active', '%john%']);
    });
  });
}
