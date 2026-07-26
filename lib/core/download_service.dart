import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles all file downloads — PDFs and audio files.
///
/// Features:
/// - Real cancel (kills the underlying HTTP stream)
/// - HTTP Range resume on network drop / cancel-and-retry
/// - HTTPS-only enforcement
/// - MIME type check (rejects html/json — catches wrong URLs)
/// - Cover extraction hook (unchanged)
/// - Fully backward-compatible public API
class DownloadService extends ChangeNotifier {
  final Map<String, double> _progress = {};
  final Map<String, bool> _downloading = {};
  final Set<String> _downloaded = {};
  final Map<String, bool> _paused = {};
  final Map<String, Map<String, dynamic>> _activeDownloads = {};

  // Active stream subscriptions — cancel() kills them for real.
  final Map<String, StreamSubscription<List<int>>>
      _activeSubs = {};

  // Currently open write sinks — closed on cancel.
  final Map<String, IOSink> _activeSinks = {};

  // http.Client per download — closed on cancel.
  final Map<String, http.Client> _activeClients = {};

  static const _downloadedKey = 'downloaded_files';
  static const _partialPrefix = 'partial_bytes_';

  // ─── Cover extraction callback ─────────────────────
  Future<void> Function(String bookId, String pdfPath)?
      onPdfDownloadComplete;

  // ─── Init ──────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_downloadedKey) ?? [];
    _downloaded.addAll(saved);

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

  bool isDownloaded(String fileId) =>
      _downloaded.contains(fileId);

  bool isDownloading(String fileId) =>
      _downloading[fileId] == true;

  bool isPaused(String fileId) =>
      _paused[fileId] == true;

  double progress(String fileId) =>
      _progress[fileId] ?? 0;

  int get downloadedCount => _downloaded.length;
  bool get hasActiveDownloads => _activeDownloads.isNotEmpty;

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

    // ── URL validation ──
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      onError('This file has no download URL yet.');
      return;
    }
    final uri = Uri.tryParse(trimmedUrl);
    if (uri == null || !uri.hasAbsolutePath) {
      onError('Invalid download URL.');
      return;
    }
    if (uri.scheme != 'https') {
      onError('Only secure (https://) URLs are allowed.');
      return;
    }

    _paused[fileId] = false;
    _downloading[fileId] = true;
    _progress[fileId] = 0;

    _activeDownloads[fileId] = {
      'fileId': fileId,
      'displayName': displayName ?? fileId,
      'bookId': bookId ?? '',
      'progress': 0.0,
      'speedKbps': 0.0,
      'paused': false,
      'startedAt': DateTime.now(),
    };

    notifyListeners();

    // ── Check for resumable partial file ──
    final file = await _fileFor(fileId);
    int startByte = 0;
    if (await file.exists()) {
      startByte = await file.length();
    }
    // Verify saved offset matches actual file size.
    final savedOffset = await _readPartialOffset(fileId);
    if (savedOffset > 0 && savedOffset == startByte) {
      // Good — resume from here.
    } else {
      // Mismatch — start fresh.
      startByte = 0;
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }

    final client = http.Client();
    _activeClients[fileId] = client;

    try {
      final request = http.Request('GET', uri);
      if (startByte > 0) {
        request.headers['Range'] = 'bytes=$startByte-';
      }
      // Force redirect follow (http package does this by default,
      // but being explicit for clarity).
      request.followRedirects = true;
      request.maxRedirects = 5;

      final response = await client.send(request);

      // ── Status code check ──
      // 200 = full download. 206 = partial (Range accepted).
      // Anything else = error.
      if (response.statusCode != 200 &&
          response.statusCode != 206) {
        // If we asked for a Range and the server refused,
        // fall back to a fresh full download.
        if (startByte > 0 && response.statusCode == 416) {
          // 416 Range Not Satisfiable — file changed or server
          // doesn't support ranges. Restart fresh.
          client.close();
          _activeClients.remove(fileId);
          if (await file.exists()) await file.delete();
          await _clearPartialOffset(fileId);
          _failDownload(fileId);
          // Retry once from scratch
          return download(
            fileId: fileId,
            url: url,
            displayName: displayName,
            bookId: bookId,
            onError: onError,
            onComplete: onComplete,
          );
        }
        client.close();
        _activeClients.remove(fileId);
        _failDownload(fileId);
        onError('Server error: ${response.statusCode}');
        return;
      }

      // ── MIME type sanity check ──
      // Reject html/json — usually means the URL is a share
      // page, not a direct file link.
      final contentType =
          (response.headers['content-type'] ?? '').toLowerCase();
      if (contentType.contains('text/html') ||
          contentType.contains('application/json')) {
        client.close();
        _activeClients.remove(fileId);
        _failDownload(fileId);
        onError(
            'This URL does not point to a downloadable file. Use a direct link.');
        return;
      }

      // ── Open sink in append mode if resuming ──
      final sink = response.statusCode == 206
          ? file.openWrite(mode: FileMode.append)
          : file.openWrite();
      _activeSinks[fileId] = sink;

      // Total size: for 206, add Range start byte back.
      final contentLength = response.contentLength ?? 0;
      final total = response.statusCode == 206
          ? startByte + contentLength
          : contentLength;

      var received = startByte;
      var lastTime = DateTime.now();
      var lastReceived = received;

      final completer = Completer<void>();

      final sub = response.stream.listen(
        (chunk) async {
          // Handle pause: buffer this chunk and wait.
          while (_paused[fileId] == true) {
            await Future.delayed(
                const Duration(milliseconds: 200));
            if (!(_downloading[fileId] == true)) {
              // Was cancelled during pause.
              return;
            }
          }

          try {
            sink.add(chunk);
          } catch (_) {
            // Sink write failed — treat as cancel.
            return;
          }
          received += chunk.length;

          // Save byte offset periodically so we can resume
          // after crash / kill / network loss.
          if (received % (256 * 1024) < chunk.length) {
            _writePartialOffset(fileId, received);
          }

          // Speed calculation
          final now = DateTime.now();
          final elapsed =
              now.difference(lastTime).inMilliseconds;
          if (elapsed >= 500) {
            final bytesPerMs =
                (received - lastReceived) / elapsed;
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
        },
        onDone: () async {
          try {
            await sink.flush();
            await sink.close();
          } catch (_) {}
          _activeSinks.remove(fileId);
          client.close();
          _activeClients.remove(fileId);
          _activeSubs.remove(fileId);
          await _clearPartialOffset(fileId);

          _downloaded.add(fileId);
          await _saveDownloaded();
          _completeCleanup(fileId);
          notifyListeners();

          // ── Trigger cover extraction if PDF ──
          if (fileId.startsWith('pdf_') &&
              onPdfDownloadComplete != null) {
            final pdfPath = (await _fileFor(fileId)).path;
            final extractBookId =
                bookId ?? fileId.replaceFirst('pdf_', '');
            onPdfDownloadComplete!(extractBookId, pdfPath)
                .catchError((_) {});
          }

          onComplete();
          completer.complete();
        },
        onError: (err) async {
          // Network drop or read error.
          // KEEP the partial file so next download call resumes.
          try {
            await sink.flush();
            await sink.close();
          } catch (_) {}
          _activeSinks.remove(fileId);
          client.close();
          _activeClients.remove(fileId);
          _activeSubs.remove(fileId);
          // Save final offset for resume.
          try {
            final f = await _fileFor(fileId);
            if (await f.exists()) {
              await _writePartialOffset(
                  fileId, await f.length());
            }
          } catch (_) {}
          _failDownload(fileId);
          onError(
              'Network interrupted. Tap download again to resume.');
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: true,
      );

      _activeSubs[fileId] = sub;
      await completer.future;
    } catch (e) {
      _activeClients[fileId]?.close();
      _activeClients.remove(fileId);
      try {
        await _activeSinks[fileId]?.close();
      } catch (_) {}
      _activeSinks.remove(fileId);
      _activeSubs.remove(fileId);
      // Save resume offset if we have a partial file.
      try {
        final f = await _fileFor(fileId);
        if (await f.exists()) {
          await _writePartialOffset(
              fileId, await f.length());
        }
      } catch (_) {}
      _failDownload(fileId);
      onError(
          'Download failed. Check your internet and try again.');
    }
  }

  // ─── Cancel ────────────────────────────────────────

  /// Actually stops the download. Kills the HTTP stream,
  /// closes the sink, deletes the partial file, and clears
  /// the resume offset.
  Future<void> cancelDownload(String fileId) async {
    if (_downloading[fileId] != true) return;

    // Cancel the stream subscription first — this stops
    // new data from arriving.
    final sub = _activeSubs.remove(fileId);
    try {
      await sub?.cancel();
    } catch (_) {}

    // Close the HTTP client to release the socket.
    _activeClients.remove(fileId)?.close();

    // Close and flush the sink.
    try {
      final sink = _activeSinks.remove(fileId);
      await sink?.close();
    } catch (_) {}

    // Delete the partial file — cancel means "start over".
    try {
      final file = await _fileFor(fileId);
      if (await file.exists()) await file.delete();
    } catch (_) {}
    await _clearPartialOffset(fileId);

    _cancelCleanup(fileId);
  }

  void _cancelCleanup(String fileId) {
    _downloading[fileId] = false;
    _paused[fileId] = false;
    _progress.remove(fileId);
    _activeDownloads.remove(fileId);
    notifyListeners();
  }

  void _completeCleanup(String fileId) {
    _downloading[fileId] = false;
    _paused[fileId] = false;
    _activeDownloads.remove(fileId);
  }

  void _failDownload(String fileId) {
    _downloading[fileId] = false;
    _paused[fileId] = false;
    _progress.remove(fileId);
    _activeDownloads.remove(fileId);
    notifyListeners();
  }

  // ─── Pause / Resume ────────────────────────────────

  void pauseDownload(String fileId) {
    if (_downloading[fileId] != true) return;
    _paused[fileId] = true;
    if (_activeDownloads.containsKey(fileId)) {
      _activeDownloads[fileId]!['paused'] = true;
    }
    notifyListeners();
  }

  void resumeDownload(String fileId) {
    if (_downloading[fileId] != true) return;
    _paused[fileId] = false;
    if (_activeDownloads.containsKey(fileId)) {
      _activeDownloads[fileId]!['paused'] = false;
    }
    notifyListeners();
  }

  // ─── Delete ────────────────────────────────────────

  Future<void> deleteFile(String fileId) async {
    if (_downloading[fileId] == true) {
      await cancelDownload(fileId);
    }

    try {
      final file = await _fileFor(fileId);
      if (await file.exists()) await file.delete();
    } catch (_) {}
    await _clearPartialOffset(fileId);

    _downloaded.remove(fileId);
    _progress.remove(fileId);
    _downloading.remove(fileId);
    _paused.remove(fileId);
    await _saveDownloaded();
    notifyListeners();
  }

  Future<void> deleteAll() async {
    for (final id in _downloading.keys.toList()) {
      if (_downloading[id] == true) {
        await cancelDownload(id);
      }
    }

    final dir = await _downloadsDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create();
    }

    // Clear all partial offsets.
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
        (k) => k.startsWith(_partialPrefix));
    for (final k in keys) {
      await prefs.remove(k);
    }

    _downloaded.clear();
    _progress.clear();
    _downloading.clear();
    _paused.clear();
    _activeDownloads.clear();
    await _saveDownloaded();
    notifyListeners();
  }

  // ─── Open ──────────────────────────────────────────

  Future<String?> localPath(String fileId) async {
    if (!_downloaded.contains(fileId)) return null;
    final file = await _fileFor(fileId);
    if (await file.exists()) return file.path;
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
      if (entity is File) total += await entity.length();
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

  // ─── Partial offset persistence ────────────────────

  Future<int> _readPartialOffset(String fileId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_partialPrefix$fileId') ?? 0;
  }

  Future<void> _writePartialOffset(
      String fileId, int bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_partialPrefix$fileId', bytes);
  }

  Future<void> _clearPartialOffset(String fileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_partialPrefix$fileId');
  }

  // ─── Helpers ───────────────────────────────────────

  Future<Directory> _downloadsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/rawdah_downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _fileFor(String fileId) async {
    final dir = await _downloadsDir();
    final ext =
        fileId.startsWith('pdf_') ? '.pdf' : '.mp3';
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

  static String surahReciterAudioId(
          int surahNumber, String reciterId, int part) =>
      'saudio_r_${surahNumber}_${reciterId}_$part';

  static String surahTeacherAudioId(
          int surahNumber, String teacherId, int part) =>
      'saudio_t_${surahNumber}_${teacherId}_$part';

  static String formatSpeed(double kbps) {
    if (kbps >= 1024) {
      return '${(kbps / 1024).toStringAsFixed(1)} MB/s';
    }
    return '${kbps.toStringAsFixed(0)} KB/s';
  }
}
