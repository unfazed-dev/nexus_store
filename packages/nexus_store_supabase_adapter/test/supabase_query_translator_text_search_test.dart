import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_supabase_adapter/nexus_store_supabase_adapter.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  FakePostgrestFilterBuilder([this.data = const []]);

  final List<Map<String, dynamic>> data;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) =>
      this;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> textSearch(
    String column,
    String query, {
    String? config,
    TextSearchType? type,
  }) =>
      this;

  @override
  // ignore: avoid_annotating_with_dynamic
  Future<S> then<S>(
    FutureOr<S> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) async =>
      onValue(data);
}

void main() {
  late SupabaseQueryTranslator<TestModel> translator;

  setUp(() {
    translator = SupabaseQueryTranslator<TestModel>();
  });

  group('SupabaseQueryTranslator textSearch', () {
    test('translates textSearch filter with plain type', () async {
      final builder = FakePostgrestFilterBuilder();
      final query = const nexus.Query<TestModel>().where(
        'description',
        textSearch: const nexus.TextSearchConfig(query: 'hello world'),
      );

      final result = await translator.apply(builder, query);

      expect(result, isA<List<Map<String, dynamic>>>());
    });

    test('translates textSearch filter with phrase type', () async {
      final builder = FakePostgrestFilterBuilder();
      final query = const nexus.Query<TestModel>().where(
        'body',
        textSearch: const nexus.TextSearchConfig(
          query: 'fat cats',
          type: nexus.TextSearchType.phrase,
        ),
      );

      final result = await translator.apply(builder, query);

      expect(result, isA<List<Map<String, dynamic>>>());
    });

    test('translates textSearch filter with websearch type', () async {
      final builder = FakePostgrestFilterBuilder();
      final query = const nexus.Query<TestModel>().where(
        'content',
        textSearch: const nexus.TextSearchConfig(
          query: '"fat cats" -dogs',
          type: nexus.TextSearchType.websearch,
          config: 'english',
        ),
      );

      final result = await translator.apply(builder, query);

      expect(result, isA<List<Map<String, dynamic>>>());
    });

    test('translates textSearch with custom locale config', () async {
      final builder = FakePostgrestFilterBuilder();
      final query = const nexus.Query<TestModel>().where(
        'title',
        textSearch: const nexus.TextSearchConfig(
          query: 'gato gordo',
          config: 'spanish',
        ),
      );

      final result = await translator.apply(builder, query);

      expect(result, isA<List<Map<String, dynamic>>>());
    });

    test('textSearch can combine with other filters', () async {
      final builder = FakePostgrestFilterBuilder();
      final query = const nexus.Query<TestModel>()
          .where('status', isEqualTo: 'published')
          .where(
            'body',
            textSearch: const nexus.TextSearchConfig(query: 'dart flutter'),
          );

      final result = await translator.apply(builder, query);

      expect(result, isA<List<Map<String, dynamic>>>());
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
