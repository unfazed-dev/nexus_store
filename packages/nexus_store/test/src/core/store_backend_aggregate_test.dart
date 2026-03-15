import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

/// Test backend that supports aggregate via in-memory calculation.
class InMemoryAggregateBackend
    with StoreBackendDefaults<Map<String, dynamic>, String> {
  final List<Map<String, dynamic>> _items = [];

  @override
  String get name => 'InMemoryAggregateBackend';

  @override
  Future<Map<String, dynamic>?> get(String id) async =>
      _items.where((item) => item['id'] == id).firstOrNull;

  @override
  Future<List<Map<String, dynamic>>> getAll(
      {Query<Map<String, dynamic>>? query}) async {
    return List.from(_items);
  }

  @override
  Stream<Map<String, dynamic>?> watch(String id) =>
      Stream.value(_items.where((item) => item['id'] == id).firstOrNull);

  @override
  Stream<List<Map<String, dynamic>>> watchAll(
          {Query<Map<String, dynamic>>? query}) =>
      Stream.value(List.from(_items));

  @override
  Future<Map<String, dynamic>> save(Map<String, dynamic> item) async {
    _items.removeWhere((i) => i['id'] == item['id']);
    _items.add(item);
    return item;
  }

  @override
  Future<List<Map<String, dynamic>>> saveAll(
      List<Map<String, dynamic>> items) async {
    for (final item in items) {
      await save(item);
    }
    return items;
  }

  @override
  Future<bool> delete(String id) async {
    final before = _items.length;
    _items.removeWhere((i) => i['id'] == id);
    return _items.length < before;
  }

  @override
  Future<int> deleteAll(List<String> ids) async {
    var count = 0;
    for (final id in ids) {
      if (await delete(id)) count++;
    }
    return count;
  }

  @override
  Future<int> deleteWhere(Query<Map<String, dynamic>> query) async {
    final count = _items.length;
    _items.clear();
    return count;
  }

  /// Override aggregate with proper in-memory implementation.
  @override
  Future<num?> aggregate(
    String field,
    AggregateType type, {
    Query<Map<String, dynamic>>? query,
  }) async {
    final items = await getAll(query: query);
    if (items.isEmpty) return null;

    final values = items.map((item) => item[field]).whereType<num>().toList();

    if (values.isEmpty) return null;

    return switch (type) {
      AggregateType.sum => values.reduce((a, b) => a + b),
      AggregateType.avg => values.reduce((a, b) => a + b) / values.length,
      AggregateType.min => values.reduce((a, b) => a.compareTo(b) <= 0 ? a : b),
      AggregateType.max => values.reduce((a, b) => a.compareTo(b) >= 0 ? a : b),
    };
  }
}

void main() {
  group('StoreBackend.aggregate', () {
    late InMemoryAggregateBackend backend;

    setUp(() {
      backend = InMemoryAggregateBackend();
    });

    group('sum', () {
      test('returns sum of numeric field', () async {
        await backend.save({'id': '1', 'amount': 10});
        await backend.save({'id': '2', 'amount': 20});
        await backend.save({'id': '3', 'amount': 30});

        final result = await backend.aggregate('amount', AggregateType.sum);
        expect(result, equals(60));
      });

      test('returns null for empty collection', () async {
        final result = await backend.aggregate('amount', AggregateType.sum);
        expect(result, isNull);
      });
    });

    group('avg', () {
      test('returns average of numeric field', () async {
        await backend.save({'id': '1', 'amount': 10});
        await backend.save({'id': '2', 'amount': 20});
        await backend.save({'id': '3', 'amount': 30});

        final result = await backend.aggregate('amount', AggregateType.avg);
        expect(result, equals(20));
      });

      test('returns null for empty collection', () async {
        final result = await backend.aggregate('amount', AggregateType.avg);
        expect(result, isNull);
      });
    });

    group('min', () {
      test('returns minimum value of numeric field', () async {
        await backend.save({'id': '1', 'amount': 30});
        await backend.save({'id': '2', 'amount': 10});
        await backend.save({'id': '3', 'amount': 20});

        final result = await backend.aggregate('amount', AggregateType.min);
        expect(result, equals(10));
      });

      test('returns null for empty collection', () async {
        final result = await backend.aggregate('amount', AggregateType.min);
        expect(result, isNull);
      });
    });

    group('max', () {
      test('returns maximum value of numeric field', () async {
        await backend.save({'id': '1', 'amount': 10});
        await backend.save({'id': '2', 'amount': 30});
        await backend.save({'id': '3', 'amount': 20});

        final result = await backend.aggregate('amount', AggregateType.max);
        expect(result, equals(30));
      });

      test('returns null for empty collection', () async {
        final result = await backend.aggregate('amount', AggregateType.max);
        expect(result, isNull);
      });
    });

    group('null handling', () {
      test('ignores null values in field', () async {
        await backend.save({'id': '1', 'amount': 10});
        await backend.save({'id': '2', 'amount': null});
        await backend.save({'id': '3', 'amount': 30});

        final result = await backend.aggregate('amount', AggregateType.sum);
        expect(result, equals(40));
      });

      test('returns null when all field values are null', () async {
        await backend.save({'id': '1', 'amount': null});
        await backend.save({'id': '2', 'amount': null});

        final result = await backend.aggregate('amount', AggregateType.sum);
        expect(result, isNull);
      });

      test('returns null for non-existent field', () async {
        await backend.save({'id': '1', 'name': 'test'});

        final result = await backend.aggregate('amount', AggregateType.sum);
        expect(result, isNull);
      });
    });

    group('StoreBackendDefaults', () {
      test('default aggregate throws UnsupportedError', () async {
        final defaultBackend = _DefaultOnlyBackend();
        await defaultBackend.save({'id': '1', 'amount': 10});

        expect(
          () => defaultBackend.aggregate('amount', AggregateType.sum),
          throwsUnsupportedError,
        );
      });
    });
  });
}

/// Minimal backend using only StoreBackendDefaults (no aggregate override).
class _DefaultOnlyBackend
    with StoreBackendDefaults<Map<String, dynamic>, String> {
  final List<Map<String, dynamic>> _items = [];

  @override
  String get name => 'DefaultOnly';

  @override
  Future<Map<String, dynamic>?> get(String id) async =>
      _items.where((item) => item['id'] == id).firstOrNull;

  @override
  Future<List<Map<String, dynamic>>> getAll(
          {Query<Map<String, dynamic>>? query}) async =>
      List.from(_items);

  @override
  Stream<Map<String, dynamic>?> watch(String id) => const Stream.empty();

  @override
  Stream<List<Map<String, dynamic>>> watchAll(
          {Query<Map<String, dynamic>>? query}) =>
      const Stream.empty();

  @override
  Future<Map<String, dynamic>> save(Map<String, dynamic> item) async {
    _items.add(item);
    return item;
  }

  @override
  Future<List<Map<String, dynamic>>> saveAll(
      List<Map<String, dynamic>> items) async {
    _items.addAll(items);
    return items;
  }

  @override
  Future<bool> delete(String id) async => false;

  @override
  Future<int> deleteAll(List<String> ids) async => 0;

  @override
  Future<int> deleteWhere(Query<Map<String, dynamic>> query) async => 0;
}
