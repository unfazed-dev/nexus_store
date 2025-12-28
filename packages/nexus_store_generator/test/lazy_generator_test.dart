import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:nexus_store_generator/builder.dart';
import 'package:test/test.dart';

void main() {
  group('LazyGenerator', () {
    test('generates accessor mixin for class with @NexusLazy annotation', () async {
      final result = await testBuilder(
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
      final result = await testBuilder(
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
      final result = await testBuilder(
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

    test('does not generate accessors when generateAccessors is false', () async {
      final result = await testBuilder(
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
  });
}
