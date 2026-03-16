import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('QueryRelation', () {
    test('constructs with table name only', () {
      const relation = QueryRelation(foreignTable: 'posts');

      expect(relation.foreignTable, 'posts');
      expect(relation.foreignKey, isNull);
      expect(relation.columns, isNull);
      expect(relation.subQuery, isNull);
    });

    test('constructs with foreign key override', () {
      const relation = QueryRelation(
        foreignTable: 'comments',
        foreignKey: 'author_id',
      );

      expect(relation.foreignTable, 'comments');
      expect(relation.foreignKey, 'author_id');
    });

    test('constructs with column selection', () {
      const relation = QueryRelation(
        foreignTable: 'posts',
        columns: {'id', 'title', 'body'},
      );

      expect(relation.columns, {'id', 'title', 'body'});
    });

    test('constructs with sub-query for nested relations', () {
      final subQuery = const Query<dynamic>().withRelation('comments');
      final relation = QueryRelation(
        foreignTable: 'posts',
        subQuery: subQuery,
      );

      expect(relation.subQuery, isNotNull);
      expect(relation.subQuery!.relations, hasLength(1));
      expect(relation.subQuery!.relations.first.foreignTable, 'comments');
    });

    test('equality works for identical relations', () {
      const a = QueryRelation(foreignTable: 'posts');
      const b = QueryRelation(foreignTable: 'posts');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality for different table names', () {
      const a = QueryRelation(foreignTable: 'posts');
      const b = QueryRelation(foreignTable: 'comments');

      expect(a, isNot(equals(b)));
    });

    test('equality includes foreignKey', () {
      const a = QueryRelation(
        foreignTable: 'posts',
        foreignKey: 'user_id',
      );
      const b = QueryRelation(
        foreignTable: 'posts',
        foreignKey: 'author_id',
      );

      expect(a, isNot(equals(b)));
    });

    test('toString is descriptive', () {
      const relation = QueryRelation(
        foreignTable: 'posts',
        foreignKey: 'author_id',
      );

      expect(relation.toString(), contains('posts'));
      expect(relation.toString(), contains('author_id'));
    });
  });

  group('Query.withRelation', () {
    test('returns empty relations list by default', () {
      const query = Query<dynamic>();

      expect(query.relations, isEmpty);
    });

    test('adds a single relation', () {
      final query = const Query<dynamic>().withRelation('posts');

      expect(query.relations, hasLength(1));
      expect(query.relations.first.foreignTable, 'posts');
    });

    test('adds relation with foreign key', () {
      final query = const Query<dynamic>().withRelation(
        'posts',
        foreignKey: 'author_id',
      );

      expect(query.relations.first.foreignKey, 'author_id');
    });

    test('adds relation with column selection', () {
      final query = const Query<dynamic>().withRelation(
        'posts',
        columns: {'id', 'title'},
      );

      expect(query.relations.first.columns, {'id', 'title'});
    });

    test('adds relation with sub-query', () {
      final subQuery = const Query<dynamic>().where(
        'status',
        isEqualTo: 'published',
      );
      final query = const Query<dynamic>().withRelation(
        'posts',
        subQuery: subQuery,
      );

      expect(query.relations.first.subQuery, isNotNull);
      expect(query.relations.first.subQuery!.filters, hasLength(1));
    });

    test('supports multiple relations', () {
      final query = const Query<dynamic>()
          .withRelation('posts')
          .withRelation('comments')
          .withRelation('tags');

      expect(query.relations, hasLength(3));
      expect(
        query.relations.map((r) => r.foreignTable),
        ['posts', 'comments', 'tags'],
      );
    });

    test('supports nested relations via sub-query', () {
      final query = const Query<dynamic>().withRelation(
        'posts',
        subQuery: const Query<dynamic>().withRelation('comments'),
      );

      expect(query.relations, hasLength(1));
      expect(query.relations.first.subQuery!.relations, hasLength(1));
      expect(
        query.relations.first.subQuery!.relations.first.foreignTable,
        'comments',
      );
    });

    test('relations list is unmodifiable', () {
      final query = const Query<dynamic>().withRelation('posts');

      expect(
        () => (query.relations as List).add(
          const QueryRelation(foreignTable: 'hack'),
        ),
        throwsUnsupportedError,
      );
    });

    test('isNotEmpty when relations exist', () {
      final query = const Query<dynamic>().withRelation('posts');

      expect(query.isNotEmpty, isTrue);
      expect(query.isEmpty, isFalse);
    });

    test('preserves existing query state when adding relation', () {
      final query = const Query<dynamic>()
          .where('status', isEqualTo: 'active')
          .orderByField('created_at', descending: true)
          .limitTo(10)
          .withRelation('posts');

      expect(query.filters, hasLength(1));
      expect(query.orderBy, hasLength(1));
      expect(query.limit, 10);
      expect(query.relations, hasLength(1));
    });

    test('copyWith includes relations', () {
      final query = const Query<dynamic>().withRelation('posts');
      final copied = query.copyWith(limit: 5);

      expect(copied.relations, hasLength(1));
      expect(copied.limit, 5);
    });

    test('copyWith can override relations', () {
      final query = const Query<dynamic>().withRelation('posts');
      final copied = query.copyWith(
        relations: [const QueryRelation(foreignTable: 'comments')],
      );

      expect(copied.relations, hasLength(1));
      expect(copied.relations.first.foreignTable, 'comments');
    });

    test('equality includes relations', () {
      final a = const Query<dynamic>().withRelation('posts');
      final b = const Query<dynamic>().withRelation('posts');
      final c = const Query<dynamic>().withRelation('comments');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
