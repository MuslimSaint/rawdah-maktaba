import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'models.dart';

/// Manages external content table files for books.
///
/// Each book can have a contentTableUrl pointing to a
/// small JSON file like:
///   [{"titleAr":"...", "titleEn":"...", "page": 1}]
///
/// Files are cached locally as:
///   {appDocumentsDir}/book_toc/toc_<bookId>.json
///
/// Priority order in PdfReaderScreen:
///   1. Local cached external file (if downloaded)
///   2. Embedded contentTable in the catalog
///   3. No content table (button not shown)
class ContentTableService {
  static const _tocDirName = 'book_toc';

  final Map<String, List<ContentTableEntry>>
      _cache = {};
  final Set<String> _downloading = {};

  // ─── Read ──────────────────────────────────────

  /// Returns the content table for a book, or null
  /// if none is available locally.
  ///
  /// Checks the local cache file first. Does NOT
  /// trigger a download — downloads are triggered
  /// separately by the app state.
  Future<List<ContentTableEntry>?> getLocalToc(
      String bookId) async {
    if (_cache.containsKey(bookId)) {
      final cached = _cache[bookId]!;
      return cached.isEmpty ? null : cached;
    }

    try {
      final file = await _tocFileFor(bookId);
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final parsed = _parseJson(content);
      _cache[bookId] = parsed;
      return parsed.isEmpty ? null : parsed;
    } catch (e) {
      debugPrint(
          'ContentTableService: read failed for $bookId: $e');
      return null;
    }
  }

  /// Returns the effective content table for a book.
  ///
  /// Priority:
  ///   1. Local cached external file
  ///   2. Embedded contentTable in Book model
  ///   3. null (no content table)
  Future<List<ContentTableEntry>?> getEffectiveToc(
      Book book) async {
    // Try external file first
    if (book.hasContentTableUrl) {
      final external = await getLocalToc(book.id);
      if (external != null && external.isNotEmpty) {
        return external;
      }
    }

    // Fall back to embedded
    if (book.hasContentTable) {
      return book.contentTable;
    }

    return null;
  }

  /// Synchronously check if a local TOC file exists.
  /// Used by PdfReaderScreen to decide whether to show
  /// the content table button before the async load.
  bool hasCachedToc(String bookId) {
    return _cache.containsKey(bookId) &&
        _cache[bookId]!.isNotEmpty;
  }

  // ─── Download ──────────────────────────────────

  /// Downloads the external content table file for
  /// a book and caches it locally.
  ///
  /// Called automatically when a book PDF is downloaded.
  /// Silent — no UI feedback.
  Future<void> downloadToc({
    required String bookId,
    required String url,
  }) async {
    if (url.isEmpty) return;
    if (_downloading.contains(bookId)) return;

    // Already cached and valid
    if (_cache.containsKey(bookId) &&
        _cache[bookId]!.isNotEmpty) return;

    final file = await _tocFileFor(bookId);
    if (await file.exists()) {
      // File exists — read into cache
      try {
        final content = await file.readAsString();
        final parsed = _parseJson(content);
        if (parsed.isNotEmpty) {
          _cache[bookId] = parsed;
          return;
        }
      } catch (_) {}
    }

    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.scheme != 'https') return;

    _downloading.add(bookId);

    try {
      final response = await http
          .get(uri, headers: const {
            'Cache-Control': 'no-cache',
          })
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        _downloading.remove(bookId);
        return;
      }

      final parsed = _parseJson(response.body);
      if (parsed.isEmpty) {
        _downloading.remove(bookId);
        return;
      }

      await file.writeAsString(response.body);
      _cache[bookId] = parsed;

      debugPrint(
        'ContentTableService: downloaded TOC for '
        '$bookId (${parsed.length} entries)',
      );
    } catch (e) {
      debugPrint(
          'ContentTableService: download failed for $bookId: $e');
    } finally {
      _downloading.remove(bookId);
    }
  }

  // ─── Delete ────────────────────────────────────

  /// Deletes the local TOC file for a book.
  /// Called when the book PDF is deleted.
  Future<void> deleteToc(String bookId) async {
    _cache.remove(bookId);
    try {
      final file = await _tocFileFor(bookId);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  // ─── Init ──────────────────────────────────────

  /// Pre-loads all existing local TOC files into
  /// the in-memory cache. Called once at app startup.
  Future<void> init() async {
    try {
      final dir = await _tocDir();
      if (!await dir.exists()) return;
      await for (final entity in dir.list()) {
        if (entity is File &&
            entity.path.endsWith('.json')) {
          final name = entity.path.split('/').last;
          if (name.startsWith('toc_')) {
            final bookId = name
                .replaceFirst('toc_', '')
                .replaceAll('.json', '');
            try {
              final content =
                  await entity.readAsString();
              final parsed = _parseJson(content);
              if (parsed.isNotEmpty) {
                _cache[bookId] = parsed;
              }
            } catch (_) {}
          }
        }
      }
      debugPrint(
        'ContentTableService: loaded '
        '${_cache.length} TOC(s) from disk.',
      );
    } catch (e) {
      debugPrint(
          'ContentTableService: init failed: $e');
    }
  }

  // ─── Helpers ───────────────────────────────────

  Future<Directory> _tocDir() async {
    final appDir =
        await getApplicationDocumentsDirectory();
    final dir =
        Directory('${appDir.path}/$_tocDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _tocFileFor(String bookId) async {
    final dir = await _tocDir();
    return File('${dir.path}/toc_$bookId.json');
  }

  List<ContentTableEntry> _parseJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((m) => ContentTableEntry.fromJson(m))
          .where(
              (e) => e.titleAr.isNotEmpty && e.page >= 1)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
