/// A unified reactive data store abstraction providing a single consistent API
/// across multiple storage backends with policy-based fetching, RxDart streams,
/// and optional compliance features.
///
/// ## Features
///
/// - **Unified API**: Single interface for PowerSync, Drift, Supabase, Brick,
///   CRDT and more
/// - **Policy-based fetching**: Apollo GraphQL-style fetch policies
///   (cacheFirst, networkFirst, etc.)
/// - **Reactive streams**: RxDart BehaviorSubject for immediate value on
///   subscribe
/// - **Encryption**: SQLCipher database encryption and field-level encryption
/// - **Compliance**: GDPR erasure/portability, HIPAA audit logging
/// - **Type-safe queries**: Fluent query builder with backend translation
///
/// ## Quick Start
///
/// ```dart
/// import 'package:nexus_store/nexus_store.dart';
/// import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';
///
/// // Create a store with PowerSync backend
/// final userStore = NexusStore<User, String>(
///   backend: PowerSyncBackend(powerSync, 'users'),
///   config: StoreConfig(
///     fetchPolicy: FetchPolicy.cacheFirst,
///   ),
/// );
///
/// // Read with policy
/// final user = await userStore.get('user-123');
///
/// // Watch for changes (BehaviorSubject - immediate value)
/// userStore.watch('user-123').listen((user) {
///   print('User updated: $user');
/// });
///
/// // Query with fluent builder
/// final activeUsers = await userStore.getAll(
///   query: Query<User>()
///     .where('status', isEqualTo: 'active')
///     .orderBy('createdAt', descending: true)
///     .limit(10),
/// );
/// ```
library;

export 'src/compliance/audit_log_entry.dart';
// Compliance
export 'src/compliance/audit_service.dart';
export 'src/compliance/gdpr_service.dart';
export 'src/config/policies.dart';
export 'src/config/retry_config.dart';
// Config
export 'src/config/store_config.dart';
export 'src/core/composite_backend.dart';
// Core
export 'src/core/nexus_store.dart';
export 'src/core/store_backend.dart';
// Errors
export 'src/errors/store_errors.dart';
// Pagination
export 'src/pagination/cursor.dart';
export 'src/pagination/page_info.dart';
export 'src/pagination/paged_result.dart';
export 'src/pagination/pagination_controller.dart';
export 'src/pagination/pagination_state.dart';
export 'src/pagination/streaming_config.dart';
// Policy handlers
export 'src/policy/fetch_policy_handler.dart';
export 'src/policy/write_policy_handler.dart';
// Query
export 'src/query/query.dart';
export 'src/query/query_translator.dart';
// Reactive
export 'src/reactive/reactive_store_mixin.dart';
export 'src/security/encryption_algorithm.dart';
// Security
export 'src/security/encryption_config.dart';
export 'src/security/encryption_service.dart';
export 'src/security/field_encryptor.dart';
