import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store/src/reliability/schema_definition.dart';

void main() {
  group('FieldType', () {
    test('has string type', () {
      expect(FieldType.string, isNotNull);
    });

    test('has int type', () {
      expect(FieldType.integer, isNotNull);
    });

    test('has double type', () {
      expect(FieldType.double_, isNotNull);
    });

    test('has bool type', () {
      expect(FieldType.boolean, isNotNull);
    });

    test('has dateTime type', () {
      expect(FieldType.dateTime, isNotNull);
    });

    test('has list type', () {
      expect(FieldType.list, isNotNull);
    });

    test('has map type', () {
      expect(FieldType.map, isNotNull);
    });

    test('has dynamic type', () {
      expect(FieldType.dynamic_, isNotNull);
    });

    group('matchesValue', () {
      test('string matches string value', () {
        expect(FieldType.string.matchesValue('hello'), isTrue);
      });

      test('string does not match int value', () {
        expect(FieldType.string.matchesValue(42), isFalse);
      });

      test('integer matches int value', () {
        expect(FieldType.integer.matchesValue(42), isTrue);
      });

      test('double matches double value', () {
        expect(FieldType.double_.matchesValue(3.14), isTrue);
      });

      test('double matches int value', () {
        // int is subtype of num, allow promotion
        expect(FieldType.double_.matchesValue(42), isTrue);
      });

      test('boolean matches bool value', () {
        expect(FieldType.boolean.matchesValue(true), isTrue);
      });

      test('dateTime matches DateTime value', () {
        expect(FieldType.dateTime.matchesValue(DateTime.now()), isTrue);
      });

      test('list matches List value', () {
        expect(FieldType.list.matchesValue([1, 2, 3]), isTrue);
      });

      test('map matches Map value', () {
        expect(FieldType.map.matchesValue({'key': 'value'}), isTrue);
      });

      test('dynamic matches any value', () {
        expect(FieldType.dynamic_.matchesValue('string'), isTrue);
        expect(FieldType.dynamic_.matchesValue(42), isTrue);
        expect(FieldType.dynamic_.matchesValue(null), isTrue);
      });

      test('null matches any type', () {
        expect(FieldType.string.matchesValue(null), isTrue);
        expect(FieldType.integer.matchesValue(null), isTrue);
      });
    });
  });

  group('FieldSchema', () {
    group('factory', () {
      test('creates required string field', () {
        const schema = FieldSchema(
          name: 'email',
          type: FieldType.string,
          isRequired: true,
        );
        expect(schema.name, equals('email'));
        expect(schema.type, equals(FieldType.string));
        expect(schema.isRequired, isTrue);
      });

      test('creates optional field with default nullable', () {
        const schema = FieldSchema(
          name: 'nickname',
          type: FieldType.string,
        );
        expect(schema.isRequired, isFalse);
        expect(schema.isNullable, isTrue);
      });

      test('creates field with constraints', () {
        const schema = FieldSchema(
          name: 'age',
          type: FieldType.integer,
          constraints: {'min': 0, 'max': 150},
        );
        expect(schema.constraints, isNotNull);
        expect(schema.constraints!['min'], equals(0));
      });
    });

    group('validate', () {
      test('returns null for valid required string', () {
        const schema = FieldSchema(
          name: 'name',
          type: FieldType.string,
          isRequired: true,
        );
        expect(schema.validate('John'), isNull);
      });

      test('returns error for missing required field', () {
        const schema = FieldSchema(
          name: 'name',
          type: FieldType.string,
          isRequired: true,
        );
        expect(schema.validate(null), contains('required'));
      });

      test('returns null for missing optional field', () {
        const schema = FieldSchema(
          name: 'nickname',
          type: FieldType.string,
        );
        expect(schema.validate(null), isNull);
      });

      test('returns error for wrong type', () {
        const schema = FieldSchema(
          name: 'age',
          type: FieldType.integer,
          isRequired: true,
        );
        expect(schema.validate('not an int'), contains('type'));
      });

      test('returns null for correct type', () {
        const schema = FieldSchema(
          name: 'age',
          type: FieldType.integer,
          isRequired: true,
        );
        expect(schema.validate(25), isNull);
      });
    });

    group('presets', () {
      test('id creates required string id field', () {
        final schema = FieldSchema.id();
        expect(schema.name, equals('id'));
        expect(schema.type, equals(FieldType.string));
        expect(schema.isRequired, isTrue);
      });

      test('requiredString creates required string field', () {
        final schema = FieldSchema.requiredString('email');
        expect(schema.name, equals('email'));
        expect(schema.type, equals(FieldType.string));
        expect(schema.isRequired, isTrue);
      });

      test('optionalString creates optional string field', () {
        final schema = FieldSchema.optionalString('bio');
        expect(schema.name, equals('bio'));
        expect(schema.isRequired, isFalse);
        expect(schema.isNullable, isTrue);
      });

      test('requiredInt creates required integer field', () {
        final schema = FieldSchema.requiredInt('count');
        expect(schema.name, equals('count'));
        expect(schema.type, equals(FieldType.integer));
        expect(schema.isRequired, isTrue);
      });

      test('timestamp creates required dateTime field', () {
        final schema = FieldSchema.timestamp('createdAt');
        expect(schema.name, equals('createdAt'));
        expect(schema.type, equals(FieldType.dateTime));
        expect(schema.isRequired, isTrue);
      });
    });
  });

  group('SchemaDefinition', () {
    group('factory', () {
      test('creates schema with name and fields', () {
        const schema = SchemaDefinition(
          name: 'User',
          fields: [
            FieldSchema(name: 'id', type: FieldType.string, isRequired: true),
            FieldSchema(name: 'name', type: FieldType.string, isRequired: true),
          ],
        );
        expect(schema.name, equals('User'));
        expect(schema.fields.length, equals(2));
      });

      test('creates schema with version', () {
        const schema = SchemaDefinition(
          name: 'User',
          fields: [],
          version: 2,
        );
        expect(schema.version, equals(2));
      });
    });

    group('validate', () {
      late SchemaDefinition userSchema;

      setUp(() {
        userSchema = const SchemaDefinition(
          name: 'User',
          fields: [
            FieldSchema(name: 'id', type: FieldType.string, isRequired: true),
            FieldSchema(name: 'name', type: FieldType.string, isRequired: true),
            FieldSchema(name: 'age', type: FieldType.integer),
          ],
        );
      });

      test('returns empty list for valid data', () {
        final errors = userSchema.validate({
          'id': '123',
          'name': 'John',
          'age': 25,
        });
        expect(errors, isEmpty);
      });

      test('returns errors for missing required fields', () {
        final errors = userSchema.validate({
          'id': '123',
        });
        expect(errors, isNotEmpty);
        expect(errors.any((e) => e.contains('name')), isTrue);
      });

      test('returns errors for wrong type', () {
        final errors = userSchema.validate({
          'id': '123',
          'name': 'John',
          'age': 'twenty-five', // Wrong type
        });
        expect(errors, isNotEmpty);
        expect(errors.any((e) => e.contains('age')), isTrue);
      });

      test('ignores extra fields by default', () {
        final errors = userSchema.validate({
          'id': '123',
          'name': 'John',
          'extraField': 'ignored',
        });
        expect(errors, isEmpty);
      });

      test('reports extra fields in strict mode', () {
        final strictSchema = SchemaDefinition(
          name: 'User',
          fields: const [
            FieldSchema(name: 'id', type: FieldType.string, isRequired: true),
          ],
          strictMode: true,
        );
        final errors = strictSchema.validate({
          'id': '123',
          'unknown': 'field',
        });
        expect(errors, isNotEmpty);
        expect(errors.any((e) => e.contains('unknown')), isTrue);
      });
    });

    group('isValid', () {
      test('returns true for valid data', () {
        const schema = SchemaDefinition(
          name: 'User',
          fields: [
            FieldSchema(name: 'id', type: FieldType.string, isRequired: true),
          ],
        );
        expect(schema.isValid({'id': '123'}), isTrue);
      });

      test('returns false for invalid data', () {
        const schema = SchemaDefinition(
          name: 'User',
          fields: [
            FieldSchema(name: 'id', type: FieldType.string, isRequired: true),
          ],
        );
        expect(schema.isValid({}), isFalse);
      });
    });

    group('getField', () {
      test('returns field by name', () {
        const schema = SchemaDefinition(
          name: 'User',
          fields: [
            FieldSchema(name: 'id', type: FieldType.string, isRequired: true),
            FieldSchema(name: 'name', type: FieldType.string),
          ],
        );
        final field = schema.getField('name');
        expect(field, isNotNull);
        expect(field!.name, equals('name'));
      });

      test('returns null for unknown field', () {
        const schema = SchemaDefinition(
          name: 'User',
          fields: [],
        );
        expect(schema.getField('unknown'), isNull);
      });
    });

    group('requiredFields', () {
      test('returns only required fields', () {
        const schema = SchemaDefinition(
          name: 'User',
          fields: [
            FieldSchema(name: 'id', type: FieldType.string, isRequired: true),
            FieldSchema(
                name: 'email', type: FieldType.string, isRequired: true),
            FieldSchema(name: 'nickname', type: FieldType.string),
          ],
        );
        final required = schema.requiredFields;
        expect(required.length, equals(2));
        expect(required.map((f) => f.name), containsAll(['id', 'email']));
      });
    });

    group('optionalFields', () {
      test('returns only optional fields', () {
        const schema = SchemaDefinition(
          name: 'User',
          fields: [
            FieldSchema(name: 'id', type: FieldType.string, isRequired: true),
            FieldSchema(name: 'bio', type: FieldType.string),
            FieldSchema(name: 'avatar', type: FieldType.string),
          ],
        );
        final optional = schema.optionalFields;
        expect(optional.length, equals(2));
        expect(optional.map((f) => f.name), containsAll(['bio', 'avatar']));
      });
    });
  });
}
