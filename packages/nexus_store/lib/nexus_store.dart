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

// Cache
export 'src/cache/cache_entry.dart';
export 'src/cache/cache_stats.dart';
export 'src/cache/cache_tag_index.dart';
export 'src/cache/eviction_strategy.dart';
export 'src/cache/lru_tracker.dart';
export 'src/cache/memory_config.dart';
export 'src/cache/memory_manager.dart';
export 'src/cache/memory_metrics.dart';
export 'src/cache/memory_pressure_handler.dart';
export 'src/cache/memory_pressure_level.dart';
export 'src/cache/query_evaluator.dart';
export 'src/cache/size_estimator.dart';
export 'src/compliance/audit_log_entry.dart';
// Compliance
export 'src/compliance/audit_service.dart';
export 'src/compliance/breach_report.dart';
export 'src/compliance/breach_service.dart';
export 'src/compliance/breach_storage.dart';
export 'src/compliance/consent_record.dart';
export 'src/compliance/consent_service.dart';
export 'src/compliance/consent_storage.dart';
export 'src/compliance/data_minimization_service.dart';
export 'src/compliance/gdpr_config.dart';
export 'src/compliance/gdpr_service.dart';
export 'src/compliance/retention_policy.dart';
export 'src/config/policies.dart';
export 'src/config/retry_config.dart';
// Config
export 'src/config/store_config.dart';
// Interceptors
export 'src/interceptors/caching_interceptor.dart';
export 'src/interceptors/interceptor_chain.dart';
export 'src/interceptors/interceptor_context.dart';
export 'src/interceptors/interceptor_result.dart';
export 'src/interceptors/logging_interceptor.dart';
export 'src/interceptors/store_interceptor.dart';
export 'src/interceptors/store_operation.dart';
export 'src/interceptors/timing_interceptor.dart';
export 'src/interceptors/validation_interceptor.dart';
export 'src/core/composite_backend.dart';
// Core
export 'src/core/nexus_store.dart';
export 'src/core/store_backend.dart';
// Errors
export 'src/errors/store_errors.dart';
// Lazy Loading
export 'src/lazy/annotations.dart';
export 'src/lazy/field_loader.dart';
export 'src/lazy/lazy_entity.dart';
export 'src/lazy/lazy_field.dart';
export 'src/lazy/lazy_field_registry.dart';
export 'src/lazy/lazy_field_state.dart';
export 'src/lazy/lazy_load_config.dart';
// Pagination
export 'src/pagination/cursor.dart';
export 'src/pagination/page_info.dart';
export 'src/pagination/paged_result.dart';
export 'src/pagination/pagination_controller.dart';
export 'src/pagination/pagination_state.dart';
export 'src/pagination/streaming_config.dart';
// Pool
export 'src/pool/connection_factory.dart';
export 'src/pool/connection_health_check.dart';
export 'src/pool/connection_pool.dart';
export 'src/pool/connection_pool_config.dart';
export 'src/pool/connection_scope.dart';
export 'src/pool/pool_errors.dart';
export 'src/pool/pool_metric.dart';
export 'src/pool/pool_metrics.dart';
export 'src/pool/pooled_connection.dart';
// Policy handlers
export 'src/policy/fetch_policy_handler.dart';
export 'src/policy/write_policy_handler.dart';
// Query
export 'src/query/expression.dart';
export 'src/query/field.dart';
export 'src/query/fields.dart';
export 'src/query/query.dart';
export 'src/query/query_expression_extension.dart';
export 'src/query/query_translator.dart';
// Reactive
export 'src/reactive/reactive_store_mixin.dart';
export 'src/security/derived_key.dart';
export 'src/security/encryption_algorithm.dart';
// Security
export 'src/security/encryption_config.dart';
export 'src/security/encryption_service.dart';
export 'src/security/field_encryptor.dart';
export 'src/security/key_deriver.dart';
export 'src/security/key_derivation_config.dart';
export 'src/security/key_derivation_service.dart';
export 'src/security/pbkdf2_key_deriver.dart';
export 'src/security/salt_storage.dart';
// Sync
export 'src/sync/conflict_action.dart';
export 'src/sync/conflict_details.dart';
export 'src/sync/delta_change.dart';
export 'src/sync/delta_merge_strategy.dart';
export 'src/sync/delta_merger.dart';
export 'src/sync/delta_sync_config.dart';
export 'src/sync/delta_tracker.dart';
export 'src/sync/field_change.dart';
export 'src/sync/pending_change.dart';
export 'src/sync/pending_changes_manager.dart';
export 'src/sync/tracked_entity.dart';
// Transaction
export 'src/transaction/transaction.dart';
export 'src/transaction/transaction_context.dart';
export 'src/transaction/transaction_operation.dart';
// Telemetry
export 'src/telemetry/buffered_metrics_reporter.dart';
export 'src/telemetry/cache_metric.dart';
export 'src/telemetry/console_metrics_reporter.dart';
export 'src/telemetry/error_metric.dart';
export 'src/telemetry/metrics_config.dart';
export 'src/telemetry/metrics_reporter.dart';
export 'src/telemetry/operation_metric.dart';
export 'src/telemetry/store_stats.dart';
export 'src/telemetry/sync_metric.dart';
// Reliability
export 'src/reliability/circuit_breaker.dart';
export 'src/reliability/circuit_breaker_config.dart';
export 'src/reliability/circuit_breaker_metrics.dart';
export 'src/reliability/circuit_breaker_state.dart';
export 'src/reliability/component_health.dart';
export 'src/reliability/degradation_config.dart';
export 'src/reliability/degradation_manager.dart';
export 'src/reliability/degradation_mode.dart';
export 'src/reliability/health_check_config.dart';
export 'src/reliability/health_check_service.dart';
export 'src/reliability/health_status.dart';
export 'src/reliability/schema_definition.dart';
export 'src/reliability/schema_validation_config.dart';
// Coordination (Saga Transactions)
export 'src/coordination/nexus_store_coordinator.dart';
export 'src/coordination/saga_context.dart';
export 'src/coordination/saga_coordinator.dart';
export 'src/coordination/saga_event.dart';
export 'src/coordination/saga_persistence.dart';
export 'src/coordination/saga_result.dart';
export 'src/coordination/saga_state.dart';
export 'src/coordination/saga_step.dart';
// State
export 'src/state/state.dart';
