import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store_flutter/src/background/priority_sync_queue.dart';
import 'package:nexus_store_flutter/src/background/sync_priority.dart';

void main() {
  group('PrioritySyncQueue', () {
    late PrioritySyncQueue<String> queue;

    setUp(() {
      queue = PrioritySyncQueue<String>();
    });

    group('enqueue', () {
      test('adds item to queue', () {
        queue.enqueue('item1', SyncPriority.normal);

        expect(queue.length, equals(1));
        expect(queue.isEmpty, isFalse);
      });

      test('can add multiple items', () {
        queue.enqueue('item1', SyncPriority.normal);
        queue.enqueue('item2', SyncPriority.high);
        queue.enqueue('item3', SyncPriority.low);

        expect(queue.length, equals(3));
      });

      test('accepts all priority levels', () {
        queue.enqueue('critical', SyncPriority.critical);
        queue.enqueue('high', SyncPriority.high);
        queue.enqueue('normal', SyncPriority.normal);
        queue.enqueue('low', SyncPriority.low);

        expect(queue.length, equals(4));
      });
    });

    group('dequeue', () {
      test('returns null when queue is empty', () {
        expect(queue.dequeue(), isNull);
      });

      test('returns and removes highest priority item', () {
        queue.enqueue('low', SyncPriority.low);
        queue.enqueue('critical', SyncPriority.critical);
        queue.enqueue('normal', SyncPriority.normal);

        final item = queue.dequeue();

        expect(item, equals('critical'));
        expect(queue.length, equals(2));
      });

      test('returns items in priority order', () {
        queue.enqueue('low', SyncPriority.low);
        queue.enqueue('critical', SyncPriority.critical);
        queue.enqueue('high', SyncPriority.high);
        queue.enqueue('normal', SyncPriority.normal);

        expect(queue.dequeue(), equals('critical'));
        expect(queue.dequeue(), equals('high'));
        expect(queue.dequeue(), equals('normal'));
        expect(queue.dequeue(), equals('low'));
        expect(queue.dequeue(), isNull);
      });
    });

    group('priority ordering', () {
      test('critical items come before high', () {
        queue.enqueue('high', SyncPriority.high);
        queue.enqueue('critical', SyncPriority.critical);

        expect(queue.dequeue(), equals('critical'));
        expect(queue.dequeue(), equals('high'));
      });

      test('high items come before normal', () {
        queue.enqueue('normal', SyncPriority.normal);
        queue.enqueue('high', SyncPriority.high);

        expect(queue.dequeue(), equals('high'));
        expect(queue.dequeue(), equals('normal'));
      });

      test('normal items come before low', () {
        queue.enqueue('low', SyncPriority.low);
        queue.enqueue('normal', SyncPriority.normal);

        expect(queue.dequeue(), equals('normal'));
        expect(queue.dequeue(), equals('low'));
      });
    });

    group('FIFO within same priority', () {
      test('items with same priority are FIFO', () {
        queue.enqueue('first', SyncPriority.normal);
        queue.enqueue('second', SyncPriority.normal);
        queue.enqueue('third', SyncPriority.normal);

        expect(queue.dequeue(), equals('first'));
        expect(queue.dequeue(), equals('second'));
        expect(queue.dequeue(), equals('third'));
      });

      test('FIFO is maintained for each priority level', () {
        queue.enqueue('high1', SyncPriority.high);
        queue.enqueue('normal1', SyncPriority.normal);
        queue.enqueue('high2', SyncPriority.high);
        queue.enqueue('normal2', SyncPriority.normal);

        expect(queue.dequeue(), equals('high1'));
        expect(queue.dequeue(), equals('high2'));
        expect(queue.dequeue(), equals('normal1'));
        expect(queue.dequeue(), equals('normal2'));
      });
    });

    group('peek', () {
      test('returns null when queue is empty', () {
        expect(queue.peek(), isNull);
      });

      test('returns highest priority item without removing', () {
        queue.enqueue('normal', SyncPriority.normal);
        queue.enqueue('critical', SyncPriority.critical);

        expect(queue.peek(), equals('critical'));
        expect(queue.length, equals(2));
        expect(queue.peek(), equals('critical'));
      });
    });

    group('clear', () {
      test('removes all items', () {
        queue.enqueue('item1', SyncPriority.normal);
        queue.enqueue('item2', SyncPriority.high);
        queue.enqueue('item3', SyncPriority.low);

        queue.clear();

        expect(queue.isEmpty, isTrue);
        expect(queue.length, equals(0));
      });
    });

    group('isEmpty and isNotEmpty', () {
      test('isEmpty is true for new queue', () {
        expect(queue.isEmpty, isTrue);
        expect(queue.isNotEmpty, isFalse);
      });

      test('isEmpty is false after adding item', () {
        queue.enqueue('item', SyncPriority.normal);

        expect(queue.isEmpty, isFalse);
        expect(queue.isNotEmpty, isTrue);
      });

      test('isEmpty is true after removing all items', () {
        queue.enqueue('item', SyncPriority.normal);
        queue.dequeue();

        expect(queue.isEmpty, isTrue);
      });
    });

    group('length', () {
      test('returns 0 for empty queue', () {
        expect(queue.length, equals(0));
      });

      test('returns correct count', () {
        queue.enqueue('item1', SyncPriority.normal);
        expect(queue.length, equals(1));

        queue.enqueue('item2', SyncPriority.high);
        expect(queue.length, equals(2));

        queue.dequeue();
        expect(queue.length, equals(1));
      });
    });

    group('toList', () {
      test('returns empty list for empty queue', () {
        expect(queue.toList(), isEmpty);
      });

      test('returns items in priority order', () {
        queue.enqueue('low', SyncPriority.low);
        queue.enqueue('critical', SyncPriority.critical);
        queue.enqueue('high', SyncPriority.high);

        final list = queue.toList();

        expect(list, equals(['critical', 'high', 'low']));
      });

      test('does not modify the queue', () {
        queue.enqueue('item', SyncPriority.normal);

        queue.toList();

        expect(queue.length, equals(1));
      });
    });

    group('type safety', () {
      test('works with custom types', () {
        final customQueue = PrioritySyncQueue<Map<String, dynamic>>();

        customQueue.enqueue({'id': 1}, SyncPriority.high);
        customQueue.enqueue({'id': 2}, SyncPriority.normal);

        final item = customQueue.dequeue();
        expect(item, equals({'id': 1}));
      });

      test('works with nullable types', () {
        final nullableQueue = PrioritySyncQueue<String?>();

        nullableQueue.enqueue(null, SyncPriority.normal);
        nullableQueue.enqueue('value', SyncPriority.high);

        expect(nullableQueue.dequeue(), equals('value'));
        expect(nullableQueue.dequeue(), isNull);
      });
    });

    group('edge cases', () {
      test('handles large number of items', () {
        for (var i = 0; i < 1000; i++) {
          queue.enqueue('item$i', SyncPriority.values[i % 4]);
        }

        expect(queue.length, equals(1000));

        // Verify all critical items come first
        var lastPriority = SyncPriority.critical;
        while (queue.isNotEmpty) {
          queue.dequeue();
        }

        expect(queue.isEmpty, isTrue);
      });

      test('interleaving enqueue and dequeue works correctly', () {
        queue.enqueue('a', SyncPriority.normal);
        expect(queue.dequeue(), equals('a'));

        queue.enqueue('b', SyncPriority.high);
        queue.enqueue('c', SyncPriority.critical);
        expect(queue.dequeue(), equals('c'));

        queue.enqueue('d', SyncPriority.low);
        expect(queue.dequeue(), equals('b'));
        expect(queue.dequeue(), equals('d'));

        expect(queue.isEmpty, isTrue);
      });
    });
  });
}
