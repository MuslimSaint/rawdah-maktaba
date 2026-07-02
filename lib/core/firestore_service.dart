import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handles all Firestore sync operations.
/// Syncs reading progress and user profile to the cloud.
/// Falls back gracefully if offline or not signed in.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Current User ───────────────────────────────────

  String? get _uid => _auth.currentUser?.uid;
  bool get _isSignedIn => _uid != null;

  // ─── User Document ──────────────────────────────────

  DocumentReference? get _userDoc {
    if (!_isSignedIn) return null;
    return _db.collection('users').doc(_uid);
  }

  // ─── Save Reading Progress ──────────────────────────

  /// Saves the last opened book and page to Firestore.
  Future<void> saveReadingProgress({
    required String bookId,
    required String bookTitle,
    required int page,
    required int totalPages,
  }) async {
    if (!_isSignedIn) return;
    try {
      await _userDoc!.set(
        {
          'readingProgress': {
            'lastBookId': bookId,
            'lastBookTitle': bookTitle,
            'lastPage': page,
            'totalPages': totalPages,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Silently fail — local data is source of truth
    }
  }

  /// Loads reading progress from Firestore.
  /// Returns null if not found or offline.
  Future<Map<String, dynamic>?> loadReadingProgress() async {
    if (!_isSignedIn) return null;
    try {
      final doc = await _userDoc!.get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>?;
      return data?['readingProgress'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ─── Save User Profile ──────────────────────────────

  /// Creates or updates user profile in Firestore.
  Future<void> saveUserProfile({
    required String name,
    required String email,
  }) async {
    if (!_isSignedIn) return;
    try {
      await _userDoc!.set(
        {
          'profile': {
            'name': name,
            'email': email,
            'uid': _uid,
            'createdAt': FieldValue.serverTimestamp(),
          },
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  // ─── Save Lesson Progress ───────────────────────────

  /// Saves completed lessons for a book/teacher combo.
  Future<void> saveLessonProgress({
    required String bookId,
    required String teacherId,
    required List<bool> completed,
  }) async {
    if (!_isSignedIn) return;
    try {
      final key = '${bookId}_$teacherId';
      await _userDoc!.set(
        {
          'lessonProgress': {
            key: completed
                .asMap()
                .entries
                .where((e) => e.value)
                .map((e) => e.key)
                .toList(),
          },
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  /// Loads lesson progress for a book/teacher combo.
  /// Returns list of completed lesson indices.
  Future<List<int>> loadLessonProgress({
    required String bookId,
    required String teacherId,
  }) async {
    if (!_isSignedIn) return [];
    try {
      final doc = await _userDoc!.get();
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>?;
      final lessonData =
          data?['lessonProgress'] as Map<String, dynamic>?;
      final key = '${bookId}_$teacherId';
      final completed = lessonData?[key] as List<dynamic>?;
      return completed?.cast<int>() ?? [];
    } catch (_) {
      return [];
    }
  }

  // ─── Sync on Login ──────────────────────────────────

  /// Called after user signs in — syncs cloud data to local.
  /// Returns reading progress from cloud if available.
  Future<Map<String, dynamic>?> syncOnLogin() async {
    if (!_isSignedIn) return null;
    try {
      // Save profile
      final user = _auth.currentUser!;
      await saveUserProfile(
        name: user.displayName ?? '',
        email: user.email ?? '',
      );

      // Load and return reading progress
      return await loadReadingProgress();
    } catch (_) {
      return null;
    }
  }
}
