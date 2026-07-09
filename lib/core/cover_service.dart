import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Extracts and caches:
///   1. The first page of downloaded PDFs as cover images
///   2. The real page count of each downloaded PDF
///
/// Both operations happen in a single PdfDocument.openFile()
/// call for efficiency. Completely UI-independent —
/// extraction works regardless of which screen user is on.
class CoverService extends ChangeNotifier {
  static const _pageCountsKey = 'pdf_page_counts';

  final Map<String, String> _coverPaths = {};
  final Map<String, int> _pageCounts = {};
  final Set<String> _extracting = {};

  // ─── Getters ───────────────────────────────────────

  bool hasCover(String bookId) =>
      _coverPaths.containsKey(bookId);

  String? coverPath(String bookId) => _coverPaths[bookId];

  /// Returns the real PDF page count for a book,
  /// or null if not yet extracted / PDF not downloaded.
  int? pageCount(String bookId) => _pageCounts[bookId];

  bool hasPageCount(String bookId) =>
      _pageCounts.containsKey(bookId);

  // ─── Init ──────────────────────────────────────────

  Future<void> init() async {
    // Load cached page counts from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_pageCountsKey) ?? [];
      for (final entry in raw) {
        final parts = entry.split('|');
        if (parts.length == 2) {
          final count = int.tryParse(parts[1]);
          if (count != null && count > 0) {
            _pageCounts[parts[0]] = count;
          }
        }
      }
    } catch (_) {}

    // Load existing cover files
    try {
      final dir = await _coversDir();
      if (!await dir.exists()) {
        if (_pageCounts.isNotEmpty) notifyListeners();
        return;
      }
      await for (final entity in dir.list()) {
        if (entity is File &&
            entity.path.endsWith('.jpg')) {
          final name = entity.path.split('/').last;
          final bookId = name.replaceAll('.jpg', '');
          _coverPaths[bookId] = entity.path;
        }
      }
    } catch (_) {}

    if (_coverPaths.isNotEmpty || _pageCounts.isNotEmpty) {
      notifyListeners();
    }
  }

  // ─── Extract ───────────────────────────────────────

  /// Extracts the first page as cover AND the real page
  /// count from a downloaded PDF.
  /// Safe to call multiple times — skips work already done.
  /// UI-independent — can be called from any service.
  Future<void> extractCover({
    required String bookId,
    required String pdfPath,
  }) async {
    // Already fully processed
    if (_coverPaths.containsKey(bookId) &&
        _pageCounts.containsKey(bookId)) {
      return;
    }
    if (_extracting.contains(bookId)) return;

    // Verify PDF exists
    if (!await File(pdfPath).exists()) return;

    _extracting.add(bookId);

    try {
      final doc = await PdfDocument.openFile(pdfPath);

      if (doc.pageCount == 0) {
        _extracting.remove(bookId);
        return;
      }

      // ── 1. Save the real page count ──
      _pageCounts[bookId] = doc.pageCount;
      await _savePageCounts();
      notifyListeners();

      // ── 2. Extract cover (only if not already done) ──
      if (!_coverPaths.containsKey(bookId)) {
        final page = await doc.getPage(1);
        final targetWidth = 400;
        final targetHeight =
            (targetWidth * page.height / page.width).round();

        final pageImage = await page.render(
          width: targetWidth,
          height: targetHeight,
        );

        final uiImage =
            await pageImage.createImageIfNotAvailable();
        if (uiImage == null) {
          _extracting.remove(bookId);
          return;
        }

        final byteData = await uiImage.toByteData(
          format: ui.ImageByteFormat.png,
        );

        if (byteData == null) {
          _extracting.remove(bookId);
          return;
        }

        final dir = await _coversDir();
        final file = File('${dir.path}/$bookId.jpg');
        await file.writeAsBytes(
            byteData.buffer.asUint8List());

        _coverPaths[bookId] = file.path;
        notifyListeners();
      }
    } catch (_) {
      // Silently fail — placeholder cover used
    } finally {
      _extracting.remove(bookId);
    }
  }

  // ─── Delete ────────────────────────────────────────

  /// Called when a PDF is deleted — removes its cover too.
  /// Note: page count is intentionally kept — even if PDF
  /// is deleted, the count remains valid metadata about
  /// that book. If deletion of count is desired later,
  /// call [clearPageCount] separately.
  Future<void> deleteCover(String bookId) async {
    try {
      final path = _coverPaths[bookId];
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {}
    _coverPaths.remove(bookId);
    notifyListeners();
  }

  /// Optional — clears cached page count for a book.
  Future<void> clearPageCount(String bookId) async {
    _pageCounts.remove(bookId);
    await _savePageCounts();
    notifyListeners();
  }

  // ─── Persistence ───────────────────────────────────

  Future<void> _savePageCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _pageCounts.entries
          .map((e) => '${e.key}|${e.value}')
          .toList();
      await prefs.setStringList(_pageCountsKey, list);
    } catch (_) {}
  }

  // ─── Helpers ───────────────────────────────────────

  Future<Directory> _coversDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/book_covers');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
