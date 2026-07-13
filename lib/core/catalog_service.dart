import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Loads and caches the book catalog.
/// Tries primary URL first, falls back to backup if primary fails.
class CatalogService extends ChangeNotifier {
  static const _cacheKey = 'catalog_json';
  static const _primaryUrl =
      'https://raw.githubusercontent.com/MuslimSaint/rawdah-catalog/main/catalog.json';
  static const _backupUrl =
      'https://raw.githubusercontent.com/SaintMuslim/rawdah-catalog-backup/main/catalog.json';

  Catalog? _catalog;
  bool _isLoading = false;
  String? _error;

  Catalog? get catalog => _catalog;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _catalog != null;

  // ─── Catalog data ──────────────────────────────────

  List<Book> get books => _catalog?.books ?? [];
  List<Teacher> get teachers => _catalog?.teachers ?? [];
  List<Reciter> get reciters => _catalog?.reciters ?? [];
  QuranData get quran => _catalog?.quran ?? QuranData.empty();

  List<QuranSubBranch> get quranSubBranches =>
      _catalog?.quran.subBranches ?? const [];

  String get audioBaseUrl =>
      _catalog?.audioBaseUrl ??
      'https://github.com/MuslimSaint/rawdah-catalog/releases/download/v1.0-books';

  String get quranBaseUrl =>
      _catalog?.quranBaseUrl ??
      'https://github.com/MuslimSaint/rawdah-catalog/releases/download/v1.0-quran';

  Announcement? get activeAnnouncement {
    final a = _catalog?.announcement;
    if (a == null || !a.active || a.message.isEmpty) {
      return null;
    }
    return a;
  }

  // ─── Load ────────────────────────────────────────────

  Future<void> load() async {
    await _loadFromCache();
    await _fetchFromNetwork();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        _catalog = Catalog.fromJson(json);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('CatalogService cache load failed: $e');
    }
  }

  Future<void> _fetchFromNetwork() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Try primary URL first
    final primaryResult = await _tryFetchFrom(_primaryUrl);

    if (primaryResult != null) {
      _applyCatalog(primaryResult);
      return;
    }

    // Primary failed — try backup
    debugPrint('Primary catalog URL failed. Trying backup...');
    final backupResult = await _tryFetchFrom(_backupUrl);

    if (backupResult != null) {
      debugPrint('Backup catalog loaded successfully.');
      _applyCatalog(backupResult);
      return;
    }

    // Both failed
    debugPrint('Both catalog URLs failed — keeping cache.');
    if (_catalog == null) {
      _error = 'No internet connection and no cached data.';
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Tries to fetch and parse catalog from a URL.
  /// Returns the raw response body on success, null on failure.
  Future<String?> _tryFetchFrom(String baseUrl) async {
    try {
      final timestamp =
          DateTime.now().millisecondsSinceEpoch;
      final url = '$baseUrl?t=$timestamp';

      final response = await http.get(
        Uri.parse(url),
        headers: const {
          'Cache-Control': 'no-cache, no-store',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // Verify it parses correctly before accepting
        try {
          final json = jsonDecode(response.body)
              as Map<String, dynamic>;
          Catalog.fromJson(json); // test parse
          return response.body;
        } catch (parseError) {
          debugPrint(
              'Catalog parse failed from $baseUrl: $parseError');
          return null;
        }
      } else {
        debugPrint(
            'Catalog fetch from $baseUrl returned ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint(
          'Catalog fetch from $baseUrl failed: $e');
      return null;
    }
  }

  void _applyCatalog(String responseBody) {
    try {
      final json =
          jsonDecode(responseBody) as Map<String, dynamic>;
      _catalog = Catalog.fromJson(json);
      _error = null;

      // Save to cache
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(_cacheKey, responseBody);
      });

      debugPrint(
          'Catalog refreshed. Version: ${_catalog!.version}, '
          'Books: ${_catalog!.books.length}, '
          'SubBranches: ${_catalog!.quran.subBranches.length}');
    } catch (e) {
      debugPrint('Catalog apply failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _fetchFromNetwork();
  }

  // ─── Helpers ─────────────────────────────────────────

  List<Book> booksInBranch(String branchId) =>
      _catalog?.booksInBranch(branchId) ?? [];

  List<Book> search(String query) =>
      _catalog?.search(query) ?? [];

  Teacher? teacherById(String id) =>
      _catalog?.teacherById(id);

  Reciter? reciterById(String id) =>
      _catalog?.reciterById(id);

  int bookCountForBranch(String branchId) =>
      booksInBranch(branchId).length;

  QuranSubBranch? quranSubBranchById(String id) {
    try {
      return quranSubBranches.firstWhere((sb) => sb.id == id);
    } catch (_) {
      return null;
    }
  }

  String audioUrl({
    required String bookId,
    required String teacherId,
    required int partNumber,
  }) {
    return '$audioBaseUrl/${bookId}_${teacherId}_$partNumber.mp3';
  }

  String surahPdfUrl(int surahNumber) {
    return '$quranBaseUrl/surah_$surahNumber.pdf';
  }

  String surahReciterUrl({
    required int surahNumber,
    required String reciterId,
    required int partNumber,
  }) {
    return '$quranBaseUrl/surah_${surahNumber}_reciter_${reciterId}_$partNumber.mp3';
  }

  String surahTeacherUrl({
    required int surahNumber,
    required String teacherId,
    required int partNumber,
  }) {
    return '$quranBaseUrl/surah_${surahNumber}_teacher_${teacherId}_$partNumber.mp3';
  }

  String? get mushafPdfUrl {
    final url = _catalog?.quran.mushafPdfUrl ?? '';
    if (url.isEmpty) return null;
    return url;
  }
}
