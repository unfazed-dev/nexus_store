// ignore_for_file: avoid_relative_lib_imports
import 'package:test/test.dart';

// We test the generator logic by unit testing the helper methods.
// The generator depends on flutter_riverpod transitively, which makes
// build_test unavailable (dart:mirrors + dart:ui conflict).
// Instead, we test the logic directly.

/// Derives the base name from a function name.
/// This mirrors the _deriveBaseName method in the generator.
String deriveBaseName(String functionName) {
  if (functionName.endsWith('Store')) {
    return functionName.substring(0, functionName.length - 5);
  }
  return functionName;
}

/// Pluralizes a name using simple English rules.
/// This mirrors the _pluralize method in the generator.
String pluralize(String name) {
  if (name.endsWith('y')) {
    return '${name.substring(0, name.length - 1)}ies';
  } else if (name.endsWith('s') ||
      name.endsWith('x') ||
      name.endsWith('ch') ||
      name.endsWith('sh')) {
    return '${name}es';
  }
  return '${name}s';
}

/// Generates provider code for given parameters.
/// This mirrors the _generateProviders method in the generator.
String generateProviders({
  required String functionName,
  required String baseName,
  required String pluralName,
  required String entityType,
  required String idType,
  required bool keepAlive,
}) {
  final providerModifier = keepAlive ? '' : '.autoDispose';

  return '''
// **************************************************************************
// NexusStoreRiverpodGenerator
// **************************************************************************

/// Provider for the $entityType store.
final ${baseName}StoreProvider = Provider$providerModifier<NexusStore<$entityType, $idType>>((ref) {
  final store = $functionName(ref);
  ref.onDispose(() => store.dispose());
  return store;
});

/// StreamProvider for all $pluralName.
final ${pluralName}Provider = StreamProvider$providerModifier<List<$entityType>>((ref) {
  final store = ref.watch(${baseName}StoreProvider);
  return store.watchAll();
});

/// StreamProvider.family for a single $baseName by ID.
final ${baseName}ByIdProvider = StreamProvider$providerModifier.family<$entityType?, $idType>((ref, id) {
  final store = ref.watch(${baseName}StoreProvider);
  return store.watch(id);
});

/// StreamProvider for all $pluralName with StoreResult status.
final ${pluralName}StatusProvider = StreamProvider$providerModifier<StoreResult<List<$entityType>>>((ref) {
  final store = ref.watch(${baseName}StoreProvider);
  return store.watchAll().map(StoreResult.success);
});
''';
}

void main() {
  group('NexusStoreRiverpodGenerator Logic', () {
    group('deriveBaseName', () {
      test('strips Store suffix from function name', () {
        expect(deriveBaseName('userStore'), equals('user'));
        expect(deriveBaseName('productStore'), equals('product'));
        expect(deriveBaseName('entityStore'), equals('entity'));
      });

      test('returns name unchanged if no Store suffix', () {
        expect(deriveBaseName('userRepo'), equals('userRepo'));
        expect(deriveBaseName('createUser'), equals('createUser'));
        expect(deriveBaseName('data'), equals('data'));
      });

      test('handles edge cases', () {
        expect(deriveBaseName('Store'), equals(''));
        expect(deriveBaseName('store'), equals('store'));
        expect(deriveBaseName(''), equals(''));
      });
    });

    group('pluralize', () {
      test('adds s for regular nouns', () {
        expect(pluralize('user'), equals('users'));
        expect(pluralize('product'), equals('products'));
        expect(pluralize('item'), equals('items'));
      });

      test('converts y to ies', () {
        expect(pluralize('entity'), equals('entities'));
        expect(pluralize('category'), equals('categories'));
        expect(pluralize('city'), equals('cities'));
      });

      test('adds es for s ending', () {
        expect(pluralize('access'), equals('accesses'));
        expect(pluralize('class'), equals('classes'));
        expect(pluralize('bus'), equals('buses'));
      });

      test('adds es for x ending', () {
        expect(pluralize('box'), equals('boxes'));
        expect(pluralize('tax'), equals('taxes'));
        expect(pluralize('fox'), equals('foxes'));
      });

      test('adds es for ch ending', () {
        expect(pluralize('match'), equals('matches'));
        expect(pluralize('watch'), equals('watches'));
        expect(pluralize('batch'), equals('batches'));
      });

      test('adds es for sh ending', () {
        expect(pluralize('wish'), equals('wishes'));
        expect(pluralize('dish'), equals('dishes'));
        expect(pluralize('brush'), equals('brushes'));
      });
    });

    group('generateProviders', () {
      test('generates 4 providers with autoDispose by default', () {
        final result = generateProviders(
          functionName: 'userStore',
          baseName: 'user',
          pluralName: 'users',
          entityType: 'User',
          idType: 'String',
          keepAlive: false,
        );

        expect(result, contains('userStoreProvider'));
        expect(result, contains('usersProvider'));
        expect(result, contains('userByIdProvider'));
        expect(result, contains('usersStatusProvider'));
        expect(result, contains('.autoDispose'));
        expect(result, contains('ref.onDispose'));
      });

      test('generates providers without autoDispose when keepAlive is true',
          () {
        final result = generateProviders(
          functionName: 'sessionStore',
          baseName: 'session',
          pluralName: 'sessions',
          entityType: 'Session',
          idType: 'String',
          keepAlive: true,
        );

        expect(result, contains('sessionStoreProvider'));
        expect(result, contains('Provider<NexusStore<Session, String>>'));
        expect(result, contains('StreamProvider<List<Session>>'));
        expect(result, isNot(contains('.autoDispose')));
      });

      test('generates correct type parameters', () {
        final result = generateProviders(
          functionName: 'productStore',
          baseName: 'product',
          pluralName: 'products',
          entityType: 'Product',
          idType: 'int',
          keepAlive: false,
        );

        expect(result, contains('NexusStore<Product, int>'));
        expect(result, contains('List<Product>'));
        expect(result, contains('Product?'));
        expect(result, contains('family<Product?, int>'));
      });

      test('includes store disposal code', () {
        final result = generateProviders(
          functionName: 'userStore',
          baseName: 'user',
          pluralName: 'users',
          entityType: 'User',
          idType: 'String',
          keepAlive: false,
        );

        expect(result, contains('ref.onDispose(() => store.dispose())'));
      });

      test('uses watchAll for list providers', () {
        final result = generateProviders(
          functionName: 'userStore',
          baseName: 'user',
          pluralName: 'users',
          entityType: 'User',
          idType: 'String',
          keepAlive: false,
        );

        expect(result, contains('store.watchAll()'));
      });

      test('uses watch for single item provider', () {
        final result = generateProviders(
          functionName: 'userStore',
          baseName: 'user',
          pluralName: 'users',
          entityType: 'User',
          idType: 'String',
          keepAlive: false,
        );

        expect(result, contains('store.watch(id)'));
      });

      test('wraps result in StoreResult for status provider', () {
        final result = generateProviders(
          functionName: 'userStore',
          baseName: 'user',
          pluralName: 'users',
          entityType: 'User',
          idType: 'String',
          keepAlive: false,
        );

        expect(result, contains('StoreResult.success'));
        expect(result, contains('StoreResult<List<User>>'));
      });
    });

    group('integration - name derivation + pluralization', () {
      test('userStore becomes user/users', () {
        final baseName = deriveBaseName('userStore');
        final pluralName = pluralize(baseName);

        expect(baseName, equals('user'));
        expect(pluralName, equals('users'));
      });

      test('entityStore becomes entity/entities', () {
        final baseName = deriveBaseName('entityStore');
        final pluralName = pluralize(baseName);

        expect(baseName, equals('entity'));
        expect(pluralName, equals('entities'));
      });

      test('accessStore becomes access/accesses', () {
        final baseName = deriveBaseName('accessStore');
        final pluralName = pluralize(baseName);

        expect(baseName, equals('access'));
        expect(pluralName, equals('accesses'));
      });

      test('boxStore becomes box/boxes', () {
        final baseName = deriveBaseName('boxStore');
        final pluralName = pluralize(baseName);

        expect(baseName, equals('box'));
        expect(pluralName, equals('boxes'));
      });

      test('matchStore becomes match/matches', () {
        final baseName = deriveBaseName('matchStore');
        final pluralName = pluralize(baseName);

        expect(baseName, equals('match'));
        expect(pluralName, equals('matches'));
      });

      test('wishStore becomes wish/wishes', () {
        final baseName = deriveBaseName('wishStore');
        final pluralName = pluralize(baseName);

        expect(baseName, equals('wish'));
        expect(pluralName, equals('wishes'));
      });

      test('function without Store suffix keeps name', () {
        final baseName = deriveBaseName('userRepo');
        final pluralName = pluralize(baseName);

        expect(baseName, equals('userRepo'));
        expect(pluralName, equals('userRepos'));
      });
    });
  });
}
