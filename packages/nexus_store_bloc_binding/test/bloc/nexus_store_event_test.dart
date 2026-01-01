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
        const event = LoadAll<TestUser, String>(query: query);
        expect(event.query, equals(query));
      });

      test('should have value equality with same query', () {
        const query = Query<TestUser>();
        const event1 = LoadAll<TestUser, String>(query: query);
        const event2 = LoadAll<TestUser, String>(query: query);
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

      test('SaveAll toString', () {
        const users = [TestUser(id: 'user-1', name: 'Test')];
        const event = SaveAll<TestUser, String>(users);
        expect(event.toString(), contains('SaveAll'));
      });

      test('Delete toString', () {
        const event = Delete<TestUser, String>('user-1');
        expect(event.toString(), contains('Delete'));
        expect(event.toString(), contains('user-1'));
      });

      test('DeleteAll toString', () {
        const event = DeleteAll<TestUser, String>(['user-1', 'user-2']);
        expect(event.toString(), contains('DeleteAll'));
      });

      test('Refresh toString', () {
        const event = Refresh<TestUser, String>();
        expect(event.toString(), contains('Refresh'));
      });

      test('DataReceived toString', () {
        const users = [TestUser(id: 'user-1', name: 'Test')];
        const event = DataReceived<TestUser, String>(users);
        expect(event.toString(), contains('DataReceived'));
      });

      test('ErrorReceived toString', () {
        final error = Exception('test');
        final stackTrace = StackTrace.current;
        final event = ErrorReceived<TestUser, String>(error, stackTrace);
        expect(event.toString(), contains('ErrorReceived'));
      });
    });

    group('hashCode', () {
      test('LoadAll hashCode is consistent', () {
        const query = Query<TestUser>();
        const event1 = LoadAll<TestUser, String>(query: query);
        const event2 = LoadAll<TestUser, String>(query: query);
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('LoadAll hashCode differs with different query', () {
        const event1 = LoadAll<TestUser, String>();
        const event2 = LoadAll<TestUser, String>(query: Query<TestUser>());
        expect(event1.hashCode, isNot(equals(event2.hashCode)));
      });

      test('Save hashCode is consistent', () {
        const user = TestUser(id: 'user-1', name: 'Test');
        const event1 = Save<TestUser, String>(user);
        const event2 = Save<TestUser, String>(user);
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('Save hashCode handles null tags', () {
        const user = TestUser(id: 'user-1', name: 'Test');
        const event = Save<TestUser, String>(user);
        expect(event.hashCode, isNotNull);
      });

      test('Save hashCode handles non-null tags', () {
        const user = TestUser(id: 'user-1', name: 'Test');
        const event = Save<TestUser, String>(user, tags: {'tag1'});
        expect(event.hashCode, isNotNull);
      });

      test('SaveAll hashCode is consistent', () {
        const users = [TestUser(id: 'user-1', name: 'Test')];
        const event1 = SaveAll<TestUser, String>(users);
        const event2 = SaveAll<TestUser, String>(users);
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('SaveAll hashCode handles null tags', () {
        const users = [TestUser(id: 'user-1', name: 'Test')];
        const event = SaveAll<TestUser, String>(users);
        expect(event.hashCode, isNotNull);
      });

      test('SaveAll hashCode handles non-null tags', () {
        const users = [TestUser(id: 'user-1', name: 'Test')];
        const event = SaveAll<TestUser, String>(users, tags: {'tag1'});
        expect(event.hashCode, isNotNull);
      });

      test('Delete hashCode is consistent', () {
        const event1 = Delete<TestUser, String>('user-1');
        const event2 = Delete<TestUser, String>('user-1');
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('DeleteAll hashCode is consistent', () {
        const event1 = DeleteAll<TestUser, String>(['user-1']);
        const event2 = DeleteAll<TestUser, String>(['user-1']);
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('Refresh hashCode is consistent', () {
        const event1 = Refresh<TestUser, String>();
        const event2 = Refresh<TestUser, String>();
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('DataReceived hashCode is consistent', () {
        const users = [TestUser(id: 'user-1', name: 'Test')];
        const event1 = DataReceived<TestUser, String>(users);
        const event2 = DataReceived<TestUser, String>(users);
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('ErrorReceived hashCode is consistent', () {
        final error = Exception('test');
        final stackTrace = StackTrace.current;
        final event1 = ErrorReceived<TestUser, String>(error, stackTrace);
        final event2 = ErrorReceived<TestUser, String>(error, stackTrace);
        expect(event1.hashCode, equals(event2.hashCode));
      });
    });

    group('equality edge cases', () {
      test('LoadAll not equal with different query', () {
        const event1 = LoadAll<TestUser, String>();
        const event2 = LoadAll<TestUser, String>(query: Query<TestUser>());
        expect(event1, isNot(equals(event2)));
      });

      test('Save not equal with different item', () {
        const user1 = TestUser(id: 'user-1', name: 'Test1');
        const user2 = TestUser(id: 'user-2', name: 'Test2');
        const event1 = Save<TestUser, String>(user1);
        const event2 = Save<TestUser, String>(user2);
        expect(event1, isNot(equals(event2)));
      });

      test('Save not equal with different policy', () {
        const user = TestUser(id: 'user-1', name: 'Test');
        const event1 = Save<TestUser, String>(user);
        const event2 = Save<TestUser, String>(
          user,
          policy: WritePolicy.cacheOnly,
        );
        expect(event1, isNot(equals(event2)));
      });

      test('Save not equal with different tags', () {
        const user = TestUser(id: 'user-1', name: 'Test');
        const event1 = Save<TestUser, String>(user, tags: {'tag1'});
        const event2 = Save<TestUser, String>(user, tags: {'tag2'});
        expect(event1, isNot(equals(event2)));
      });

      test('SaveAll not equal with different items', () {
        const users1 = [TestUser(id: 'user-1', name: 'Test1')];
        const users2 = [TestUser(id: 'user-2', name: 'Test2')];
        const event1 = SaveAll<TestUser, String>(users1);
        const event2 = SaveAll<TestUser, String>(users2);
        expect(event1, isNot(equals(event2)));
      });

      test('SaveAll not equal with different policy', () {
        const users = [TestUser(id: 'user-1', name: 'Test')];
        const event1 = SaveAll<TestUser, String>(users);
        const event2 = SaveAll<TestUser, String>(
          users,
          policy: WritePolicy.cacheOnly,
        );
        expect(event1, isNot(equals(event2)));
      });

      test('SaveAll not equal with different tags', () {
        const users = [TestUser(id: 'user-1', name: 'Test')];
        const event1 = SaveAll<TestUser, String>(users, tags: {'tag1'});
        const event2 = SaveAll<TestUser, String>(users, tags: {'tag2'});
        expect(event1, isNot(equals(event2)));
      });

      test('Delete not equal with different id', () {
        const event1 = Delete<TestUser, String>('user-1');
        const event2 = Delete<TestUser, String>('user-2');
        expect(event1, isNot(equals(event2)));
      });

      test('Delete not equal with different policy', () {
        const event1 = Delete<TestUser, String>('user-1');
        const event2 = Delete<TestUser, String>(
          'user-1',
          policy: WritePolicy.cacheOnly,
        );
        expect(event1, isNot(equals(event2)));
      });

      test('DeleteAll not equal with different ids', () {
        const event1 = DeleteAll<TestUser, String>(['user-1']);
        const event2 = DeleteAll<TestUser, String>(['user-2']);
        expect(event1, isNot(equals(event2)));
      });

      test('DeleteAll not equal with different policy', () {
        const event1 = DeleteAll<TestUser, String>(['user-1']);
        const event2 = DeleteAll<TestUser, String>(
          ['user-1'],
          policy: WritePolicy.cacheOnly,
        );
        expect(event1, isNot(equals(event2)));
      });

      test('DataReceived not equal with different data', () {
        const users1 = [TestUser(id: 'user-1', name: 'Test1')];
        const users2 = [TestUser(id: 'user-2', name: 'Test2')];
        const event1 = DataReceived<TestUser, String>(users1);
        const event2 = DataReceived<TestUser, String>(users2);
        expect(event1, isNot(equals(event2)));
      });

      test('DataReceived equal with same data', () {
        const users = [TestUser(id: 'user-1', name: 'Test')];
        const event1 = DataReceived<TestUser, String>(users);
        const event2 = DataReceived<TestUser, String>(users);
        expect(event1, equals(event2));
      });

      test('ErrorReceived not equal with different error', () {
        final error1 = Exception('error1');
        final error2 = Exception('error2');
        final stackTrace = StackTrace.current;
        final event1 = ErrorReceived<TestUser, String>(error1, stackTrace);
        final event2 = ErrorReceived<TestUser, String>(error2, stackTrace);
        expect(event1, isNot(equals(event2)));
      });

      test('ErrorReceived equal with same error and stackTrace', () {
        final error = Exception('test');
        final stackTrace = StackTrace.current;
        final event1 = ErrorReceived<TestUser, String>(error, stackTrace);
        final event2 = ErrorReceived<TestUser, String>(error, stackTrace);
        expect(event1, equals(event2));
      });

      test('events not equal to different types', () {
        const event1 = LoadAll<TestUser, String>();
        const event2 = Refresh<TestUser, String>();
        expect(event1, isNot(equals(event2)));
      });

      test('event equals itself (identical)', () {
        const event = LoadAll<TestUser, String>();
        expect(event == event, isTrue);
      });
    });

    group('internal events', () {
      test('DataReceived should be a NexusStoreEvent', () {
        const users = [TestUser(id: 'user-1', name: 'Test')];
        const event = DataReceived<TestUser, String>(users);
        expect(event, isA<NexusStoreEvent<TestUser, String>>());
      });

      test('ErrorReceived should be a NexusStoreEvent', () {
        final error = Exception('test');
        final stackTrace = StackTrace.current;
        final event = ErrorReceived<TestUser, String>(error, stackTrace);
        expect(event, isA<NexusStoreEvent<TestUser, String>>());
      });
    });
  });
}
