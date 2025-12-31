import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:nexus_store_riverpod_binding/nexus_store_riverpod_binding.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for `@riverpodNexusStore` annotated functions.
///
/// Generates the following providers for each annotated function:
/// - `{name}StoreProvider` - `Provider<NexusStore<T, ID>>`
/// - `{name}Provider` - `StreamProvider<List<T>>` (from watchAll)
/// - `{name}ByIdProvider` - `StreamProvider.family<T?, ID>` (from watch)
/// - `{name}StatusProvider` - `StreamProvider<StoreResult<List<T>>>`
class NexusStoreRiverpodGenerator
    extends GeneratorForAnnotation<RiverpodNexusStore> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! FunctionElement) {
      throw InvalidGenerationSourceError(
        '@riverpodNexusStore can only be applied to functions',
        element: element,
      );
    }

    final function = element;
    final returnType = function.returnType;

    // Validate return type is NexusStore<T, ID>
    if (!_isNexusStoreType(returnType)) {
      throw InvalidGenerationSourceError(
        '@riverpodNexusStore function must return NexusStore<T, ID>',
        element: element,
      );
    }

    // Extract type parameters
    final typeArgs = _extractTypeArguments(returnType);
    if (typeArgs == null) {
      throw InvalidGenerationSourceError(
        'Could not extract type arguments from NexusStore return type',
        element: element,
      );
    }

    final entityType = typeArgs.$1;
    final idType = typeArgs.$2;

    // Get annotation options
    final keepAlive = annotation.read('keepAlive').boolValue;
    final customName = annotation.peek('name')?.stringValue;

    // Derive provider names
    final baseName = customName ?? _deriveBaseName(function.name);
    final pluralName = _pluralize(baseName);

    // Generate the code
    return _generateProviders(
      functionName: function.name,
      baseName: baseName,
      pluralName: pluralName,
      entityType: entityType,
      idType: idType,
      keepAlive: keepAlive,
    );
  }

  bool _isNexusStoreType(DartType type) {
    if (type is! InterfaceType) return false;
    return type.element.name == 'NexusStore';
  }

  (String, String)? _extractTypeArguments(DartType type) {
    if (type is! InterfaceType) return null;
    final typeArgs = type.typeArguments;
    if (typeArgs.length != 2) return null;
    return (
      typeArgs[0].getDisplayString(withNullability: false),
      typeArgs[1].getDisplayString(withNullability: false),
    );
  }

  String _deriveBaseName(String functionName) {
    // userStore -> user
    // productStore -> product
    if (functionName.endsWith('Store')) {
      return functionName.substring(0, functionName.length - 5);
    }
    return functionName;
  }

  String _pluralize(String name) {
    // Simple pluralization - works for most English nouns
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

  String _generateProviders({
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
}
