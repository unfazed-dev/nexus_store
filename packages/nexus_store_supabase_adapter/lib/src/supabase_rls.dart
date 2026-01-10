/// PostgreSQL RLS operation types.
enum SupabaseRLSOperation {
  /// SELECT operations (read).
  select,

  /// INSERT operations (create).
  insert,

  /// UPDATE operations (modify).
  update,

  /// DELETE operations (remove).
  delete,

  /// ALL operations (SELECT, INSERT, UPDATE, DELETE).
  all,
}

/// A Row Level Security (RLS) policy definition for PostgreSQL/Supabase.
///
/// RLS policies control access to rows in a table based on expressions
/// that evaluate to true or false.
///
/// Example:
/// ```dart
/// // Only allow users to see their own rows
/// final selectPolicy = SupabaseRLSPolicy.select(
///   name: 'users_select_own',
///   using: 'auth.uid() = id',
/// );
///
/// // Only allow users to insert rows with their own ID
/// final insertPolicy = SupabaseRLSPolicy.insert(
///   name: 'users_insert_own',
///   withCheck: 'auth.uid() = id',
/// );
///
/// print(selectPolicy.toSql('users'));
/// // CREATE POLICY "users_select_own" ON "users" FOR SELECT TO PUBLIC
/// //   USING (auth.uid() = id)
/// ```
class SupabaseRLSPolicy {
  const SupabaseRLSPolicy._({
    required this.name,
    required this.operation,
    this.using,
    this.withCheck,
    this.role,
  });

  /// Creates a SELECT policy.
  ///
  /// SELECT policies use the USING clause to filter which rows are visible.
  const factory SupabaseRLSPolicy.select({
    required String name,
    required String using,
    String? role,
  }) = _SelectPolicy;

  /// Creates an INSERT policy.
  ///
  /// INSERT policies use the WITH CHECK clause to validate new rows.
  const factory SupabaseRLSPolicy.insert({
    required String name,
    required String withCheck,
    String? role,
  }) = _InsertPolicy;

  /// Creates an UPDATE policy.
  ///
  /// UPDATE policies can use both USING (for row visibility) and
  /// WITH CHECK (for validating the new row values).
  const factory SupabaseRLSPolicy.update({
    required String name,
    required String using,
    String? withCheck,
    String? role,
  }) = _UpdatePolicy;

  /// Creates a DELETE policy.
  ///
  /// DELETE policies use the USING clause to filter which rows can be deleted.
  const factory SupabaseRLSPolicy.delete({
    required String name,
    required String using,
    String? role,
  }) = _DeletePolicy;

  /// Creates an ALL operations policy.
  ///
  /// ALL policies apply to SELECT, INSERT, UPDATE, and DELETE.
  const factory SupabaseRLSPolicy.all({
    required String name,
    required String using,
    String? withCheck,
    String? role,
  }) = _AllPolicy;

  /// The policy name.
  final String name;

  /// The operation this policy applies to.
  final SupabaseRLSOperation operation;

  /// The USING expression (for filtering existing rows).
  final String? using;

  /// The WITH CHECK expression (for validating new/updated rows).
  final String? withCheck;

  /// The role this policy applies to (defaults to PUBLIC).
  final String? role;

  /// Generates the CREATE POLICY SQL statement.
  ///
  /// Example output:
  /// ```sql
  /// CREATE POLICY "users_select_own" ON "users" FOR SELECT TO PUBLIC
  ///   USING (auth.uid() = id)
  /// ```
  String toSql(String tableName) {
    final buffer = StringBuffer('CREATE POLICY "$name" ON "$tableName" ')
      // Add operation
      ..write('FOR ');
    switch (operation) {
      case SupabaseRLSOperation.select:
        buffer.write('SELECT');
      case SupabaseRLSOperation.insert:
        buffer.write('INSERT');
      case SupabaseRLSOperation.update:
        buffer.write('UPDATE');
      case SupabaseRLSOperation.delete:
        buffer.write('DELETE');
      case SupabaseRLSOperation.all:
        buffer.write('ALL');
    }

    // Add role
    buffer.write(' TO ${role ?? "PUBLIC"}');

    // Add USING clause if present
    if (using != null) {
      buffer.write(' USING ($using)');
    }

    // Add WITH CHECK clause if present
    if (withCheck != null) {
      buffer.write(' WITH CHECK ($withCheck)');
    }

    return buffer.toString();
  }

  /// Generates the DROP POLICY SQL statement.
  String toDropSql(String tableName) =>
      'DROP POLICY IF EXISTS "$name" ON "$tableName"';
}

class _SelectPolicy extends SupabaseRLSPolicy {
  const _SelectPolicy({
    required super.name,
    required String super.using,
    super.role,
  }) : super._(operation: SupabaseRLSOperation.select);
}

class _InsertPolicy extends SupabaseRLSPolicy {
  const _InsertPolicy({
    required super.name,
    required String super.withCheck,
    super.role,
  }) : super._(operation: SupabaseRLSOperation.insert);
}

class _UpdatePolicy extends SupabaseRLSPolicy {
  const _UpdatePolicy({
    required super.name,
    required String super.using,
    super.withCheck,
    super.role,
  }) : super._(operation: SupabaseRLSOperation.update);
}

class _DeletePolicy extends SupabaseRLSPolicy {
  const _DeletePolicy({
    required super.name,
    required String super.using,
    super.role,
  }) : super._(operation: SupabaseRLSOperation.delete);
}

class _AllPolicy extends SupabaseRLSPolicy {
  const _AllPolicy({
    required super.name,
    required String super.using,
    super.withCheck,
    super.role,
  }) : super._(operation: SupabaseRLSOperation.all);
}

/// A collection of RLS policies for a table.
///
/// This class helps generate all the SQL needed to set up RLS on a table.
///
/// Example:
/// ```dart
/// final rules = SupabaseRLSRules([
///   SupabaseRLSPolicy.select(
///     name: 'users_select_own',
///     using: 'auth.uid() = id',
///   ),
///   SupabaseRLSPolicy.insert(
///     name: 'users_insert_own',
///     withCheck: 'auth.uid() = id',
///   ),
///   SupabaseRLSPolicy.update(
///     name: 'users_update_own',
///     using: 'auth.uid() = id',
///     withCheck: 'auth.uid() = id',
///   ),
///   SupabaseRLSPolicy.delete(
///     name: 'users_delete_own',
///     using: 'auth.uid() = id',
///   ),
/// ]);
///
/// // Get all SQL statements to set up RLS
/// final sqlStatements = rules.toFullSql('users');
/// for (final sql in sqlStatements) {
///   print(sql);
/// }
/// ```
class SupabaseRLSRules {
  /// Creates a collection of RLS policies.
  const SupabaseRLSRules(this.policies);

  /// The list of policies.
  final List<SupabaseRLSPolicy> policies;

  /// Generates SQL statements for all policies.
  List<String> toSql(String tableName) =>
      policies.map((p) => p.toSql(tableName)).toList();

  /// Generates the ALTER TABLE ENABLE ROW LEVEL SECURITY statement.
  String toEnableRLSSql(String tableName) =>
      'ALTER TABLE "$tableName" ENABLE ROW LEVEL SECURITY';

  /// Generates the ALTER TABLE FORCE ROW LEVEL SECURITY statement.
  ///
  /// FORCE RLS ensures that even table owners are subject to RLS policies.
  String toForceRLSSql(String tableName) =>
      'ALTER TABLE "$tableName" FORCE ROW LEVEL SECURITY';

  /// Generates all SQL statements needed to fully set up RLS.
  ///
  /// This includes:
  /// 1. ALTER TABLE ENABLE ROW LEVEL SECURITY
  /// 2. (Optional) ALTER TABLE FORCE ROW LEVEL SECURITY
  /// 3. All CREATE POLICY statements
  ///
  /// Set [forceRls] to true to include the FORCE RLS statement.
  List<String> toFullSql(String tableName, {bool forceRls = false}) {
    final result = <String>[toEnableRLSSql(tableName)];

    if (forceRls) {
      result.add(toForceRLSSql(tableName));
    }

    result.addAll(toSql(tableName));
    return result;
  }
}
