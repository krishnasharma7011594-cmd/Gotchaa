import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../nation/nation_data.dart';
import '../repositories/auth_repository.dart';
import 'repository_providers.dart';

// ── Stream: auth state ───────────────────────────────────────────────────────

final authStateProvider = StreamProvider<User?>(
    (ref) => ref.watch(authRepositoryProvider).authStateChanges);

// ── Current user convenience provider ───────────────────────────────────────

final currentUserProvider =
    Provider<User?>((ref) => ref.watch(authStateProvider).asData?.value);

// ── AuthController state ─────────────────────────────────────────────────────

/// Represents what the auth controller is doing / has done.
sealed class AuthState {
  const AuthState();
}

class AuthIdle extends AuthState {
  const AuthIdle();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  const AuthSuccess();
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

// ── Controller ───────────────────────────────────────────────────────────────

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthIdle());
  final AuthRepository _repo;

  /// Translates raw Firebase exception codes to user-friendly messages.
  String _friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found for that email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'email-already-in-use':
          return 'An account already exists with that email.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'network-request-failed':
          return 'Network error. Check your connection.';
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
          return 'Sign-in was cancelled.';
        default:
          return e.message ?? 'Authentication failed.';
      }
    }
    final msg = e.toString();
    if (msg.contains('aborted by user')) return 'Sign-in was cancelled.';
    return 'An unexpected error occurred.';
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = const AuthLoading();
    try {
      await action();
      state = const AuthSuccess();
      return true;
    } catch (e) {
      state = AuthError(_friendlyError(e));
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = const AuthLoading();
    try {
      await _repo.signInWithEmail(email, password);
      state = const AuthSuccess();
      return true;
    } catch (e) {
      try {
        await FirebaseFunctions.instance
            .httpsCallable('trackFailedLogin')
            .call({'email': email});
      } catch (_) {}
      state = AuthError(_friendlyError(e));
      return false;
    }
  }

  Future<bool> signUp(String email, String password, {NationData? nation}) =>
      _run(() => _repo.signUpWithEmail(email, password, nation: nation));

  Future<bool> signInWithGoogle() => _run(_repo.signInWithGoogle);

  Future<bool> signInWithApple() => _run(_repo.signInWithApple);

  Future<void> signOut() async {
    state = const AuthLoading();
    try {
      await _repo.signOut();
      state = const AuthIdle();
    } catch (_) {
      state = const AuthIdle(); // Always recover
    }
  }

  Future<bool> signInAnonymously() => _run(_repo.signInAnonymously);

  void resetState() => state = const AuthIdle();
}

// ── Provider ─────────────────────────────────────────────────────────────────

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
    (ref) => AuthController(ref.watch(authRepositoryProvider)));
