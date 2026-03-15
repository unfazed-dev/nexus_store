import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('PowerSyncQueryTranslator.toUpdateWhereSql', () {
    late PowerSyncQueryTranslator<Map<String, dynamic>> translator;

    setUp(() {
      translator = PowerSyncQueryTranslator<Map<String, dynamic>>();
    });

    test('generates UPDATE SET with single field and WHERE clause', () {
      final query = const Query<Map<String, dynamic>>()
          .where('status', isEqualTo: 'active');
      final (sql, args) = translator.toUpdateWhereSql(
        tableName: 'users',
        query: query,
        updates: {'status': 'archived'},
      );

      expect(sql, equals('UPDATE users SET status = ? WHERE status = ?'));
      expect(args, equals(['archived', 'active']));
    });

    test('generates UPDATE SET with multiple fields', () {
      final query =
          const Query<Map<String, dynamic>>().where('id', isEqualTo: '123');
      final (sql, args) = translator.toUpdateWhereSql(
        tableName: 'users',
        query: query,
        updates: {'name': 'New Name', 'age': 30},
      );

      expect(sql, contains('UPDATE users SET'));
      expect(sql, contains('name = ?'));
      expect(sql, contains('age = ?'));
      expect(sql, contains('WHERE id = ?'));
      expect(args, contains('New Name'));
      expect(args, contains(30));
      expect(args, contains('123'));
    });

    test('generates UPDATE SET with complex WHERE clause', () {
      final query = const Query<Map<String, dynamic>>()
          .where('status', isEqualTo: 'active')
          .where('age', isGreaterThan: 18);
      final (sql, args) = translator.toUpdateWhereSql(
        tableName: 'users',
        query: query,
        updates: {'status': 'verified'},
      );

      expect(sql, contains('UPDATE users SET status = ?'));
      expect(sql, contains('WHERE'));
      expect(sql, contains('status = ?'));
      expect(sql, contains('age > ?'));
    });

    test('handles null value in updates', () {
      final query =
          const Query<Map<String, dynamic>>().where('id', isEqualTo: '123');
      final (sql, args) = translator.toUpdateWhereSql(
        tableName: 'users',
        query: query,
        updates: {'nickname': null},
      );

      expect(sql, contains('nickname = ?'));
      expect(args.first, isNull);
    });
  });
}
