import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_supabase_adapter/nexus_store_supabase_adapter.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

/// Tracks method calls on PostgrestFilterBuilder without needing mocktail.
/// This avoids issues with mocktail's Future detection on PostgrestBuilder types.
class SpyPostgrestFilterBuilder
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final List<String> calls = [];
  late final SpyPostgrestTransformBuilder transformBuilder;

  SpyPostgrestFilterBuilder() {
    transformBuilder = SpyPostgrestTransformBuilder(this);
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object? value,
  ) {
    calls.add('eq($column, $value)');
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> neq(
    String column,
    Object? value,
  ) {
    calls.add('neq($column, $value)');
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> lt(
    String column,
    Object? value,
  ) {
    calls.add('lt($column, $value)');
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> lte(
    String column,
    Object? value,
  ) {
    calls.add('lte($column, $value)');
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> gt(
    String column,
    Object? value,
  ) {
    calls.add('gt($column, $value)');
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> gte(
    String column,
    Object? value,
  ) {
    calls.add('gte($column, $value)');
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> ilike(
    String column,
    Object? pattern,
  ) {
    calls.add('ilike($column, $pattern)');
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> inFilter(
    String column,
    List<Object?> values,
  ) {
    calls.add('inFilter($column, $values)');
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> isFilter(
    String column,
    Object? value,
  ) {
    calls.add('isFilter($column, $value)');
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> not(
    String column,
    String operator,
    Object? value,
  ) {
    calls.add('not($column, $operator, $value)');
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> contains(
    String column,
    Object? value,
  ) {
    calls.add('contains($column, $value)');
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> overlaps(
    String column,
    Object? value,
  ) {
    calls.add('overlaps($column, $value)');
    return this;
  }

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    calls.add('order($column, ascending: $ascending)');
    return transformBuilder;
  }

  // Required overrides that we don't need to track
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
        'Method ${invocation.memberName} not implemented in spy',
      );
}

/// Tracks method calls on PostgrestTransformBuilder.
class SpyPostgrestTransformBuilder
    implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  final SpyPostgrestFilterBuilder parent;

  SpyPostgrestTransformBuilder(this.parent);

  List<String> get calls => parent.calls;

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    calls.add('order($column, ascending: $ascending)');
    return this;
  }

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> range(
    int from,
    int to, {
    String? referencedTable,
  }) {
    calls.add('range($from, $to)');
    return this;
  }

  // Required overrides that we don't need to track
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
        'Method ${invocation.memberName} not implemented in spy',
      );
}

void main() {
  group('SupabaseQueryTranslator', () {
    late SupabaseQueryTranslator<TestModel> translator;

    setUp(() {
      translator = SupabaseQueryTranslator<TestModel>();
    });

    group('construction', () {
      test('creates translator without field mapping', () {
        final t = SupabaseQueryTranslator<TestModel>();
        expect(t, isNotNull);
      });

      test('creates translator with field mapping', () {
        final t = SupabaseQueryTranslator<TestModel>(
          fieldMapping: {'userName': 'user_name'},
        );
        expect(t, isNotNull);
      });
    });

    group('translate', () {
      test('translate returns void (no-op)', () {
        final query = const Query<TestModel>().where('name', isEqualTo: 'John');
        // translate is a no-op that returns void
        expect(() => translator.translate(query), returnsNormally);
      });
    });

    group('translateFilters', () {
      test('translateFilters returns void (no-op)', () {
        final filters = [
          const QueryFilter(
            field: 'name',
            operator: FilterOperator.equals,
            value: 'John',
          ),
        ];
        expect(() => translator.translateFilters(filters), returnsNormally);
      });
    });

    group('translateOrderBy', () {
      test('translateOrderBy returns void (no-op)', () {
        final orderBy = [
          const QueryOrderBy(field: 'name'),
        ];
        expect(() => translator.translateOrderBy(orderBy), returnsNormally);
      });
    });

    group('field mapping', () {
      test('uses original field name when no mapping provided', () {
        final t = SupabaseQueryTranslator<TestModel>();
        // Field mapping is internal, but we can verify behavior through
        // the translator creation and that it doesn't throw
        expect(t, isNotNull);
      });

      test('applies field mapping when provided', () {
        final t = SupabaseQueryTranslator<TestModel>(
          fieldMapping: {
            'userName': 'user_name',
            'createdAt': 'created_at',
            'isActive': 'is_active',
          },
        );
        expect(t, isNotNull);
      });
    });
  });

  group('SupabaseQueryExtension', () {
    test('extension method exists on Query', () {
      const query = Query<TestModel>();
      // Verify the extension method exists (compilation check)
      expect(query, isNotNull);
    });
  });

  group('FilterOperator coverage', () {
    // These tests verify that all FilterOperator values are handled
    // by checking that the translator can be instantiated and used

    test('handles all filter operators in switch expression', () {
      // This is a compile-time check - the switch must be exhaustive
      // If any operator is missing, Dart will throw a compile error
      final translator = SupabaseQueryTranslator<TestModel>();

      // Just verify the translator exists and can handle queries
      const operators = FilterOperator.values;
      expect(operators.length, greaterThan(0));
      expect(translator, isNotNull);
    });

    test('equals operator is handled', () {
      const query = Query<TestModel>();
      final q = query.where('name', isEqualTo: 'John');
      expect(q.filters, hasLength(1));
      expect(q.filters.first.operator, FilterOperator.equals);
    });

    test('notEquals operator is handled', () {
      const query = Query<TestModel>();
      final q = query.where('name', isNotEqualTo: 'John');
      expect(q.filters, hasLength(1));
      expect(q.filters.first.operator, FilterOperator.notEquals);
    });

    test('lessThan operator is handled', () {
      const query = Query<TestModel>();
      final q = query.where('age', isLessThan: 30);
      expect(q.filters, hasLength(1));
      expect(q.filters.first.operator, FilterOperator.lessThan);
    });

    test('lessThanOrEquals operator is handled', () {
      const query = Query<TestModel>();
      final q = query.where('age', isLessThanOrEqualTo: 30);
      expect(q.filters, hasLength(1));
      expect(q.filters.first.operator, FilterOperator.lessThanOrEquals);
    });

    test('greaterThan operator is handled', () {
      const query = Query<TestModel>();
      final q = query.where('age', isGreaterThan: 18);
      expect(q.filters, hasLength(1));
      expect(q.filters.first.operator, FilterOperator.greaterThan);
    });

    test('greaterThanOrEquals operator is handled', () {
      const query = Query<TestModel>();
      final q = query.where('age', isGreaterThanOrEqualTo: 18);
      expect(q.filters, hasLength(1));
      expect(q.filters.first.operator, FilterOperator.greaterThanOrEquals);
    });

    test('whereIn operator is handled', () {
      const query = Query<TestModel>();
      final q = query.where('status', whereIn: ['active', 'pending']);
      expect(q.filters, hasLength(1));
      expect(q.filters.first.operator, FilterOperator.whereIn);
    });

    test('whereNotIn operator is handled', () {
      const query = Query<TestModel>();
      final q = query.where('status', whereNotIn: ['deleted', 'archived']);
      expect(q.filters, hasLength(1));
      expect(q.filters.first.operator, FilterOperator.whereNotIn);
    });

    test('isNull operator is handled', () {
      const query = Query<TestModel>();
      final q = query.where('deletedAt', isNull: true);
      expect(q.filters, hasLength(1));
      expect(q.filters.first.operator, FilterOperator.isNull);
    });

    test('arrayContains operator is handled', () {
      const query = Query<TestModel>();
      final q = query.where('tags', arrayContains: 'important');
      expect(q.filters, hasLength(1));
      expect(q.filters.first.operator, FilterOperator.arrayContains);
    });

    test('arrayContainsAny operator is handled', () {
      const query = Query<TestModel>();
      final q = query.where('tags', arrayContainsAny: ['urgent', 'important']);
      expect(q.filters, hasLength(1));
      expect(q.filters.first.operator, FilterOperator.arrayContainsAny);
    });
  });

  group('Query building', () {
    test('creates empty query', () {
      const query = Query<TestModel>();
      expect(query.isEmpty, isTrue);
      expect(query.filters, isEmpty);
      expect(query.orderBy, isEmpty);
      expect(query.limit, isNull);
      expect(query.offset, isNull);
    });

    test('adds single filter', () {
      final query = const Query<TestModel>().where('name', isEqualTo: 'Test');
      expect(query.filters, hasLength(1));
    });

    test('adds multiple filters', () {
      final query = const Query<TestModel>()
          .where('name', isEqualTo: 'Test')
          .where('age', isGreaterThan: 18);
      expect(query.filters, hasLength(2));
    });

    test('adds ordering', () {
      final query = const Query<TestModel>().orderByField('name');
      expect(query.orderBy, hasLength(1));
      expect(query.orderBy.first.descending, isFalse);
    });

    test('adds descending ordering', () {
      final query =
          const Query<TestModel>().orderByField('createdAt', descending: true);
      expect(query.orderBy, hasLength(1));
      expect(query.orderBy.first.descending, isTrue);
    });

    test('adds multiple orderings', () {
      final query = const Query<TestModel>()
          .orderByField('name')
          .orderByField('createdAt', descending: true);
      expect(query.orderBy, hasLength(2));
    });

    test('adds limit', () {
      final query = const Query<TestModel>().limitTo(10);
      expect(query.limit, 10);
    });

    test('adds offset', () {
      final query = const Query<TestModel>().offsetBy(5);
      expect(query.offset, 5);
    });

    test('combines filters, ordering, and pagination', () {
      final query = const Query<TestModel>()
          .where('status', isEqualTo: 'active')
          .where('age', isGreaterThan: 18)
          .orderByField('name')
          .orderByField('createdAt', descending: true)
          .limitTo(20)
          .offsetBy(10);

      expect(query.filters, hasLength(2));
      expect(query.orderBy, hasLength(2));
      expect(query.limit, 20);
      expect(query.offset, 10);
      expect(query.isNotEmpty, isTrue);
    });
  });

  group('apply with spy builders', () {
    late SupabaseQueryTranslator<TestModel> translator;
    late SpyPostgrestFilterBuilder spyBuilder;

    setUp(() {
      translator = SupabaseQueryTranslator<TestModel>();
      spyBuilder = SpyPostgrestFilterBuilder();
    });

    group('applyFilters', () {
      test('applies equals filter with eq method', () {
        final query = const Query<TestModel>().where('name', isEqualTo: 'John');

        translator.applyFilters(spyBuilder, query.filters);

        expect(spyBuilder.calls, contains('eq(name, John)'));
      });

      test('applies notEquals filter with neq method', () {
        final query =
            const Query<TestModel>().where('status', isNotEqualTo: 'deleted');

        translator.applyFilters(spyBuilder, query.filters);

        expect(spyBuilder.calls, contains('neq(status, deleted)'));
      });

      test('applies lessThan filter with lt method', () {
        final query = const Query<TestModel>().where('age', isLessThan: 30);

        translator.applyFilters(spyBuilder, query.filters);

        expect(spyBuilder.calls, contains('lt(age, 30)'));
      });

      test('applies lessThanOrEquals filter with lte method', () {
        final query =
            const Query<TestModel>().where('age', isLessThanOrEqualTo: 30);

        translator.applyFilters(spyBuilder, query.filters);

        expect(spyBuilder.calls, contains('lte(age, 30)'));
      });

      test('applies greaterThan filter with gt method', () {
        final query = const Query<TestModel>().where('age', isGreaterThan: 18);

        translator.applyFilters(spyBuilder, query.filters);

        expect(spyBuilder.calls, contains('gt(age, 18)'));
      });

      test('applies greaterThanOrEquals filter with gte method', () {
        final query =
            const Query<TestModel>().where('age', isGreaterThanOrEqualTo: 18);

        translator.applyFilters(spyBuilder, query.filters);

        expect(spyBuilder.calls, contains('gte(age, 18)'));
      });

      test('applies contains filter with ilike and wildcards', () {
        final filters = [
          const QueryFilter(
            field: 'name',
            operator: FilterOperator.contains,
            value: 'john',
          ),
        ];

        translator.applyFilters(spyBuilder, filters);

        expect(spyBuilder.calls, contains('ilike(name, %john%)'));
      });

      test('applies startsWith filter with ilike and suffix wildcard', () {
        final filters = [
          const QueryFilter(
            field: 'name',
            operator: FilterOperator.startsWith,
            value: 'John',
          ),
        ];

        translator.applyFilters(spyBuilder, filters);

        expect(spyBuilder.calls, contains('ilike(name, John%)'));
      });

      test('applies endsWith filter with ilike and prefix wildcard', () {
        final filters = [
          const QueryFilter(
            field: 'name',
            operator: FilterOperator.endsWith,
            value: 'son',
          ),
        ];

        translator.applyFilters(spyBuilder, filters);

        expect(spyBuilder.calls, contains('ilike(name, %son)'));
      });

      test('applies whereIn filter with inFilter method', () {
        final query = const Query<TestModel>()
            .where('status', whereIn: ['active', 'pending']);

        translator.applyFilters(spyBuilder, query.filters);

        expect(
          spyBuilder.calls,
          contains('inFilter(status, [active, pending])'),
        );
      });

      test('applies whereIn with empty list returns impossible value', () {
        final query = const Query<TestModel>().where('status', whereIn: []);

        translator.applyFilters(spyBuilder, query.filters);

        expect(spyBuilder.calls, contains('eq(status, __impossible_value__)'));
      });

      test('applies whereNotIn filter with not method', () {
        final query = const Query<TestModel>()
            .where('status', whereNotIn: ['deleted', 'archived']);

        translator.applyFilters(spyBuilder, query.filters);

        expect(
          spyBuilder.calls,
          contains('not(status, in, (deleted,archived))'),
        );
      });

      test('applies whereNotIn with empty list is no-op', () {
        final query = const Query<TestModel>().where('status', whereNotIn: []);

        translator.applyFilters(spyBuilder, query.filters);

        // No not() call should be made for empty list
        expect(
          spyBuilder.calls.where((c) => c.startsWith('not(')),
          isEmpty,
        );
      });

      test('applies isNull filter with isFilter method', () {
        final query = const Query<TestModel>().where('deletedAt', isNull: true);

        translator.applyFilters(spyBuilder, query.filters);

        expect(spyBuilder.calls, contains('isFilter(deletedAt, null)'));
      });

      test('applies isNotNull filter with not method', () {
        final filters = [
          const QueryFilter(
            field: 'deletedAt',
            operator: FilterOperator.isNotNull,
            value: null,
          ),
        ];

        translator.applyFilters(spyBuilder, filters);

        expect(spyBuilder.calls, contains('not(deletedAt, is, null)'));
      });

      test('applies arrayContains filter with contains method', () {
        final query =
            const Query<TestModel>().where('tags', arrayContains: 'important');

        translator.applyFilters(spyBuilder, query.filters);

        expect(spyBuilder.calls, contains('contains(tags, [important])'));
      });

      test('applies arrayContainsAny filter with overlaps method', () {
        final query = const Query<TestModel>()
            .where('tags', arrayContainsAny: ['urgent', 'important']);

        translator.applyFilters(spyBuilder, query.filters);

        expect(
          spyBuilder.calls,
          contains('overlaps(tags, [urgent, important])'),
        );
      });

      test('applies arrayContainsAny with empty list is no-op', () {
        final query =
            const Query<TestModel>().where('tags', arrayContainsAny: []);

        translator.applyFilters(spyBuilder, query.filters);

        // No overlaps() call should be made for empty list
        expect(
          spyBuilder.calls.where((c) => c.startsWith('overlaps(')),
          isEmpty,
        );
      });

      test('applies multiple filters in sequence', () {
        final query = const Query<TestModel>()
            .where('name', isEqualTo: 'John')
            .where('age', isGreaterThan: 18)
            .where('status', isNotEqualTo: 'inactive');

        translator.applyFilters(spyBuilder, query.filters);

        expect(spyBuilder.calls, contains('eq(name, John)'));
        expect(spyBuilder.calls, contains('gt(age, 18)'));
        expect(spyBuilder.calls, contains('neq(status, inactive)'));
      });
    });

    group('applyOrderBy', () {
      test('returns builder unchanged when no ordering', () {
        const query = Query<TestModel>();

        translator.applyOrderBy(spyBuilder, query.orderBy);

        // No order() calls should be made
        expect(
          spyBuilder.calls.where((c) => c.startsWith('order(')),
          isEmpty,
        );
      });

      test('applies single order by ascending', () {
        final query = const Query<TestModel>().orderByField('name');

        translator.applyOrderBy(spyBuilder, query.orderBy);

        expect(spyBuilder.calls, contains('order(name, ascending: true)'));
      });

      test('applies single order by descending', () {
        final query = const Query<TestModel>()
            .orderByField('createdAt', descending: true);

        translator.applyOrderBy(spyBuilder, query.orderBy);

        expect(spyBuilder.calls, contains('order(createdAt, ascending: false)'));
      });

      test('applies multiple order by clauses', () {
        final query = const Query<TestModel>()
            .orderByField('name')
            .orderByField('createdAt', descending: true);

        translator.applyOrderBy(spyBuilder, query.orderBy);

        expect(spyBuilder.calls, contains('order(name, ascending: true)'));
        expect(spyBuilder.calls, contains('order(createdAt, ascending: false)'));
      });
    });

    group('applyPagination', () {
      test('returns builder unchanged when no pagination', () {
        const query = Query<TestModel>();

        // Need a transform builder for pagination
        translator.applyPagination(spyBuilder.transformBuilder, query);

        // No range() calls should be made
        expect(
          spyBuilder.calls.where((c) => c.startsWith('range(')),
          isEmpty,
        );
      });

      test('applies limit only with range(0, limit-1)', () {
        final query = const Query<TestModel>().limitTo(10);

        translator.applyPagination(spyBuilder.transformBuilder, query);

        expect(spyBuilder.calls, contains('range(0, 9)'));
      });

      test('applies offset only with range(offset, offset+999)', () {
        final query = const Query<TestModel>().offsetBy(20);

        translator.applyPagination(spyBuilder.transformBuilder, query);

        expect(spyBuilder.calls, contains('range(20, 1019)'));
      });

      test('applies limit and offset with range(offset, offset+limit-1)', () {
        final query = const Query<TestModel>().limitTo(10).offsetBy(20);

        translator.applyPagination(spyBuilder.transformBuilder, query);

        expect(spyBuilder.calls, contains('range(20, 29)'));
      });
    });

    group('apply (full pipeline)', () {
      test('applies filters, ordering, and pagination together', () {
        final query = const Query<TestModel>()
            .where('status', isEqualTo: 'active')
            .orderByField('createdAt', descending: true)
            .limitTo(20)
            .offsetBy(10);

        translator.apply(spyBuilder, query);

        expect(spyBuilder.calls, contains('eq(status, active)'));
        expect(spyBuilder.calls, contains('order(createdAt, ascending: false)'));
        expect(spyBuilder.calls, contains('range(10, 29)'));
      });

      test('applies empty query without calling any methods', () {
        const query = Query<TestModel>();

        translator.apply(spyBuilder, query);

        // Empty query should not call any filter/order/range methods
        expect(spyBuilder.calls, isEmpty);
      });
    });
  });

  group('field mapping with spy', () {
    test('maps field names in filters', () {
      final translator = SupabaseQueryTranslator<TestModel>(
        fieldMapping: {'userName': 'user_name', 'createdAt': 'created_at'},
      );
      final spyBuilder = SpyPostgrestFilterBuilder();
      final query =
          const Query<TestModel>().where('userName', isEqualTo: 'John');

      translator.applyFilters(spyBuilder, query.filters);

      expect(spyBuilder.calls, contains('eq(user_name, John)'));
    });

    test('maps field names in ordering', () {
      final translator = SupabaseQueryTranslator<TestModel>(
        fieldMapping: {'createdAt': 'created_at'},
      );
      final spyBuilder = SpyPostgrestFilterBuilder();
      final query =
          const Query<TestModel>().orderByField('createdAt', descending: true);

      translator.applyOrderBy(spyBuilder, query.orderBy);

      expect(spyBuilder.calls, contains('order(created_at, ascending: false)'));
    });

    test('uses original name when no mapping exists', () {
      final translator = SupabaseQueryTranslator<TestModel>(
        fieldMapping: {'other': 'other_field'},
      );
      final spyBuilder = SpyPostgrestFilterBuilder();
      final query =
          const Query<TestModel>().where('unmapped', isEqualTo: 'value');

      translator.applyFilters(spyBuilder, query.filters);

      expect(spyBuilder.calls, contains('eq(unmapped, value)'));
    });
  });

  group('applyToSupabase extension', () {
    test('applies query via extension method', () {
      final query = const Query<TestModel>()
          .where('name', isEqualTo: 'Test')
          .orderByField('name')
          .limitTo(5);
      final spyBuilder = SpyPostgrestFilterBuilder();

      query.applyToSupabase(spyBuilder);

      expect(spyBuilder.calls, contains('eq(name, Test)'));
      expect(spyBuilder.calls, contains('order(name, ascending: true)'));
      expect(spyBuilder.calls, contains('range(0, 4)'));
    });

    test('applies field mapping via extension method', () {
      final query =
          const Query<TestModel>().where('userName', isEqualTo: 'Test');
      final spyBuilder = SpyPostgrestFilterBuilder();

      query.applyToSupabase(
        spyBuilder,
        fieldMapping: {'userName': 'user_name'},
      );

      expect(spyBuilder.calls, contains('eq(user_name, Test)'));
    });
  });
}

/// Test model for query translator tests.
class TestModel {
  const TestModel({
    required this.id,
    required this.name,
    this.age,
    this.status,
    this.tags,
  });

  // ignore: unreachable_from_main
  factory TestModel.fromJson(Map<String, dynamic> json) => TestModel(
        id: json['id'] as String,
        name: json['name'] as String,
        age: json['age'] as int?,
        status: json['status'] as String?,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      );

  final String id;
  final String name;
  final int? age;
  final String? status;
  final List<String>? tags;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'status': status,
        'tags': tags,
      };
}
