import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles all file downloads — PDFs and audio files.
class DownloadService extends ChangeNotifier {
  final Map<String, double> _progress = {};
  final Map<String, bool> _downloading = {};
  final Set<String> _downloaded = {};

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

  // ─── Download ──────────────────────────────────────

  Future<void> download({
    required String fileId,
    required String url,
    required Function(String error) onError,
    required VoidCallback onComplete,
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

    _downloading[fileId] = true;
    _progress[fileId] = 0;
    notifyListeners();

    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();

      if (response.statusCode != 200) {
        _downloading[fileId] = false;
        _progress.remove(fileId);
        notifyListeners();
        onError('Server error: ${response.statusCode}');
        return;
      }

      final file = await _fileFor(fileId);
      final sink = file.openWrite();
      final total = response.contentLength ?? 0;
      var received = 0;

      // Use await for — reliable stream handling
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) {
            _progress[fileId] = received / total;
            notifyListeners();
          }
        }

        // Stream finished — file complete
        await sink.flush();
        await sink.close();

        _downloading[fileId] = false;
        _progress[fileId] = 1.0;
        _downloaded.add(fileId);
        await _saveDownloaded();
        notifyListeners();
        onComplete();
      } catch (e) {
        await sink.close();
        if (await file.exists()) await file.delete();
        _downloading[fileId] = false;
        _progress.remove(fileId);
        notifyListeners();
        onError('Download interrupted. Please try again.');
      }
    } catch (e) {
      _downloading[fileId] = false;
      _progress.remove(fileId);
      notifyListeners();
      onError('Download failed. Check your internet connection.');
    }
  }

  // ─── Delete ────────────────────────────────────────

  Future<void> deleteFile(String fileId) async {
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
    final dir = await _downloadsDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create();
    }
    _downloaded.clear();
    _progress.clear();
    _downloading.clear();
    await _saveDownloaded();
    notifyListeners();
  }

  // ─── Open ──────────────────────────────────────────

  Future<String?> localPath(String fileId) async {
    final file = await _fileFor(fileId);
    if (await file.exists()) return file.path;
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
    for (final id in _downloaded) {
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
    await prefs.setStringList(_downloadedKey, _downloaded.toList());
  }

  // ─── ID Helpers ────────────────────────────────────

  static String pdfId(String bookId) => 'pdf_$bookId';

  static String audioId(String bookId, String teacherId, int part) =>
      'audio_${bookId}_${teacherId}_$part';
}
