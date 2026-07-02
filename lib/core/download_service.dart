import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles all file downloads — PDFs and audio files.
class DownloadService extends ChangeNotifier {

  // ─── State ─────────────────────────────────────────
  final Map<String, double> _progress = {};
  final Map<String, bool> _downloading = {};
  final Set<String> _downloaded = {};
  final Map<String, bool> _cancelled = {};

  // Active download metadata (for Downloads tab)
  final Map<String, Map<String, dynamic>> _activeDownloads = {};

  static const _downloadedKey = 'downloaded_files';

  // ─── Init ──────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_downloadedKey) ?? [];
    _downloaded.addAll(saved);

    // Verify files still exist
    final toRemove = <String>[];
    for (final id in _downloaded) {
      final file = await _fileFor(id);
      if (!await file.exists()) {
        toRemove.add(id);
      }
    }
    if (toRemove.isNotEmpty) {
      _downloaded.removeAll(toRemove);
      await _saveDownloaded();
      notifyListeners();
    }
  }

  // ─── Getters ───────────────────────────────────────

  bool isDownloaded(String fileId) => _downloaded.contains(fileId);
  bool isDownloading(String fileId) => _downloading[fileId] ?? false;
  double progress(String fileId) => _progress[fileId] ?? 0;
  int get downloadedCount => _downloaded.length;
  bool get hasActiveDownloads => _activeDownloads.isNotEmpty;

  /// Returns list of currently downloading files
  List<Map<String, dynamic>> get activeDownloads =>
      _activeDownloads.values.toList();

  // ─── Download ──────────────────────────────────────

  Future<void> download({
    required String fileId,
    required String url,
    required Function(String error) onError,
    required VoidCallback onComplete,
    String? displayName,
    String? bookId,
  }) async {
    if (_downloading[fileId] == true) return;
    if (_downloaded.contains(fileId)) {
      onComplete();
      return;
    }

    if (url.isEmpty) {
      onError('This file is not available yet.');
      return;
    }

    // Reset cancelled flag
    _cancelled[fileId] = false;
    _downloading[fileId] = true;
    _progress[fileId] = 0;

    // Track in active downloads
    _activeDownloads[fileId] = {
      'fileId': fileId,
      'displayName': displayName ?? fileId,
      'bookId': bookId ?? '',
      'progress': 0.0,
      'speedKbps': 0.0,
      'startedAt': DateTime.now(),
    };

    notifyListeners();

    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();

      if (response.statusCode != 200) {
        _cleanupActive(fileId);
        onError('Server error: ${response.statusCode}');
        return;
      }

      final file = await _fileFor(fileId);
      final sink = file.openWrite();
      final total = response.contentLength ?? 0;
      var received = 0;
      var lastTime = DateTime.now();
      var lastReceived = 0;

      try {
        await for (final chunk in response.stream) {
          // Check if cancelled
          if (_cancelled[fileId] == true) {
            await sink.close();
            if (await file.exists()) await file.delete();
            _cleanupActive(fileId);
            return;
          }

          sink.add(chunk);
          received += chunk.length;

          // Calculate speed every 500ms
          final now = DateTime.now();
          final elapsed = now.difference(lastTime).inMilliseconds;
          if (elapsed >= 500) {
            final bytesPerMs = (received - lastReceived) / elapsed;
            final kbps = (bytesPerMs * 1000) / 1024;
            lastTime = now;
            lastReceived = received;

            if (_activeDownloads.containsKey(fileId)) {
              _activeDownloads[fileId]!['speedKbps'] = kbps;
            }
          }

          if (total > 0) {
            _progress[fileId] = received / total;
            if (_activeDownloads.containsKey(fileId)) {
              _activeDownloads[fileId]!['progress'] =
                  _progress[fileId];
            }
            notifyListeners();
          }
        }

        // Stream complete — save file
        await sink.flush();
        await sink.close();

        _downloaded.add(fileId);
        await _saveDownloaded();
        _cleanupActive(fileId);
        _progress[fileId] = 1.0;
        notifyListeners();
        onComplete();
      } catch (e) {
        await sink.close();
        if (await file.exists()) await file.delete();
        _cleanupActive(fileId);
        onError('Download interrupted. Please try again.');
      }
    } catch (e) {
      _cleanupActive(fileId);
      onError('Download failed. Check your internet connection.');
    }
  }

  // ─── Cancel ────────────────────────────────────────

  Future<void> cancelDownload(String fileId) async {
    if (_downloading[fileId] != true) return;
    _cancelled[fileId] = true;
    // Cleanup happens inside the download loop
    notifyListeners();
  }

  void _cleanupActive(String fileId) {
    _downloading[fileId] = false;
    _activeDownloads.remove(fileId);
    _cancelled.remove(fileId);
  }

  // ─── Delete ────────────────────────────────────────

  Future<void> deleteFile(String fileId) async {
    // Cancel if downloading
    if (_downloading[fileId] == true) {
      await cancelDownload(fileId);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    try {
      final file = await _fileFor(fileId);
      if (await file.exists()) await file.delete();
    } catch (_) {}

    _downloaded.remove(fileId);
    _progress.remove(fileId);
    _downloading.remove(fileId);
    await _saveDownloaded();
    notifyListeners();
  }

  Future<void> deleteAll() async {
    // Cancel all active downloads
    for (final id in _downloading.keys.toList()) {
      if (_downloading[id] == true) {
        _cancelled[id] = true;
      }
    }
    await Future.delayed(const Duration(milliseconds: 300));

    final dir = await _downloadsDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create();
    }
    _downloaded.clear();
    _progress.clear();
    _downloading.clear();
    _activeDownloads.clear();
    _cancelled.clear();
    await _saveDownloaded();
    notifyListeners();
  }

  // ─── Open ──────────────────────────────────────────

  Future<String?> localPath(String fileId) async {
    if (!_downloaded.contains(fileId)) return null;
    final file = await _fileFor(fileId);
    if (await file.exists()) return file.path;
    // File missing — remove from downloaded list
    _downloaded.remove(fileId);
    await _saveDownloaded();
    notifyListeners();
    return null;
  }

  // ─── Storage ───────────────────────────────────────

  Future<double> totalStorageMb() async {
    final dir = await _downloadsDir();
    if (!await dir.exists()) return 0;

    double total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total / (1024 * 1024);
  }

  Future<List<Map<String, dynamic>>> downloadedFiles() async {
    final result = <Map<String, dynamic>>[];
    for (final id in _downloaded.toList()) {
      final file = await _fileFor(id);
      if (await file.exists()) {
        final size = await file.length();
        result.add({
          'id': id,
          'sizeMb': size / (1024 * 1024),
          'path': file.path,
        });
      }
    }
    return result;
  }

  // ─── Helpers ───────────────────────────────────────

  Future<Directory> _downloadsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/rawdah_downloads');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _fileFor(String fileId) async {
    final dir = await _downloadsDir();
    final ext = fileId.startsWith('pdf_') ? '.pdf' : '.mp3';
    return File('${dir.path}/$fileId$ext');
  }

  Future<void> _saveDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _downloadedKey, _downloaded.toList());
  }

  // ─── ID Helpers ────────────────────────────────────

  static String pdfId(String bookId) => 'pdf_$bookId';

  static String audioId(
          String bookId, String teacherId, int part) =>
      'audio_${bookId}_${teacherId}_$part';

  // ─── Speed helper ──────────────────────────────────

  static String formatSpeed(double kbps) {
    if (kbps >= 1024) {
      return '${(kbps / 1024).toStringAsFixed(1)} MB/s';
    }
    return '${kbps.toStringAsFixed(0)} KB/s';
  }
}
