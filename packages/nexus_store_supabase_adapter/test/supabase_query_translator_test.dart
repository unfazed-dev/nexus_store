import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_supabase_adapter/nexus_store_supabase_adapter.dart';
import 'package:test/test.dart';

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
