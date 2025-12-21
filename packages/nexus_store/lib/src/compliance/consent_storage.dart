import 'package:nexus_store/src/compliance/consent_record.dart';

/// Abstract interface for consent record storage.
///
/// Implementations can store consent data in various backends.
abstract interface class ConsentStorage {
  /// Saves a consent record.
  Future<void> save(ConsentRecord record);

  /// Retrieves a consent record by user ID.
  Future<ConsentRecord?> get(String userId);

  /// Retrieves all consent records.
  Future<List<ConsentRecord>> getAll();
}

/// In-memory implementation of [ConsentStorage] for testing.
class InMemoryConsentStorage implements ConsentStorage {
  final Map<String, ConsentRecord> _storage = {};

  @override
  Future<void> save(ConsentRecord record) async {
    _storage[record.userId] = record;
  }

  @override
  Future<ConsentRecord?> get(String userId) async {
    return _storage[userId];
  }

  @override
  Future<List<ConsentRecord>> getAll() async {
    return _storage.values.toList();
  }

  /// Clears all stored records (for testing).
  void clear() {
    _storage.clear();
  }
}
