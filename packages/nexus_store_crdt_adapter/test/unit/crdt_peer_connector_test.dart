import 'dart:async';

import 'package:nexus_store_crdt_adapter/src/crdt_peer_connector.dart';
import 'package:test/test.dart';

void main() {
  group('CrdtPeerConnectionState', () {
    test('has all expected values', () {
      expect(CrdtPeerConnectionState.values, hasLength(4));
      expect(
        CrdtPeerConnectionState.values,
        contains(CrdtPeerConnectionState.disconnected),
      );
      expect(
        CrdtPeerConnectionState.values,
        contains(CrdtPeerConnectionState.connecting),
      );
      expect(
        CrdtPeerConnectionState.values,
        contains(CrdtPeerConnectionState.connected),
      );
      expect(
        CrdtPeerConnectionState.values,
        contains(CrdtPeerConnectionState.error),
      );
    });
  });

  group('CrdtMemoryConnector', () {
    test('starts in disconnected state', () {
      final connector = CrdtMemoryConnector();

      expect(connector.currentState, CrdtPeerConnectionState.disconnected);
    });

    test('connect changes state to connected', () async {
      final connector = CrdtMemoryConnector();

      await connector.connect();

      expect(connector.currentState, CrdtPeerConnectionState.connected);
    });

    test('disconnect changes state to disconnected', () async {
      final connector = CrdtMemoryConnector();
      await connector.connect();

      await connector.disconnect();

      expect(connector.currentState, CrdtPeerConnectionState.disconnected);
    });

    test('stateChanges stream emits state changes', () async {
      final connector = CrdtMemoryConnector();
      final states = <CrdtPeerConnectionState>[];
      final subscription = connector.stateChanges.listen(states.add);

      await connector.connect();
      await connector.disconnect();
      // Allow stream events to propagate
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(states, [
        CrdtPeerConnectionState.connecting,
        CrdtPeerConnectionState.connected,
        CrdtPeerConnectionState.disconnected,
      ]);
    });

    test('sendChangeset adds to outgoing stream', () async {
      final connector = CrdtMemoryConnector();
      await connector.connect();

      final changesets = <CrdtChangesetMessage>[];
      final subscription = connector.outgoingChangesets.listen(changesets.add);

      final changeset = CrdtChangesetMessage(
        sourceNodeId: 'node1',
        payload: {'table': 'users', 'data': <dynamic>[]},
      );
      await connector.sendChangeset(changeset);

      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(changesets, hasLength(1));
      expect(changesets.first.sourceNodeId, 'node1');
    });

    test('incomingChangesets receives messages', () async {
      final connector = CrdtMemoryConnector();
      await connector.connect();

      final changesets = <CrdtChangesetMessage>[];
      final subscription = connector.incomingChangesets.listen(changesets.add);

      final changeset = CrdtChangesetMessage(
        sourceNodeId: 'peer1',
        payload: {'table': 'posts', 'data': <dynamic>[]},
      );
      connector.simulateIncomingChangeset(changeset);

      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(changesets, hasLength(1));
      expect(changesets.first.sourceNodeId, 'peer1');
    });

    test('simulateError transitions to error state', () async {
      final connector = CrdtMemoryConnector();
      await connector.connect();

      connector.simulateError('Connection lost');

      expect(connector.currentState, CrdtPeerConnectionState.error);
      expect(connector.lastError, 'Connection lost');
    });

    test('dispose closes all streams', () async {
      final connector = CrdtMemoryConnector();
      await connector.connect();

      await connector.dispose();

      // Streams should be closed
      expect(connector.currentState, CrdtPeerConnectionState.disconnected);
    });

    test('peerId returns configured id', () {
      final connector = CrdtMemoryConnector(peerId: 'test-peer');

      expect(connector.peerId, 'test-peer');
    });

    test('peerId generates uuid if not provided', () {
      final connector = CrdtMemoryConnector();

      expect(connector.peerId, isNotEmpty);
      expect(connector.peerId.length, greaterThan(10));
    });
  });

  group('CrdtChangesetMessage', () {
    test('creates message with required fields', () {
      final message = CrdtChangesetMessage(
        sourceNodeId: 'node1',
        payload: {'key': 'value'},
      );

      expect(message.sourceNodeId, 'node1');
      expect(message.payload, {'key': 'value'});
      expect(message.timestamp, isNotNull);
    });

    test('creates message with custom timestamp', () {
      final timestamp = DateTime(2024);
      final message = CrdtChangesetMessage(
        sourceNodeId: 'node1',
        payload: {},
        timestamp: timestamp,
      );

      expect(message.timestamp, timestamp);
    });

    test('creates message with optional hlc', () {
      final message = CrdtChangesetMessage(
        sourceNodeId: 'node1',
        payload: {},
        hlcTimestamp: '2024-01-01T00:00:00.000Z-0000-node1',
      );

      expect(message.hlcTimestamp, isNotNull);
    });
  });

  group('CrdtPeerConnectorPair', () {
    test('connects two memory connectors', () async {
      final pair = CrdtPeerConnectorPair.create();

      await pair.nodeA.connect();
      await pair.nodeB.connect();

      expect(pair.nodeA.currentState, CrdtPeerConnectionState.connected);
      expect(pair.nodeB.currentState, CrdtPeerConnectionState.connected);
    });

    test('messages from A arrive at B', () async {
      final pair = CrdtPeerConnectorPair.create();
      await pair.nodeA.connect();
      await pair.nodeB.connect();

      final receivedAtB = <CrdtChangesetMessage>[];
      final subscription =
          pair.nodeB.incomingChangesets.listen(receivedAtB.add);

      final message = CrdtChangesetMessage(
        sourceNodeId: 'nodeA',
        payload: {'data': 'test'},
      );
      await pair.nodeA.sendChangeset(message);

      // Allow message propagation
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await subscription.cancel();

      expect(receivedAtB, hasLength(1));
      expect(receivedAtB.first.payload, {'data': 'test'});
    });

    test('messages from B arrive at A', () async {
      final pair = CrdtPeerConnectorPair.create();
      await pair.nodeA.connect();
      await pair.nodeB.connect();

      final receivedAtA = <CrdtChangesetMessage>[];
      final subscription =
          pair.nodeA.incomingChangesets.listen(receivedAtA.add);

      final message = CrdtChangesetMessage(
        sourceNodeId: 'nodeB',
        payload: {'data': 'reply'},
      );
      await pair.nodeB.sendChangeset(message);

      // Allow message propagation
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await subscription.cancel();

      expect(receivedAtA, hasLength(1));
      expect(receivedAtA.first.payload, {'data': 'reply'});
    });

    test('dispose closes both connectors', () async {
      final pair = CrdtPeerConnectorPair.create();
      await pair.nodeA.connect();
      await pair.nodeB.connect();

      await pair.dispose();

      expect(pair.nodeA.currentState, CrdtPeerConnectionState.disconnected);
      expect(pair.nodeB.currentState, CrdtPeerConnectionState.disconnected);
    });
  });
}
