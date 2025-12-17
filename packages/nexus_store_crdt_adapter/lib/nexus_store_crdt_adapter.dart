/// CRDT adapter for nexus_store with conflict-free replicated data types.
library;

export 'src/crdt_backend.dart' show CrdtBackend;
export 'src/crdt_query_translator.dart'
    show CrdtQueryExtension, CrdtQueryTranslator;
