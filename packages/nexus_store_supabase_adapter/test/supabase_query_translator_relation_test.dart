import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_supabase_adapter/nexus_store_supabase_adapter.dart';
import 'package:test/test.dart';

void main() {
  late SupabaseQueryTranslator<TestModel> translator;

  setUp(() {
    translator = SupabaseQueryTranslator<TestModel>();
  });

  group('SupabaseQueryTranslator buildSelectString', () {
    test('returns * for query with no relations', () {
      const query = nexus.Query<TestModel>();

      final result = translator.buildSelectString(query);

      expect(result, '*');
    });

    test('generates select with single relation', () {
      final query = const nexus.Query<TestModel>().withRelation('posts');

      final result = translator.buildSelectString(query);

      expect(result, '*,posts(*)');
    });

    test('generates select with multiple relations', () {
      final query = const nexus.Query<TestModel>()
          .withRelation('posts')
          .withRelation('comments');

      final result = translator.buildSelectString(query);

      expect(result, '*,posts(*),comments(*)');
    });

    test('generates select with nested relation embedding', () {
      final query = const nexus.Query<TestModel>().withRelation(
        'posts',
        subQuery: const nexus.Query<dynamic>().withRelation('comments'),
      );

      final result = translator.buildSelectString(query);

      expect(result, '*,posts(*,comments(*))');
    });

    test('generates select with relation column selection', () {
      final query = const nexus.Query<TestModel>().withRelation(
        'posts',
        columns: {'id', 'title', 'body'},
      );

      final result = translator.buildSelectString(query);

      // Column order may vary, so check parts
      expect(result, startsWith('*,posts('));
      expect(result, contains('id'));
      expect(result, contains('title'));
      expect(result, contains('body'));
      expect(result, endsWith(')'));
    });

    test('generates select with nested relation and columns', () {
      final query = const nexus.Query<TestModel>().withRelation(
        'posts',
        columns: {'id', 'title'},
        subQuery: const nexus.Query<dynamic>().withRelation(
          'comments',
          columns: {'id', 'body'},
        ),
      );

      final result = translator.buildSelectString(query);

      // Should include both column selection and nested relation
      expect(result, contains('posts('));
      expect(result, contains('comments('));
    });

    test('generates select with deeply nested relations', () {
      final query = const nexus.Query<TestModel>().withRelation(
        'posts',
        subQuery: const nexus.Query<dynamic>().withRelation(
          'comments',
          subQuery: const nexus.Query<dynamic>().withRelation('likes'),
        ),
      );

      final result = translator.buildSelectString(query);

      expect(result, '*,posts(*,comments(*,likes(*)))');
    });

    test('uses field mapping for relation foreign key', () {
      final mappedTranslator = SupabaseQueryTranslator<TestModel>(
        fieldMapping: {'authorPosts': 'author_posts'},
      );
      final query = const nexus.Query<TestModel>().withRelation('author_posts');

      final result = mappedTranslator.buildSelectString(query);

      expect(result, '*,author_posts(*)');
    });

    test('generates select with relation foreign key hint', () {
      final query = const nexus.Query<TestModel>().withRelation(
        'posts',
        foreignKey: 'author_id',
      );

      final result = translator.buildSelectString(query);

      // PostgREST foreign key hint: table!foreign_key(*)
      expect(result, '*,posts!author_id(*)');
    });
  });
}

// ignore: unreachable_from_main
class TestModel {
  // ignore: unreachable_from_main
  const TestModel({
    required this.id,
    required this.name,
  });

  // ignore: unreachable_from_main
  final String id;
  // ignore: unreachable_from_main
  final String name;
}
