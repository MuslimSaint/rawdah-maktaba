import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Loads and caches the book catalog.
class CatalogService extends ChangeNotifier {
  static const _cacheKey = 'catalog_json';
  static const _catalogBaseUrl =
      'https://raw.githubusercontent.com/MuslimSaint/rawdah-catalog/main/catalog.json';

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

  /// List of Quran sub-branches, in the order defined by
  /// the catalog. Fully remote-controlled.
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

    try {
      final timestamp =
          DateTime.now().millisecondsSinceEpoch;
      final url = '$_catalogBaseUrl?t=$timestamp';

      final response = await http.get(
        Uri.parse(url),
        headers: const {
          'Cache-Control': 'no-cache, no-store',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        Catalog? freshCatalog;
        try {
          final json = jsonDecode(response.body)
              as Map<String, dynamic>;
          freshCatalog = Catalog.fromJson(json);
        } catch (parseError) {
          debugPrint(
              'CatalogService parse failed — keeping cache. Error: $parseError');
          _error = null;
          _isLoading = false;
          notifyListeners();
          return;
        }

        _catalog = freshCatalog;
        _error = null;

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, response.body);
        } catch (e) {
          debugPrint('Failed to write catalog cache: $e');
        }

        debugPrint(
            'Catalog refreshed. Version: ${freshCatalog.version}, Books: ${freshCatalog.books.length}, SubBranches: ${freshCatalog.quran.subBranches.length}');
      } else {
        debugPrint(
            'Catalog fetch returned ${response.statusCode} — keeping cache');
      }
    } catch (e) {
      debugPrint(
          'CatalogService network fetch failed — keeping cache. Error: $e');
      if (_catalog == null) {
        _error =
            'No internet connection and no cached data.';
      }
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

  /// Find a Quran sub-branch by its id.
  QuranSubBranch? quranSubBranchById(String id) {
    try {
      return quranSubBranches.firstWhere((sb) => sb.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Constructs a regular book audio URL.
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
