import 'dart:io';

import 'package:nexus_store_powersync_adapter/src/sync_rules/ps_bucket.dart';

/// Container for PowerSync sync rules.
///
/// This class generates the sync rules YAML file that defines what data
/// is synced to PowerSync clients.
///
/// Example:
/// ```dart
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
/// final yaml = syncRules.toYaml();
/// await syncRules.saveToFile('sync-rules.yaml');
/// ```
class PSSyncRules {
  /// Creates sync rules with the given bucket definitions.
  const PSSyncRules(this.buckets);

  /// The bucket definitions for these sync rules.
  final List<PSBucket> buckets;

  /// Converts these sync rules to a map suitable for YAML serialization.
  ///
  /// The output format follows the PowerSync sync rules specification:
  /// ```yaml
  /// bucket_definitions:
  ///   - name: bucket_name
  ///     parameters: SELECT ...
  ///     data:
  ///       - SELECT ...
  /// ```
  Map<String, dynamic> toYamlMap() => {
        'bucket_definitions': buckets.map((b) => b.toYamlMap()).toList(),
      };

  /// Generates a YAML string for these sync rules.
  ///
  /// The output can be saved to a `sync-rules.yaml` file and deployed
  /// to PowerSync.
  String toYaml() {
    final buffer = StringBuffer()..writeln('bucket_definitions:');

    for (final bucket in buckets) {
      final bucketMap = bucket.toYamlMap();

      buffer.writeln('  - name: ${bucketMap['name']}');

      if (bucketMap.containsKey('parameters')) {
        buffer.writeln('    parameters: ${bucketMap['parameters']}');
      }

      buffer.writeln('    data:');
      final data = bucketMap['data'] as List<dynamic>;
      for (final query in data) {
        buffer.writeln('      - $query');
      }
    }

    return buffer.toString();
  }

  /// Saves these sync rules to a YAML file at the given [path].
  ///
  /// This will create or overwrite the file.
  Future<void> saveToFile(String path) async {
    final file = File(path);
    await file.writeAsString(toYaml());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PSSyncRules) return false;

    return _listEquals(other.buckets, buckets);
  }

  @override
  int get hashCode => Object.hashAll(buckets);

  @override
  String toString() => 'PSSyncRules(buckets: ${buckets.length})';
}

/// Helper function to compare lists for equality.
bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
