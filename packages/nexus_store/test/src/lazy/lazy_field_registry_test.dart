import 'package:nexus_store/src/lazy/lazy_field_registry.dart';
import 'package:nexus_store/src/lazy/lazy_load_config.dart';
import 'package:test/test.dart';

// Test entity types
class User {
  final String id;
  final String name;
  User(this.id, this.name);
}

class Product {
  final String id;
  final String title;
  Product(this.id, this.title);
}

void main() {
  group('LazyFieldRegistry', () {
    late LazyFieldRegistry registry;

    setUp(() {
      registry = LazyFieldRegistry();
    });

    group('register', () {
      test('registers config for entity type', () {
        const config = LazyLoadConfig(
          lazyFields: {'avatar', 'profileImage'},
        );

        registry.register<User>(config);

        expect(registry.getConfig<User>(), equals(config));
      });

      test('allows registering different configs for different types', () {
        const userConfig = LazyLoadConfig(
          lazyFields: {'avatar'},
        );
        const productConfig = LazyLoadConfig(
          lazyFields: {'thumbnail', 'images'},
        );

        registry.register<User>(userConfig);
        registry.register<Product>(productConfig);

        expect(registry.getConfig<User>(), equals(userConfig));
        expect(registry.getConfig<Product>(), equals(productConfig));
      });

      test('overwrites previous registration for same type', () {
        const config1 = LazyLoadConfig(
          lazyFields: {'avatar'},
        );
        const config2 = LazyLoadConfig(
          lazyFields: {'profileImage'},
        );

        registry.register<User>(config1);
        registry.register<User>(config2);

        expect(registry.getConfig<User>(), equals(config2));
      });
    });

    group('getConfig', () {
      test('returns null for unregistered type', () {
        expect(registry.getConfig<User>(), isNull);
      });

      test('returns registered config', () {
        const config = LazyLoadConfig(
          lazyFields: {'avatar'},
        );

        registry.register<User>(config);

        expect(registry.getConfig<User>(), equals(config));
      });
    });

    group('isLazy', () {
      test('returns true for lazy field of registered type', () {
        const config = LazyLoadConfig(
          lazyFields: {'avatar', 'coverImage'},
        );

        registry.register<User>(config);

        expect(registry.isLazy<User>('avatar'), isTrue);
        expect(registry.isLazy<User>('coverImage'), isTrue);
      });

      test('returns false for non-lazy field of registered type', () {
        const config = LazyLoadConfig(
          lazyFields: {'avatar'},
        );

        registry.register<User>(config);

        expect(registry.isLazy<User>('name'), isFalse);
        expect(registry.isLazy<User>('email'), isFalse);
      });

      test('returns false for any field of unregistered type', () {
        expect(registry.isLazy<User>('avatar'), isFalse);
        expect(registry.isLazy<User>('name'), isFalse);
      });
    });

    group('clear', () {
      test('removes all registrations', () {
        const userConfig = LazyLoadConfig(
          lazyFields: {'avatar'},
        );
        const productConfig = LazyLoadConfig(
          lazyFields: {'thumbnail'},
        );

        registry.register<User>(userConfig);
        registry.register<Product>(productConfig);

        expect(registry.getConfig<User>(), isNotNull);
        expect(registry.getConfig<Product>(), isNotNull);

        registry.clear();

        expect(registry.getConfig<User>(), isNull);
        expect(registry.getConfig<Product>(), isNull);
      });

      test('allows re-registration after clear', () {
        const config = LazyLoadConfig(
          lazyFields: {'avatar'},
        );

        registry.register<User>(config);
        registry.clear();

        expect(registry.getConfig<User>(), isNull);

        registry.register<User>(config);

        expect(registry.getConfig<User>(), equals(config));
      });
    });
  });
}
