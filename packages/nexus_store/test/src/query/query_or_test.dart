import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('Query OR logic', () {
    group('or() builder', () {
      test('creates a query with an OR filter group', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', isEqualTo: 'active')
            .or(
              (q) => q
                  .where('role', isEqualTo: 'admin')
                  .where('role', isEqualTo: 'superadmin'),
            );

        expect(query.filters, hasLength(1)); // top-level AND filter
        expect(query.filterGroups, hasLength(1)); // one OR group
        expect(query.filterGroups.first.filters, hasLength(2));
        expect(query.filterGroups.first.combinator, FilterGroupCombinator.or);
      });

      test('creates multiple OR groups', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', isEqualTo: 'active')
            .or(
              (q) => q
                  .where('role', isEqualTo: 'admin')
                  .where('role', isEqualTo: 'superadmin'),
            )
            .or(
              (q) => q
                  .where('tier', isEqualTo: 'premium')
                  .where('tier', isEqualTo: 'enterprise'),
            );

        expect(query.filters, hasLength(1));
        expect(query.filterGroups, hasLength(2));
      });

      test('OR group with single condition is valid', () {
        final query = const Query<Map<String, dynamic>>().or(
          (q) => q.where('role', isEqualTo: 'admin'),
        );

        expect(query.filterGroups, hasLength(1));
        expect(query.filterGroups.first.filters, hasLength(1));
      });

      test('OR group with empty builder creates no group', () {
        final query = const Query<Map<String, dynamic>>().or(
          (q) => q, // no conditions added
        );

        expect(query.filterGroups, isEmpty);
      });

      test('hasFilters returns true when only OR groups exist', () {
        final query = const Query<Map<String, dynamic>>().or(
          (q) => q
              .where('role', isEqualTo: 'admin')
              .where('role', isEqualTo: 'superadmin'),
        );

        expect(query.filters, isEmpty);
        expect(query.filterGroups, hasLength(1));
        expect(query.hasFilters, isTrue);
      });

      test('isEmpty returns false when OR groups exist', () {
        final query = const Query<Map<String, dynamic>>().or(
          (q) => q.where('role', isEqualTo: 'admin'),
        );

        expect(query.isEmpty, isFalse);
        expect(query.isNotEmpty, isTrue);
      });
    });

    group('nested AND/OR', () {
      test('AND filters combined with OR group', () {
        // status = 'active' AND (role = 'admin' OR role = 'superadmin')
        final query = const Query<Map<String, dynamic>>()
            .where('status', isEqualTo: 'active')
            .or(
              (q) => q
                  .where('role', isEqualTo: 'admin')
                  .where('role', isEqualTo: 'superadmin'),
            );

        expect(query.filters, hasLength(1));
        expect(query.filters.first.field, 'status');
        expect(query.filterGroups, hasLength(1));
        expect(query.filterGroups.first.filters.first.field, 'role');
      });

      test('multiple AND filters with multiple OR groups', () {
        // status = 'active' AND age > 18 AND (role = 'admin' OR role = 'mod') AND (tier = 'a' OR tier = 'b')
        final query = const Query<Map<String, dynamic>>()
            .where('status', isEqualTo: 'active')
            .where('age', isGreaterThan: 18)
            .or(
              (q) => q
                  .where('role', isEqualTo: 'admin')
                  .where('role', isEqualTo: 'mod'),
            )
            .or(
              (q) =>
                  q.where('tier', isEqualTo: 'a').where('tier', isEqualTo: 'b'),
            );

        expect(query.filters, hasLength(2));
        expect(query.filterGroups, hasLength(2));
      });
    });

    group('QueryFilterGroup', () {
      test('equality', () {
        final group1 = QueryFilterGroup(
          filters: const [
            QueryFilter(
              field: 'role',
              operator: FilterOperator.equals,
              value: 'admin',
            ),
          ],
          combinator: FilterGroupCombinator.or,
        );
        final group2 = QueryFilterGroup(
          filters: const [
            QueryFilter(
              field: 'role',
              operator: FilterOperator.equals,
              value: 'admin',
            ),
          ],
          combinator: FilterGroupCombinator.or,
        );

        expect(group1, equals(group2));
        expect(group1.hashCode, equals(group2.hashCode));
      });

      test('toString', () {
        final group = QueryFilterGroup(
          filters: const [
            QueryFilter(
              field: 'a',
              operator: FilterOperator.equals,
              value: 1,
            ),
            QueryFilter(
              field: 'b',
              operator: FilterOperator.equals,
              value: 2,
            ),
          ],
          combinator: FilterGroupCombinator.or,
        );

        expect(group.toString(), contains('OR'));
      });
    });

    group('copyWith', () {
      test('preserves filterGroups', () {
        final query = const Query<Map<String, dynamic>>()
            .where('status', isEqualTo: 'active')
            .or(
              (q) => q
                  .where('role', isEqualTo: 'admin')
                  .where('role', isEqualTo: 'superadmin'),
            );

        final copied = query.copyWith(limit: 10);

        expect(copied.filterGroups, hasLength(1));
        expect(copied.limit, 10);
        expect(copied.filters, hasLength(1));
      });

      test('can override filterGroups', () {
        final query = const Query<Map<String, dynamic>>().or(
          (q) => q.where('role', isEqualTo: 'admin'),
        );

        final copied = query.copyWith(filterGroups: []);

        expect(copied.filterGroups, isEmpty);
      });
    });

    group('equality', () {
      test('queries with same OR groups are equal', () {
        final q1 = const Query<Map<String, dynamic>>()
            .where('status', isEqualTo: 'active')
            .or(
              (q) => q
                  .where('role', isEqualTo: 'admin')
                  .where('role', isEqualTo: 'superadmin'),
            );

        final q2 = const Query<Map<String, dynamic>>()
            .where('status', isEqualTo: 'active')
            .or(
              (q) => q
                  .where('role', isEqualTo: 'admin')
                  .where('role', isEqualTo: 'superadmin'),
            );

        expect(q1, equals(q2));
        expect(q1.hashCode, equals(q2.hashCode));
      });

      test('queries with different OR groups are not equal', () {
        final q1 = const Query<Map<String, dynamic>>().or(
          (q) => q.where('role', isEqualTo: 'admin'),
        );

        final q2 = const Query<Map<String, dynamic>>().or(
          (q) => q.where('role', isEqualTo: 'user'),
        );

        expect(q1, isNot(equals(q2)));
      });
    });
  });
}
