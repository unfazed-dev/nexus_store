import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:nexus_store_entity_generator/builder.dart';
import 'package:test/test.dart';

void main() {
  group('EntityGenerator', () {
    test('generates Fields class for @NexusEntity annotated class', () async {
      await testBuilder(
        entityBuilder(BuilderOptions.empty),
        {
          'a|lib/user.dart': '''
import 'package:nexus_store/nexus_store.dart';

@NexusEntity()
class User {
  final String id;
  final String name;
  final int age;
  final DateTime createdAt;
  final List<String> tags;

  User({
    required this.id,
    required this.name,
    required this.age,
    required this.createdAt,
    required this.tags,
  });
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {
          'a|lib/user.entity.dart': decodedMatches(
            allOf([
              contains('class UserFields extends Fields<User>'),
              contains("static final id = StringField<User>('id')"),
              contains("static final name = StringField<User>('name')"),
              contains("static final age = ComparableField<User, int>('age')"),
              contains(
                "static final createdAt = ComparableField<User, DateTime>('createdAt')",
              ),
              contains(
                "static final tags = ListField<User, String>('tags')",
              ),
            ]),
          ),
        },
      );
    });

    test('generates correct field types for various Dart types', () async {
      await testBuilder(
        entityBuilder(BuilderOptions.empty),
        {
          'a|lib/product.dart': '''
import 'package:nexus_store/nexus_store.dart';

@NexusEntity()
class Product {
  final String sku;
  final double price;
  final num quantity;
  final Duration warranty;
  final bool isAvailable;

  Product({
    required this.sku,
    required this.price,
    required this.quantity,
    required this.warranty,
    required this.isAvailable,
  });
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {
          'a|lib/product.entity.dart': decodedMatches(
            allOf([
              contains('class ProductFields extends Fields<Product>'),
              contains("static final sku = StringField<Product>('sku')"),
              contains(
                "static final price = ComparableField<Product, double>('price')",
              ),
              contains(
                "static final quantity = ComparableField<Product, num>('quantity')",
              ),
              contains(
                "static final warranty = ComparableField<Product, Duration>('warranty')",
              ),
              contains(
                "static final isAvailable = Field<Product, bool>('isAvailable')",
              ),
            ]),
          ),
        },
      );
    });

    test('handles nullable fields correctly', () async {
      await testBuilder(
        entityBuilder(BuilderOptions.empty),
        {
          'a|lib/item.dart': '''
import 'package:nexus_store/nexus_store.dart';

@NexusEntity()
class Item {
  final String id;
  final String? description;
  final int? quantity;

  Item({required this.id, this.description, this.quantity});
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {
          'a|lib/item.entity.dart': decodedMatches(
            allOf([
              contains('class ItemFields extends Fields<Item>'),
              contains("static final id = StringField<Item>('id')"),
              contains(
                "static final description = StringField<Item>('description')",
              ),
              contains(
                "static final quantity = ComparableField<Item, int>('quantity')",
              ),
            ]),
          ),
        },
      );
    });

    test('uses custom suffix when provided', () async {
      await testBuilder(
        entityBuilder(BuilderOptions.empty),
        {
          'a|lib/order.dart': '''
import 'package:nexus_store/nexus_store.dart';

@NexusEntity(fieldsSuffix: 'Columns')
class Order {
  final String id;
  final double total;

  Order({required this.id, required this.total});
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {
          'a|lib/order.entity.dart': decodedMatches(
            contains('class OrderColumns extends Fields<Order>'),
          ),
        },
      );
    });

    test('skips generation when generateFields is false', () async {
      await testBuilder(
        entityBuilder(BuilderOptions.empty),
        {
          'a|lib/config.dart': '''
import 'package:nexus_store/nexus_store.dart';

@NexusEntity(generateFields: false)
class Config {
  final String key;
  final String value;

  Config({required this.key, required this.value});
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {},
      );
    });

    test('handles nested List types', () async {
      await testBuilder(
        entityBuilder(BuilderOptions.empty),
        {
          'a|lib/document.dart': '''
import 'package:nexus_store/nexus_store.dart';

@NexusEntity()
class Document {
  final String id;
  final List<int> pageNumbers;
  final List<DateTime> revisions;

  Document({
    required this.id,
    required this.pageNumbers,
    required this.revisions,
  });
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {
          'a|lib/document.entity.dart': decodedMatches(
            allOf([
              contains(
                "static final pageNumbers = ListField<Document, int>('pageNumbers')",
              ),
              contains(
                "static final revisions = ListField<Document, DateTime>('revisions')",
              ),
            ]),
          ),
        },
      );
    });

    test('skips static fields', () async {
      await testBuilder(
        entityBuilder(BuilderOptions.empty),
        {
          'a|lib/counter.dart': '''
import 'package:nexus_store/nexus_store.dart';

@NexusEntity()
class Counter {
  static const defaultValue = 0;
  static String version = '1.0.0';

  final String id;
  final int count;

  Counter({required this.id, required this.count});
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {
          'a|lib/counter.entity.dart': decodedMatches(
            allOf([
              isNot(contains('defaultValue')),
              isNot(contains('version')),
              contains("static final id = StringField<Counter>('id')"),
              contains(
                "static final count = ComparableField<Counter, int>('count')",
              ),
            ]),
          ),
        },
      );
    });

    test('skips classes without @NexusEntity annotation', () async {
      await testBuilder(
        entityBuilder(BuilderOptions.empty),
        {
          'a|lib/plain.dart': '''
class PlainClass {
  final String id;
  PlainClass({required this.id});
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {},
      );
    });

    test('generates documentation comments', () async {
      await testBuilder(
        entityBuilder(BuilderOptions.empty),
        {
          'a|lib/task.dart': '''
import 'package:nexus_store/nexus_store.dart';

@NexusEntity()
class Task {
  final String id;
  final String title;

  Task({required this.id, required this.title});
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {
          'a|lib/task.entity.dart': decodedMatches(
            allOf([
              contains('/// Type-safe field accessors for [Task]'),
              contains('/// Field accessor for [id]'),
              contains('/// Field accessor for [title]'),
            ]),
          ),
        },
      );
    });

    test('generates singleton instance', () async {
      await testBuilder(
        entityBuilder(BuilderOptions.empty),
        {
          'a|lib/entity.dart': '''
import 'package:nexus_store/nexus_store.dart';

@NexusEntity()
class Entity {
  final String id;
  Entity({required this.id});
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {
          'a|lib/entity.entity.dart': decodedMatches(
            allOf([
              contains('EntityFields._()'),
              contains('static const instance = EntityFields._()'),
            ]),
          ),
        },
      );
    });

    test('handles custom class types as base Field', () async {
      await testBuilder(
        entityBuilder(BuilderOptions.empty),
        {
          'a|lib/profile.dart': '''
import 'package:nexus_store/nexus_store.dart';

class Address {
  final String street;
  final String city;
  Address({required this.street, required this.city});
}

@NexusEntity()
class Profile {
  final String id;
  final Address address;

  Profile({required this.id, required this.address});
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {
          'a|lib/profile.entity.dart': decodedMatches(
            allOf([
              contains("static final id = StringField<Profile>('id')"),
              contains(
                "static final address = Field<Profile, Address>('address')",
              ),
            ]),
          ),
        },
      );
    });

    test('includes nexus_store import in generated file', () async {
      await testBuilder(
        entityBuilder(BuilderOptions.empty),
        {
          'a|lib/model.dart': '''
import 'package:nexus_store/nexus_store.dart';

@NexusEntity()
class Model {
  final String id;
  Model({required this.id});
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {
          'a|lib/model.entity.dart': decodedMatches(
            contains("import 'package:nexus_store/nexus_store.dart'"),
          ),
        },
      );
    });

    test('handles enum fields as base Field', () async {
      await testBuilder(
        entityBuilder(BuilderOptions.empty),
        {
          'a|lib/status_model.dart': '''
import 'package:nexus_store/nexus_store.dart';

enum Status { active, inactive, pending }

@NexusEntity()
class StatusModel {
  final String id;
  final Status status;

  StatusModel({required this.id, required this.status});
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {
          'a|lib/status_model.entity.dart': decodedMatches(
            allOf([
              contains("static final id = StringField<StatusModel>('id')"),
              contains(
                "static final status = Field<StatusModel, Status>('status')",
              ),
            ]),
          ),
        },
      );
    });
  });
}
