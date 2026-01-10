import 'package:nexus_store_crdt_adapter/src/crdt_sync_rules.dart';
import 'package:test/test.dart';

void main() {
  group('CrdtSyncDirection', () {
    test('has all expected values', () {
      expect(CrdtSyncDirection.values, hasLength(4));
      expect(
        CrdtSyncDirection.values,
        contains(CrdtSyncDirection.bidirectional),
      );
      expect(CrdtSyncDirection.values, contains(CrdtSyncDirection.pushOnly));
      expect(CrdtSyncDirection.values, contains(CrdtSyncDirection.pullOnly));
      expect(CrdtSyncDirection.values, contains(CrdtSyncDirection.none));
    });
  });

  group('CrdtSyncTableRule', () {
    test('creates rule with defaults', () {
      const rule = CrdtSyncTableRule(tableName: 'users');

      expect(rule.tableName, 'users');
      expect(rule.direction, CrdtSyncDirection.bidirectional);
      expect(rule.filter, isNull);
      expect(rule.priority, 0);
    });

    test('creates rule with custom direction', () {
      const rule = CrdtSyncTableRule(
        tableName: 'logs',
        direction: CrdtSyncDirection.pushOnly,
      );

      expect(rule.direction, CrdtSyncDirection.pushOnly);
    });

    test('creates rule with filter', () {
      final rule = CrdtSyncTableRule(
        tableName: 'posts',
        filter: (r) => r['is_public'] == true,
      );

      expect(rule.filter, isNotNull);
      expect(rule.filter!({'is_public': true}), true);
      expect(rule.filter!({'is_public': false}), false);
    });

    test('creates rule with priority', () {
      const rule = CrdtSyncTableRule(tableName: 'users', priority: 10);

      expect(rule.priority, 10);
    });

    group('allowsPush', () {
      test('returns true for bidirectional', () {
        const rule = CrdtSyncTableRule(
          tableName: 'test',
        );

        expect(rule.allowsPush, true);
      });

      test('returns true for pushOnly', () {
        const rule = CrdtSyncTableRule(
          tableName: 'test',
          direction: CrdtSyncDirection.pushOnly,
        );

        expect(rule.allowsPush, true);
      });

      test('returns false for pullOnly', () {
        const rule = CrdtSyncTableRule(
          tableName: 'test',
          direction: CrdtSyncDirection.pullOnly,
        );

        expect(rule.allowsPush, false);
      });

      test('returns false for none', () {
        const rule = CrdtSyncTableRule(
          tableName: 'test',
          direction: CrdtSyncDirection.none,
        );

        expect(rule.allowsPush, false);
      });
    });

    group('allowsPull', () {
      test('returns true for bidirectional', () {
        const rule = CrdtSyncTableRule(
          tableName: 'test',
        );

        expect(rule.allowsPull, true);
      });

      test('returns false for pushOnly', () {
        const rule = CrdtSyncTableRule(
          tableName: 'test',
          direction: CrdtSyncDirection.pushOnly,
        );

        expect(rule.allowsPull, false);
      });

      test('returns true for pullOnly', () {
        const rule = CrdtSyncTableRule(
          tableName: 'test',
          direction: CrdtSyncDirection.pullOnly,
        );

        expect(rule.allowsPull, true);
      });

      test('returns false for none', () {
        const rule = CrdtSyncTableRule(
          tableName: 'test',
          direction: CrdtSyncDirection.none,
        );

        expect(rule.allowsPull, false);
      });
    });

    test('copyWith creates copy with overrides', () {
      const original = CrdtSyncTableRule(
        tableName: 'users',
        priority: 5,
      );

      final copy = original.copyWith(
        direction: CrdtSyncDirection.pushOnly,
      );

      expect(copy.tableName, 'users');
      expect(copy.direction, CrdtSyncDirection.pushOnly);
      expect(copy.priority, 5);
    });

    test('copyWith preserves direction when not overridden', () {
      const original = CrdtSyncTableRule(
        tableName: 'logs',
        direction: CrdtSyncDirection.pullOnly,
        priority: 3,
      );

      final copy = original.copyWith(
        tableName: 'audit_logs',
        priority: 10,
      );

      expect(copy.tableName, 'audit_logs');
      expect(copy.direction, CrdtSyncDirection.pullOnly);
      expect(copy.priority, 10);
    });
  });

  group('CrdtSyncRules', () {
    test('creates rules with defaults', () {
      const rules = CrdtSyncRules();

      expect(rules.defaultDirection, CrdtSyncDirection.bidirectional);
      expect(rules.tableRules, isEmpty);
    });

    test('getRuleForTable returns rule when defined', () {
      const rules = CrdtSyncRules(
        tableRules: [
          CrdtSyncTableRule(tableName: 'users'),
          CrdtSyncTableRule(tableName: 'posts'),
        ],
      );

      final rule = rules.getRuleForTable('users');

      expect(rule, isNotNull);
      expect(rule!.tableName, 'users');
    });

    test('getRuleForTable returns null when not defined', () {
      const rules = CrdtSyncRules(
        tableRules: [
          CrdtSyncTableRule(tableName: 'users'),
        ],
      );

      final rule = rules.getRuleForTable('posts');

      expect(rule, isNull);
    });

    test('getDirectionForTable returns rule direction when defined', () {
      const rules = CrdtSyncRules(
        tableRules: [
          CrdtSyncTableRule(
            tableName: 'logs',
            direction: CrdtSyncDirection.pushOnly,
          ),
        ],
      );

      expect(
        rules.getDirectionForTable('logs'),
        CrdtSyncDirection.pushOnly,
      );
    });

    test('getDirectionForTable returns default when not defined', () {
      const rules = CrdtSyncRules(
        defaultDirection: CrdtSyncDirection.pullOnly,
      );

      expect(
        rules.getDirectionForTable('any_table'),
        CrdtSyncDirection.pullOnly,
      );
    });

    group('filterChangeset', () {
      test('includes tables with bidirectional on push', () {
        const rules = CrdtSyncRules();
        final changeset = {
          'users': [
            {'id': '1', 'name': 'Alice'},
          ],
        };

        final filtered = rules.filterChangeset(changeset, isOutgoing: true);

        expect(filtered.containsKey('users'), true);
        expect(filtered['users'], hasLength(1));
      });

      test('excludes tables with none direction', () {
        const rules = CrdtSyncRules(
          tableRules: [
            CrdtSyncTableRule(
              tableName: 'private',
              direction: CrdtSyncDirection.none,
            ),
          ],
        );
        final changeset = {
          'private': [
            {'id': '1', 'secret': 'data'},
          ],
        };

        final filtered = rules.filterChangeset(changeset, isOutgoing: true);

        expect(filtered.containsKey('private'), false);
      });

      test('excludes pullOnly tables on push', () {
        const rules = CrdtSyncRules(
          tableRules: [
            CrdtSyncTableRule(
              tableName: 'readonly',
              direction: CrdtSyncDirection.pullOnly,
            ),
          ],
        );
        final changeset = {
          'readonly': [
            {'id': '1'},
          ],
        };

        final filtered = rules.filterChangeset(changeset, isOutgoing: true);

        expect(filtered.containsKey('readonly'), false);
      });

      test('excludes pushOnly tables on pull', () {
        const rules = CrdtSyncRules(
          tableRules: [
            CrdtSyncTableRule(
              tableName: 'writeonly',
              direction: CrdtSyncDirection.pushOnly,
            ),
          ],
        );
        final changeset = {
          'writeonly': [
            {'id': '1'},
          ],
        };

        final filtered = rules.filterChangeset(changeset, isOutgoing: false);

        expect(filtered.containsKey('writeonly'), false);
      });

      test('applies filter function', () {
        final rules = CrdtSyncRules(
          tableRules: [
            CrdtSyncTableRule(
              tableName: 'posts',
              filter: (r) => r['is_public'] == true,
            ),
          ],
        );
        final changeset = {
          'posts': [
            {'id': '1', 'is_public': true},
            {'id': '2', 'is_public': false},
            {'id': '3', 'is_public': true},
          ],
        };

        final filtered = rules.filterChangeset(changeset, isOutgoing: true);

        expect(filtered['posts'], hasLength(2));
        expect(filtered['posts']![0]['id'], '1');
        expect(filtered['posts']![1]['id'], '3');
      });

      test('excludes empty tables after filtering', () {
        final rules = CrdtSyncRules(
          tableRules: [
            CrdtSyncTableRule(
              tableName: 'posts',
              filter: (r) => false, // Filter everything
            ),
          ],
        );
        final changeset = {
          'posts': [
            {'id': '1'},
          ],
        };

        final filtered = rules.filterChangeset(changeset, isOutgoing: true);

        expect(filtered.containsKey('posts'), false);
      });

      test('sorts tables by priority in filtered result', () {
        const rules = CrdtSyncRules(
          tableRules: [
            CrdtSyncTableRule(tableName: 'comments', priority: 1),
            CrdtSyncTableRule(tableName: 'users', priority: 10),
            CrdtSyncTableRule(tableName: 'posts', priority: 5),
          ],
        );
        final changeset = {
          'comments': [
            {'id': 'c1'},
          ],
          'users': [
            {'id': 'u1'},
          ],
          'posts': [
            {'id': 'p1'},
          ],
        };

        final filtered = rules.filterChangeset(changeset, isOutgoing: true);

        // Result should be sorted by priority (descending)
        final keys = filtered.keys.toList();
        expect(keys, ['users', 'posts', 'comments']);
      });

      test('sorts tables with mixed priorities and default', () {
        const rules = CrdtSyncRules(
          tableRules: [
            CrdtSyncTableRule(tableName: 'important', priority: 100),
          ],
        );
        final changeset = {
          'normal': [
            {'id': '1'},
          ],
          'important': [
            {'id': '2'},
          ],
        };

        final filtered = rules.filterChangeset(changeset, isOutgoing: true);

        // important (priority 100) should come before normal (priority 0)
        final keys = filtered.keys.toList();
        expect(keys.first, 'important');
      });
    });

    group('getTablesInPriorityOrder', () {
      test('sorts tables by priority descending', () {
        const rules = CrdtSyncRules(
          tableRules: [
            CrdtSyncTableRule(tableName: 'users', priority: 10),
            CrdtSyncTableRule(tableName: 'posts', priority: 5),
            CrdtSyncTableRule(tableName: 'comments', priority: 1),
          ],
        );

        final sorted = rules.getTablesInPriorityOrder(
          ['comments', 'users', 'posts'],
        );

        expect(sorted, ['users', 'posts', 'comments']);
      });

      test('tables without rules have priority 0', () {
        const rules = CrdtSyncRules(
          tableRules: [
            CrdtSyncTableRule(tableName: 'important', priority: 5),
          ],
        );

        final sorted = rules.getTablesInPriorityOrder(
          ['important', 'normal'],
        );

        expect(sorted, ['important', 'normal']);
      });
    });
  });
}
