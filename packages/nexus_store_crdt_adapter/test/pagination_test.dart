import 'dart:async';

import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_crdt_adapter/nexus_store_crdt_adapter.dart';
import 'package:test/test.dart';

/// Test model for pagination tests.
class TestModel {
  TestModel({
    required this.id,
    required this.name,
    this.age = 0,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) => TestModel(
        id: json['id'] as String,
        name: json['name'] as String,
        age: json['age'] as int? ?? 0,
      );

  final String id;
  final String name;
  final int age;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => Object.hash(id, name, age);

  @override
  String toString() => 'TestModel(id: $id, name: $name, age: $age)';
}

void main() {
  group('CrdtBackend Pagination', () {
    late CrdtBackend<TestModel, String> backend;

    setUp(() async {
      backend = CrdtBackend<TestModel, String>(
        tableName: 'test_models',
        getId: (m) => m.id,
        fromJson: TestModel.fromJson,
        toJson: (m) => m.toJson(),
        primaryKeyField: 'id',
      );
      await backend.initialize();
    });

    tearDown(() async {
      await backend.close();
    });

    group('getAllPaged', () {
      test('returns empty page when no items exist', () async {
        final result = await backend.getAllPaged();

        expect(result.items, isEmpty);
        expect(result.pageInfo.hasNextPage, isFalse);
        expect(result.pageInfo.hasPreviousPage, isFalse);
        expect(result.pageInfo.totalCount, equals(0));
        expect(result.pageInfo.startCursor, isNull);
        expect(result.pageInfo.endCursor, isNull);
      });

      test('returns all items when no pagination specified', () async {
        for (var i = 0; i < 5; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        final result = await backend.getAllPaged();

        expect(result.items.length, equals(5));
        expect(result.pageInfo.hasNextPage, isFalse);
        expect(result.pageInfo.hasPreviousPage, isFalse);
        expect(result.pageInfo.totalCount, equals(5));
      });

      test('respects firstCount for page size', () async {
        for (var i = 0; i < 10; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        final query = const nexus.Query<TestModel>().first(3);
        final result = await backend.getAllPaged(query: query);

        expect(result.items.length, equals(3));
        expect(result.pageInfo.hasNextPage, isTrue);
        expect(result.pageInfo.hasPreviousPage, isFalse);
        expect(result.pageInfo.totalCount, equals(10));
        expect(result.pageInfo.endCursor, isNotNull);
      });

      test('firstCount must be positive (Query validation)', () async {
        // Query.first() validates that count > 0
        expect(
          () => const nexus.Query<TestModel>().first(0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('firstCount larger than total returns all items', () async {
        for (var i = 0; i < 3; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        final query = const nexus.Query<TestModel>().first(100);
        final result = await backend.getAllPaged(query: query);

        expect(result.items.length, equals(3));
        expect(result.pageInfo.hasNextPage, isFalse);
        expect(result.pageInfo.hasPreviousPage, isFalse);
        expect(result.pageInfo.totalCount, equals(3));
      });

      test('afterCursor starts from correct position', () async {
        for (var i = 0; i < 10; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        // Get first page
        final query1 = const nexus.Query<TestModel>().first(3);
        final page1 = await backend.getAllPaged(query: query1);

        // Get second page using cursor
        final query2 = const nexus.Query<TestModel>()
            .first(3)
            .after(page1.pageInfo.endCursor!);
        final page2 = await backend.getAllPaged(query: query2);

        expect(page2.items.length, equals(3));
        expect(page2.pageInfo.hasPreviousPage, isTrue);
        expect(page2.pageInfo.hasNextPage, isTrue);
      });

      test('cursor with index out of bounds is clamped and returns empty page',
          () async {
        for (var i = 0; i < 5; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        // Create cursor pointing beyond the data
        // Should be clamped to items.length
        final outOfBoundsCursor = nexus.Cursor.fromValues(
          const {'_index': 100},
        );
        final query =
            const nexus.Query<TestModel>().first(3).after(outOfBoundsCursor);
        final result = await backend.getAllPaged(query: query);

        // Cursor is clamped to 5, so startIndex=5, endIndex=5, empty result
        expect(result.items, isEmpty);
        expect(result.pageInfo.hasNextPage, isFalse);
        // hasPreviousPage is true because clamped startIndex (5) > 0
        expect(result.pageInfo.hasPreviousPage, isTrue);
      });

      test('cursor with null _index starts from beginning', () async {
        for (var i = 0; i < 5; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        // Create cursor with null _index
        final nullIndexCursor = nexus.Cursor.fromValues(const {'_index': null});
        final query =
            const nexus.Query<TestModel>().first(3).after(nullIndexCursor);
        final result = await backend.getAllPaged(query: query);

        // Should start from index 0 since null is treated as 0
        expect(result.items.length, equals(3));
        expect(result.pageInfo.hasPreviousPage, isFalse);
      });

      test('pagination through all pages', () async {
        for (var i = 0; i < 10; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        final allItems = <TestModel>[];
        nexus.Cursor? cursor;

        // Fetch all pages
        while (true) {
          var query = const nexus.Query<TestModel>().first(3);
          if (cursor != null) {
            query = query.after(cursor);
          }

          final page = await backend.getAllPaged(query: query);
          allItems.addAll(page.items);

          if (!page.pageInfo.hasNextPage) break;
          cursor = page.pageInfo.endCursor;
        }

        expect(allItems.length, equals(10));
      });

      test('combines with query filters', () async {
        for (var i = 0; i < 10; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        // Filter for age >= 25, then paginate
        final query = const nexus.Query<TestModel>()
            .where('age', isGreaterThanOrEqualTo: 25)
            .first(2);
        final result = await backend.getAllPaged(query: query);

        // Should have 5 items with age >= 25 (ages 25-29), returning first 2
        expect(result.items.length, equals(2));
        expect(result.pageInfo.hasNextPage, isTrue);
        expect(result.pageInfo.totalCount, equals(5));
      });
    });

    group('watchAllPaged', () {
      test('emits empty page when no items', () async {
        final stream = backend.watchAllPaged();
        final result = await stream.first;

        expect(result.items, isEmpty);
        expect(result.pageInfo.totalCount, equals(0));
      });

      test('emits paged results', () async {
        for (var i = 0; i < 5; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        final query = const nexus.Query<TestModel>().first(2);
        final stream = backend.watchAllPaged(query: query);
        final result = await stream.first;

        expect(result.items.length, equals(2));
        expect(result.pageInfo.hasNextPage, isTrue);
        expect(result.pageInfo.totalCount, equals(5));
      });

      test('emits updates when data changes', () async {
        await backend.save(TestModel(id: '1', name: 'User1', age: 20));

        final stream = backend.watchAllPaged();
        final completer = Completer<nexus.PagedResult<TestModel>>();

        // Skip first emission, wait for second
        var count = 0;
        final subscription = stream.listen((result) {
          count++;
          if (count == 2) {
            completer.complete(result);
          }
        });

        // Allow first emission to process
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Add another item
        await backend.save(TestModel(id: '2', name: 'User2', age: 25));

        // Wait for second emission with timeout
        final result = await completer.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () => throw TimeoutException('No update received'),
        );

        expect(result.items.length, equals(2));
        await subscription.cancel();
      });

      test('cursor pagination in stream', () async {
        for (var i = 0; i < 10; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        // Get first page
        final query1 = const nexus.Query<TestModel>().first(3);
        final page1 = await backend.watchAllPaged(query: query1).first;

        expect(page1.items.length, equals(3));
        expect(page1.pageInfo.endCursor, isNotNull);

        // Get second page using cursor
        final query2 = const nexus.Query<TestModel>()
            .first(3)
            .after(page1.pageInfo.endCursor!);
        final page2 = await backend.watchAllPaged(query: query2).first;

        expect(page2.items.length, equals(3));
        expect(page2.pageInfo.hasPreviousPage, isTrue);
      });

      test('stream handles large cursor values by clamping', () async {
        for (var i = 0; i < 5; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        // Cursor beyond data - should be clamped to items.length
        final largeCursor = nexus.Cursor.fromValues(const {'_index': 1000});
        final query =
            const nexus.Query<TestModel>().first(3).after(largeCursor);
        final result = await backend.watchAllPaged(query: query).first;

        // Clamped to items.length (5), so empty result
        expect(result.items, isEmpty);
        expect(result.pageInfo.hasPreviousPage, isTrue);
        expect(result.pageInfo.hasNextPage, isFalse);
      });
    });

    group('PageInfo', () {
      test('startCursor is set for non-empty results', () async {
        await backend.save(TestModel(id: '1', name: 'User1', age: 20));

        final result = await backend.getAllPaged();

        expect(result.pageInfo.startCursor, isNotNull);
        expect(result.pageInfo.startCursor!.toValues()['_index'], equals(0));
      });

      test('endCursor is only set when hasNextPage is true', () async {
        await backend.save(TestModel(id: '1', name: 'User1', age: 20));

        final result = await backend.getAllPaged();

        // Only one item, no next page, so endCursor should be null
        expect(result.pageInfo.hasNextPage, isFalse);
        expect(result.pageInfo.endCursor, isNull);
      });

      test('endCursor points to next page start', () async {
        for (var i = 0; i < 10; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        final query = const nexus.Query<TestModel>().first(3);
        final result = await backend.getAllPaged(query: query);

        expect(result.pageInfo.endCursor, isNotNull);
        expect(result.pageInfo.endCursor!.toValues()['_index'], equals(3));
      });
    });
  });
}
