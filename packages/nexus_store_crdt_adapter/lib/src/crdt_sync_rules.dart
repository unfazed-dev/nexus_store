/// Direction of synchronization for a table.
enum CrdtSyncDirection {
  /// Sync changes in both directions (default).
  bidirectional,

  /// Only push local changes to peers, don't accept incoming changes.
  pushOnly,

  /// Only pull changes from peers, don't push local changes.
  pullOnly,

  /// Don't sync this table at all.
  none,
}

/// A rule defining sync behavior for a specific table.
///
/// Example:
/// ```dart
/// final rule = CrdtSyncTableRule(
///   tableName: 'users',
///   direction: CrdtSyncDirection.bidirectional,
///   filter: (record) => record['is_public'] == true,
/// );
/// ```
class CrdtSyncTableRule {
  /// Creates a sync rule for a table.
  const CrdtSyncTableRule({
    required this.tableName,
    this.direction = CrdtSyncDirection.bidirectional,
    this.filter,
    this.priority = 0,
  });

  /// The table name this rule applies to.
  final String tableName;

  /// The sync direction for this table.
  final CrdtSyncDirection direction;

  /// Optional filter function to determine which records to sync.
  ///
  /// Return true to include the record in sync, false to exclude.
  /// If null, all records are synced.
  final bool Function(Map<String, dynamic> record)? filter;

  /// Priority for sync order (higher = synced first).
  ///
  /// Tables with higher priority are synced before those with lower priority.
  /// Useful for syncing parent records before child records.
  final int priority;

  /// Whether this rule allows pushing changes to peers.
  bool get allowsPush =>
      direction == CrdtSyncDirection.bidirectional ||
      direction == CrdtSyncDirection.pushOnly;

  /// Whether this rule allows pulling changes from peers.
  bool get allowsPull =>
      direction == CrdtSyncDirection.bidirectional ||
      direction == CrdtSyncDirection.pullOnly;

  /// Creates a copy with the specified overrides.
  CrdtSyncTableRule copyWith({
    String? tableName,
    CrdtSyncDirection? direction,
    bool Function(Map<String, dynamic> record)? filter,
    int? priority,
  }) => CrdtSyncTableRule(
        tableName: tableName ?? this.tableName,
        direction: direction ?? this.direction,
        filter: filter ?? this.filter,
        priority: priority ?? this.priority,
      );
}

/// Configuration for sync rules across all tables.
///
/// This allows fine-grained control over what data syncs and how.
///
/// Example:
/// ```dart
/// final rules = CrdtSyncRules(
///   defaultDirection: CrdtSyncDirection.bidirectional,
///   tableRules: [
///     CrdtSyncTableRule(
///       tableName: 'users',
///       direction: CrdtSyncDirection.pullOnly,
///     ),
///     CrdtSyncTableRule(
///       tableName: 'private_notes',
///       direction: CrdtSyncDirection.none,
///     ),
///     CrdtSyncTableRule(
///       tableName: 'posts',
///       filter: (r) => r['is_public'] == true,
///       priority: 1,
///     ),
///   ],
/// );
///
/// // Apply rules to a changeset
/// final filteredChangeset = rules.filterChangeset(
///   changeset,
///   isOutgoing: true,
/// );
/// ```
class CrdtSyncRules {
  /// Creates sync rules configuration.
  const CrdtSyncRules({
    this.defaultDirection = CrdtSyncDirection.bidirectional,
    this.tableRules = const [],
  });

  /// Default sync direction for tables without explicit rules.
  final CrdtSyncDirection defaultDirection;

  /// Per-table sync rules.
  final List<CrdtSyncTableRule> tableRules;

  /// Gets the rule for a specific table.
  ///
  /// Returns null if no explicit rule is defined (use [defaultDirection]).
  CrdtSyncTableRule? getRuleForTable(String tableName) {
    for (final rule in tableRules) {
      if (rule.tableName == tableName) return rule;
    }
    return null;
  }

  /// Gets the effective direction for a table.
  CrdtSyncDirection getDirectionForTable(String tableName) =>
      getRuleForTable(tableName)?.direction ?? defaultDirection;

  /// Whether a table allows pushing changes.
  bool allowsPush(String tableName) {
    final direction = getDirectionForTable(tableName);
    return direction == CrdtSyncDirection.bidirectional ||
        direction == CrdtSyncDirection.pushOnly;
  }

  /// Whether a table allows pulling changes.
  bool allowsPull(String tableName) {
    final direction = getDirectionForTable(tableName);
    return direction == CrdtSyncDirection.bidirectional ||
        direction == CrdtSyncDirection.pullOnly;
  }

  /// Filters a changeset based on sync rules.
  ///
  /// - [isOutgoing]: true for push operations, false for pull
  ///
  /// Returns a new changeset with only the allowed tables and records.
  Map<String, List<Map<String, dynamic>>> filterChangeset(
    Map<String, Iterable<Map<String, dynamic>>> changeset, {
    required bool isOutgoing,
  }) {
    final result = <String, List<Map<String, dynamic>>>{};

    // Sort tables by priority (higher first)
    final tables = changeset.keys.toList()
      ..sort((a, b) {
        final ruleA = getRuleForTable(a);
        final ruleB = getRuleForTable(b);
        final priorityA = ruleA?.priority ?? 0;
        final priorityB = ruleB?.priority ?? 0;
        return priorityB.compareTo(priorityA); // Descending
      });

    for (final tableName in tables) {
      // Check direction
      final allowed =
          isOutgoing ? allowsPush(tableName) : allowsPull(tableName);
      if (!allowed) continue;

      // Get filter function
      final rule = getRuleForTable(tableName);
      final filter = rule?.filter;

      // Filter records
      final records = changeset[tableName]!;
      if (filter != null) {
        final filteredRecords = records
            .where((r) => filter(Map<String, dynamic>.from(r)))
            .map(Map<String, dynamic>.from)
            .toList();
        if (filteredRecords.isNotEmpty) {
          result[tableName] = filteredRecords;
        }
      } else {
        final allRecords =
            records.map(Map<String, dynamic>.from).toList();
        if (allRecords.isNotEmpty) {
          result[tableName] = allRecords;
        }
      }
    }

    return result;
  }

  /// Returns table names in sync priority order (highest first).
  List<String> getTablesInPriorityOrder(Iterable<String> tableNames) {
    final tables = tableNames.toList()
      ..sort((a, b) {
        final ruleA = getRuleForTable(a);
        final ruleB = getRuleForTable(b);
        final priorityA = ruleA?.priority ?? 0;
        final priorityB = ruleB?.priority ?? 0;
        return priorityB.compareTo(priorityA);
      });
    return tables;
  }
}
