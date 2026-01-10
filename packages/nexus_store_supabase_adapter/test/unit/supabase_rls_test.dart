import 'package:nexus_store_supabase_adapter/src/supabase_rls.dart';
import 'package:test/test.dart';

void main() {
  group('SupabaseRLSOperation', () {
    test('has all expected operations', () {
      expect(SupabaseRLSOperation.values, containsAll([
        SupabaseRLSOperation.select,
        SupabaseRLSOperation.insert,
        SupabaseRLSOperation.update,
        SupabaseRLSOperation.delete,
        SupabaseRLSOperation.all,
      ]),);
    });
  });

  group('SupabaseRLSPolicy', () {
    group('factory methods', () {
      test('select() creates SELECT policy', () {
        const policy = SupabaseRLSPolicy.select(
          name: 'users_select_own',
          using: 'auth.uid() = id',
        );

        expect(policy.name, 'users_select_own');
        expect(policy.operation, SupabaseRLSOperation.select);
        expect(policy.using, 'auth.uid() = id');
        expect(policy.withCheck, isNull);
      });

      test('insert() creates INSERT policy with withCheck', () {
        const policy = SupabaseRLSPolicy.insert(
          name: 'users_insert_own',
          withCheck: 'auth.uid() = id',
        );

        expect(policy.name, 'users_insert_own');
        expect(policy.operation, SupabaseRLSOperation.insert);
        expect(policy.using, isNull);
        expect(policy.withCheck, 'auth.uid() = id');
      });

      test('update() creates UPDATE policy with both clauses', () {
        const policy = SupabaseRLSPolicy.update(
          name: 'users_update_own',
          using: 'auth.uid() = id',
          withCheck: 'auth.uid() = id',
        );

        expect(policy.name, 'users_update_own');
        expect(policy.operation, SupabaseRLSOperation.update);
        expect(policy.using, 'auth.uid() = id');
        expect(policy.withCheck, 'auth.uid() = id');
      });

      test('delete() creates DELETE policy', () {
        const policy = SupabaseRLSPolicy.delete(
          name: 'users_delete_own',
          using: 'auth.uid() = id',
        );

        expect(policy.name, 'users_delete_own');
        expect(policy.operation, SupabaseRLSOperation.delete);
        expect(policy.using, 'auth.uid() = id');
      });

      test('all() creates ALL policy', () {
        const policy = SupabaseRLSPolicy.all(
          name: 'users_all_own',
          using: 'auth.uid() = id',
          withCheck: 'auth.uid() = id',
        );

        expect(policy.name, 'users_all_own');
        expect(policy.operation, SupabaseRLSOperation.all);
      });
    });

    group('toSql', () {
      test('generates SELECT policy SQL', () {
        const policy = SupabaseRLSPolicy.select(
          name: 'users_select_own',
          using: 'auth.uid() = id',
        );

        final sql = policy.toSql('users');
        expect(sql, contains('CREATE POLICY "users_select_own"'));
        expect(sql, contains('ON "users"'));
        expect(sql, contains('FOR SELECT'));
        expect(sql, contains('USING (auth.uid() = id)'));
      });

      test('generates INSERT policy SQL with WITH CHECK', () {
        const policy = SupabaseRLSPolicy.insert(
          name: 'users_insert_own',
          withCheck: 'auth.uid() = id',
        );

        final sql = policy.toSql('users');
        expect(sql, contains('CREATE POLICY "users_insert_own"'));
        expect(sql, contains('FOR INSERT'));
        expect(sql, contains('WITH CHECK (auth.uid() = id)'));
        expect(sql, isNot(contains('USING')));
      });

      test('generates UPDATE policy SQL with both clauses', () {
        const policy = SupabaseRLSPolicy.update(
          name: 'users_update_own',
          using: 'auth.uid() = id',
          withCheck: 'auth.uid() = id',
        );

        final sql = policy.toSql('users');
        expect(sql, contains('FOR UPDATE'));
        expect(sql, contains('USING (auth.uid() = id)'));
        expect(sql, contains('WITH CHECK (auth.uid() = id)'));
      });

      test('generates DELETE policy SQL', () {
        const policy = SupabaseRLSPolicy.delete(
          name: 'users_delete_own',
          using: 'auth.uid() = id',
        );

        final sql = policy.toSql('users');
        expect(sql, contains('FOR DELETE'));
        expect(sql, contains('USING (auth.uid() = id)'));
      });

      test('generates ALL policy SQL', () {
        const policy = SupabaseRLSPolicy.all(
          name: 'users_full_access',
          using: 'auth.uid() = id',
          withCheck: 'auth.uid() = id',
        );

        final sql = policy.toSql('users');
        expect(sql, contains('FOR ALL'));
      });

      test('includes role when specified', () {
        const policy = SupabaseRLSPolicy.select(
          name: 'users_select_authenticated',
          using: 'auth.uid() IS NOT NULL',
          role: 'authenticated',
        );

        final sql = policy.toSql('users');
        expect(sql, contains('TO authenticated'));
      });

      test('defaults to PUBLIC role when not specified', () {
        const policy = SupabaseRLSPolicy.select(
          name: 'users_select_public',
          using: 'true',
        );

        final sql = policy.toSql('users');
        expect(sql, contains('TO PUBLIC'));
      });
    });

    group('toDropSql', () {
      test('generates DROP POLICY SQL', () {
        const policy = SupabaseRLSPolicy.select(
          name: 'users_select_own',
          using: 'auth.uid() = id',
        );

        final sql = policy.toDropSql('users');
        expect(sql, 'DROP POLICY IF EXISTS "users_select_own" ON "users"');
      });
    });
  });

  group('SupabaseRLSRules', () {
    test('creates empty rules', () {
      const rules = SupabaseRLSRules([]);
      expect(rules.policies, isEmpty);
    });

    test('creates rules with policies', () {
      const rules = SupabaseRLSRules([
        SupabaseRLSPolicy.select(
          name: 'users_select',
          using: 'auth.uid() = id',
        ),
        SupabaseRLSPolicy.insert(
          name: 'users_insert',
          withCheck: 'auth.uid() = id',
        ),
      ]);

      expect(rules.policies, hasLength(2));
    });

    test('toSql generates all policy SQL statements', () {
      const rules = SupabaseRLSRules([
        SupabaseRLSPolicy.select(
          name: 'users_select',
          using: 'auth.uid() = id',
        ),
        SupabaseRLSPolicy.insert(
          name: 'users_insert',
          withCheck: 'auth.uid() = id',
        ),
      ]);

      final sqlList = rules.toSql('users');
      expect(sqlList, hasLength(2));
      expect(sqlList[0], contains('users_select'));
      expect(sqlList[1], contains('users_insert'));
    });

    test('toEnableRLSSql generates ALTER TABLE statement', () {
      const rules = SupabaseRLSRules([]);

      final sql = rules.toEnableRLSSql('users');
      expect(sql, 'ALTER TABLE "users" ENABLE ROW LEVEL SECURITY');
    });

    test('toForceRLSSql generates FORCE RLS statement', () {
      const rules = SupabaseRLSRules([]);

      final sql = rules.toForceRLSSql('users');
      expect(
        sql,
        'ALTER TABLE "users" FORCE ROW LEVEL SECURITY',
      );
    });

    test('toFullSql generates complete RLS setup', () {
      const rules = SupabaseRLSRules([
        SupabaseRLSPolicy.select(
          name: 'users_select',
          using: 'auth.uid() = id',
        ),
      ]);

      final sqlList = rules.toFullSql('users');
      expect(sqlList, hasLength(2)); // enable + 1 policy
      expect(sqlList[0], contains('ENABLE ROW LEVEL SECURITY'));
      expect(sqlList[1], contains('CREATE POLICY'));
    });

    test('toFullSql with forceRls includes FORCE statement', () {
      const rules = SupabaseRLSRules([
        SupabaseRLSPolicy.select(
          name: 'users_select',
          using: 'auth.uid() = id',
        ),
      ]);

      final sqlList = rules.toFullSql('users', forceRls: true);
      expect(sqlList, hasLength(3)); // enable + force + 1 policy
      expect(sqlList[0], contains('ENABLE ROW LEVEL SECURITY'));
      expect(sqlList[1], contains('FORCE ROW LEVEL SECURITY'));
      expect(sqlList[2], contains('CREATE POLICY'));
    });
  });
}
