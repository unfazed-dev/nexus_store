import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:nexus_store_riverpod_binding/nexus_store_riverpod_binding.dart';
import 'package:source_gen/source_gen.dart';

import 'generator_helpers.dart';

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
    if (!isNexusStoreType(returnType)) {
      throw InvalidGenerationSourceError(
        '@riverpodNexusStore function must return NexusStore<T, ID>',
        element: element,
      );
    }

    // Extract type parameters
    final typeArgs = extractTypeArguments(returnType);
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
    final baseName = customName ?? deriveBaseName(function.name);
    final pluralName = pluralize(baseName);

    // Generate the code
    return generateProviders(
      functionName: function.name,
      baseName: baseName,
      pluralName: pluralName,
      entityType: entityType,
      idType: idType,
      keepAlive: keepAlive,
    );
  }

  /// Checks if the given type is a NexusStore type.
  static bool isNexusStoreType(DartType type) {
    if (type is! InterfaceType) return false;
    return type.element.name == 'NexusStore';
  }

  /// Extracts the type arguments (T, ID) from a `NexusStore<T, ID>` type.
  ///
  /// Returns null if the type is not an InterfaceType or doesn't have
  /// exactly 2 type arguments.
  static (String, String)? extractTypeArguments(DartType type) {
    if (type is! InterfaceType) return null;
    final typeArgs = type.typeArguments;
    if (typeArgs.length != 2) return null;
    return (
      typeArgs[0].getDisplayString(withNullability: false),
      typeArgs[1].getDisplayString(withNullability: false),
    );
  }
}
