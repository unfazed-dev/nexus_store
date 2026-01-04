import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_supabase_adapter/src/supabase_realtime_manager.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

// Mock classes
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

// Test model
class TestUser {
  const TestUser({required this.id, required this.name});

  factory TestUser.fromJson(Map<String, dynamic> json) => TestUser(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestUser && id == other.id && name == other.name;

  @override
  int get hashCode => Object.hash(id, name);
}

void main() {
  setUpAll(() {
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue((PostgresChangePayload p) {});
    registerFallbackValue(MockRealtimeChannel());
  });
  group('SupabaseRealtimeManager', () {
    late MockSupabaseClient mockClient;
    late MockRealtimeChannel mockChannel;
    late SupabaseRealtimeManager<TestUser, String> manager;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockChannel = MockRealtimeChannel();

      // Setup default mock behavior
      when(() => mockClient.channel(any())).thenReturn(mockChannel);
      when(
        () => mockChannel.onPostgresChanges(
          event: any(named: 'event'),
          schema: any(named: 'schema'),
          table: any(named: 'table'),
          callback: any(named: 'callback'),
        ),
      ).thenReturn(mockChannel);
      when(() => mockChannel.subscribe()).thenReturn(mockChannel);
      when(() => mockClient.removeChannel(any())).thenAnswer((_) async => 'ok');

      manager = SupabaseRealtimeManager<TestUser, String>(
        client: mockClient,
        tableName: 'users',
        fromJson: TestUser.fromJson,
        getId: (user) => user.id,
      );
    });

    tearDown(() async {
      try {
        await manager.dispose();
      } on Object {
        // Ignore dispose errors
      }
    });

    group('construction', () {
      test('creates manager with required parameters', () {
        expect(manager, isNotNull);
        expect(manager.isInitialized, isFalse);
      });

      test('creates manager with custom primary key column', () {
        final customManager = SupabaseRealtimeManager<TestUser, String>(
          client: mockClient,
          tableName: 'users',
          fromJson: TestUser.fromJson,
          getId: (user) => user.id,
          primaryKeyColumn: 'uuid',
        );
        expect(customManager, isNotNull);
      });

      test('creates manager with custom schema', () {
        final customManager = SupabaseRealtimeManager<TestUser, String>(
          client: mockClient,
          tableName: 'users',
          fromJson: TestUser.fromJson,
          getId: (user) => user.id,
          schema: 'custom_schema',
        );
        expect(customManager, isNotNull);
      });
    });

    group('initialize', () {
      test('initializes the realtime manager', () async {
        await manager.initialize();

        expect(manager.isInitialized, isTrue);
        verify(() => mockClient.channel('users_changes')).called(1);
      });

      test('sets up postgres changes listener', () async {
        await manager.initialize();

        verify(
          () => mockChannel.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'users',
            callback: any(named: 'callback'),
          ),
        ).called(1);
        verify(() => mockChannel.subscribe()).called(1);
      });

      test('initialize does nothing if already initialized', () async {
        await manager.initialize();
        await manager.initialize();

        // Should only be called once
        verify(() => mockClient.channel(any())).called(1);
      });

      test('initialize does nothing if disposed', () async {
        await manager.dispose();
        await manager.initialize();

        // Should not create channel after dispose
        verifyNever(() => mockClient.channel(any()));
      });
    });

    group('dispose', () {
      test('disposes resources', () async {
        await manager.initialize();
        await manager.dispose();

        expect(manager.isInitialized, isFalse);
        verify(() => mockClient.removeChannel(mockChannel)).called(1);
      });

      test('dispose can be called multiple times', () async {
        await manager.initialize();
        await manager.dispose();
        await manager.dispose();

        // Should only remove channel once
        verify(() => mockClient.removeChannel(mockChannel)).called(1);
      });

      test('closes all item subjects on dispose', () async {
        await manager.initialize();

        // Create some subjects
        manager
          ..watchItem('1')
          ..watchItem('2');

        await manager.dispose();

        // After dispose, trying to watch should throw
        expect(
          () => manager.watchItem('1'),
          throwsA(isA<StateError>()),
        );
      });

      test('closes all items subject on dispose', () async {
        await manager.initialize();

        manager.watchAll();

        await manager.dispose();

        // After dispose, trying to watch should throw
        expect(
          () => manager.watchAll(),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('watchItem', () {
      test('throws StateError when not initialized', () async {
        expect(
          () => manager.watchItem('1'),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError when disposed', () async {
        await manager.initialize();
        await manager.dispose();

        expect(
          () => manager.watchItem('1'),
          throwsA(isA<StateError>()),
        );
      });

      test('returns stream for item', () async {
        await manager.initialize();

        final stream = manager.watchItem('1');

        expect(stream, isA<Stream<TestUser?>>());
      });

      test('returns same stream for same ID', () async {
        await manager.initialize();

        final stream1 = manager.watchItem('1');
        final stream2 = manager.watchItem('1');

        // Both streams should emit the same values (backed by same subject)
        const user = TestUser(id: '1', name: 'Test');
        manager.notifyItemChanged(user);

        await expectLater(stream1, emitsThrough(user));
        await expectLater(stream2, emitsThrough(user));
      });

      test('returns different streams for different IDs', () async {
        await manager.initialize();

        final stream1 = manager.watchItem('1');
        final stream2 = manager.watchItem('2');

        expect(identical(stream1, stream2), isFalse);
      });

      test('seeds stream with initial value', () async {
        await manager.initialize();

        const initialUser = TestUser(id: '1', name: 'Initial');
        final stream = manager.watchItem('1', initialValue: initialUser);

        await expectLater(stream, emits(initialUser));
      });

      test('seeds stream with null if no initial value', () async {
        await manager.initialize();

        final stream = manager.watchItem('1');

        await expectLater(stream, emits(null));
      });
    });

    group('watchAll', () {
      test('throws StateError when not initialized', () async {
        expect(
          () => manager.watchAll(),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError when disposed', () async {
        await manager.initialize();
        await manager.dispose();

        expect(
          () => manager.watchAll(),
          throwsA(isA<StateError>()),
        );
      });

      test('returns stream for all items', () async {
        await manager.initialize();

        final stream = manager.watchAll();

        expect(stream, isA<Stream<List<TestUser>>>());
      });

      test('returns same stream on subsequent calls', () async {
        await manager.initialize();

        final stream1 = manager.watchAll();
        final stream2 = manager.watchAll();

        // Both streams should emit the same values (backed by same subject)
        const user = TestUser(id: '1', name: 'Test');
        manager.notifyItemChanged(user);

        await expectLater(
          stream1,
          emitsThrough(predicate<List<TestUser>>((users) => users.length == 1)),
        );
        await expectLater(
          stream2,
          emitsThrough(predicate<List<TestUser>>((users) => users.length == 1)),
        );
      });

      test('seeds stream with initial value', () async {
        await manager.initialize();

        const initialUsers = [
          TestUser(id: '1', name: 'User 1'),
          TestUser(id: '2', name: 'User 2'),
        ];
        final stream = manager.watchAll(initialValue: initialUsers);

        await expectLater(
          stream,
          emits(
            predicate<List<TestUser>>(
              (users) => users.length == 2,
            ),
          ),
        );
      });

      test('seeds stream with empty list if no initial value', () async {
        await manager.initialize();

        final stream = manager.watchAll();

        await expectLater(stream, emits(isEmpty));
      });
    });

    group('notifyItemChanged', () {
      test('updates item subject', () async {
        await manager.initialize();

        final stream = manager.watchItem('1');

        const user = TestUser(id: '1', name: 'Test User');
        manager.notifyItemChanged(user);

        await expectLater(stream, emitsThrough(user));
      });

      test('updates all items subject', () async {
        await manager.initialize();

        final stream = manager.watchAll();

        const user = TestUser(id: '1', name: 'Test User');
        manager.notifyItemChanged(user);

        await expectLater(
          stream,
          emitsThrough(
            predicate<List<TestUser>>(
              (users) => users.length == 1 && users.first.id == '1',
            ),
          ),
        );
      });

      test('updates existing item in all items map', () async {
        await manager.initialize();

        const initialUsers = [TestUser(id: '1', name: 'Original')];
        final stream = manager.watchAll(initialValue: initialUsers);

        const updatedUser = TestUser(id: '1', name: 'Updated');
        manager.notifyItemChanged(updatedUser);

        await expectLater(
          stream,
          emitsThrough(
            predicate<List<TestUser>>(
              (users) => users.length == 1 && users.first.name == 'Updated',
            ),
          ),
        );
      });

      test('does not notify if item subject does not exist', () async {
        await manager.initialize();

        // Just call without creating a stream first
        const user = TestUser(id: '1', name: 'Test');
        manager.notifyItemChanged(user);

        // Should update all items map
        final stream = manager.watchAll();
        await expectLater(
          stream,
          emitsThrough(
            predicate<List<TestUser>>(
              (users) => users.length == 1,
            ),
          ),
        );
      });
    });

    group('notifyItemDeleted', () {
      test('notifies item subject with null', () async {
        await manager.initialize();

        const user = TestUser(id: '1', name: 'Test');
        final stream = manager.watchItem('1', initialValue: user);

        manager.notifyItemDeleted('1');

        await expectLater(stream, emitsThrough(null));
      });

      test('removes item from all items map', () async {
        await manager.initialize();

        const initialUsers = [
          TestUser(id: '1', name: 'User 1'),
          TestUser(id: '2', name: 'User 2'),
        ];
        final stream = manager.watchAll(initialValue: initialUsers);

        manager.notifyItemDeleted('1');

        await expectLater(
          stream,
          emitsThrough(
            predicate<List<TestUser>>(
              (users) => users.length == 1 && users.first.id == '2',
            ),
          ),
        );
      });

      test('does not throw if item subject does not exist', () async {
        await manager.initialize();

        // Delete item that was never watched
        expect(() => manager.notifyItemDeleted('nonexistent'), returnsNormally);
      });
    });

    group('realtime event handling', () {
      late void Function(PostgresChangePayload) capturedCallback;

      setUp(() {
        when(
          () => mockChannel.onPostgresChanges(
            event: any(named: 'event'),
            schema: any(named: 'schema'),
            table: any(named: 'table'),
            callback: any(named: 'callback'),
          ),
        ).thenAnswer((invocation) {
          capturedCallback = invocation.namedArguments[#callback] as void
              Function(PostgresChangePayload);
          return mockChannel;
        });
      });

      test('handles INSERT event', () async {
        await manager.initialize();

        final stream = manager.watchAll();

        // Simulate INSERT event
        capturedCallback(
          _createPayload(
            eventType: PostgresChangeEvent.insert,
            newRecord: {'id': '1', 'name': 'New User'},
          ),
        );

        await expectLater(
          stream,
          emitsThrough(
            predicate<List<TestUser>>(
              (users) => users.any((u) => u.id == '1' && u.name == 'New User'),
            ),
          ),
        );
      });

      test('handles UPDATE event', () async {
        await manager.initialize();

        const initialUsers = [TestUser(id: '1', name: 'Original')];
        final stream = manager.watchAll(initialValue: initialUsers);

        // Simulate UPDATE event
        capturedCallback(
          _createPayload(
            eventType: PostgresChangeEvent.update,
            newRecord: {'id': '1', 'name': 'Updated'},
          ),
        );

        await expectLater(
          stream,
          emitsThrough(
            predicate<List<TestUser>>(
              (users) => users.first.name == 'Updated',
            ),
          ),
        );
      });

      test('handles DELETE event', () async {
        await manager.initialize();

        const initialUsers = [TestUser(id: '1', name: 'To Delete')];
        final stream = manager.watchAll(initialValue: initialUsers);

        // Simulate DELETE event
        capturedCallback(
          _createPayload(
            eventType: PostgresChangeEvent.delete,
            oldRecord: {'id': '1', 'name': 'To Delete'},
          ),
        );

        await expectLater(
          stream,
          emitsThrough(isEmpty),
        );
      });

      test('ignores INSERT with empty new record', () async {
        await manager.initialize();

        final stream = manager.watchAll();

        // Simulate INSERT with empty record
        capturedCallback(
          _createPayload(
            eventType: PostgresChangeEvent.insert,
            newRecord: {},
          ),
        );

        // Should still emit empty list
        await expectLater(stream, emits(isEmpty));
      });

      test('ignores UPDATE with empty new record', () async {
        await manager.initialize();

        const initialUsers = [TestUser(id: '1', name: 'Original')];
        final stream = manager.watchAll(initialValue: initialUsers);

        // Simulate UPDATE with empty record
        capturedCallback(
          _createPayload(
            eventType: PostgresChangeEvent.update,
            newRecord: {},
          ),
        );

        // Should keep original value
        await expectLater(
          stream,
          emits(
            predicate<List<TestUser>>(
              (users) => users.first.name == 'Original',
            ),
          ),
        );
      });

      test('ignores DELETE with empty old record', () async {
        await manager.initialize();

        const initialUsers = [TestUser(id: '1', name: 'Keep Me')];
        final stream = manager.watchAll(initialValue: initialUsers);

        // Simulate DELETE with empty record
        capturedCallback(
          _createPayload(
            eventType: PostgresChangeEvent.delete,
            oldRecord: {},
          ),
        );

        // Should keep the item
        await expectLater(
          stream,
          emits(
            predicate<List<TestUser>>(
              (users) => users.length == 1,
            ),
          ),
        );
      });

      test('ignores DELETE with null primary key', () async {
        await manager.initialize();

        const initialUsers = [TestUser(id: '1', name: 'Keep Me')];
        final stream = manager.watchAll(initialValue: initialUsers);

        // Simulate DELETE with null id
        capturedCallback(
          _createPayload(
            eventType: PostgresChangeEvent.delete,
            oldRecord: {'id': null, 'name': 'Keep Me'},
          ),
        );

        // Should keep the item
        await expectLater(
          stream,
          emits(
            predicate<List<TestUser>>(
              (users) => users.length == 1,
            ),
          ),
        );
      });

      test('handles all event type gracefully', () async {
        await manager.initialize();

        final stream = manager.watchAll();

        // Simulate 'all' event type
        // (shouldn't happen in callback, but handle it)
        capturedCallback(
          _createPayload(
            eventType: PostgresChangeEvent.all,
            newRecord: {'id': '1', 'name': 'Test'},
          ),
        );

        // Should not crash, just emit empty list
        await expectLater(stream, emits(isEmpty));
      });

      test('handles fromJson errors gracefully', () async {
        // Create manager with fromJson that throws
        final errorManager = SupabaseRealtimeManager<TestUser, String>(
          client: mockClient,
          tableName: 'users',
          fromJson: (json) => throw Exception('Parse error'),
          getId: (user) => user.id,
        );

        await errorManager.initialize();

        final stream = errorManager.watchAll();

        // Simulate INSERT that will fail to parse
        capturedCallback(
          _createPayload(
            eventType: PostgresChangeEvent.insert,
            newRecord: {'id': '1', 'name': 'Test'},
          ),
        );

        // Should not crash the stream
        await expectLater(stream, emits(isEmpty));

        await errorManager.dispose();
      });
    });

    group('_notifyAllItemsChanged', () {
      test('does not notify if subject is null', () async {
        await manager.initialize();

        // Notify before creating watchAll stream
        const user = TestUser(id: '1', name: 'Test');
        manager.notifyItemChanged(user);

        // Should not throw
        final stream = manager.watchAll();
        await expectLater(
          stream,
          emits(predicate<List<TestUser>>((users) => users.length == 1)),
        );
      });

      test('does not notify if subject is closed', () async {
        await manager.initialize();

        manager.watchAll();
        await manager.dispose();

        // After dispose, trying to watch should throw StateError
        expect(
          () => manager.watchAll(),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}

/// Helper to create PostgresChangePayload for testing.
PostgresChangePayload _createPayload({
  required PostgresChangeEvent eventType,
  Map<String, dynamic>? newRecord,
  Map<String, dynamic>? oldRecord,
}) =>
    PostgresChangePayload(
      schema: 'public',
      table: 'users',
      commitTimestamp: DateTime.now(),
      eventType: eventType,
      newRecord: newRecord ?? {},
      oldRecord: oldRecord ?? {},
      errors: null,
    );
