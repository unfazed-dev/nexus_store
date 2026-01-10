/// CRDT adapter for nexus_store with conflict-free replicated data types.
library;

export 'src/crdt_backend.dart' show CrdtBackend;
export 'src/crdt_column.dart'
    show CrdtColumn, CrdtColumnType, CrdtIndex, CrdtTableDefinition;
export 'src/crdt_database_wrapper.dart'
    show
        CrdtDatabaseWrapper,
        CrdtTransactionContext,
        DefaultCrdtDatabaseWrapper;
export 'src/crdt_manager.dart' show CrdtManager;
export 'src/crdt_merge_strategy.dart'
    show
        CrdtConflictDetail,
        CrdtFieldMerger,
        CrdtMergeConfig,
        CrdtMergeFunction,
        CrdtMergeResult,
        CrdtMergeStrategy;
export 'src/crdt_peer_connector.dart'
    show
        CrdtChangesetMessage,
        CrdtMemoryConnector,
        CrdtPeerConnectionState,
        CrdtPeerConnector,
        CrdtPeerConnectorPair;
export 'src/crdt_query_translator.dart'
    show CrdtQueryExtension, CrdtQueryTranslator;
export 'src/crdt_sync_rules.dart'
    show CrdtSyncDirection, CrdtSyncRules, CrdtSyncTableRule;
export 'src/crdt_table_config.dart' show CrdtTableConfig;
