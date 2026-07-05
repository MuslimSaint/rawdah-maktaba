import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_render/pdf_render.dart';

/// Extracts and caches the first page of downloaded PDFs
/// as cover images. Uses Android's built-in PDF renderer.
class CoverService extends ChangeNotifier {
  // bookId → local file path of extracted cover image
  final Map<String, String> _coverPaths = {};
  final Set<String> _extracting = {};

  // ─── Getters ───────────────────────────────────────

  bool hasCover(String bookId) =>
      _coverPaths.containsKey(bookId);

  String? coverPath(String bookId) => _coverPaths[bookId];

  // ─── Init ──────────────────────────────────────────

  /// Loads already-extracted covers from disk on startup.
  Future<void> init() async {
    try {
      final dir = await _coversDir();
      if (!await dir.exists()) return;
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.jpg')) {
          final name = entity.path.split('/').last;
          final bookId = name.replaceAll('.jpg', '');
          _coverPaths[bookId] = entity.path;
        }
      }
      if (_coverPaths.isNotEmpty) notifyListeners();
    } catch (_) {}
  }

  // ─── Extract ───────────────────────────────────────

  /// Extracts the first page of a PDF and saves it as a
  /// cover image. Called automatically after PDF download.
  Future<void> extractCover({
    required String bookId,
    required String pdfPath,
  }) async {
    // Already extracted or currently extracting
    if (_coverPaths.containsKey(bookId)) return;
    if (_extracting.contains(bookId)) return;

    _extracting.add(bookId);

    try {
      final doc = await PdfDocument.openFile(pdfPath);
      final page = await doc.getPage(1); // First page

      // Render at reasonable resolution for display
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

      // Save to disk
      final dir = await _coversDir();
      final file = File('${dir.path}/$bookId.jpg');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      _coverPaths[bookId] = file.path;
      notifyListeners();
    } catch (_) {
      // Silently fail — placeholder cover will be used
    } finally {
      _extracting.remove(bookId);
    }
  }

  // ─── Delete ────────────────────────────────────────

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

  // ─── Helpers ───────────────────────────────────────

  Future<Directory> _coversDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/book_covers');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
