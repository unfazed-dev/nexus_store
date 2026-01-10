import 'dart:async';

import 'package:supabase/supabase.dart';

/// The authentication state for a Supabase session.
enum SupabaseAuthState {
  /// User is signed in with a valid session.
  signedIn,

  /// User is signed out or has no session.
  signedOut,

  /// Authentication is in progress (loading).
  loading,

  /// An error occurred during authentication.
  error,
}

/// An abstract interface for Supabase authentication.
///
/// This abstraction enables:
/// - Testability: Mock implementations for unit testing
/// - Custom auth flows: Support for custom JWT providers
/// - Flexibility: Different auth providers for different environments
///
/// Example implementation:
/// ```dart
/// class CustomAuthProvider implements SupabaseAuthProvider {
///   @override
///   SupabaseAuthState get currentState => _state;
///
///   @override
///   Stream<SupabaseAuthState> get authStateChanges => _controller.stream;
///
///   @override
///   String? get currentUserId => _userId;
///
///   @override
///   Future<String?> getAccessToken() async => _token;
///
///   @override
///   Future<void> dispose() async => _controller.close();
/// }
/// ```
abstract interface class SupabaseAuthProvider {
  /// The current authentication state.
  SupabaseAuthState get currentState;

  /// Stream of authentication state changes.
  Stream<SupabaseAuthState> get authStateChanges;

  /// The current user's ID, or null if not signed in.
  String? get currentUserId;

  /// Gets the current access token.
  ///
  /// Returns null if not signed in or token is expired.
  Future<String?> getAccessToken();

  /// Disposes any resources held by this provider.
  Future<void> dispose();
}

/// Default implementation of [SupabaseAuthProvider] using Supabase client.
///
/// This implementation wraps a [SupabaseClient] and exposes its auth
/// state through the [SupabaseAuthProvider] interface.
///
/// Example:
/// ```dart
/// final client = SupabaseClient('url', 'key');
/// final authProvider = DefaultSupabaseAuthProvider(client);
///
/// authProvider.authStateChanges.listen((state) {
///   print('Auth state: $state');
/// });
/// ```
class DefaultSupabaseAuthProvider implements SupabaseAuthProvider {
  /// Creates a [DefaultSupabaseAuthProvider] with the given Supabase client.
  DefaultSupabaseAuthProvider(this._client) {
    _initialize();
  }

  final SupabaseClient _client;
  final _authStateController = StreamController<SupabaseAuthState>.broadcast();
  StreamSubscription<AuthState>? _authSubscription;
  SupabaseAuthState _currentState = SupabaseAuthState.loading;

  void _initialize() {
    // Set initial state based on current session
    final session = _client.auth.currentSession;
    _currentState = session != null
        ? SupabaseAuthState.signedIn
        : SupabaseAuthState.signedOut;

    // Listen for auth state changes
    _authSubscription = _client.auth.onAuthStateChange.listen(
      (data) {
        final event = data.event;
        switch (event) {
          case AuthChangeEvent.signedIn:
          case AuthChangeEvent.tokenRefreshed:
          case AuthChangeEvent.userUpdated:
            _currentState = SupabaseAuthState.signedIn;
          case AuthChangeEvent.signedOut:
          // ignore: deprecated_member_use
          case AuthChangeEvent.userDeleted:
            _currentState = SupabaseAuthState.signedOut;
          case AuthChangeEvent.initialSession:
            _currentState = data.session != null
                ? SupabaseAuthState.signedIn
                : SupabaseAuthState.signedOut;
          case AuthChangeEvent.passwordRecovery:
          case AuthChangeEvent.mfaChallengeVerified:
            // These don't change the signed-in state
            break;
        }
        _authStateController.add(_currentState);
      },
      onError: (Object error) {
        _currentState = SupabaseAuthState.error;
        _authStateController.add(_currentState);
      },
    );
  }

  @override
  SupabaseAuthState get currentState => _currentState;

  @override
  Stream<SupabaseAuthState> get authStateChanges => _authStateController.stream;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<String?> getAccessToken() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;

    // Check if token is expired and needs refresh
    if (session.isExpired) {
      try {
        final response = await _client.auth.refreshSession();
        return response.session?.accessToken;
      } on Object {
        return null;
      }
    }

    return session.accessToken;
  }

  @override
  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _authStateController.close();
  }
}
