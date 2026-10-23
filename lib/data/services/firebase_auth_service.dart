import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Service wrapping Firebase Authentication with real Email/Password support.
/// Anonymous authentication is strictly removed.
class FirebaseAuthService {
  final FirebaseAuth? _injectedAuth;

  FirebaseAuthService({FirebaseAuth? auth}) : _injectedAuth = auth;

  FirebaseAuth? get _auth {
    if (_injectedAuth != null) return _injectedAuth;
    if (Firebase.apps.isEmpty) return null;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  bool get isAvailable => _auth != null;
  User? get currentUser => _auth?.currentUser;
  String? get currentUserId => _auth?.currentUser?.uid;
  String? get currentUserEmail => _auth?.currentUser?.email;
  String? get currentUserDisplayName => _auth?.currentUser?.displayName;
  bool get isSignedIn => currentUserId != null;

  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw FirebaseAuthException(
        code: 'firebase-unavailable',
        message: 'Firebase is not initialized or available.',
      );
    }
    return await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Create new user account with email, password, and optional display name
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw FirebaseAuthException(
        code: 'firebase-unavailable',
        message: 'Firebase is not initialized or available.',
      );
    }
    final cred = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (displayName != null && displayName.trim().isNotEmpty && cred.user != null) {
      try {
        await cred.user!.updateDisplayName(displayName.trim());
      } catch (e) {
        debugPrint('Failed to update display name: $e');
      }
    }

    return cred;
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _auth;
    if (auth == null) return;
    await auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Sign out the current Firebase user
  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (e) {
      debugPrint('Error signing out of Firebase: $e');
    }
  }

  /// Permanently delete the current Firebase Auth user
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth?.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      debugPrint('Error deleting user from Firebase Auth: $e');
      // If requires-recent-login or network error, still allow local cleanup
    }
  }

  /// Converts Firebase Auth errors into clear, user-friendly messages
  static String getReadableErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'email-already-in-use':
          return 'An account already exists for this email.';
        case 'invalid-email':
          return 'The email address is badly formatted.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'firebase-unavailable':
          return 'Firebase is offline. You can use Offline Mode.';
        default:
          return error.message ?? 'Authentication error occurred.';
      }
    }
    return error.toString();
  }
}
