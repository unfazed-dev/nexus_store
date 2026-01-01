/// Helper functions for the NexusStoreRiverpodGenerator.
///
/// Extracted to allow testing without build_test dependencies.
library;

/// Derives the base name from a function name by stripping 'Store' suffix.
///
/// Examples:
/// - `userStore` → `user`
/// - `productStore` → `product`
/// - `userRepo` → `userRepo` (no change)
String deriveBaseName(String functionName) {
  if (functionName.endsWith('Store')) {
    return functionName.substring(0, functionName.length - 5);
  }
  return functionName;
}

/// Pluralizes a name using simple English rules.
///
/// Handles common patterns:
/// - Words ending in 'y' → 'ies' (entity → entities)
/// - Words ending in 's', 'x', 'ch', 'sh' → 'es' (box → boxes)
/// - Default → 's' (user → users)
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

/// Generates Riverpod provider code for a NexusStore.
///
/// Generates four providers:
/// - `{baseName}StoreProvider` - Provider for the store itself
/// - `{pluralName}Provider` - StreamProvider for all items
/// - `{baseName}ByIdProvider` - StreamProvider.family for single item
/// - `{pluralName}StatusProvider` - StreamProvider with StoreResult wrapper
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
