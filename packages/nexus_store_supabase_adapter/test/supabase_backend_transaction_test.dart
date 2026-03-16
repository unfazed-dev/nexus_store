import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_supabase_adapter/nexus_store_supabase_adapter.dart';
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

  group('SupabaseBackend transactions', () {
    test('supportsTransactions returns true', () {
      expect(backend.supportsTransactions, isTrue);
    });

    test('runInTransaction returns callback result on success', () async {
      when(
        () => mockWrapper.rpc(
          'nx_batch_execute',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) async => {'status': 'ok'});

      final result =
          await backend.runInTransaction<String>(() async => 'success');

      expect(result, 'success');
    });

    test('runInTransaction batches save operations into single RPC call',
        () async {
      when(
        () => mockWrapper.rpc(
          'nx_batch_execute',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) async => {'status': 'ok'});

      await backend.runInTransaction(() async {
        await backend.save(const TestModel(id: '1', name: 'Alice'));
        await backend.save(const TestModel(id: '2', name: 'Bob'));
      });

      // Verify single RPC call with both operations
      final captured = verify(
        () => mockWrapper.rpc(
          'nx_batch_execute',
          params: captureAny(named: 'params'),
        ),
      ).captured;

      expect(captured, hasLength(1));
      final params = captured.first as Map<String, dynamic>;
      final operations = params['operations'] as List<dynamic>;
      expect(operations, hasLength(2));
      final op0 = operations[0] as Map<String, dynamic>;
      final op1 = operations[1] as Map<String, dynamic>;
      expect(op0['type'], 'upsert');
      expect(op0['table'], 'test_models');
      expect((op0['data'] as Map<String, dynamic>)['id'], '1');
      expect((op1['data'] as Map<String, dynamic>)['id'], '2');
    });

    test('runInTransaction batches delete operations into single RPC call',
        () async {
      when(
        () => mockWrapper.rpc(
          'nx_batch_execute',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) async => {'status': 'ok'});

      await backend.runInTransaction(() async {
        await backend.save(const TestModel(id: '1', name: 'Alice'));
        await backend.delete('item-1');
        await backend.deleteAll(['item-2', 'item-3']);
      });

      final captured = verify(
        () => mockWrapper.rpc(
          'nx_batch_execute',
          params: captureAny(named: 'params'),
        ),
      ).captured;

      expect(captured, hasLength(1));
      final params = captured.first as Map<String, dynamic>;
      final operations = params['operations'] as List<dynamic>;
      expect(operations, hasLength(3));
      final op0 = operations[0] as Map<String, dynamic>;
      final op1 = operations[1] as Map<String, dynamic>;
      final op2 = operations[2] as Map<String, dynamic>;
      expect(op0['type'], 'upsert');
      expect(op1['type'], 'delete');
      expect(op1['id'], 'item-1');
      expect(op2['type'], 'delete_many');
      expect(op2['ids'], ['item-2', 'item-3']);
    });

    test('runInTransaction batches saveAll operations into RPC call', () async {
      when(
        () => mockWrapper.rpc(
          'nx_batch_execute',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) async => {'status': 'ok'});

      await backend.runInTransaction(() async {
        await backend.saveAll([
          const TestModel(id: '1', name: 'Alice'),
          const TestModel(id: '2', name: 'Bob'),
        ]);
      });

      final captured = verify(
        () => mockWrapper.rpc(
          'nx_batch_execute',
          params: captureAny(named: 'params'),
        ),
      ).captured;

      expect(captured, hasLength(1));
      final params = captured.first as Map<String, dynamic>;
      final operations = params['operations'] as List<dynamic>;
      expect(operations, hasLength(2));
      final op0 = operations[0] as Map<String, dynamic>;
      final op1 = operations[1] as Map<String, dynamic>;
      expect(op0['type'], 'upsert');
      expect((op0['data'] as Map<String, dynamic>)['name'], 'Alice');
      expect(op1['type'], 'upsert');
      expect((op1['data'] as Map<String, dynamic>)['name'], 'Bob');
    });

    test('runInTransaction rolls back on callback failure', () async {
      expect(
        () => backend.runInTransaction(() async {
          await backend.save(const TestModel(id: '1', name: 'Alice'));
          throw Exception('Something went wrong');
        }),
        throwsA(
          isA<nexus.TransactionError>()
              .having((e) => e.wasRolledBack, 'wasRolledBack', isTrue),
        ),
      );

      // Verify no RPC call was made (rolled back before commit)
      verifyNever(
        () => mockWrapper.rpc(
          'nx_batch_execute',
          params: any(named: 'params'),
        ),
      );
    });

    test('beginTransaction / commitTransaction lifecycle', () async {
      when(
        () => mockWrapper.rpc(
          'nx_batch_execute',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) async => {'status': 'ok'});

      final txId = await backend.beginTransaction();
      expect(txId, startsWith('stx_'));

      await backend.save(const TestModel(id: '1', name: 'Alice'));
      await backend.commitTransaction(txId);

      verify(
        () => mockWrapper.rpc(
          'nx_batch_execute',
          params: any(named: 'params'),
        ),
      ).called(1);
    });

    test('rollbackTransaction discards pending operations', () async {
      final txId = await backend.beginTransaction();
      await backend.save(const TestModel(id: '1', name: 'Alice'));
      await backend.rollbackTransaction(txId);

      // Verify no RPC call (operations discarded)
      verifyNever(
        () => mockWrapper.rpc(
          'nx_batch_execute',
          params: any(named: 'params'),
        ),
      );
    });

    test('commit with wrong transaction ID throws TransactionError', () async {
      await backend.beginTransaction();

      expect(
        () => backend.commitTransaction('wrong_id'),
        throwsA(isA<nexus.TransactionError>()),
      );
    });

    test('error during RPC commit wraps in TransactionError with wasRolledBack',
        () async {
      when(
        () => mockWrapper.rpc(
          'nx_batch_execute',
          params: any(named: 'params'),
        ),
      ).thenThrow(Exception('RPC failed'));

      expect(
        () => backend.runInTransaction(() async {
          await backend.save(const TestModel(id: '1', name: 'Alice'));
        }),
        throwsA(
          isA<nexus.TransactionError>()
              .having((e) => e.wasRolledBack, 'wasRolledBack', isTrue)
              .having(
                (e) => e.message,
                'message',
                contains('Failed to commit'),
              ),
        ),
      );
    });

    test('transaction timeout throws TransactionError', () async {
      final slowBackend =
          SupabaseBackend<TestModel, String>.withRealtimeWrapper(
        wrapper: mockWrapper,
        realtimeWrapper: mockRealtimeWrapper,
        tableName: 'test_models',
        getId: (model) => model.id,
        fromJson: TestModel.fromJson,
        toJson: (model) => model.toJson(),
        transactionTimeout: const Duration(milliseconds: 50),
      );
      await slowBackend.initialize();

      expect(
        () => slowBackend.runInTransaction(() async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return 'never reached';
        }),
        throwsA(
          isA<nexus.TransactionError>()
              .having((e) => e.wasRolledBack, 'wasRolledBack', isTrue),
        ),
      );

      await slowBackend.close();
    });

    test('nested transactions throw TransactionError', () async {
      when(
        () => mockWrapper.rpc(
          'nx_batch_execute',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) async => {'status': 'ok'});

      expect(
        () => backend.runInTransaction(
          () async => backend.runInTransaction(() async => 'nested'),
        ),
        throwsA(isA<nexus.TransactionError>()),
      );
    });

    test('operations after transaction completes execute normally', () async {
      when(
        () => mockWrapper.rpc(
          'nx_batch_execute',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) async => {'status': 'ok'});

      // Complete a transaction
      await backend.runInTransaction(() async {
        await backend.save(const TestModel(id: '1', name: 'Alice'));
      });

      // Normal save should go directly to Supabase (not buffered)
      when(() => mockWrapper.upsert('test_models', any())).thenAnswer(
        (_) async => {'id': '2', 'name': 'Bob'},
      );

      final result = await backend.save(const TestModel(id: '2', name: 'Bob'));
      expect(result.id, '2');

      verify(() => mockWrapper.upsert('test_models', any())).called(1);
    });

    test('empty transaction skips RPC call', () async {
      await backend.runInTransaction(() async => 'empty');

      // No RPC call needed for empty transaction
      verifyNever(
        () => mockWrapper.rpc(
          'nx_batch_execute',
          params: any(named: 'params'),
        ),
      );
    });

    test('custom transaction function name is used', () async {
      final customBackend =
          SupabaseBackend<TestModel, String>.withRealtimeWrapper(
        wrapper: mockWrapper,
        realtimeWrapper: mockRealtimeWrapper,
        tableName: 'test_models',
        getId: (model) => model.id,
        fromJson: TestModel.fromJson,
        toJson: (model) => model.toJson(),
        transactionFunctionName: 'custom_batch',
      );
      await customBackend.initialize();

      when(
        () => mockWrapper.rpc(
          'custom_batch',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) async => {'status': 'ok'});

      await customBackend.runInTransaction(() async {
        await customBackend.save(const TestModel(id: '1', name: 'Alice'));
      });

      verify(
        () => mockWrapper.rpc(
          'custom_batch',
          params: any(named: 'params'),
        ),
      ).called(1);

      await customBackend.close();
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
