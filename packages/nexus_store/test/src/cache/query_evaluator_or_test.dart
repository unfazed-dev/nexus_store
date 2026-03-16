import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryQueryEvaluator<Map<String, dynamic>> evaluator;

  setUp(() {
    evaluator = InMemoryQueryEvaluator<Map<String, dynamic>>(
      fieldAccessor: (item, field) => item[field],
    );
  });

  final items = [
    {
      'id': '1',
      'name': 'Alice',
      'role': 'admin',
      'status': 'active',
      'age': 30
    },
    {'id': '2', 'name': 'Bob', 'role': 'user', 'status': 'active', 'age': 25},
    {
      'id': '3',
      'name': 'Carol',
      'role': 'superadmin',
      'status': 'inactive',
      'age': 35
    },
    {'id': '4', 'name': 'Dave', 'role': 'mod', 'status': 'active', 'age': 40},
    {'id': '5', 'name': 'Eve', 'role': 'user', 'status': 'inactive', 'age': 22},
  ];

  group('InMemoryQueryEvaluator OR logic', () {
    test('evaluates OR group correctly', () {
      // role = 'admin' OR role = 'superadmin'
      final query = const Query<Map<String, dynamic>>().or(
        (q) => q
            .where('role', isEqualTo: 'admin')
            .where('role', isEqualTo: 'superadmin'),
      );

      final results = evaluator.evaluate(items, query);

      expect(results, hasLength(2));
      expect(results.map((e) => e['name']), containsAll(['Alice', 'Carol']));
    });

    test('evaluates AND + OR combined', () {
      // status = 'active' AND (role = 'admin' OR role = 'mod')
      final query = const Query<Map<String, dynamic>>()
          .where('status', isEqualTo: 'active')
          .or(
            (q) => q
                .where('role', isEqualTo: 'admin')
                .where('role', isEqualTo: 'mod'),
          );

      final results = evaluator.evaluate(items, query);

      expect(results, hasLength(2));
      expect(results.map((e) => e['name']), containsAll(['Alice', 'Dave']));
    });

    test('evaluates multiple OR groups', () {
      // (role = 'admin' OR role = 'mod') AND (status = 'active' OR status = 'inactive')
      final query = const Query<Map<String, dynamic>>()
          .or(
            (q) => q
                .where('role', isEqualTo: 'admin')
                .where('role', isEqualTo: 'mod'),
          )
          .or(
            (q) => q
                .where('status', isEqualTo: 'active')
                .where('status', isEqualTo: 'inactive'),
          );

      final results = evaluator.evaluate(items, query);

      // admin+active (Alice), mod+active (Dave) — both match both OR groups
      expect(results, hasLength(2));
      expect(results.map((e) => e['name']), containsAll(['Alice', 'Dave']));
    });

    test('matches returns true for item matching OR group', () {
      final query = const Query<Map<String, dynamic>>().or(
        (q) => q
            .where('role', isEqualTo: 'admin')
            .where('role', isEqualTo: 'superadmin'),
      );

      expect(evaluator.matches(items[0], query), isTrue); // Alice: admin
      expect(evaluator.matches(items[1], query), isFalse); // Bob: user
      expect(evaluator.matches(items[2], query), isTrue); // Carol: superadmin
    });

    test('OR group with comparison operators', () {
      // age < 25 OR age > 35
      final query = const Query<Map<String, dynamic>>().or(
        (q) => q.where('age', isLessThan: 25).where('age', isGreaterThan: 35),
      );

      final results = evaluator.evaluate(items, query);

      expect(results, hasLength(2));
      expect(results.map((e) => e['name']), containsAll(['Dave', 'Eve']));
    });

    test('empty items returns empty with OR query', () {
      final query = const Query<Map<String, dynamic>>().or(
        (q) => q.where('role', isEqualTo: 'admin'),
      );

      final results = evaluator.evaluate([], query);

      expect(results, isEmpty);
    });

    test('evaluates AND filter group (default combinator)', () {
      // Create an AND group via copyWith — both conditions must match
      // This exercises query_evaluator.dart line 51:
      //   group.filters.every((filter) => _matchesFilter(item, filter))
      final subQuery = const Query<Map<String, dynamic>>()
          .where('status', isEqualTo: 'active')
          .where('role', isEqualTo: 'admin');
      final query = const Query<Map<String, dynamic>>().copyWith(
        filterGroups: [
          QueryFilterGroup(
            filters: subQuery.filters,
            combinator: FilterGroupCombinator.and,
          ),
        ],
      );

      final results = evaluator.evaluate(items, query);

      // Only Alice is active AND admin
      expect(results, hasLength(1));
      expect(results.first['name'], equals('Alice'));
    });

    test('AND filter group rejects items that only partially match', () {
      final subQuery = const Query<Map<String, dynamic>>()
          .where('status', isEqualTo: 'active')
          .where('role', isEqualTo: 'superadmin');
      final query = const Query<Map<String, dynamic>>().copyWith(
        filterGroups: [
          QueryFilterGroup(
            filters: subQuery.filters,
            combinator: FilterGroupCombinator.and,
          ),
        ],
      );

      final results = evaluator.evaluate(items, query);

      // No one is both active AND superadmin
      expect(results, isEmpty);
    });
  });
}
