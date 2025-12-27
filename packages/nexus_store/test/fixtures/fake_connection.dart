/// A fake connection for testing connection pooling.
class FakeConnection {
  /// Creates a fake connection with the given ID.
  FakeConnection([String? id]) : id = id ?? 'conn-${_counter++}';

  static int _counter = 0;

  /// Unique identifier for this connection.
  final String id;

  /// Whether this connection is open.
  bool isOpen = true;

  /// Number of operations performed on this connection.
  int operationCount = 0;

  /// Simulates performing an operation on this connection.
  void performOperation() {
    if (!isOpen) {
      throw StateError('Connection is closed');
    }
    operationCount++;
  }

  /// Closes this connection.
  void close() {
    isOpen = false;
  }

  /// Resets the counter for generating connection IDs.
  static void resetCounter() {
    _counter = 0;
  }

  @override
  String toString() => 'FakeConnection($id, isOpen: $isOpen)';
}
