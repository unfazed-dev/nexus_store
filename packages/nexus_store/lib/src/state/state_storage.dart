/// Abstract storage interface for persisting state values.
///
/// Implement this interface with SharedPreferences, Hive, or any key-value store.
///
/// ## Example Implementation (SharedPreferences)
///
/// ```dart
/// import 'package:shared_preferences/shared_preferences.dart';
///
/// class SharedPrefsStorage implements StateStorage {
///   SharedPrefsStorage(this._prefs);
///   final SharedPreferences _prefs;
///
///   @override
///   Future<String?> read(String key) async => _prefs.getString(key);
///
///   @override
///   Future<void> write(String key, String value) async {
///     await _prefs.setString(key, value);
///   }
///
///   @override
///   Future<void> delete(String key) async {
///     await _prefs.remove(key);
///   }
/// }
/// ```
///
/// ## Example Implementation (Hive)
///
/// ```dart
/// import 'package:hive/hive.dart';
///
/// class HiveStorage implements StateStorage {
///   HiveStorage(this._box);
///   final Box<String> _box;
///
///   @override
///   Future<String?> read(String key) async => _box.get(key);
///
///   @override
///   Future<void> write(String key, String value) async {
///     await _box.put(key, value);
///   }
///
///   @override
///   Future<void> delete(String key) async {
///     await _box.delete(key);
///   }
/// }
/// ```
abstract class StateStorage {
  /// Reads a value from storage.
  ///
  /// Returns `null` if the key doesn't exist.
  Future<String?> read(String key);

  /// Writes a value to storage.
  ///
  /// Overwrites any existing value for the key.
  Future<void> write(String key, String value);

  /// Deletes a key from storage.
  ///
  /// Does nothing if the key doesn't exist.
  Future<void> delete(String key);
}
