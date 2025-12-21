import 'package:nexus_store/src/cache/cache_tag_index.dart';
import 'package:test/test.dart';

void main() {
  group('CacheTagIndex', () {
    late CacheTagIndex<String> index;

    setUp(() {
      index = CacheTagIndex<String>();
    });

    group('addTags', () {
      test('should add ID with tags', () {
        index.addTags('user-1', {'premium', 'active'});

        expect(index.getIdsByTag('premium'), contains('user-1'));
        expect(index.getIdsByTag('active'), contains('user-1'));
      });

      test('should support multiple IDs per tag', () {
        index.addTags('user-1', {'premium'});
        index.addTags('user-2', {'premium'});

        expect(index.getIdsByTag('premium'), containsAll(['user-1', 'user-2']));
      });

      test('should accumulate tags for same ID', () {
        index.addTags('user-1', {'premium'});
        index.addTags('user-1', {'active'});

        expect(index.getTagsForId('user-1'), containsAll(['premium', 'active']));
      });

      test('should handle empty tags set', () {
        index.addTags('user-1', {});

        expect(index.getTagsForId('user-1'), isEmpty);
      });
    });

    group('getTagsForId', () {
      test('should get tags for ID', () {
        index.addTags('user-1', {'premium', 'active'});

        expect(index.getTagsForId('user-1'), containsAll(['premium', 'active']));
      });

      test('should return empty set for unknown ID', () {
        expect(index.getTagsForId('unknown'), isEmpty);
      });
    });

    group('getIdsByTag', () {
      test('should get IDs by tag', () {
        index.addTags('user-1', {'premium'});
        index.addTags('user-2', {'premium'});
        index.addTags('user-3', {'basic'});

        final premiumIds = index.getIdsByTag('premium');

        expect(premiumIds, containsAll(['user-1', 'user-2']));
        expect(premiumIds, isNot(contains('user-3')));
      });

      test('should return empty set for unknown tag', () {
        expect(index.getIdsByTag('unknown'), isEmpty);
      });
    });

    group('getIdsByAnyTag', () {
      test('should get IDs matching any tag (union)', () {
        index.addTags('user-1', {'premium'});
        index.addTags('user-2', {'admin'});
        index.addTags('user-3', {'basic'});

        final result = index.getIdsByAnyTag({'premium', 'admin'});

        expect(result, containsAll(['user-1', 'user-2']));
        expect(result, isNot(contains('user-3')));
      });

      test('should return empty set when no matches', () {
        index.addTags('user-1', {'basic'});

        expect(index.getIdsByAnyTag({'premium', 'admin'}), isEmpty);
      });

      test('should handle empty tags set', () {
        index.addTags('user-1', {'premium'});

        expect(index.getIdsByAnyTag({}), isEmpty);
      });
    });

    group('getIdsByAllTags', () {
      test('should get IDs matching all tags (intersection)', () {
        index.addTags('user-1', {'premium', 'active'});
        index.addTags('user-2', {'premium', 'inactive'});
        index.addTags('user-3', {'basic', 'active'});

        final result = index.getIdsByAllTags({'premium', 'active'});

        expect(result, equals({'user-1'}));
      });

      test('should return empty set when no ID has all tags', () {
        index.addTags('user-1', {'premium'});
        index.addTags('user-2', {'admin'});

        expect(index.getIdsByAllTags({'premium', 'admin'}), isEmpty);
      });

      test('should handle single tag', () {
        index.addTags('user-1', {'premium'});

        expect(index.getIdsByAllTags({'premium'}), equals({'user-1'}));
      });
    });

    group('removeTags', () {
      test('should remove tags from ID', () {
        index.addTags('user-1', {'premium', 'active'});

        index.removeTags('user-1', {'premium'});

        expect(index.getTagsForId('user-1'), equals({'active'}));
        expect(index.getIdsByTag('premium'), isEmpty);
      });

      test('should handle removing non-existent tags', () {
        index.addTags('user-1', {'premium'});

        index.removeTags('user-1', {'nonexistent'});

        expect(index.getTagsForId('user-1'), equals({'premium'}));
      });

      test('should handle removing from non-existent ID', () {
        index.removeTags('unknown', {'premium'});

        expect(index.getTagsForId('unknown'), isEmpty);
      });
    });

    group('removeId', () {
      test('should remove ID from all tags', () {
        index.addTags('user-1', {'premium', 'active'});

        index.removeId('user-1');

        expect(index.getTagsForId('user-1'), isEmpty);
        expect(index.getIdsByTag('premium'), isEmpty);
        expect(index.getIdsByTag('active'), isEmpty);
      });

      test('should not affect other IDs', () {
        index.addTags('user-1', {'premium'});
        index.addTags('user-2', {'premium'});

        index.removeId('user-1');

        expect(index.getIdsByTag('premium'), equals({'user-2'}));
      });

      test('should handle removing non-existent ID', () {
        index.addTags('user-1', {'premium'});

        index.removeId('unknown');

        expect(index.getIdsByTag('premium'), equals({'user-1'}));
      });
    });

    group('clear', () {
      test('should clear all tags', () {
        index.addTags('user-1', {'premium'});
        index.addTags('user-2', {'admin'});

        index.clear();

        expect(index.isEmpty, isTrue);
        expect(index.getIdsByTag('premium'), isEmpty);
        expect(index.getTagsForId('user-1'), isEmpty);
      });
    });

    group('isEmpty', () {
      test('should be empty initially', () {
        expect(index.isEmpty, isTrue);
      });

      test('should not be empty after adding tags', () {
        index.addTags('user-1', {'premium'});

        expect(index.isEmpty, isFalse);
      });

      test('should be empty after clearing', () {
        index.addTags('user-1', {'premium'});
        index.clear();

        expect(index.isEmpty, isTrue);
      });
    });

    group('allTags', () {
      test('should return all unique tags', () {
        index.addTags('user-1', {'premium', 'active'});
        index.addTags('user-2', {'premium', 'admin'});

        expect(index.allTags, containsAll(['premium', 'active', 'admin']));
        expect(index.allTags, hasLength(3));
      });

      test('should return empty set when no tags', () {
        expect(index.allTags, isEmpty);
      });
    });

    group('allIds', () {
      test('should return all IDs with tags', () {
        index.addTags('user-1', {'premium'});
        index.addTags('user-2', {'admin'});

        expect(index.allIds, containsAll(['user-1', 'user-2']));
      });

      test('should return empty set when no IDs', () {
        expect(index.allIds, isEmpty);
      });
    });
  });
}
