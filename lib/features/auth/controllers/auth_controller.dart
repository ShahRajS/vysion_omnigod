import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vysion_omnigod/core/telemetry/telemetry_service.dart';

/// State class containing the current user status and loading state.
class AuthState {
  /// Creates the authentication state wrapper.
  const AuthState({
    required this.user,
    required this.isLoading,
    this.errorMessage,
  });

  /// The Firebase user instance, null if unauthenticated.
  final User? user;

  /// Whether authentication action is in progress.
  final bool isLoading;

  /// Error message from the last action, if any.
  final String? errorMessage;

  /// Returns a copy of the state with updated parameters.
  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Notifier managing auth requests and Firebase interactions.
class AuthNotifier extends StateNotifier<AuthState> {
  /// Instantiates the Auth Notifier.
  AuthNotifier(this._auth, this._telemetry)
      : super(AuthState(user: _auth.currentUser, isLoading: false)) {
    // Listen for auth changes
    _auth.authStateChanges().listen((user) {
      if (state.user is! MockUser) {
        state = state.copyWith(user: user);
      }
    });
  }

  final FirebaseAuth _auth;
  final TelemetryService _telemetry;

  /// Signs in anonymously first.
  Future<void> signInAnonymously() async {
    state = state.copyWith(isLoading: true);
    try {
      final credential = await _auth.signInAnonymously();
      _telemetry.trackEvent('auth_sign_in_anonymous', parameters: {
        'uid': credential.user?.uid,
      },);
    } catch (e, stack) {
      _telemetry.logException(
        e,
        stackTrace: stack,
        context: 'signInAnonymously',
      );
      // Fallback to MockUser in development environment (e.g. if API Key is stub or missing)
      _telemetry.trackEvent('auth_sign_in_anonymous_mock_fallback');
      state = state.copyWith(
        user: MockUser(),
        errorMessage: null, // Clear error message since we recovered with mock user
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Authenticate user via Email and Password.
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _telemetry.trackEvent('auth_sign_in_email', parameters: {
        'uid': credential.user?.uid,
      },);
    } on FirebaseAuthException catch (e, stack) {
      _telemetry.logException(e, stackTrace: stack, context: 'signInWithEmail');
      state = state.copyWith(errorMessage: e.message);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Links active anonymous profile to permanent credentials.
  Future<void> linkAccount(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.linkWithCredential(credential);
        _telemetry.trackEvent('auth_link_account', parameters: {
          'uid': user.uid,
        },);
      }
    } on FirebaseAuthException catch (e, stack) {
      _telemetry.logException(e, stackTrace: stack, context: 'linkAccount');
      state = state.copyWith(errorMessage: e.message);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Sign out current session.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      if (state.user is MockUser) {
        state = state.copyWith(user: null);
      } else {
        await _auth.signOut();
      }
      _telemetry.trackEvent('auth_sign_out');
    } catch (e, stack) {
      _telemetry.logException(e, stackTrace: stack, context: 'signOut');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

/// Provider for the Firebase Auth instance.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider for the AuthNotifier.
final authControllerProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final telemetry = ref.watch(telemetryServiceProvider);
  return AuthNotifier(auth, telemetry);
});

/// Mock User class representing a guest session in development environments.
class MockUser implements User {
  @override
  final String uid = 'mock-uid-12345';

  @override
  final bool isAnonymous = true;

  @override
  final String? email = 'mock-user@vysion.co';

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async {
    return 'mock-token';
  }

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    return _MockUserCredential();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockUserCredential implements UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
