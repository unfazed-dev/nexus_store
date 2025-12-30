import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_bloc_binding/nexus_store_bloc_binding.dart';
import 'package:test/test.dart';

import '../fixtures/test_entities.dart';

void main() {
  group('NexusStoreEvent', () {
    group('LoadAll', () {
      test('should create without query', () {
        const event = LoadAll<TestUser, String>();
        expect(event.query, isNull);
      });

      test('should create with query', () {
        const query = Query<TestUser>();
        final event = LoadAll<TestUser, String>(query: query);
        expect(event.query, equals(query));
      });

      test('should have value equality with same query', () {
        const query = Query<TestUser>();
        final event1 = LoadAll<TestUser, String>(query: query);
        final event2 = LoadAll<TestUser, String>(query: query);
        expect(event1, equals(event2));
      });

      test('should be a NexusStoreEvent', () {
        const event = LoadAll<TestUser, String>();
        expect(event, isA<NexusStoreEvent<TestUser, String>>());
      });
    });

    group('Save', () {
      test('should hold the item', () {
        const user = TestUser(id: 'user-1', name: 'Test User');
        const event = Save<TestUser, String>(user);
        expect(event.item, equals(user));
      });

      test('should hold policy and tags', () {
        const user = TestUser(id: 'user-1', name: 'Test User');
        const event = Save<TestUser, String>(
          user,
          policy: WritePolicy.cacheOnly,
          tags: {'tag1', 'tag2'},
        );
        expect(event.item, equals(user));
        expect(event.policy, equals(WritePolicy.cacheOnly));
        expect(event.tags, equals({'tag1', 'tag2'}));
      });

      test('should have value equality with same item', () {
        const user = TestUser(id: 'user-1', name: 'Test User');
        const event1 = Save<TestUser, String>(user);
        const event2 = Save<TestUser, String>(user);
        expect(event1, equals(event2));
      });

      test('should be a NexusStoreEvent', () {
        const user = TestUser(id: 'user-1', name: 'Test User');
        const event = Save<TestUser, String>(user);
        expect(event, isA<NexusStoreEvent<TestUser, String>>());
      });
    });

    group('SaveAll', () {
      test('should hold the items', () {
        const users = [
          TestUser(id: 'user-1', name: 'User 1'),
          TestUser(id: 'user-2', name: 'User 2'),
        ];
        const event = SaveAll<TestUser, String>(users);
        expect(event.items, equals(users));
      });

      test('should hold policy and tags', () {
        const users = [
          TestUser(id: 'user-1', name: 'User 1'),
        ];
        const event = SaveAll<TestUser, String>(
          users,
          policy: WritePolicy.networkFirst,
          tags: {'batch'},
        );
        expect(event.items, equals(users));
        expect(event.policy, equals(WritePolicy.networkFirst));
        expect(event.tags, equals({'batch'}));
      });

      test('should be a NexusStoreEvent', () {
        const event = SaveAll<TestUser, String>([]);
        expect(event, isA<NexusStoreEvent<TestUser, String>>());
      });
    });

    group('Delete', () {
      test('should hold the id', () {
        const event = Delete<TestUser, String>('user-1');
        expect(event.id, equals('user-1'));
      });

      test('should hold policy', () {
        const event = Delete<TestUser, String>(
          'user-1',
          policy: WritePolicy.cacheOnly,
        );
        expect(event.id, equals('user-1'));
        expect(event.policy, equals(WritePolicy.cacheOnly));
      });

      test('should have value equality with same id', () {
        const event1 = Delete<TestUser, String>('user-1');
        const event2 = Delete<TestUser, String>('user-1');
        expect(event1, equals(event2));
      });

      test('should be a NexusStoreEvent', () {
        const event = Delete<TestUser, String>('user-1');
        expect(event, isA<NexusStoreEvent<TestUser, String>>());
      });
    });

    group('DeleteAll', () {
      test('should hold the ids', () {
        const event = DeleteAll<TestUser, String>(['user-1', 'user-2']);
        expect(event.ids, equals(['user-1', 'user-2']));
      });

      test('should hold policy', () {
        const event = DeleteAll<TestUser, String>(
          ['user-1'],
          policy: WritePolicy.cacheOnly,
        );
        expect(event.ids, equals(['user-1']));
        expect(event.policy, equals(WritePolicy.cacheOnly));
      });

      test('should be a NexusStoreEvent', () {
        const event = DeleteAll<TestUser, String>([]);
        expect(event, isA<NexusStoreEvent<TestUser, String>>());
      });
    });

    group('Refresh', () {
      test('should be a singleton-like const', () {
        const event1 = Refresh<TestUser, String>();
        const event2 = Refresh<TestUser, String>();
        expect(identical(event1, event2), isTrue);
      });

      test('should be a NexusStoreEvent', () {
        const event = Refresh<TestUser, String>();
        expect(event, isA<NexusStoreEvent<TestUser, String>>());
      });
    });

    group('toString', () {
      test('LoadAll toString', () {
        const event = LoadAll<TestUser, String>();
        expect(event.toString(), contains('LoadAll'));
      });

      test('Save toString', () {
        const user = TestUser(id: 'user-1', name: 'Test');
        const event = Save<TestUser, String>(user);
        expect(event.toString(), contains('Save'));
        expect(event.toString(), contains('user-1'));
      });

      test('Delete toString', () {
        const event = Delete<TestUser, String>('user-1');
        expect(event.toString(), contains('Delete'));
        expect(event.toString(), contains('user-1'));
      });

      test('Refresh toString', () {
        const event = Refresh<TestUser, String>();
        expect(event.toString(), contains('Refresh'));
      });
    });
  });
}
