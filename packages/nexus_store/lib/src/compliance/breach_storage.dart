import 'package:nexus_store/src/compliance/breach_report.dart';

/// Abstract interface for breach report storage.
abstract interface class BreachStorage {
  /// Saves a breach report.
  Future<void> save(BreachReport report);

  /// Retrieves a breach report by ID.
  Future<BreachReport?> get(String breachId);

  /// Retrieves all breach reports.
  Future<List<BreachReport>> getAll();

  /// Updates an existing breach report.
  Future<void> update(BreachReport report);
}

/// In-memory implementation of [BreachStorage] for testing.
class InMemoryBreachStorage implements BreachStorage {
  final Map<String, BreachReport> _storage = {};

  @override
  Future<void> save(BreachReport report) async {
    _storage[report.id] = report;
  }

  @override
  Future<BreachReport?> get(String breachId) async {
    return _storage[breachId];
  }

  @override
  Future<List<BreachReport>> getAll() async {
    return _storage.values.toList();
  }

  @override
  Future<void> update(BreachReport report) async {
    _storage[report.id] = report;
  }

  /// Clears all stored reports (for testing).
  void clear() {
    _storage.clear();
  }
}
