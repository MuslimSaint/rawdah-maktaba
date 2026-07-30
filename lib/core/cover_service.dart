import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Extracts and caches per-book metadata from downloaded PDFs:
///   1. Cover image (first page rendered as JPG)
///   2. Real page count
///   3. Real file size in MB
///
/// All done in a single pass. Completely UI-independent.
class CoverService extends ChangeNotifier {
  static const _pageCountsKey = 'pdf_page_counts';
  static const _fileSizesKey = 'pdf_file_sizes_mb';

  final Map<String, String> _coverPaths = {};
  final Map<String, int> _pageCounts = {};
  final Map<String, double> _fileSizesMb = {};
  final Set<String> _extracting = {};

  // ─── Getters ───────────────────────────────────────

  bool hasCover(String bookId) =>
      _coverPaths.containsKey(bookId);

  String? coverPath(String bookId) => _coverPaths[bookId];

  int? pageCount(String bookId) => _pageCounts[bookId];

  bool hasPageCount(String bookId) =>
      _pageCounts.containsKey(bookId);

  double? fileSizeMb(String bookId) =>
      _fileSizesMb[bookId];

  bool hasFileSize(String bookId) =>
      _fileSizesMb.containsKey(bookId);

  // ─── Init ──────────────────────────────────────────

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final pcRaw =
          prefs.getStringList(_pageCountsKey) ?? [];
      for (final entry in pcRaw) {
        final parts = entry.split('|');
        if (parts.length == 2) {
          final count = int.tryParse(parts[1]);
          if (count != null && count > 0) {
            _pageCounts[parts[0]] = count;
          }
        }
      }

      final fsRaw =
          prefs.getStringList(_fileSizesKey) ?? [];
      for (final entry in fsRaw) {
        final parts = entry.split('|');
        if (parts.length == 2) {
          final size = double.tryParse(parts[1]);
          if (size != null && size > 0) {
            _fileSizesMb[parts[0]] = size;
          }
        }
      }
    } catch (_) {}

    try {
      final dir = await _coversDir();
      if (!await dir.exists()) {
        _notifyIfAny();
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

    _notifyIfAny();
  }

  void _notifyIfAny() {
    if (_coverPaths.isNotEmpty ||
        _pageCounts.isNotEmpty ||
        _fileSizesMb.isNotEmpty) {
      notifyListeners();
    }
  }

  // ─── Extract ───────────────────────────────────────

  Future<void> extractCover({
    required String bookId,
    required String pdfPath,
  }) async {
    if (_coverPaths.containsKey(bookId) &&
        _pageCounts.containsKey(bookId) &&
        _fileSizesMb.containsKey(bookId)) {
      return;
    }
    if (_extracting.contains(bookId)) return;

    final pdfFile = File(pdfPath);
    if (!await pdfFile.exists()) return;

    _extracting.add(bookId);

    try {
      // ── 1. File size ──
      if (!_fileSizesMb.containsKey(bookId)) {
        final bytes = await pdfFile.length();
        _fileSizesMb[bookId] = bytes / (1024 * 1024);
        await _saveFileSizes();
        notifyListeners();
      }

      // ── 2. Open PDF once for cover + page count ──
      final doc = await PdfDocument.openFile(pdfPath);

      if (doc.pageCount == 0) {
        _extracting.remove(bookId);
        return;
      }

      if (!_pageCounts.containsKey(bookId)) {
        _pageCounts[bookId] = doc.pageCount;
        await _savePageCounts();
        notifyListeners();
      }

      if (!_coverPaths.containsKey(bookId)) {
        final page = await doc.getPage(1);
        final targetWidth = 400;
        final targetHeight =
            (targetWidth * page.height / page.width)
                .round();

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
        await file
            .writeAsBytes(byteData.buffer.asUint8List());

        _coverPaths[bookId] = file.path;
        notifyListeners();
      }
    } catch (_) {
      // Silently fail
    } finally {
      _extracting.remove(bookId);
    }
  }

  // ─── Clear for a single book (Task 4) ──────────────

  /// Deletes the extracted cover image, cached page count,
  /// and cached file size for the given bookId.
  ///
  /// Called by AppState when a PDF is deleted so no
  /// orphaned data is left behind.
  Future<void> clearFor(String bookId) async {
    // Delete the cover image file from disk.
    try {
      final path = _coverPaths[bookId];
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {}

    // Remove from in-memory maps.
    _coverPaths.remove(bookId);
    _pageCounts.remove(bookId);
    _fileSizesMb.remove(bookId);

    // Persist the updated maps.
    await _savePageCounts();
    await _saveFileSizes();

    notifyListeners();
  }

  // ─── Legacy individual deleters ────────────────────
  // Kept for backward compatibility with any existing
  // callers. Both now simply delegate to clearFor() or
  // do their specific job.

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

  Future<void> clearPageCount(String bookId) async {
    _pageCounts.remove(bookId);
    await _savePageCounts();
    notifyListeners();
  }

  Future<void> clearFileSize(String bookId) async {
    _fileSizesMb.remove(bookId);
    await _saveFileSizes();
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

  Future<void> _saveFileSizes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _fileSizesMb.entries
          .map((e) =>
              '${e.key}|${e.value.toStringAsFixed(3)}')
          .toList();
      await prefs.setStringList(_fileSizesKey, list);
    } catch (_) {}
  }

  // ─── Helpers ───────────────────────────────────────

  Future<Directory> _coversDir() async {
    final appDir =
        await getApplicationDocumentsDirectory();
    final dir =
        Directory('${appDir.path}/book_covers');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String formatSize(double mb) {
    if (mb < 1) {
      return '${(mb * 1024).toStringAsFixed(0)} KB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }
}
