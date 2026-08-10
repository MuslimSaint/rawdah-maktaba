import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Loads and caches the book catalog.
///
/// Supports both monolithic and 6-file split formats.
///
/// Version-check optimization (Task 8):
///   On every app launch, only catalog.json (root, ~1 KB)
///   is fetched first. If its "version" field matches the
///   cached version, the 5 sub-files are NOT re-fetched —
///   the existing assembled cache is used directly.
///   Only when the version differs (catalog was updated)
///   are all 5 sub-files re-fetched and reassembled.
class CatalogService extends ChangeNotifier {
  static const _cacheKey = 'catalog_json';
  static const _cachedVersionKey = 'catalog_cached_version';
  static const _rootCacheKey = 'catalog_root_json';
  static const _teachersCacheKey = 'catalog_teachers_json';
  static const _recitersCacheKey = 'catalog_reciters_json';
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

  /// The current app version, injected from AppState.
  /// Used to filter announcements by version range.
  /// If empty, no version filtering is applied.
  String _currentAppVersion = '';

  Catalog? get catalog => _catalog;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _catalog != null;

  /// Called by AppState after it discovers the app version
  /// via MethodChannel to Android.
  void setCurrentAppVersion(String version) {
    if (_currentAppVersion == version) return;
    _currentAppVersion = version;
    notifyListeners();
  }

  String get currentAppVersion => _currentAppVersion;

  // ─── Catalog data ──────────────────────────────────

  List<Book> get books => _catalog?.books ?? [];
  List<Teacher> get teachers => _catalog?.teachers ?? [];
  List<Reciter> get reciters => _catalog?.reciters ?? [];
  QuranData get quran => _catalog?.quran ?? QuranData.empty();
  AppSettings get settings =>
      _catalog?.settings ?? AppSettings.defaults();

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

  /// Returns the active announcement, filtered by:
  ///   1. active flag
  ///   2. non-empty message
  ///   3. currentAppVersion within
  ///      [minVersionToShow .. maxVersionToShow] range
  ///
  /// If minVersionToShow / maxVersionToShow are empty,
  /// they are ignored (no lower / upper bound).
  ///
  /// If currentAppVersion is empty (not yet loaded from
  /// Android), no version filtering is applied — the
  /// announcement shows.
  Announcement? get activeAnnouncement {
    final a = _catalog?.announcement;
    if (a == null || !a.active || a.message.isEmpty) {
      return null;
    }

    if (_currentAppVersion.isEmpty) {
      // App version not yet loaded — show anyway.
      return a;
    }

    // Check min version
    if (a.minVersionToShow.isNotEmpty) {
      if (_compareVersions(
              _currentAppVersion, a.minVersionToShow) <
          0) {
        // current < min → don't show
        return null;
      }
    }

    // Check max version
    if (a.maxVersionToShow.isNotEmpty) {
      if (_compareVersions(
              _currentAppVersion, a.maxVersionToShow) >
          0) {
        // current > max → user already updated → don't show
        return null;
      }
    }

    return a;
  }

  /// Semantic version comparison.
  /// Returns:
  ///   -1 if a < b
  ///    0 if a == b
  ///    1 if a > b
  ///
  /// Splits on '.' and '+' and compares numerically.
  /// Examples:
  ///   compareVersions('1.0.0', '1.0.1')      → -1
  ///   compareVersions('1.0.0.1', '1.0.0')    →  1
  ///   compareVersions('1.0.0+1', '1.0.0')    →  0  (build code ignored)
  ///   compareVersions('1.0.0+2', '1.0.0+1')  →  0  (both are 1.0.0)
  int _compareVersions(String a, String b) {
    // Strip build code (everything after '+')
    final aClean = a.split('+').first.trim();
    final bClean = b.split('+').first.trim();

    final aParts = aClean.split('.');
    final bParts = bClean.split('.');
    final maxLen =
        aParts.length > bParts.length ? aParts.length : bParts.length;

    for (var i = 0; i < maxLen; i++) {
      final aNum =
          i < aParts.length ? int.tryParse(aParts[i]) ?? 0 : 0;
      final bNum =
          i < bParts.length ? int.tryParse(bParts[i]) ?? 0 : 0;
      if (aNum < bNum) return -1;
      if (aNum > bNum) return 1;
    }
    return 0;
  }

  /// Public version comparison — exposed so other services
  /// (like APK cleanup logic in AppState) can use the same
  /// logic without duplicating it.
  int compareVersions(String a, String b) =>
      _compareVersions(a, b);

  // ─── Load ──────────────────────────────────────────

  Future<void> load() async {
    await _loadFromCache();
    await _fetchFromNetwork();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        final json = _decodeMap(cached);
        if (json != null) {
          _catalog = Catalog.fromJson(json);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('CatalogService cache load failed: $e');
    }
  }

  Future<void> _fetchFromNetwork() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final primaryFresh =
        await _tryRepo(_primaryBase, allowCacheFallback: false);
    if (primaryFresh != null) {
      await _apply(primaryFresh);
      return;
    }

    final backupFresh =
        await _tryRepo(_backupBase, allowCacheFallback: false);
    if (backupFresh != null) {
      await _apply(backupFresh);
      return;
    }

    final primaryCached =
        await _tryRepo(_primaryBase, allowCacheFallback: true);
    if (primaryCached != null) {
      await _apply(primaryCached);
      return;
    }

    final backupCached =
        await _tryRepo(_backupBase, allowCacheFallback: true);
    if (backupCached != null) {
      await _apply(backupCached);
      return;
    }

    debugPrint('All catalog fetches failed — keeping cache.');
    if (_catalog == null) {
      _error = 'No internet connection and no cached data.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _tryRepo(
    String baseUrl, {
    required bool allowCacheFallback,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final root = await _fetchFile(
        url: '$baseUrl/catalog.json',
        cacheKey: _rootCacheKey,
        prefs: prefs,
        allowCacheFallback: allowCacheFallback,
      );
      if (root == null) return null;

      final remoteVersion =
          root['version']?.toString() ?? '';
      final cachedVersion =
          prefs.getString(_cachedVersionKey) ?? '';

      if (!allowCacheFallback &&
          remoteVersion.isNotEmpty &&
          remoteVersion == cachedVersion) {
        final assembledCached = prefs.getString(_cacheKey);
        if (assembledCached != null) {
          final assembledJson = _decodeMap(assembledCached);
          if (assembledJson != null) {
            try {
              Catalog.fromJson(assembledJson);
              debugPrint(
                'Catalog version $remoteVersion unchanged '
                '— using cache, skipping sub-file fetches.',
              );
              return assembledJson;
            } catch (_) {}
          }
        }
      }

      final includes = _readIncludes(root['includes']);

      if (includes.isEmpty) {
        try {
          Catalog.fromJson(root);
          debugPrint(
            'Loaded monolithic catalog from $baseUrl '
            '(version: $remoteVersion)',
          );
          return root;
        } catch (e) {
          debugPrint(
              'Monolithic parse failed from $baseUrl: $e');
          return null;
        }
      }

      final teachersPath =
          includes['teachers'] ?? 'teachers.json';
      final recitersPath =
          includes['reciters'] ?? 'reciters.json';
      final booksPath = includes['books'] ?? 'books.json';
      final surahsPath =
          includes['surahs'] ?? 'surahs.json';
      final mushafPath =
          includes['mushaf'] ?? 'mushaf.json';

      debugPrint(
        'Catalog version changed ($cachedVersion → $remoteVersion). '
        'Fetching all sub-files from $baseUrl...',
      );

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
            'Sub-file fetch incomplete from $baseUrl');
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

      try {
        Catalog.fromJson(assembled);
      } catch (e) {
        debugPrint('Assembled catalog parse failed: $e');
        return null;
      }

      debugPrint(
        'Fetched and assembled split catalog from $baseUrl '
        '(version: $remoteVersion)',
      );
      return assembled;
    } catch (e) {
      debugPrint(
          'Catalog fetch from $baseUrl failed: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchFile({
    required String url,
    required String cacheKey,
    required SharedPreferences prefs,
    required bool allowCacheFallback,
  }) async {
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final uri = Uri.parse('$url?t=$ts');

      final response = await http
          .get(uri, headers: const {
            'Cache-Control': 'no-cache, no-store',
            'Pragma': 'no-cache',
          })
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final json = _decodeMap(response.body);
      if (json == null) {
        throw Exception('Response is not a JSON object');
      }

      await prefs.setString(cacheKey, response.body);
      return json;
    } catch (e) {
      debugPrint('Fetch failed for $url: $e');
      if (!allowCacheFallback) return null;

      final cached = prefs.getString(cacheKey);
      if (cached == null) return null;
      return _decodeMap(cached);
    }
  }

  Future<void> _apply(
      Map<String, dynamic> assembled) async {
    try {
      _catalog = Catalog.fromJson(assembled);
      _error = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(assembled));
      await prefs.setString(
          _cachedVersionKey, _catalog!.version);

      debugPrint(
        'Catalog applied. '
        'Version: ${_catalog!.version}, '
        'Books: ${_catalog!.books.length}, '
        'Reciters: ${_catalog!.reciters.length}, '
        'Settings links: '
        '${_catalog!.settings.connectLinks.length}',
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedVersionKey);
    await _fetchFromNetwork();
  }

  Map<String, dynamic>? _decodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
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

  String audioUrlFor({
    required String bookId,
    required TeacherAudio teacherAudio,
    required int partNumber,
  }) {
    final override = teacherAudio.urlForPart(partNumber);
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
    final override = reciterAudio.urlForPart(partNumber);
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
    final override = teacherAudio.urlForPart(partNumber);
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

  String surahPdfUrl(int surahNumber) =>
      '$quranBaseUrl/$surahNumber.pdf';

  String? get mushafPdfUrl {
    final url = _catalog?.quran.mushafPdfUrl ?? '';
    if (url.isEmpty) return null;
    return url;
  }
}
