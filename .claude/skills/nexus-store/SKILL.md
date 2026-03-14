---
name: nexus-store
description: "NexusStore unified reactive data layer — PowerSync remote sync + Drift local storage"
metadata:
  scope: core
  status: active
  review_by: "2026-06-09"
  harness_compatible: true
  referenced_by:
    - migration-planner
    - arch-check
  related_rules:
    - .claude/rules/data-layer.md
---

# NexusStore
> Unified reactive data store across PowerSync (remote sync) and Drift (local-only) backends with typed CRUD, queries, and interceptors.

## Harness Integration
- **Extends:** `.claude/rules/data-layer.md` (PowerSync JSONB arrays, NexusStore patterns, CRUD queue)
- **Referenced by:** `migration-planner` (schema planning), `arch-check` (data layer validation)

## When to Use
- Creating a new data store for an entity
- Writing CRUD operations via repositories
- Managing offline sync with CRUD queue cleanup
- Adding store interceptors for pre/post operation hooks

## Key Patterns

### Two-Registry Architecture

```dart
// StoreRegistry — remote synced via PowerSync (50+ stores)
class StoreRegistry {
  late NexusStore<Profile, String> profiles;
  late NexusStore<Booking, String> bookings;
  late NexusStore<JournalEntry, String> journalEntries;
  late NexusStore<WalletAccount, String> walletAccounts;
  late NexusStore<Expense, String> expenses;
  // ... 50+ domain stores

  Future<void> initialize() async { /* lazy init */ }
  Future<void> reinitializeStores() async { /* on auth change */ }
}

// LocalStoreRegistry — local-only via Drift
class LocalStoreRegistry {
  late NexusStore<DeviceSettings, String> deviceSettings;
  late NexusStore<FormDraft, String> formDrafts;
  late NexusStore<ChatMessage, String> chatMessages;
  late NexusStore<SyncOperation, String> syncOperations;
}
```

### Store CRUD via Repository
```dart
class JournalRepository implements InterfaceJournalRepository {
  final _stores = locator<StoreRegistry>();

  Future<JournalEntry> createEntry(JournalEntry entry) async {
    return await _stores.journalEntries.save(entry);
  }

  Future<List<JournalEntry>> getEntries() async {
    return await _stores.journalEntries
        .query(const Query<JournalEntry>()
            .orderByField('created_at', ascending: false)
            .limitTo(50));
  }
}
```

### CRUD Queue Cleanup (Auth Flow)
```dart
// After fetching authoritative data from Supabase directly,
// clear stale PowerSync CRUD entries:
await powerSyncService.clearCrudQueueForTable('profiles');
await powerSyncService.clearCrudQueueForTable('customer_bookings');
```

### Store Interceptor
```dart
class StoreInterceptor {
  // Pre/post operation hooks for cross-cutting concerns
  // Example: audit logging, validation, cache invalidation
}
```

### SupabaseDataProvider
```dart
// Custom upload/download logic for stores that need
// non-standard sync behavior (e.g., file attachments)
class SupabaseDataProvider {
  // Override default PowerSync sync with custom Supabase calls
}
```

### GenUI Bridge (NexusStoreTableHandler)
```dart
final handler = NexusStoreTableHandler<Expense>(
  tableName: 'expenses',
  surfaceDataService: locator<SurfaceDataService>(),
  fromJson: Expense.fromJson,
  toSuccessMessage: (e) => 'Expense of ${e.formattedAmount} created',
);
// Used by MCQ → one-shot DB write flow
```

## Design Principles
1. **Two-registry:** StoreRegistry (remote synced, 53 stores) + LocalStoreRegistry (local-only)
2. **Lazy initialization:** Stores initialized only when first accessed
3. **Reinitialization on auth:** All stores reinit after user login/logout
4. **CRUD queue management:** Clear pending ops after fetching authoritative data
5. **JSONB arrays:** Use JSONB not TEXT[] for PowerSync synced arrays
6. **Repository-only access:** Only Repositories touch stores — never Views or ViewModels

## Drift Notes (v2.32.0)
- Type converters: Use `toSql`/`fromSql` (NOT deprecated `mapToSql`/`mapToDart`)
- `rightOuterJoin` and `fullOuterJoin` available (2.30.0+)
- `QueryRow.read` no longer supports nullable — use `readNullable` instead
- Auto-throws on database downgrades in step-by-step migrations (2.31.0+)
- Migrated to `sqlite3` package v3.x

## References
- Data layer rules: `.claude/rules/data-layer.md`
- Store registry: `lib/data/stores/store_registry.dart`
- Local store registry: `lib/data/stores/local_store_registry.dart`
- GenUI handler: `lib/genui/handlers/nexus_store_table_handler.dart`
- PowerSync service: `lib/core/services/powersync_service.dart`
