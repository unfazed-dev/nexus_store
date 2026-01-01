import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_bloc_binding/nexus_store_bloc_binding.dart';
import 'package:test/test.dart';

import '../fixtures/test_entities.dart';

void main() {
  group('NexusItemEvent', () {
    group('LoadItem', () {
      test('should be a singleton-like const', () {
        const event1 = LoadItem<TestUser, String>();
        const event2 = LoadItem<TestUser, String>();
        expect(identical(event1, event2), isTrue);
      });

      test('should be a NexusItemEvent', () {
        const event = LoadItem<TestUser, String>();
        expect(event, isA<NexusItemEvent<TestUser, String>>());
      });

      test('should have value equality', () {
        const event1 = LoadItem<TestUser, String>();
        const event2 = LoadItem<TestUser, String>();
        expect(event1, equals(event2));
      });

      test('hashCode is consistent', () {
        const event1 = LoadItem<TestUser, String>();
        const event2 = LoadItem<TestUser, String>();
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('toString contains LoadItem', () {
        const event = LoadItem<TestUser, String>();
        expect(event.toString(), contains('LoadItem'));
      });

      test('equals itself (identical)', () {
        const event = LoadItem<TestUser, String>();
        expect(event == event, isTrue);
      });
    });

    group('SaveItem', () {
      test('should hold the item', () {
        const user = TestUser(id: 'user-1', name: 'Test User');
        const event = SaveItem<TestUser, String>(user);
        expect(event.item, equals(user));
      });

      test('should hold policy and tags', () {
        const user = TestUser(id: 'user-1', name: 'Test User');
        const event = SaveItem<TestUser, String>(
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
        const event1 = SaveItem<TestUser, String>(user);
        const event2 = SaveItem<TestUser, String>(user);
        expect(event1, equals(event2));
      });

      test('should be a NexusItemEvent', () {
        const user = TestUser(id: 'user-1', name: 'Test User');
        const event = SaveItem<TestUser, String>(user);
        expect(event, isA<NexusItemEvent<TestUser, String>>());
      });

      test('hashCode is consistent', () {
        const user = TestUser(id: 'user-1', name: 'Test');
        const event1 = SaveItem<TestUser, String>(user);
        const event2 = SaveItem<TestUser, String>(user);
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('hashCode handles null tags', () {
        const user = TestUser(id: 'user-1', name: 'Test');
        const event = SaveItem<TestUser, String>(user);
        expect(event.hashCode, isNotNull);
      });

      test('hashCode handles non-null tags', () {
        const user = TestUser(id: 'user-1', name: 'Test');
        const event = SaveItem<TestUser, String>(user, tags: {'tag1'});
        expect(event.hashCode, isNotNull);
      });

      test('toString contains SaveItem', () {
        const user = TestUser(id: 'user-1', name: 'Test');
        const event = SaveItem<TestUser, String>(user);
        expect(event.toString(), contains('SaveItem'));
      });

      test('not equal with different item', () {
        const user1 = TestUser(id: 'user-1', name: 'Test1');
        const user2 = TestUser(id: 'user-2', name: 'Test2');
        const event1 = SaveItem<TestUser, String>(user1);
        const event2 = SaveItem<TestUser, String>(user2);
        expect(event1, isNot(equals(event2)));
      });

      test('not equal with different policy', () {
        const user = TestUser(id: 'user-1', name: 'Test');
        const event1 = SaveItem<TestUser, String>(user);
        const event2 = SaveItem<TestUser, String>(
          user,
          policy: WritePolicy.cacheOnly,
        );
        expect(event1, isNot(equals(event2)));
      });

      test('not equal with different tags', () {
        const user = TestUser(id: 'user-1', name: 'Test');
        const event1 = SaveItem<TestUser, String>(user, tags: {'tag1'});
        const event2 = SaveItem<TestUser, String>(user, tags: {'tag2'});
        expect(event1, isNot(equals(event2)));
      });

      test('equals itself (identical)', () {
        const user = TestUser(id: 'user-1', name: 'Test');
        const event = SaveItem<TestUser, String>(user);
        expect(event == event, isTrue);
      });
    });

    group('DeleteItem', () {
      test('should be created with default values', () {
        const event = DeleteItem<TestUser, String>();
        expect(event.policy, isNull);
      });

      test('should hold policy', () {
        const event = DeleteItem<TestUser, String>(
          policy: WritePolicy.cacheOnly,
        );
        expect(event.policy, equals(WritePolicy.cacheOnly));
      });

      test('should have value equality', () {
        const event1 = DeleteItem<TestUser, String>();
        const event2 = DeleteItem<TestUser, String>();
        expect(event1, equals(event2));
      });

      test('should be a NexusItemEvent', () {
        const event = DeleteItem<TestUser, String>();
        expect(event, isA<NexusItemEvent<TestUser, String>>());
      });

      test('hashCode is consistent', () {
        const event1 = DeleteItem<TestUser, String>();
        const event2 = DeleteItem<TestUser, String>();
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('toString contains DeleteItem', () {
        const event = DeleteItem<TestUser, String>();
        expect(event.toString(), contains('DeleteItem'));
      });

      test('not equal with different policy', () {
        const event1 = DeleteItem<TestUser, String>();
        const event2 = DeleteItem<TestUser, String>(
          policy: WritePolicy.cacheOnly,
        );
        expect(event1, isNot(equals(event2)));
      });

      test('equals itself (identical)', () {
        const event = DeleteItem<TestUser, String>();
        expect(event == event, isTrue);
      });
    });

    group('RefreshItem', () {
      test('should be a singleton-like const', () {
        const event1 = RefreshItem<TestUser, String>();
        const event2 = RefreshItem<TestUser, String>();
        expect(identical(event1, event2), isTrue);
      });

      test('should be a NexusItemEvent', () {
        const event = RefreshItem<TestUser, String>();
        expect(event, isA<NexusItemEvent<TestUser, String>>());
      });

      test('should have value equality', () {
        const event1 = RefreshItem<TestUser, String>();
        const event2 = RefreshItem<TestUser, String>();
        expect(event1, equals(event2));
      });

      test('hashCode is consistent', () {
        const event1 = RefreshItem<TestUser, String>();
        const event2 = RefreshItem<TestUser, String>();
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('toString contains RefreshItem', () {
        const event = RefreshItem<TestUser, String>();
        expect(event.toString(), contains('RefreshItem'));
      });

      test('equals itself (identical)', () {
        const event = RefreshItem<TestUser, String>();
        expect(event == event, isTrue);
      });
    });

    group('ItemDataReceived', () {
      test('should hold the data', () {
        const user = TestUser(id: 'user-1', name: 'Test');
        const event = ItemDataReceived<TestUser, String>(user);
        expect(event.data, equals(user));
      });

      test('should hold null data', () {
        const event = ItemDataReceived<TestUser, String>(null);
        expect(event.data, isNull);
      });

      test('should have value equality', () {
        const user = TestUser(id: 'user-1', name: 'Test');
        const event1 = ItemDataReceived<TestUser, String>(user);
        const event2 = ItemDataReceived<TestUser, String>(user);
        expect(event1, equals(event2));
      });

      test('should be a NexusItemEvent', () {
        const user = TestUser(id: 'user-1', name: 'Test');
        const event = ItemDataReceived<TestUser, String>(user);
        expect(event, isA<NexusItemEvent<TestUser, String>>());
      });

      test('hashCode is consistent', () {
        const user = TestUser(id: 'user-1', name: 'Test');
        const event1 = ItemDataReceived<TestUser, String>(user);
        const event2 = ItemDataReceived<TestUser, String>(user);
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('toString contains ItemDataReceived', () {
        const user = TestUser(id: 'user-1', name: 'Test');
        const event = ItemDataReceived<TestUser, String>(user);
        expect(event.toString(), contains('ItemDataReceived'));
      });

      test('not equal with different data', () {
        const user1 = TestUser(id: 'user-1', name: 'Test1');
        const user2 = TestUser(id: 'user-2', name: 'Test2');
        const event1 = ItemDataReceived<TestUser, String>(user1);
        const event2 = ItemDataReceived<TestUser, String>(user2);
        expect(event1, isNot(equals(event2)));
      });

      test('not equal when one is null', () {
        const user = TestUser(id: 'user-1', name: 'Test');
        const event1 = ItemDataReceived<TestUser, String>(user);
        const event2 = ItemDataReceived<TestUser, String>(null);
        expect(event1, isNot(equals(event2)));
      });

      test('equals itself (identical)', () {
        const user = TestUser(id: 'user-1', name: 'Test');
        const event = ItemDataReceived<TestUser, String>(user);
        expect(event == event, isTrue);
      });
    });

    group('ItemErrorReceived', () {
      test('should hold error and stackTrace', () {
        final error = Exception('test');
        final stackTrace = StackTrace.current;
        final event = ItemErrorReceived<TestUser, String>(error, stackTrace);
        expect(event.error, equals(error));
        expect(event.stackTrace, equals(stackTrace));
      });

      test('should have value equality', () {
        final error = Exception('test');
        final stackTrace = StackTrace.current;
        final event1 = ItemErrorReceived<TestUser, String>(error, stackTrace);
        final event2 = ItemErrorReceived<TestUser, String>(error, stackTrace);
        expect(event1, equals(event2));
      });

      test('should be a NexusItemEvent', () {
        final error = Exception('test');
        final stackTrace = StackTrace.current;
        final event = ItemErrorReceived<TestUser, String>(error, stackTrace);
        expect(event, isA<NexusItemEvent<TestUser, String>>());
      });

      test('hashCode is consistent', () {
        final error = Exception('test');
        final stackTrace = StackTrace.current;
        final event1 = ItemErrorReceived<TestUser, String>(error, stackTrace);
        final event2 = ItemErrorReceived<TestUser, String>(error, stackTrace);
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('toString contains ItemErrorReceived', () {
        final error = Exception('test');
        final stackTrace = StackTrace.current;
        final event = ItemErrorReceived<TestUser, String>(error, stackTrace);
        expect(event.toString(), contains('ItemErrorReceived'));
      });

      test('not equal with different error', () {
        final error1 = Exception('error1');
        final error2 = Exception('error2');
        final stackTrace = StackTrace.current;
        final event1 = ItemErrorReceived<TestUser, String>(error1, stackTrace);
        final event2 = ItemErrorReceived<TestUser, String>(error2, stackTrace);
        expect(event1, isNot(equals(event2)));
      });

      test('equals itself (identical)', () {
        final error = Exception('test');
        final stackTrace = StackTrace.current;
        final event = ItemErrorReceived<TestUser, String>(error, stackTrace);
        expect(event == event, isTrue);
      });
    });

    group('event type distinction', () {
      test('different event types are not equal', () {
        const loadEvent = LoadItem<TestUser, String>();
        const refreshEvent = RefreshItem<TestUser, String>();
        expect(loadEvent, isNot(equals(refreshEvent)));
      });
    });
  });
}
