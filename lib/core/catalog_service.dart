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

  Catalog? get catalog => _catalog;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _catalog != null;

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

  Announcement? get activeAnnouncement {
    final a = _catalog?.announcement;
    if (a == null || !a.active || a.message.isEmpty) return null;
    return a;
  }

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

    // ── Pass 1: fresh fetch, no cache fallback ──────
    // Try primary first, then backup.
    // Both use the version-check optimization:
    // if the remote version matches our cached version,
    // we skip all sub-file fetches entirely.
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

    // ── Pass 2: cache-assisted fallback ────────────
    // Network failed. Try again but allow each sub-file
    // to fall back to its individual cached copy.
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

  // ─── _tryRepo ──────────────────────────────────────
  //
  // Returns an assembled catalog JSON map if successful,
  // or null if the fetch/parse failed.
  //
  // Version-check logic:
  //   1. Fetch only catalog.json (root).
  //   2. Read its "version" field.
  //   3. Compare to the locally stored cached version.
  //   4. If SAME and we have a valid assembled cache:
  //      → Return the cached assembled catalog immediately.
  //      → Zero additional HTTP requests.
  //   5. If DIFFERENT (or no cache):
  //      → Fetch all 5 sub-files in parallel.
  //      → Assemble and return.

  Future<Map<String, dynamic>?> _tryRepo(
    String baseUrl, {
    required bool allowCacheFallback,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Step 1 — fetch root catalog.json
      final root = await _fetchFile(
        url: '$baseUrl/catalog.json',
        cacheKey: _rootCacheKey,
        prefs: prefs,
        allowCacheFallback: allowCacheFallback,
      );
      if (root == null) return null;

      // Step 2 — read remote version
      final remoteVersion =
          root['version']?.toString() ?? '';

      // Step 3 — read locally cached version
      final cachedVersion =
          prefs.getString(_cachedVersionKey) ?? '';

      // Step 4 — version-check shortcut
      // Only applies when:
      //   - versions match (catalog not updated)
      //   - we have a valid assembled cache
      //   - we are not in cache-fallback mode
      //     (cache-fallback mode means network already
      //      failed so we skip version shortcut to avoid
      //      using a stale assembled cache if root was
      //      served from local cache too)
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
            } catch (_) {
              // Assembled cache is corrupt — fall through
              // to full fetch below.
            }
          }
        }
      }

      // Step 5 — version changed (or no cache).
      // Determine if this is split or monolithic.
      final includes = _readIncludes(root['includes']);

      if (includes.isEmpty) {
        // Monolithic format
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

      // Step 6 — split format: fetch 5 sub-files in parallel
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

  // ─── _fetchFile ────────────────────────────────────

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

  // ─── _apply ────────────────────────────────────────

  Future<void> _apply(
      Map<String, dynamic> assembled) async {
    try {
      _catalog = Catalog.fromJson(assembled);
      _error = null;

      final prefs = await SharedPreferences.getInstance();

      // Save assembled catalog for cold-start cache
      await prefs.setString(_cacheKey, jsonEncode(assembled));

      // Save the version so the next launch can do a
      // version-check shortcut.
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
    // Force a full re-fetch regardless of version.
    // Called manually by the user (pull to refresh)
    // or by the app on demand.
    // Clear the cached version so the version-check
    // shortcut is bypassed this one time.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedVersionKey);
    await _fetchFromNetwork();
  }

  // ─── JSON helpers ──────────────────────────────────

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
