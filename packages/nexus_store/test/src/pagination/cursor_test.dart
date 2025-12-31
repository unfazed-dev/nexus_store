import 'dart:convert';

import 'package:nexus_store/src/pagination/cursor.dart';
import 'package:test/test.dart';

void main() {
  group('Cursor', () {
    group('construction', () {
      test('creates cursor from single value', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});

        expect(cursor, isNotNull);
        expect(cursor.toValues(), equals({'id': 'user-123'}));
      });

      test('creates cursor from multiple values', () {
        final cursor = Cursor.fromValues({
          'id': 'user-123',
          'createdAt': '2024-01-15T10:30:00Z',
        });

        expect(
            cursor.toValues(),
            equals({
              'id': 'user-123',
              'createdAt': '2024-01-15T10:30:00Z',
            }));
      });

      test('creates cursor with numeric values', () {
        final cursor = Cursor.fromValues({
          'id': 123,
          'score': 99.5,
        });

        expect(
            cursor.toValues(),
            equals({
              'id': 123,
              'score': 99.5,
            }));
      });

      test('creates cursor with null values', () {
        final cursor = Cursor.fromValues({
          'id': 'user-123',
          'deletedAt': null,
        });

        expect(
            cursor.toValues(),
            equals({
              'id': 'user-123',
              'deletedAt': null,
            }));
      });

      test('creates cursor with boolean values', () {
        final cursor = Cursor.fromValues({
          'id': 'user-123',
          'isActive': true,
        });

        expect(
            cursor.toValues(),
            equals({
              'id': 'user-123',
              'isActive': true,
            }));
      });
    });

    group('encode', () {
      test('encodes cursor to base64 string', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        final encoded = cursor.encode();

        expect(encoded, isA<String>());
        expect(encoded, isNotEmpty);
        // Should be valid base64
        expect(() => base64Decode(encoded), returnsNormally);
      });

      test('encoded string contains JSON data', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        final encoded = cursor.encode();
        final decoded = utf8.decode(base64Decode(encoded));

        expect(decoded, contains('user-123'));
      });

      test('different values produce different encoded strings', () {
        final cursor1 = Cursor.fromValues({'id': 'user-123'});
        final cursor2 = Cursor.fromValues({'id': 'user-456'});

        expect(cursor1.encode(), isNot(equals(cursor2.encode())));
      });
    });

    group('decode', () {
      test('decodes base64 string back to cursor', () {
        final original = Cursor.fromValues({'id': 'user-123'});
        final encoded = original.encode();
        final decoded = Cursor.decode(encoded);

        expect(decoded.toValues(), equals(original.toValues()));
      });

      test('decodes cursor with multiple values', () {
        final original = Cursor.fromValues({
          'id': 'user-123',
          'createdAt': '2024-01-15T10:30:00Z',
          'score': 42,
        });
        final encoded = original.encode();
        final decoded = Cursor.decode(encoded);

        expect(decoded.toValues(), equals(original.toValues()));
      });

      test('throws InvalidCursorException for invalid base64', () {
        expect(
          () => Cursor.decode('not-valid-base64!!!'),
          throwsA(isA<InvalidCursorException>()),
        );
      });

      test('throws InvalidCursorException for invalid JSON', () {
        final invalidJson = base64Encode(utf8.encode('not json'));
        expect(
          () => Cursor.decode(invalidJson),
          throwsA(isA<InvalidCursorException>()),
        );
      });

      test('throws InvalidCursorException for empty string', () {
        expect(
          () => Cursor.decode(''),
          throwsA(isA<InvalidCursorException>()),
        );
      });

      test('throws InvalidCursorException for JSON that is not a map', () {
        final jsonArray = base64Encode(utf8.encode('["not", "a", "map"]'));
        expect(
          () => Cursor.decode(jsonArray),
          throwsA(isA<InvalidCursorException>()),
        );
      });
    });

    group('isEmpty', () {
      test('returns true for cursor with empty values', () {
        final cursor = Cursor.fromValues({});
        expect(cursor.isEmpty, isTrue);
      });

      test('returns false for cursor with values', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        expect(cursor.isEmpty, isFalse);
      });
    });

    group('isNotEmpty', () {
      test('returns false for cursor with empty values', () {
        final cursor = Cursor.fromValues({});
        expect(cursor.isNotEmpty, isFalse);
      });

      test('returns true for cursor with values', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        expect(cursor.isNotEmpty, isTrue);
      });
    });

    group('equality', () {
      test('cursors with same values are equal', () {
        final cursor1 = Cursor.fromValues({'id': 'user-123'});
        final cursor2 = Cursor.fromValues({'id': 'user-123'});

        expect(cursor1, equals(cursor2));
      });

      test('cursors with different values are not equal', () {
        final cursor1 = Cursor.fromValues({'id': 'user-123'});
        final cursor2 = Cursor.fromValues({'id': 'user-456'});

        expect(cursor1, isNot(equals(cursor2)));
      });

      test('cursors with same values in different order are equal', () {
        final cursor1 = Cursor.fromValues({'id': 'user-123', 'name': 'John'});
        final cursor2 = Cursor.fromValues({'name': 'John', 'id': 'user-123'});

        expect(cursor1, equals(cursor2));
      });

      test('cursors with different number of values are not equal', () {
        final cursor1 = Cursor.fromValues({'id': 'user-123'});
        final cursor2 = Cursor.fromValues({'id': 'user-123', 'name': 'John'});

        expect(cursor1, isNot(equals(cursor2)));
      });
    });

    group('hashCode', () {
      test('cursors with same values have same hashCode', () {
        final cursor1 = Cursor.fromValues({'id': 'user-123'});
        final cursor2 = Cursor.fromValues({'id': 'user-123'});

        expect(cursor1.hashCode, equals(cursor2.hashCode));
      });

      test('can be used in sets', () {
        final cursor1 = Cursor.fromValues({'id': 'user-123'});
        final cursor2 = Cursor.fromValues({'id': 'user-123'});
        final cursor3 = Cursor.fromValues({'id': 'user-456'});

        final set = {cursor1, cursor2, cursor3};
        expect(set.length, equals(2));
      });

      test('can be used as map keys', () {
        final cursor1 = Cursor.fromValues({'id': 'user-123'});
        final cursor2 = Cursor.fromValues({'id': 'user-123'});

        final map = <Cursor, String>{};
        map[cursor1] = 'first';
        map[cursor2] = 'second';

        expect(map.length, equals(1));
        expect(map[cursor1], equals('second'));
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        final str = cursor.toString();

        expect(str, contains('Cursor'));
        expect(str, contains('id'));
      });
    });

    group('copyWith', () {
      test('creates new cursor with updated values', () {
        final cursor = Cursor.fromValues({'id': 'user-123', 'name': 'John'});
        final updated = cursor.copyWith({'id': 'user-456'});

        expect(updated.toValues(), equals({'id': 'user-456', 'name': 'John'}));
      });

      test('original cursor is unchanged', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        cursor.copyWith({'id': 'user-456'});

        expect(cursor.toValues(), equals({'id': 'user-123'}));
      });

      test('can add new values', () {
        final cursor = Cursor.fromValues({'id': 'user-123'});
        final updated = cursor.copyWith({'name': 'John'});

        expect(updated.toValues(), equals({'id': 'user-123', 'name': 'John'}));
      });
    });

    group('roundtrip', () {
      test('encode then decode preserves all value types', () {
        final original = Cursor.fromValues({
          'string': 'hello',
          'int': 42,
          'double': 3.14,
          'bool': true,
          'null': null,
        });

        final decoded = Cursor.decode(original.encode());

        expect(decoded.toValues()['string'], equals('hello'));
        expect(decoded.toValues()['int'], equals(42));
        expect(decoded.toValues()['double'], equals(3.14));
        expect(decoded.toValues()['bool'], equals(true));
        expect(decoded.toValues()['null'], isNull);
      });
    });
  });

  group('InvalidCursorException', () {
    test('contains descriptive message', () {
      final exception = InvalidCursorException('Test error message');

      expect(exception.message, equals('Test error message'));
      expect(exception.toString(), contains('Test error message'));
    });

    test('toString includes exception type', () {
      final exception = InvalidCursorException('Bad cursor');

      expect(exception.toString(), contains('InvalidCursorException'));
    });
  });
}
