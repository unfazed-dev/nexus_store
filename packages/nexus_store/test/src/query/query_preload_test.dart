import 'package:nexus_store/src/query/query.dart';
import 'package:test/test.dart';

void main() {
  group('Query preload', () {
    test('default query has empty preload fields', () {
      const query = Query<String>();
      expect(query.preloadFields, isEmpty);
    });

    test('preload adds fields to preload set', () {
      final query = const Query<String>().preload({'thumbnail', 'fullImage'});

      expect(query.preloadFields, {'thumbnail', 'fullImage'});
    });

    test('preloadField adds single field to preload set', () {
      final query = const Query<String>().preloadField('thumbnail');

      expect(query.preloadFields, {'thumbnail'});
    });

    test('preload is cumulative', () {
      final query = const Query<String>()
          .preload({'thumbnail'})
          .preloadField('fullImage')
          .preload({'video'});

      expect(query.preloadFields, {'thumbnail', 'fullImage', 'video'});
    });

    test('preload preserves existing query conditions', () {
      final query = const Query<String>()
          .where('status', isEqualTo: 'active')
          .orderByField('createdAt', descending: true)
          .limitTo(10)
          .preload({'thumbnail'});

      expect(query.filters.length, 1);
      expect(query.orderBy.length, 1);
      expect(query.limit, 10);
      expect(query.preloadFields, {'thumbnail'});
    });

    test('isEmpty returns false when preload fields are set', () {
      final query = const Query<String>().preload({'thumbnail'});

      expect(query.isEmpty, isFalse);
      expect(query.isNotEmpty, isTrue);
    });

    test('copyWith preserves preload fields', () {
      final query = const Query<String>().preload({'thumbnail'});
      final copied = query.copyWith(limit: 10);

      expect(copied.preloadFields, {'thumbnail'});
      expect(copied.limit, 10);
    });

    test('copyWith can override preload fields', () {
      final query = const Query<String>().preload({'thumbnail'});
      final copied = query.copyWith(preloadFields: {'fullImage', 'video'});

      expect(copied.preloadFields, {'fullImage', 'video'});
    });

    test('equality includes preload fields', () {
      final query1 = const Query<String>().preload({'thumbnail'});
      final query2 = const Query<String>().preload({'thumbnail'});
      final query3 = const Query<String>().preload({'fullImage'});

      expect(query1, equals(query2));
      expect(query1, isNot(equals(query3)));
    });

    test('hashCode includes preload fields', () {
      final query1 = const Query<String>().preload({'thumbnail'});
      final query2 = const Query<String>().preload({'thumbnail'});
      final query3 = const Query<String>().preload({'fullImage'});

      expect(query1.hashCode, equals(query2.hashCode));
      expect(query1.hashCode, isNot(equals(query3.hashCode)));
    });

    test('toString includes preload fields', () {
      final query = const Query<String>().preload({'thumbnail', 'fullImage'});

      final str = query.toString();
      expect(str, contains('preloadFields'));
      expect(str, contains('thumbnail'));
      expect(str, contains('fullImage'));
    });
  });
}
