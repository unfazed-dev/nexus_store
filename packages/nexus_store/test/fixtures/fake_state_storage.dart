import 'package:nexus_store/src/state/state_storage.dart';

/// In-memory implementation of [StateStorage] for testing.
class FakeStateStorage implements StateStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  /// Clears all stored data.
  void clear() => _data.clear();

  /// Returns an unmodifiable view of the stored data.
  Map<String, String> get data => Map.unmodifiable(_data);

  /// Pre-populates storage with data for testing.
  void seed(Map<String, String> initialData) {
    _data.addAll(initialData);
  }
}

/// A [StateStorage] implementation that can be configured to fail.
class FailingStateStorage implements StateStorage {
  bool shouldFailRead = false;
  bool shouldFailWrite = false;
  bool shouldFailDelete = false;

  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async {
    if (shouldFailRead) throw Exception('Read failed');
    return _data[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (shouldFailWrite) throw Exception('Write failed');
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (shouldFailDelete) throw Exception('Delete failed');
    _data.remove(key);
  }

  /// Clears all stored data.
  void clear() => _data.clear();

  /// Returns an unmodifiable view of the stored data.
  Map<String, String> get data => Map.unmodifiable(_data);

  /// Pre-populates storage with data for testing.
  void seed(Map<String, String> initialData) {
    _data.addAll(initialData);
  }

  /// Resets all failure flags.
  void resetFailures() {
    shouldFailRead = false;
    shouldFailWrite = false;
    shouldFailDelete = false;
  }
}
