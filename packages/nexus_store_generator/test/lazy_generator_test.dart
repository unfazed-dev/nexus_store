import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:nexus_store_generator/builder.dart';
import 'package:test/test.dart';

void main() {
  group('LazyGenerator', () {
    test('generates accessor mixin for class with @NexusLazy annotation',
        () async {
      await testBuilder(
        lazyBuilder(BuilderOptions.empty),
        {
          'a|lib/user.dart': '''
import 'package:nexus_store/src/lazy/annotations.dart';

@NexusLazy()
class User {
  final String id;
  final String name;

  @Lazy()
  final String? avatar;

  @Lazy(placeholder: 'default.png')
  final String? thumbnail;

  User({required this.id, required this.name, this.avatar, this.thumbnail});
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {
          'a|lib/user.lazy.dart': decodedMatches(
            allOf([
              contains('mixin UserLazyAccessors'),
              contains('Future<dynamic> loadAvatar()'),
              contains('Future<dynamic> loadThumbnail()'),
              contains("loadField('avatar')"),
              contains("loadField('thumbnail')"),
            ]),
          ),
        },
      );
    });

    test('generates wrapper class when generateWrapper is true', () async {
      await testBuilder(
        lazyBuilder(BuilderOptions.empty),
        {
          'a|lib/item.dart': '''
import 'package:nexus_store/src/lazy/annotations.dart';

@NexusLazy(generateWrapper: true)
class Item {
  final String id;

  @Lazy()
  final String? data;

  Item({required this.id, this.data});
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {
          'a|lib/item.lazy.dart': decodedMatches(
            allOf([
              contains('class LazyItem'),
              contains('extends LazyEntity<Item, String>'),
            ]),
          ),
        },
      );
    });

    test('skips classes without @NexusLazy annotation', () async {
      await testBuilder(
        lazyBuilder(BuilderOptions.empty),
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

    test('does not generate accessors when generateAccessors is false',
        () async {
      await testBuilder(
        lazyBuilder(BuilderOptions.empty),
        {
          'a|lib/no_accessors.dart': '''
import 'package:nexus_store/src/lazy/annotations.dart';

@NexusLazy(generateAccessors: false, generateWrapper: true)
class NoAccessors {
  final String id;

  @Lazy()
  final String? data;

  NoAccessors({required this.id, this.data});
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {
          'a|lib/no_accessors.lazy.dart': decodedMatches(
            allOf([
              isNot(contains('mixin NoAccessorsLazyAccessors')),
              contains('class LazyNoAccessors'),
            ]),
          ),
        },
      );
    });

    test('generates preloadOnWatchFields for fields with preloadOnWatch: true',
        () async {
      await testBuilder(
        lazyBuilder(BuilderOptions.empty),
        {
          'a|lib/preload_model.dart': '''
import 'package:nexus_store/src/lazy/annotations.dart';

@NexusLazy(generateWrapper: true)
class PreloadModel {
  final String id;

  @Lazy(preloadOnWatch: true)
  final String? avatar;

  @Lazy(preloadOnWatch: true)
  final String? bio;

  @Lazy()
  final String? metadata;

  PreloadModel({required this.id, this.avatar, this.bio, this.metadata});
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {
          'a|lib/preload_model.lazy.dart': decodedMatches(
            allOf([
              contains('class LazyPreloadModel'),
              contains("preloadOnWatchFields = {'avatar', 'bio'}"),
            ]),
          ),
        },
      );
    });

    test('handles numeric placeholder values', () async {
      await testBuilder(
        lazyBuilder(BuilderOptions.empty),
        {
          'a|lib/numeric_placeholder.dart': '''
import 'package:nexus_store/src/lazy/annotations.dart';

@NexusLazy(generateWrapper: true)
class NumericPlaceholder {
  final String id;

  @Lazy(placeholder: 0)
  final int? count;

  @Lazy(placeholder: 0.0)
  final double? rate;

  NumericPlaceholder({required this.id, this.count, this.rate});
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {
          'a|lib/numeric_placeholder.lazy.dart': decodedMatches(
            allOf([
              contains("placeholders: {'count': 0"),
              contains("'rate': 0.0"),
            ]),
          ),
        },
      );
    });

    test('handles boolean placeholder values', () async {
      await testBuilder(
        lazyBuilder(BuilderOptions.empty),
        {
          'a|lib/bool_placeholder.dart': '''
import 'package:nexus_store/src/lazy/annotations.dart';

@NexusLazy(generateWrapper: true)
class BoolPlaceholder {
  final String id;

  @Lazy(placeholder: false)
  final bool? isActive;

  BoolPlaceholder({required this.id, this.isActive});
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {
          'a|lib/bool_placeholder.lazy.dart': decodedMatches(
            contains("placeholders: {'isActive': false}"),
          ),
        },
      );
    });

    test('returns empty for class with no @Lazy fields', () async {
      await testBuilder(
        lazyBuilder(BuilderOptions.empty),
        {
          'a|lib/no_lazy_fields.dart': '''
import 'package:nexus_store/src/lazy/annotations.dart';

@NexusLazy()
class NoLazyFields {
  final String id;
  final String name;

  NoLazyFields({required this.id, required this.name});
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {},
      );
    });

    test('throws InvalidGenerationSourceError for mixin with @NexusLazy',
        () async {
      final reader = await PackageAssetReader.currentIsolate();
      await expectLater(
        testBuilder(
          lazyBuilder(BuilderOptions.empty),
          {
            'a|lib/lazy_mixin.dart': '''
import 'package:nexus_store/src/lazy/annotations.dart';

@NexusLazy()
mixin LazyMixin {
  String get id;
}
''',
          },
          reader: reader,
          outputs: {},
        ),
        throwsA(anything),
      );
    });

    test('handles list placeholder values', () async {
      await testBuilder(
        lazyBuilder(BuilderOptions.empty),
        {
          'a|lib/list_placeholder.dart': '''
import 'package:nexus_store/src/lazy/annotations.dart';

@NexusLazy(generateWrapper: true)
class ListPlaceholder {
  final String id;

  @Lazy(placeholder: [1, 2, 3])
  final List<int>? items;

  ListPlaceholder({required this.id, this.items});
}
''',
        },
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {
          'a|lib/list_placeholder.lazy.dart': decodedMatches(
            allOf([
              contains("'items': [int(1), int(2), int(3)]"),
              contains('class LazyListPlaceholder'),
            ]),
          ),
        },
      );
    });
  });
}
