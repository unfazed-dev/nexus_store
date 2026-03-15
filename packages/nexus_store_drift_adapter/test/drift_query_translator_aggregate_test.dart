import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_drift_adapter/nexus_store_drift_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('DriftQueryTranslator.toAggregateSql', () {
    late DriftQueryTranslator<Map<String, dynamic>> translator;

    setUp(() {
      translator = DriftQueryTranslator<Map<String, dynamic>>();
    });

    test('generates SUM without query', () {
      final (sql, args) = translator.toAggregateSql(
        tableName: 'orders',
        field: 'amount',
        type: AggregateType.sum,
      );

      expect(
        sql,
        equals('SELECT SUM(amount) AS result FROM orders'),
      );
      expect(args, isEmpty);
    });

    test('generates AVG without query', () {
      final (sql, args) = translator.toAggregateSql(
        tableName: 'reviews',
        field: 'rating',
        type: AggregateType.avg,
      );

      expect(
        sql,
        equals('SELECT AVG(rating) AS result FROM reviews'),
      );
      expect(args, isEmpty);
    });

    test('generates MIN without query', () {
      final (sql, args) = translator.toAggregateSql(
        tableName: 'products',
        field: 'price',
        type: AggregateType.min,
      );

      expect(
        sql,
        equals('SELECT MIN(price) AS result FROM products'),
      );
      expect(args, isEmpty);
    });

    test('generates MAX without query', () {
      final (sql, args) = translator.toAggregateSql(
        tableName: 'products',
        field: 'price',
        type: AggregateType.max,
      );

      expect(
        sql,
        equals('SELECT MAX(price) AS result FROM products'),
      );
      expect(args, isEmpty);
    });

    test('generates SUM with WHERE clause', () {
      final query = const Query<Map<String, dynamic>>()
          .where('status', isEqualTo: 'completed');

      final (sql, args) = translator.toAggregateSql(
        tableName: 'orders',
        field: 'amount',
        type: AggregateType.sum,
        query: query,
      );

      expect(
        sql,
        equals(
          'SELECT SUM(amount) AS result FROM orders '
          'WHERE status = ?',
        ),
      );
      expect(args, equals(['completed']));
    });

    test('generates AVG with multiple filters', () {
      final query = const Query<Map<String, dynamic>>()
          .where('status', isEqualTo: 'active')
          .where('category', isEqualTo: 'premium');

      final (sql, args) = translator.toAggregateSql(
        tableName: 'subscriptions',
        field: 'price',
        type: AggregateType.avg,
        query: query,
      );

      expect(
        sql,
        equals(
          'SELECT AVG(price) AS result FROM subscriptions '
          'WHERE status = ? AND category = ?',
        ),
      );
      expect(args, equals(['active', 'premium']));
    });

    test('applies field mapping', () {
      final mapped = DriftQueryTranslator<Map<String, dynamic>>(
        fieldMapping: {'totalAmount': 'total_amount'},
      );

      final (sql, args) = mapped.toAggregateSql(
        tableName: 'orders',
        field: 'totalAmount',
        type: AggregateType.sum,
      );

      expect(
        sql,
        equals(
          'SELECT SUM(total_amount) AS result FROM orders',
        ),
      );
      expect(args, isEmpty);
    });

    test('generates with null query', () {
      final (sql, args) = translator.toAggregateSql(
        tableName: 'orders',
        field: 'amount',
        type: AggregateType.sum,
        query: null,
      );

      expect(
        sql,
        equals('SELECT SUM(amount) AS result FROM orders'),
      );
      expect(args, isEmpty);
    });
  });
}
