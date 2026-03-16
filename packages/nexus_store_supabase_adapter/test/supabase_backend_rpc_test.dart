import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_supabase_adapter/nexus_store_supabase_adapter.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

class MockSupabaseClientWrapper extends Mock implements SupabaseClientWrapper {}

class MockRealtimeManagerWrapper extends Mock
    implements RealtimeManagerWrapper<TestModel, String> {}

void main() {
  late MockSupabaseClientWrapper mockWrapper;
  late MockRealtimeManagerWrapper mockRealtimeWrapper;
  late SupabaseBackend<TestModel, String> backend;

  setUp(() async {
    mockWrapper = MockSupabaseClientWrapper();
    mockRealtimeWrapper = MockRealtimeManagerWrapper();

    when(() => mockRealtimeWrapper.initialize()).thenAnswer((_) async {});
    when(() => mockRealtimeWrapper.dispose()).thenAnswer((_) async {});

    backend = SupabaseBackend<TestModel, String>.withRealtimeWrapper(
      wrapper: mockWrapper,
      realtimeWrapper: mockRealtimeWrapper,
      tableName: 'test_models',
      getId: (model) => model.id,
      fromJson: TestModel.fromJson,
      toJson: (model) => model.toJson(),
    );

    await backend.initialize();
  });

  tearDown(() async {
    try {
      await backend.close();
    } on Object {
      // Ignore if already closed
    }
  });

  group('SupabaseBackend.rpc', () {
    test('calls wrapper.rpc with correct function name', () async {
      when(() => mockWrapper.rpc('get_user_count')).thenAnswer((_) async => 42);

      final result = await backend.rpc<int>('get_user_count');

      expect(result, 42);
      verify(() => mockWrapper.rpc('get_user_count')).called(1);
    });

    test('passes params to wrapper.rpc', () async {
      when(
        () => mockWrapper.rpc(
          'get_users_by_status',
          params: {'status': 'active'},
        ),
      ).thenAnswer(
        (_) async => [
          {'id': '1', 'name': 'Alice'},
        ],
      );

      final result = await backend.rpc<List<dynamic>>(
        'get_users_by_status',
        params: {'status': 'active'},
      );

      expect(result, isA<List<dynamic>>());
      expect(result.length, 1);
      verify(
        () => mockWrapper.rpc(
          'get_users_by_status',
          params: {'status': 'active'},
        ),
      ).called(1);
    });

    test('applies fromJson deserializer when provided', () async {
      when(() => mockWrapper.rpc('get_total'))
          .thenAnswer((_) async => {'count': 5});

      final result = await backend.rpc<int>(
        'get_total',
        fromJson: (data) => (data! as Map<String, dynamic>)['count']! as int,
      );

      expect(result, 5);
    });

    test('returns raw response when no fromJson provided', () async {
      final rawResponse = {
        'key': 'value',
        'nested': {'a': 1},
      };
      when(() => mockWrapper.rpc('get_config'))
          .thenAnswer((_) async => rawResponse);

      final result = await backend.rpc<dynamic>('get_config');

      expect(result, rawResponse);
    });

    test('wraps PostgrestException as StoreError', () async {
      when(() => mockWrapper.rpc('failing_function'))
          .thenThrow(const PostgrestException(message: 'function not found'));

      expect(
        () => backend.rpc<dynamic>('failing_function'),
        throwsA(isA<nexus.StoreError>()),
      );
    });

    test('throws StateError when not initialized', () async {
      final uninitializedBackend =
          SupabaseBackend<TestModel, String>.withRealtimeWrapper(
        wrapper: mockWrapper,
        realtimeWrapper: mockRealtimeWrapper,
        tableName: 'test_models',
        getId: (model) => model.id,
        fromJson: TestModel.fromJson,
        toJson: (model) => model.toJson(),
      );

      expect(
        () => uninitializedBackend.rpc<dynamic>('some_function'),
        throwsA(isA<nexus.StateError>()),
      );
    });
  });
}

class TestModel {
  const TestModel({
    required this.id,
    required this.name,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) => TestModel(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
