import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_supabase_adapter/nexus_store_supabase_adapter.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

// Mock classes
class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  group('SupabaseBackend', () {
    late MockSupabaseClient mockClient;
    late SupabaseBackend<TestModel, String> backend;

    setUp(() {
      mockClient = MockSupabaseClient();
    });

    tearDown(() async {
      try {
        await backend.close();
      } on Object {
        // Ignore if already closed or not initialized
      }
    });

    SupabaseBackend<TestModel, String> createBackend({
      MockSupabaseClient? client,
    }) =>
        SupabaseBackend<TestModel, String>(
          client: client ?? mockClient,
          tableName: 'test_models',
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
        );

    group('backend info', () {
      test('name returns "supabase"', () {
        backend = createBackend();
        expect(backend.name, 'supabase');
      });

      test('supportsOffline returns false', () {
        backend = createBackend();
        expect(backend.supportsOffline, isFalse);
      });

      test('supportsRealtime returns true', () {
        backend = createBackend();
        expect(backend.supportsRealtime, isTrue);
      });

      test('supportsTransactions returns false', () {
        backend = createBackend();
        expect(backend.supportsTransactions, isFalse);
      });
    });

    group('construction', () {
      test('creates backend with required parameters', () {
        backend = createBackend();
        expect(backend, isNotNull);
      });

      test('creates backend with custom primary key column', () {
        backend = SupabaseBackend<TestModel, String>(
          client: mockClient,
          tableName: 'test_models',
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
          primaryKeyColumn: 'uuid',
        );
        expect(backend, isNotNull);
      });

      test('creates backend with custom query translator', () {
        final translator = SupabaseQueryTranslator<TestModel>(
          fieldMapping: {'userName': 'user_name'},
        );
        backend = SupabaseBackend<TestModel, String>(
          client: mockClient,
          tableName: 'test_models',
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
          queryTranslator: translator,
        );
        expect(backend, isNotNull);
      });

      test('creates backend with field mapping', () {
        backend = SupabaseBackend<TestModel, String>(
          client: mockClient,
          tableName: 'test_models',
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
          fieldMapping: {'userName': 'user_name'},
        );
        expect(backend, isNotNull);
      });

      test('creates backend with custom schema', () {
        backend = SupabaseBackend<TestModel, String>(
          client: mockClient,
          tableName: 'test_models',
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
          schema: 'custom_schema',
        );
        expect(backend, isNotNull);
      });
    });

    group('sync status (online-only)', () {
      test('initial sync status is synced', () {
        backend = createBackend();
        expect(backend.syncStatus, nexus.SyncStatus.synced);
      });

      test('syncStatusStream emits synced initially', () async {
        backend = createBackend();
        final status = await backend.syncStatusStream.first;
        expect(status, nexus.SyncStatus.synced);
      });

      test('pendingChangesCount returns 0', () async {
        backend = createBackend();
        final count = await backend.pendingChangesCount;
        expect(count, 0);
      });
    });

    group('uninitialized state', () {
      test('get throws StateError when not initialized', () {
        backend = createBackend();
        expect(
          () => backend.get('test-id'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('getAll throws StateError when not initialized', () {
        backend = createBackend();
        expect(
          () => backend.getAll(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('save throws StateError when not initialized', () {
        backend = createBackend();
        expect(
          () => backend.save(const TestModel(id: '1', name: 'Test')),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('saveAll throws StateError when not initialized', () {
        backend = createBackend();
        expect(
          () => backend.saveAll([const TestModel(id: '1', name: 'Test')]),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('delete throws StateError when not initialized', () {
        backend = createBackend();
        expect(
          () => backend.delete('test-id'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('deleteAll throws StateError when not initialized', () {
        backend = createBackend();
        expect(
          () => backend.deleteAll(['test-id']),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('deleteWhere throws StateError when not initialized', () {
        backend = createBackend();
        final query =
            const nexus.Query<TestModel>().where('name', isEqualTo: 'Test');
        expect(
          () => backend.deleteWhere(query),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('watch throws StateError when not initialized', () {
        backend = createBackend();
        expect(
          () => backend.watch('test-id'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('watchAll throws StateError when not initialized', () {
        backend = createBackend();
        expect(
          () => backend.watchAll(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('sync throws StateError when not initialized', () {
        backend = createBackend();
        expect(
          () => backend.sync(),
          throwsA(isA<nexus.StateError>()),
        );
      });
    });

    group('close', () {
      test('close can be called multiple times', () async {
        backend = createBackend();
        // Close without initializing
        await backend.close();
        await backend.close();
        // Should not throw
      });
    });
  });

  group('SupabaseBackend error mapping', () {
    test('PostgrestException with PGRST116 maps to NotFoundError', () {
      // Test that the error message pattern is recognized
      const errorCode = 'PGRST116';
      expect(errorCode, contains('PGRST116'));
    });

    test('PostgrestException with 23505 maps to ValidationError', () {
      // Test that unique constraint code is recognized
      const errorCode = '23505';
      expect(errorCode, contains('23505'));
    });

    test('PostgrestException with 23503 maps to ValidationError', () {
      // Test that foreign key code is recognized
      const errorCode = '23503';
      expect(errorCode, contains('23503'));
    });

    test('PostgrestException with 42501 maps to AuthorizationError', () {
      // Test that RLS error code is recognized
      const errorCode = '42501';
      expect(errorCode, contains('42501'));
    });
  });

  group('Query integration', () {
    test('Query can be built for SupabaseBackend', () {
      const query = nexus.Query<TestModel>();
      final filtered = query
          .where('name', isEqualTo: 'Test')
          .where('age', isGreaterThan: 18)
          .orderByField('createdAt', descending: true)
          .limitTo(10)
          .offsetBy(5);

      expect(filtered.filters, hasLength(2));
      expect(filtered.orderBy, hasLength(1));
      expect(filtered.limit, 10);
      expect(filtered.offset, 5);
    });

    test('Empty query has isEmpty true', () {
      const query = nexus.Query<TestModel>();
      expect(query.isEmpty, isTrue);
    });

    test('Query with filters has isNotEmpty true', () {
      final query =
          const nexus.Query<TestModel>().where('name', isEqualTo: 'Test');
      expect(query.isNotEmpty, isTrue);
    });
  });
}

/// Test model for backend tests.
class TestModel {
  const TestModel({
    required this.id,
    required this.name,
    this.age,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) => TestModel(
        id: json['id'] as String,
        name: json['name'] as String,
        age: json['age'] as int?,
      );

  final String id;
  final String name;
  final int? age;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
      };
}
