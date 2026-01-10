/// Supabase adapter for nexus_store with real-time subscriptions.
///
/// This library provides a [SupabaseBackend] implementation that uses
/// Supabase as the backend storage with real-time capabilities.
///
/// ## Getting Started
///
/// ```dart
/// import 'package:nexus_store_supabase_adapter/nexus_store_supabase_adapter.dart';
/// import 'package:supabase/supabase.dart';
///
/// final client = SupabaseClient('your-url', 'your-key');
///
/// final backend = SupabaseBackend<User, String>(
///   client: client,
///   tableName: 'users',
///   getId: (user) => user.id,
///   fromJson: User.fromJson,
///   toJson: (user) => user.toJson(),
/// );
///
/// await backend.initialize();
///
/// // CRUD operations
/// final users = await backend.getAll();
/// await backend.save(newUser);
///
/// // Real-time streaming
/// backend.watchAll().listen((users) {
///   print('Users updated: ${users.length}');
/// });
/// ```
///
/// ## Batteries Included
///
/// For a more declarative approach, use the batteries-included features:
///
/// ```dart
/// // Type-safe column definitions
/// final columns = [
///   SupabaseColumn.uuid('id', nullable: false, defaultGenerate: true),
///   SupabaseColumn.text('name', nullable: false),
///   SupabaseColumn.timestamptz('created_at', defaultNow: true),
/// ];
///
/// // Table configuration
/// final config = SupabaseTableConfig<User, String>(
///   tableName: 'users',
///   columns: columns,
///   fromJson: User.fromJson,
///   toJson: (u) => u.toJson(),
///   getId: (u) => u.id,
///   enableRealtime: true,
/// );
///
/// // Create backend from config
/// final backend = SupabaseBackend.withConfig(
///   client: supabaseClient,
///   config: config,
/// );
///
/// // Or use SupabaseManager for multi-table apps
/// final manager = SupabaseManager.withClient(
///   client: supabaseClient,
///   tables: [userConfig, postConfig],
/// );
/// await manager.initialize();
/// ```
library;

export 'src/realtime_manager_wrapper.dart'
    show DefaultRealtimeManagerWrapper, RealtimeManagerWrapper;
export 'src/supabase_auth_provider.dart'
    show DefaultSupabaseAuthProvider, SupabaseAuthProvider, SupabaseAuthState;
export 'src/supabase_backend.dart' show SupabaseBackend;
export 'src/supabase_column.dart'
    show
        SupabaseColumn,
        SupabaseColumnType,
        SupabaseIndex,
        SupabaseTableDefinition;
export 'src/supabase_manager.dart' show SupabaseManager;
export 'src/supabase_query_translator.dart'
    show SupabaseQueryExtension, SupabaseQueryTranslator;
export 'src/supabase_realtime_manager.dart'
    show FromJsonCallback, GetIdCallback, SupabaseRealtimeManager;
export 'src/supabase_rls.dart'
    show SupabaseRLSOperation, SupabaseRLSPolicy, SupabaseRLSRules;
export 'src/supabase_table_config.dart' show SupabaseTableConfig;
