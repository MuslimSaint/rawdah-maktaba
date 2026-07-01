import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Handles all Firebase Authentication operations.
/// Sign up, sign in, Google sign-in, and sign out.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ─── Current User ───────────────────────────────────

  /// Returns the currently signed-in user, or null if not signed in.
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes.
  /// Emits a User when signed in, null when signed out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Email & Password ───────────────────────────────

  /// Creates a new account with email and password.
  /// Returns null on success, or an error message string on failure.
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

      // Save display name to the Firebase user profile
      await credential.user?.updateDisplayName(name.trim());

      return null; // success
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e.code);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Signs in with email and password.
  /// Returns null on success, or an error message string on failure.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e.code);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  // ─── Google Sign-In ─────────────────────────────────

  /// Signs in with Google.
  /// Returns null on success, or an error message string on failure.
  /// Returns 'cancelled' if the user dismissed the Google picker.
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User cancelled the sign-in
      if (googleUser == null) return 'cancelled';

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return 'Firebase error: ${e.code} — ${e.message}';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  // ─── Sign Out ───────────────────────────────────────

  /// Signs out from Firebase and Google.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ─── Error Handling ─────────────────────────────────

  /// Converts Firebase error codes into readable messages.
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
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
