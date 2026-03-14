# NexusStore Query Patterns

## Query Builder API

```dart
const Query<T>()
    .where(field, isEqualTo: value)
    .where(field, isLessThan: value)
    .where(field, isGreaterThan: value)
    .where(field, isLessThanOrEqualTo: value)
    .where(field, isNull: true)
    .orderByField(field, descending: true)
    .limitTo(n)
```

### Fetch Methods
- `.getAll(query: q)` — one-shot fetch returning `Future<List<T>>`
- `.get(id)` — single entity by ID returning `Future<T?>`
- `.watchAll(query: q)` — real-time stream returning `Stream<List<T>>`
- `.save(entity)` — create or update returning `Future<T>`
- `.delete(id)` — delete by ID returning `Future<void>`

## Pattern 1: Basic Filtering with Ordering

```dart
final query = const Query<JournalEntry>()
    .where('user_id', isEqualTo: userId)
    .where('deleted_at', isNull: true)
    .orderByField('entry_date', descending: true)
    .orderByField('updated_at', descending: true)
    .limitTo(50);

final entries = await _stores.journalEntries.getAll(query: query);
```

## Pattern 2: Date Range Filtering

```dart
final query = const Query<Document>()
    .where('expires_at', isGreaterThan: now.toIso8601String())
    .where('expires_at', isLessThanOrEqualTo: futureDate.toIso8601String())
    .orderByField('expires_at', descending: false);

final expiring = await _stores.documents.getAll(query: query);
```

## Pattern 3: Optional Pagination

```dart
var query = const Query<Booking>()
    .where('customer_id', isEqualTo: userId)
    .orderByField('start_time', descending: true);

if (before != null) {
  query = query.where('start_time', isLessThan: before.toIso8601String());
}
if (limit != null) {
  query = query.limitTo(limit);
}

return await _stores.bookings.getAll(query: query);
```

## Pattern 4: Real-Time Watch

```dart
Stream<List<JournalEntry>> watchEntries(String userId) {
  final query = const Query<JournalEntry>()
      .where('user_id', isEqualTo: userId)
      .where('deleted_at', isNull: true)
      .orderByField('entry_date', descending: true);

  return _stores.journalEntries.watchAll(query: query);
}
```

## Pattern 5: In-Memory Full-Text Search

NexusStore doesn't support full-text search — fetch all and filter in Dart:

```dart
final all = await _stores.complaints.getAll();
final lowerQuery = query.toLowerCase();

var filtered = all.where((c) {
  final subjectMatch = c.subject.toLowerCase().contains(lowerQuery);
  final descMatch = c.description.toLowerCase().contains(lowerQuery);
  return subjectMatch || descMatch;
});

// Optional status filter
if (status != null) {
  filtered = filtered.where((c) => c.status == status);
}

// Sort and paginate
var sorted = filtered.toList()
  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
if (limit != null) sorted = sorted.take(limit).toList();
```

## Pattern 6: Enum Post-Processing

NexusStore can't do `>=` comparisons — filter in memory:

```dart
final query = const Query<Incident>()
    .where('status', isEqualTo: status.value)
    .orderByField('incident_date', descending: true)
    .limitTo(limit);

final incidents = await _stores.incidents.getAll(query: query);

// Filter by severity in memory
if (minSeverity != null) {
  final order = [IncidentSeverity.low, IncidentSeverity.medium, IncidentSeverity.high];
  final minIdx = order.indexOf(minSeverity);
  return incidents.where((i) => order.indexOf(i.severity) >= minIdx).toList();
}
```

## Limitations
- No full-text search (use in-memory filtering)
- No `>=` / `<=` comparisons on non-date fields (use in-memory)
- No joins (query multiple stores separately)
- Ordering limited to indexed fields
- JSONB arrays sync correctly; TEXT[] does NOT
