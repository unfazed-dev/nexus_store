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
library;

export 'src/realtime_manager_wrapper.dart'
    show DefaultRealtimeManagerWrapper, RealtimeManagerWrapper;
export 'src/supabase_backend.dart' show SupabaseBackend;
export 'src/supabase_query_translator.dart'
    show SupabaseQueryExtension, SupabaseQueryTranslator;
export 'src/supabase_realtime_manager.dart'
    show FromJsonCallback, GetIdCallback, SupabaseRealtimeManager;
