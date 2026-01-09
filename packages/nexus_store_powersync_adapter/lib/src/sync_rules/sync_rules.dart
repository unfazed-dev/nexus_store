/// Sync rules generation for PowerSync.
///
/// This library provides classes to generate PowerSync sync rules YAML
/// programmatically from Dart code.
///
/// Example:
/// ```dart
/// import 'package:nexus_store_powersync_adapter/sync_rules.dart';
///
/// final syncRules = PSSyncRules([
///   PSBucket.global(
///     name: 'public_data',
///     queries: [PSQuery.select(table: 'settings')],
///   ),
///   PSBucket.userScoped(
///     name: 'user_data',
///     queries: [
///       PSQuery.select(table: 'users', filter: 'id = bucket.user_id'),
///     ],
///   ),
/// ]);
///
/// await syncRules.saveToFile('sync-rules.yaml');
/// ```
library;

export 'ps_bucket.dart' show PSBucket, PSBucketType;
export 'ps_query.dart' show PSQuery;
export 'ps_sync_rules.dart' show PSSyncRules;
