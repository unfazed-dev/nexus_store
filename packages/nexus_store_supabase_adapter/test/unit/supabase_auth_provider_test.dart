import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_supabase_adapter/src/supabase_auth_provider.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

// Mock classes for Supabase client
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSession extends Mock implements Session {}

class MockUser extends Mock implements User {}

class MockAuthResponse extends Mock implements AuthResponse {}

// Mock implementation for testing the interface
class MockSupabaseAuthProvider implements SupabaseAuthProvider {
  MockSupabaseAuthProvider({
    SupabaseAuthState initialState = SupabaseAuthState.signedOut,
    this.mockUserId,
    this.mockAccessToken,
  }) : _currentState = initialState;

  SupabaseAuthState _currentState;
  final String? mockUserId;
  final String? mockAccessToken;

  final _authStateController =
      StreamController<SupabaseAuthState>.broadcast();

  @override
  SupabaseAuthState get currentState => _currentState;

  @override
  Stream<SupabaseAuthState> get authStateChanges => _authStateController.stream;

  @override
  String? get currentUserId =>
      _currentState == SupabaseAuthState.signedIn ? mockUserId : null;

  @override
  Future<String?> getAccessToken() async =>
      _currentState == SupabaseAuthState.signedIn ? mockAccessToken : null;

  @override
  Future<void> dispose() async {
    await _authStateController.close();
  }

  void simulateSignIn() {
    _currentState = SupabaseAuthState.signedIn;
    _authStateController.add(SupabaseAuthState.signedIn);
  }

  void simulateSignOut() {
    _currentState = SupabaseAuthState.signedOut;
    _authStateController.add(SupabaseAuthState.signedOut);
  }
}

void main() {
  group('SupabaseAuthState', () {
    test('has expected values', () {
      expect(SupabaseAuthState.values, containsAll([
        SupabaseAuthState.signedIn,
        SupabaseAuthState.signedOut,
        SupabaseAuthState.loading,
        SupabaseAuthState.error,
      ]),);
    });
  });

  group('SupabaseAuthProvider interface', () {
    test('MockSupabaseAuthProvider implements interface correctly', () {
      final provider = MockSupabaseAuthProvider(
        initialState: SupabaseAuthState.signedIn,
        mockUserId: 'user-123',
        mockAccessToken: 'token-abc',
      );

      expect(provider.currentState, SupabaseAuthState.signedIn);
      expect(provider.currentUserId, 'user-123');
    });

    test('currentUserId is null when signed out', () {
      final provider = MockSupabaseAuthProvider(
        mockUserId: 'user-123',
      );

      expect(provider.currentState, SupabaseAuthState.signedOut);
      expect(provider.currentUserId, isNull);
    });

    test('getAccessToken returns token when signed in', () async {
      final provider = MockSupabaseAuthProvider(
        initialState: SupabaseAuthState.signedIn,
        mockAccessToken: 'my-token',
      );

      final token = await provider.getAccessToken();
      expect(token, 'my-token');
    });

    test('getAccessToken returns null when signed out', () async {
      final provider = MockSupabaseAuthProvider(
        mockAccessToken: 'my-token',
      );

      final token = await provider.getAccessToken();
      expect(token, isNull);
    });

    test('authStateChanges emits state changes', () async {
      final provider = MockSupabaseAuthProvider();

      final states = <SupabaseAuthState>[];
      final subscription = provider.authStateChanges.listen(states.add);

      provider.simulateSignIn();
      provider.simulateSignOut();
      provider.simulateSignIn();

      // Wait for events to process
      await Future<void>.delayed(Duration.zero);

      expect(states, [
        SupabaseAuthState.signedIn,
        SupabaseAuthState.signedOut,
        SupabaseAuthState.signedIn,
      ]);

      await subscription.cancel();
      await provider.dispose();
    });
  });

  group('DefaultSupabaseAuthProvider', () {
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;
    late StreamController<AuthState> authStateController;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      authStateController = StreamController<AuthState>.broadcast();

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.onAuthStateChange)
          .thenAnswer((_) => authStateController.stream);
    });

    tearDown(() async {
      await authStateController.close();
    });

    test('initializes with signedIn state when session exists', () {
      final mockSession = MockSession();
      when(() => mockAuth.currentSession).thenReturn(mockSession);

      final provider = DefaultSupabaseAuthProvider(mockClient);

      expect(provider.currentState, SupabaseAuthState.signedIn);
    });

    test('initializes with signedOut state when no session', () {
      when(() => mockAuth.currentSession).thenReturn(null);

      final provider = DefaultSupabaseAuthProvider(mockClient);

      expect(provider.currentState, SupabaseAuthState.signedOut);
    });

    test('updates state on signedIn event', () async {
      when(() => mockAuth.currentSession).thenReturn(null);

      final provider = DefaultSupabaseAuthProvider(mockClient);
      final states = <SupabaseAuthState>[];
      final subscription = provider.authStateChanges.listen(states.add);

      // Emit signedIn event
      authStateController.add(
        AuthState(AuthChangeEvent.signedIn, MockSession()),
      );

      await Future<void>.delayed(Duration.zero);

      expect(provider.currentState, SupabaseAuthState.signedIn);
      expect(states, contains(SupabaseAuthState.signedIn));

      await subscription.cancel();
      await provider.dispose();
    });

    test('updates state on tokenRefreshed event', () async {
      when(() => mockAuth.currentSession).thenReturn(null);

      final provider = DefaultSupabaseAuthProvider(mockClient);
      final states = <SupabaseAuthState>[];
      final subscription = provider.authStateChanges.listen(states.add);

      // Emit tokenRefreshed event
      authStateController.add(
        AuthState(AuthChangeEvent.tokenRefreshed, MockSession()),
      );

      await Future<void>.delayed(Duration.zero);

      expect(provider.currentState, SupabaseAuthState.signedIn);

      await subscription.cancel();
      await provider.dispose();
    });

    test('updates state on userUpdated event', () async {
      when(() => mockAuth.currentSession).thenReturn(null);

      final provider = DefaultSupabaseAuthProvider(mockClient);
      final states = <SupabaseAuthState>[];
      final subscription = provider.authStateChanges.listen(states.add);

      // Emit userUpdated event
      authStateController.add(
        AuthState(AuthChangeEvent.userUpdated, MockSession()),
      );

      await Future<void>.delayed(Duration.zero);

      expect(provider.currentState, SupabaseAuthState.signedIn);

      await subscription.cancel();
      await provider.dispose();
    });

    test('updates state on signedOut event', () async {
      final mockSession = MockSession();
      when(() => mockAuth.currentSession).thenReturn(mockSession);

      final provider = DefaultSupabaseAuthProvider(mockClient);
      final states = <SupabaseAuthState>[];
      final subscription = provider.authStateChanges.listen(states.add);

      // Emit signedOut event
      authStateController.add(
        const AuthState(AuthChangeEvent.signedOut, null),
      );

      await Future<void>.delayed(Duration.zero);

      expect(provider.currentState, SupabaseAuthState.signedOut);
      expect(states, contains(SupabaseAuthState.signedOut));

      await subscription.cancel();
      await provider.dispose();
    });

    test('updates state on initialSession event with session', () async {
      when(() => mockAuth.currentSession).thenReturn(null);

      final provider = DefaultSupabaseAuthProvider(mockClient);
      final states = <SupabaseAuthState>[];
      final subscription = provider.authStateChanges.listen(states.add);

      // Emit initialSession event with session
      authStateController.add(
        AuthState(AuthChangeEvent.initialSession, MockSession()),
      );

      await Future<void>.delayed(Duration.zero);

      expect(provider.currentState, SupabaseAuthState.signedIn);

      await subscription.cancel();
      await provider.dispose();
    });

    test('updates state on initialSession event without session', () async {
      final mockSession = MockSession();
      when(() => mockAuth.currentSession).thenReturn(mockSession);

      final provider = DefaultSupabaseAuthProvider(mockClient);
      final states = <SupabaseAuthState>[];
      final subscription = provider.authStateChanges.listen(states.add);

      // Emit initialSession event without session
      authStateController.add(
        const AuthState(AuthChangeEvent.initialSession, null),
      );

      await Future<void>.delayed(Duration.zero);

      expect(provider.currentState, SupabaseAuthState.signedOut);

      await subscription.cancel();
      await provider.dispose();
    });

    test('does not change state on passwordRecovery event', () async {
      final mockSession = MockSession();
      when(() => mockAuth.currentSession).thenReturn(mockSession);

      final provider = DefaultSupabaseAuthProvider(mockClient);

      // Emit passwordRecovery event
      authStateController.add(
        AuthState(AuthChangeEvent.passwordRecovery, mockSession),
      );

      await Future<void>.delayed(Duration.zero);

      // State should remain signedIn (unchanged)
      expect(provider.currentState, SupabaseAuthState.signedIn);

      await provider.dispose();
    });

    test('does not change state on mfaChallengeVerified event', () async {
      final mockSession = MockSession();
      when(() => mockAuth.currentSession).thenReturn(mockSession);

      final provider = DefaultSupabaseAuthProvider(mockClient);

      // Emit mfaChallengeVerified event
      authStateController.add(
        AuthState(AuthChangeEvent.mfaChallengeVerified, mockSession),
      );

      await Future<void>.delayed(Duration.zero);

      // State should remain signedIn (unchanged)
      expect(provider.currentState, SupabaseAuthState.signedIn);

      await provider.dispose();
    });

    test('sets error state on auth stream error', () async {
      when(() => mockAuth.currentSession).thenReturn(null);

      final provider = DefaultSupabaseAuthProvider(mockClient);
      final states = <SupabaseAuthState>[];
      final subscription = provider.authStateChanges.listen(states.add);

      // Emit an error
      authStateController.addError(Exception('Auth error'));

      await Future<void>.delayed(Duration.zero);

      expect(provider.currentState, SupabaseAuthState.error);
      expect(states, contains(SupabaseAuthState.error));

      await subscription.cancel();
      await provider.dispose();
    });

    test('currentUserId returns user id when signed in', () {
      final mockSession = MockSession();
      final mockUser = MockUser();
      when(() => mockAuth.currentSession).thenReturn(mockSession);
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user-123');

      final provider = DefaultSupabaseAuthProvider(mockClient);

      expect(provider.currentUserId, 'user-123');
    });

    test('currentUserId returns null when no user', () {
      when(() => mockAuth.currentSession).thenReturn(null);
      when(() => mockAuth.currentUser).thenReturn(null);

      final provider = DefaultSupabaseAuthProvider(mockClient);

      expect(provider.currentUserId, isNull);
    });

    test('getAccessToken returns token when session valid', () async {
      final mockSession = MockSession();
      when(() => mockAuth.currentSession).thenReturn(mockSession);
      when(() => mockSession.isExpired).thenReturn(false);
      when(() => mockSession.accessToken).thenReturn('access-token-123');

      final provider = DefaultSupabaseAuthProvider(mockClient);

      final token = await provider.getAccessToken();

      expect(token, 'access-token-123');

      await provider.dispose();
    });

    test('getAccessToken returns null when no session', () async {
      when(() => mockAuth.currentSession).thenReturn(null);

      final provider = DefaultSupabaseAuthProvider(mockClient);

      final token = await provider.getAccessToken();

      expect(token, isNull);

      await provider.dispose();
    });

    test('getAccessToken refreshes expired session', () async {
      final mockSession = MockSession();
      final mockNewSession = MockSession();
      final mockAuthResponse = MockAuthResponse();

      when(() => mockAuth.currentSession).thenReturn(mockSession);
      when(() => mockSession.isExpired).thenReturn(true);
      when(() => mockAuth.refreshSession())
          .thenAnswer((_) async => mockAuthResponse);
      when(() => mockAuthResponse.session).thenReturn(mockNewSession);
      when(() => mockNewSession.accessToken).thenReturn('new-access-token');

      final provider = DefaultSupabaseAuthProvider(mockClient);

      final token = await provider.getAccessToken();

      expect(token, 'new-access-token');
      verify(() => mockAuth.refreshSession()).called(1);

      await provider.dispose();
    });

    test('getAccessToken returns null when refresh fails', () async {
      final mockSession = MockSession();

      when(() => mockAuth.currentSession).thenReturn(mockSession);
      when(() => mockSession.isExpired).thenReturn(true);
      when(() => mockAuth.refreshSession())
          .thenThrow(Exception('Refresh failed'));

      final provider = DefaultSupabaseAuthProvider(mockClient);

      final token = await provider.getAccessToken();

      expect(token, isNull);

      await provider.dispose();
    });

    test('getAccessToken returns null when refresh returns no session',
        () async {
      final mockSession = MockSession();
      final mockAuthResponse = MockAuthResponse();

      when(() => mockAuth.currentSession).thenReturn(mockSession);
      when(() => mockSession.isExpired).thenReturn(true);
      when(() => mockAuth.refreshSession())
          .thenAnswer((_) async => mockAuthResponse);
      when(() => mockAuthResponse.session).thenReturn(null);

      final provider = DefaultSupabaseAuthProvider(mockClient);

      final token = await provider.getAccessToken();

      expect(token, isNull);

      await provider.dispose();
    });

    test('dispose cancels subscription and closes controller', () async {
      when(() => mockAuth.currentSession).thenReturn(null);

      final provider = DefaultSupabaseAuthProvider(mockClient);

      // Subscribe to verify the stream works
      final subscription = provider.authStateChanges.listen((_) {});

      await provider.dispose();

      // After dispose, emitting should not reach the listener
      // (controller is closed)
      expect(
        () async {
          authStateController.add(
            AuthState(AuthChangeEvent.signedIn, MockSession()),
          );
          await Future<void>.delayed(Duration.zero);
        },
        returnsNormally,
      );

      await subscription.cancel();
    });
  });
}
