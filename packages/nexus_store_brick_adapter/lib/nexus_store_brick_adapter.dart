/// Brick adapter for nexus_store with offline-first capabilities.
///
/// This package provides a [BrickBackend] implementation that integrates
/// nexus_store with Brick's offline-first repository pattern.
///
/// ## Getting Started
///
/// ```dart
/// import 'package:nexus_store_brick_adapter/nexus_store_brick_adapter.dart';
///
/// // Create a backend with your Brick repository
/// final backend = BrickBackend<MyModel, String>(
///   repository: myBrickRepository,
///   getId: (model) => model.id,
///   primaryKeyField: 'id',
/// );
///
/// await backend.initialize();
///
/// // Use with NexusStore
/// final store = NexusStore(backend: backend);
/// ```
library;

export 'src/brick_backend.dart' show BrickBackend;
export 'src/brick_manager.dart' show BrickManager;
export 'src/brick_query_translator.dart'
    show BrickQueryExtension, BrickQueryTranslator;
export 'src/brick_sync_config.dart'
    show
        BrickConflictResolution,
        BrickRetryPolicy,
        BrickSyncConfig,
        BrickSyncPolicy;
export 'src/brick_table_config.dart' show BrickTableConfig;
