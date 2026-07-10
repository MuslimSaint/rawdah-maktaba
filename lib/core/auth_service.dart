import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Handles all Firebase Authentication operations.
/// Sign up, sign in, Google sign-in, and sign out.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ─── Current User ───────────────────────────────────

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Email & Password ───────────────────────────────

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await credential.user?.updateDisplayName(name.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e.code);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e.code);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  // ─── Google Sign-In ─────────────────────────────────

  /// Signs in with Google account.
  /// Returns:
  ///   - null on success
  ///   - 'cancelled' if user cancelled the picker
  ///   - error message string on failure
  Future<String?> signInWithGoogle() async {
    try {
      // Show the Google account picker
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      // User cancelled the picker
      if (googleUser == null) {
        return 'cancelled';
      }

      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential from Google tokens
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      await _auth.signInWithCredential(credential);

      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e.code);
    } catch (e) {
      // Common Google-specific errors
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('network')) {
        return 'No internet connection. Please check your network.';
      }
      if (errorStr.contains('cancelled') ||
          errorStr.contains('canceled')) {
        return 'cancelled';
      }
      if (errorStr.contains('sign_in_failed') ||
          errorStr.contains('developer_error')) {
        return 'Google sign-in configuration error. Please contact support.';
      }
      return 'Google sign-in failed. Please try again.';
    }
  }

  // ─── Sign Out ───────────────────────────────────────

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // If Google sign-out fails, still sign out of Firebase
    }
    await _auth.signOut();
  }

  // ─── Error Handling ─────────────────────────────────

  String _handleAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'account-exists-with-different-credential':
        return 'An account with this email already exists using a different sign-in method.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
