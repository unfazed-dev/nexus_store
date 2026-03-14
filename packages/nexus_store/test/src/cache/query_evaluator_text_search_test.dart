import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryQueryEvaluator<Map<String, dynamic>> evaluator;

  setUp(() {
    evaluator = InMemoryQueryEvaluator<Map<String, dynamic>>(
      fieldAccessor: (entity, field) => entity[field],
    );
  });

  group('InMemoryQueryEvaluator text search', () {
    final items = [
      {'id': '1', 'name': 'John Smith', 'email': 'john@example.com'},
      {'id': '2', 'name': 'Jane Doe', 'email': 'jane@test.org'},
      {'id': '3', 'name': 'Johnny Appleseed', 'email': 'johnny@example.com'},
    ];

    test('contains matches substring', () {
      final query =
          Query<Map<String, dynamic>>().where('name', contains: 'ohn');

      final results = evaluator.evaluate(items, query);
      expect(results.map((e) => e['id']), unorderedEquals(['1', '3']));
    });

    test('startsWith matches prefix', () {
      final query =
          Query<Map<String, dynamic>>().where('name', startsWith: 'John');

      final results = evaluator.evaluate(items, query);
      expect(results.map((e) => e['id']), unorderedEquals(['1', '3']));
    });

    test('endsWith matches suffix', () {
      final query = Query<Map<String, dynamic>>()
          .where('email', endsWith: '@example.com');

      final results = evaluator.evaluate(items, query);
      expect(results.map((e) => e['id']), unorderedEquals(['1', '3']));
    });

    test('text search combined with equality', () {
      final query = Query<Map<String, dynamic>>()
          .where('name', contains: 'ohn')
          .where('id', isEqualTo: '1');

      final results = evaluator.evaluate(items, query);
      expect(results.map((e) => e['id']), equals(['1']));
    });
  });
}
