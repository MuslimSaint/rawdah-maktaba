import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Loads and caches the book catalog.
///
/// Supports two formats transparently:
///
/// 1. Legacy monolithic catalog.json — one big file with
///    all data. Detected when the root has no "includes"
///    key. Loaded with a single HTTP request.
///
/// 2. Split catalog — root catalog.json contains an
///    "includes" map pointing to 5 sub-files:
///      teachers.json, reciters.json, books.json,
///      surahs.json, mushaf.json
///    All 5 are fetched in parallel and assembled into
///    a single Catalog object.
///
/// Both primary and backup repos are tried. On network
/// failure, per-file SharedPreferences caches are used
/// as fallback so the app keeps working offline.
class CatalogService extends ChangeNotifier {
  // ── Assembled catalog cache (monolithic shape) ──
  static const _cacheKey = 'catalog_json';

  // ── Per-file caches for split format ──
  static const _rootCacheKey = 'catalog_root_json';
  static const _teachersCacheKey =
      'catalog_teachers_json';
  static const _recitersCacheKey =
      'catalog_reciters_json';
  static const _booksCacheKey = 'catalog_books_json';
  static const _surahsCacheKey = 'catalog_surahs_json';
  static const _mushafCacheKey = 'catalog_mushaf_json';

  static const _primaryBase =
      'https://raw.githubusercontent.com/MuslimSaint/rawdah-catalog/main';
  static const _backupBase =
      'https://raw.githubusercontent.com/SaintMuslim/rawdah-catalog-backup/main';

  Catalog? _catalog;
  bool _isLoading = false;
  String? _error;

  Catalog? get catalog => _catalog;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _catalog != null;

  // ─── Catalog data ──────────────────────────────────

  List<Book> get books => _catalog?.books ?? [];
  List<Teacher> get teachers =>
      _catalog?.teachers ?? [];
  List<Reciter> get reciters =>
      _catalog?.reciters ?? [];
  QuranData get quran =>
      _catalog?.quran ?? QuranData.empty();

  List<QuranSubBranch> get quranSubBranches =>
      _catalog?.quran.subBranches ?? const [];

  String get audioBaseUrl =>
      _catalog?.audioBaseUrl ??
      'https://github.com/MuslimSaint/rawdah-catalog/'
          'releases/download/v1.0-books';

  String get quranBaseUrl =>
      _catalog?.quranBaseUrl ??
      'https://github.com/MuslimSaint/rawdah-catalog/'
          'releases/download/v1.0-quran';

  Announcement? get activeAnnouncement {
    final a = _catalog?.announcement;
    if (a == null || !a.active || a.message.isEmpty) {
      return null;
    }
    return a;
  }

  // ─── Load ──────────────────────────────────────────

  Future<void> load() async {
    await _loadFromCache();
    await _fetchFromNetwork();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        final json = _decodeMap(cached);
        if (json != null) {
          _catalog = Catalog.fromJson(json);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint(
          'CatalogService cache load failed: $e');
    }
  }

  Future<void> _fetchFromNetwork() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Pass 1: try a fully fresh load from each repo.
    final primaryFresh = await _tryRepo(
        _primaryBase,
        allowCacheFallback: false);
    if (primaryFresh != null) {
      await _apply(primaryFresh);
      return;
    }

    final backupFresh = await _tryRepo(
        _backupBase,
        allowCacheFallback: false);
    if (backupFresh != null) {
      await _apply(backupFresh);
      return;
    }

    // Pass 2: allow per-file cache fallback.
    final primaryCached = await _tryRepo(
        _primaryBase,
        allowCacheFallback: true);
    if (primaryCached != null) {
      await _apply(primaryCached);
      return;
    }

    final backupCached = await _tryRepo(
        _backupBase,
        allowCacheFallback: true);
    if (backupCached != null) {
      await _apply(backupCached);
      return;
    }

    debugPrint(
        'All catalog fetches failed — keeping cache.');
    if (_catalog == null) {
      _error =
          'No internet connection and no cached data.';
    }
    _isLoading = false;
    notifyListeners();
  }

  // ─── Try one repo ──────────────────────────────────

  Future<Map<String, dynamic>?> _tryRepo(
    String baseUrl, {
    required bool allowCacheFallback,
  }) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      // Fetch root.
      final root = await _fetchFile(
        url: '$baseUrl/catalog.json',
        cacheKey: _rootCacheKey,
        prefs: prefs,
        allowCacheFallback: allowCacheFallback,
      );
      if (root == null) return null;

      final includes = _readIncludes(root['includes']);

      // ── Monolithic format: no includes key ──
      if (includes.isEmpty) {
        try {
          Catalog.fromJson(root);
          debugPrint(
            'Loaded monolithic catalog from $baseUrl'
            ' (cacheFallback=$allowCacheFallback)',
          );
          return root;
        } catch (e) {
          debugPrint(
              'Monolithic parse failed from $baseUrl: $e');
          return null;
        }
      }

      // ── Split format: fetch 5 sub-files in parallel ──
      final teachersPath =
          includes['teachers'] ?? 'teachers.json';
      final recitersPath =
          includes['reciters'] ?? 'reciters.json';
      final booksPath =
          includes['books'] ?? 'books.json';
      final surahsPath =
          includes['surahs'] ?? 'surahs.json';
      final mushafPath =
          includes['mushaf'] ?? 'mushaf.json';

      final results =
          await Future.wait<Map<String, dynamic>?>([
        _fetchFile(
          url: '$baseUrl/$teachersPath',
          cacheKey: _teachersCacheKey,
          prefs: prefs,
          allowCacheFallback: allowCacheFallback,
        ),
        _fetchFile(
          url: '$baseUrl/$recitersPath',
          cacheKey: _recitersCacheKey,
          prefs: prefs,
          allowCacheFallback: allowCacheFallback,
        ),
        _fetchFile(
          url: '$baseUrl/$booksPath',
          cacheKey: _booksCacheKey,
          prefs: prefs,
          allowCacheFallback: allowCacheFallback,
        ),
        _fetchFile(
          url: '$baseUrl/$surahsPath',
          cacheKey: _surahsCacheKey,
          prefs: prefs,
          allowCacheFallback: allowCacheFallback,
        ),
        _fetchFile(
          url: '$baseUrl/$mushafPath',
          cacheKey: _mushafCacheKey,
          prefs: prefs,
          allowCacheFallback: allowCacheFallback,
        ),
      ]);

      if (results.any((r) => r == null)) {
        debugPrint(
          'Split catalog incomplete from $baseUrl'
          ' (cacheFallback=$allowCacheFallback)',
        );
        return null;
      }

      final assembled = Catalog.assembleJson(
        root: root,
        teachers: results[0]!,
        reciters: results[1]!,
        books: results[2]!,
        surahs: results[3]!,
        mushaf: results[4]!,
      );

      // Validate the assembled result.
      try {
        Catalog.fromJson(assembled);
      } catch (e) {
        debugPrint(
            'Assembled catalog parse failed: $e');
        return null;
      }

      debugPrint(
        'Loaded split catalog from $baseUrl'
        ' (cacheFallback=$allowCacheFallback)',
      );
      return assembled;
    } catch (e) {
      debugPrint(
        'Catalog fetch from $baseUrl failed'
        ' (cacheFallback=$allowCacheFallback): $e',
      );
      return null;
    }
  }

  // ─── Fetch a single JSON file ──────────────────────

  Future<Map<String, dynamic>?> _fetchFile({
    required String url,
    required String cacheKey,
    required SharedPreferences prefs,
    required bool allowCacheFallback,
  }) async {
    try {
      final ts =
          DateTime.now().millisecondsSinceEpoch;
      final uri =
          Uri.parse('$url?t=$ts');

      final response = await http
          .get(uri, headers: const {
            'Cache-Control': 'no-cache, no-store',
            'Pragma': 'no-cache',
          })
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
            'HTTP ${response.statusCode}');
      }

      final json = _decodeMap(response.body);
      if (json == null) {
        throw Exception(
            'Response is not a JSON object');
      }

      // Cache successful response.
      await prefs.setString(cacheKey, response.body);
      return json;
    } catch (e) {
      debugPrint('Fetch failed for $url: $e');

      if (!allowCacheFallback) return null;

      final cached = prefs.getString(cacheKey);
      if (cached == null) {
        debugPrint(
            'No cache fallback for $url');
        return null;
      }
      final cachedJson = _decodeMap(cached);
      if (cachedJson == null) {
        debugPrint(
            'Cached data malformed for $url');
        return null;
      }
      debugPrint('Using cache fallback for $url');
      return cachedJson;
    }
  }

  // ─── Apply assembled catalog ───────────────────────

  Future<void> _apply(
      Map<String, dynamic> assembled) async {
    try {
      _catalog = Catalog.fromJson(assembled);
      _error = null;

      // Cache the assembled monolithic JSON so cold
      // starts work without network.
      final prefs =
          await SharedPreferences.getInstance();
      await prefs.setString(
          _cacheKey, jsonEncode(assembled));

      debugPrint(
        'Catalog applied. '
        'Version: ${_catalog!.version}, '
        'Books: ${_catalog!.books.length}, '
        'Reciters: ${_catalog!.reciters.length}, '
        'SubBranches: '
        '${_catalog!.quran.subBranches.length}',
      );
    } catch (e) {
      debugPrint('Catalog apply failed: $e');
      if (_catalog == null) {
        _error = 'Failed to parse catalog.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _fetchFromNetwork();
  }

  // ─── JSON helpers ──────────────────────────────────

  Map<String, dynamic>? _decodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map(
            (k, v) => MapEntry(k.toString(), v));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _readIncludes(dynamic raw) {
    if (raw is! Map) return {};
    final result = <String, String>{};
    raw.forEach((k, v) {
      if (v is String && v.trim().isNotEmpty) {
        result[k.toString()] = v.trim();
      }
    });
    return result;
  }

  // ─── Helpers ───────────────────────────────────────

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
      return quranSubBranches
          .firstWhere((sb) => sb.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── URL resolvers ─────────────────────────────────

  String audioUrlFor({
    required String bookId,
    required TeacherAudio teacherAudio,
    required int partNumber,
  }) {
    final override =
        teacherAudio.urlForPart(partNumber);
    if (override != null && override.isNotEmpty) {
      return override;
    }
    return '$audioBaseUrl/'
        '${bookId}_${teacherAudio.teacherId}_$partNumber.mp3';
  }

  String surahReciterUrlFor({
    required int surahNumber,
    required ReciterAudio reciterAudio,
    required int partNumber,
  }) {
    final override =
        reciterAudio.urlForPart(partNumber);
    if (override != null && override.isNotEmpty) {
      return override;
    }
    return '$quranBaseUrl/'
        'surah_${surahNumber}_reciter_'
        '${reciterAudio.reciterId}_$partNumber.mp3';
  }

  String surahTeacherUrlFor({
    required int surahNumber,
    required TeacherAudio teacherAudio,
    required int partNumber,
  }) {
    final override =
        teacherAudio.urlForPart(partNumber);
    if (override != null && override.isNotEmpty) {
      return override;
    }
    return '$quranBaseUrl/'
        'surah_${surahNumber}_teacher_'
        '${teacherAudio.teacherId}_$partNumber.mp3';
  }

  String surahPdfUrlFor(Surah surah) {
    if (surah.pdfUrl.isNotEmpty) return surah.pdfUrl;
    return '$quranBaseUrl/${surah.number}.pdf';
  }

  /// Legacy — kept so old call sites still compile.
  String surahPdfUrl(int surahNumber) =>
      '$quranBaseUrl/$surahNumber.pdf';

  String? get mushafPdfUrl {
    final url =
        _catalog?.quran.mushafPdfUrl ?? '';
    if (url.isEmpty) return null;
    return url;
  }
}
