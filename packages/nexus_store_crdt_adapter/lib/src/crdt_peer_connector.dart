import 'dart:async';
import 'dart:math';

/// Connection state for a peer connector.
enum CrdtPeerConnectionState {
  /// Not connected to any peer.
  disconnected,

  /// Attempting to establish connection.
  connecting,

  /// Successfully connected and ready for sync.
  connected,

  /// An error occurred during connection or sync.
  error,
}

/// A message containing a CRDT changeset for peer synchronization.
///
/// This message wraps the changeset data with metadata needed for
/// proper sync coordination between peers.
class CrdtChangesetMessage {
  /// Creates a changeset message.
  CrdtChangesetMessage({
    required this.sourceNodeId,
    required this.payload,
    DateTime? timestamp,
    this.hlcTimestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// The node ID of the sender.
  final String sourceNodeId;

  /// The changeset payload (typically serialized CRDT changes).
  final Map<String, dynamic> payload;

  /// When this message was created.
  final DateTime timestamp;

  /// The HLC timestamp string for causal ordering.
  final String? hlcTimestamp;
}

/// Abstract interface for peer-to-peer CRDT synchronization.
///
/// This abstraction enables:
/// - Testability: Use [CrdtMemoryConnector] for unit tests
/// - Flexibility: Implement WebSocket, HTTP, or custom transports
/// - Decoupling: Sync logic is independent of transport mechanism
///
/// Example implementation:
/// ```dart
/// class WebSocketConnector implements CrdtPeerConnector {
///   @override
///   Future<void> connect() async {
///     _socket = await WebSocket.connect(_url);
///     // Setup listeners...
///   }
///   // ...
/// }
/// ```
abstract interface class CrdtPeerConnector {
  /// Unique identifier for this peer.
  String get peerId;

  /// The current connection state.
  CrdtPeerConnectionState get currentState;

  /// Stream of connection state changes.
  Stream<CrdtPeerConnectionState> get stateChanges;

  /// Stream of incoming changesets from peers.
  Stream<CrdtChangesetMessage> get incomingChangesets;

  /// Stream of outgoing changesets (for monitoring/debugging).
  Stream<CrdtChangesetMessage> get outgoingChangesets;

  /// The last error that occurred, if any.
  String? get lastError;

  /// Establishes connection to peer(s).
  Future<void> connect();

  /// Closes the connection.
  Future<void> disconnect();

  /// Sends a changeset to connected peer(s).
  Future<void> sendChangeset(CrdtChangesetMessage changeset);

  /// Disposes all resources.
  Future<void> dispose();
}

/// In-memory implementation of [CrdtPeerConnector] for testing.
///
/// This connector simulates peer communication without network overhead,
/// making it ideal for unit tests and development.
///
/// Example:
/// ```dart
/// final connector = CrdtMemoryConnector();
/// await connector.connect();
///
/// // Simulate incoming data
/// connector.simulateIncomingChangeset(CrdtChangesetMessage(...));
///
/// // Check outgoing data
/// connector.outgoingChangesets.listen((msg) => print(msg));
/// ```
class CrdtMemoryConnector implements CrdtPeerConnector {
  /// Creates a memory connector with optional peer ID.
  CrdtMemoryConnector({String? peerId}) : _peerId = peerId ?? _generateId();

  final String _peerId;
  CrdtPeerConnectionState _currentState = CrdtPeerConnectionState.disconnected;
  String? _lastError;

  final _stateController =
      StreamController<CrdtPeerConnectionState>.broadcast();
  final _incomingController =
      StreamController<CrdtChangesetMessage>.broadcast();
  final _outgoingController =
      StreamController<CrdtChangesetMessage>.broadcast();

  @override
  String get peerId => _peerId;

  @override
  CrdtPeerConnectionState get currentState => _currentState;

  @override
  Stream<CrdtPeerConnectionState> get stateChanges => _stateController.stream;

  @override
  Stream<CrdtChangesetMessage> get incomingChangesets =>
      _incomingController.stream;

  @override
  Stream<CrdtChangesetMessage> get outgoingChangesets =>
      _outgoingController.stream;

  @override
  String? get lastError => _lastError;

  @override
  Future<void> connect() async {
    _updateState(CrdtPeerConnectionState.connecting);
    // Simulate connection delay
    await Future<void>.delayed(Duration.zero);
    _updateState(CrdtPeerConnectionState.connected);
  }

  @override
  Future<void> disconnect() async {
    _updateState(CrdtPeerConnectionState.disconnected);
  }

  @override
  Future<void> sendChangeset(CrdtChangesetMessage changeset) async {
    if (!_outgoingController.isClosed) {
      _outgoingController.add(changeset);
    }
  }

  @override
  Future<void> dispose() async {
    _updateState(CrdtPeerConnectionState.disconnected);
    await _stateController.close();
    await _incomingController.close();
    await _outgoingController.close();
  }

  /// Simulates receiving a changeset from a peer.
  ///
  /// Use this in tests to simulate incoming sync data.
  void simulateIncomingChangeset(CrdtChangesetMessage changeset) {
    if (!_incomingController.isClosed) {
      _incomingController.add(changeset);
    }
  }

  /// Simulates a connection error.
  ///
  /// Use this in tests to verify error handling.
  void simulateError(String error) {
    _lastError = error;
    _updateState(CrdtPeerConnectionState.error);
  }

  void _updateState(CrdtPeerConnectionState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  static String _generateId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

/// A pair of connected memory connectors for testing bidirectional sync.
///
/// Messages sent from nodeA appear in nodeB's incoming stream and vice versa.
///
/// Example:
/// ```dart
/// final pair = CrdtPeerConnectorPair.create();
/// await pair.nodeA.connect();
/// await pair.nodeB.connect();
///
/// // Message from A arrives at B
/// await pair.nodeA.sendChangeset(message);
/// // pair.nodeB.incomingChangesets receives the message
/// ```
class CrdtPeerConnectorPair {
  CrdtPeerConnectorPair._({
    required this.nodeA,
    required this.nodeB,
  }) {
    // Wire up bidirectional communication
    _subscriptionA =
        nodeA.outgoingChangesets.listen(nodeB.simulateIncomingChangeset);
    _subscriptionB =
        nodeB.outgoingChangesets.listen(nodeA.simulateIncomingChangeset);
  }

  /// Creates a connected pair of memory connectors.
  factory CrdtPeerConnectorPair.create({
    String? nodeAId,
    String? nodeBId,
  }) =>
      CrdtPeerConnectorPair._(
        nodeA: CrdtMemoryConnector(peerId: nodeAId ?? 'nodeA'),
        nodeB: CrdtMemoryConnector(peerId: nodeBId ?? 'nodeB'),
      );

  /// The first connector in the pair.
  final CrdtMemoryConnector nodeA;

  /// The second connector in the pair.
  final CrdtMemoryConnector nodeB;

  late final StreamSubscription<CrdtChangesetMessage> _subscriptionA;
  late final StreamSubscription<CrdtChangesetMessage> _subscriptionB;

  /// Disposes both connectors and cleans up wiring.
  Future<void> dispose() async {
    await _subscriptionA.cancel();
    await _subscriptionB.cancel();
    await nodeA.dispose();
    await nodeB.dispose();
  }
}
