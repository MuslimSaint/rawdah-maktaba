import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles all file downloads — PDFs, audio files,
/// and teacher/reciter photos.
///
/// Features:
///   - Max 2 concurrent user downloads (queue system)
///   - Silent downloads (photos, TOCs) bypass the queue
///   - Pausing an active download frees a slot for queued items
///   - Real-time speed and MB tracking
class DownloadService extends ChangeNotifier {
  static const int maxConcurrentDownloads = 2;

  final Map<String, double> _progress = {};
  final Map<String, bool> _downloading = {};
  final Set<String> _downloaded = {};
  final Map<String, bool> _paused = {};
  final Map<String, bool> _awaitingNetwork = {};
  final Map<String, _RetryParams> _retryParams = {};
  final Map<String, Timer> _retryTimers = {};
  final Map<String, Map<String, dynamic>> _activeDownloads = {};
  final Map<String, StreamSubscription<List<int>>> _activeSubs = {};
  final Map<String, IOSink> _activeSinks = {};
  final Map<String, http.Client> _activeClients = {};

  /// Queue for user downloads waiting to start
  final List<String> _downloadQueue = [];

  final Set<String> _downloadedPhotos = {};
  final Set<String> _downloadingPhotos = {};

  static const _downloadedKey = 'downloaded_files';
  static const _downloadedPhotosKey = 'downloaded_photos';
  static const _partialPrefix = 'partial_bytes_';

  Future<void> Function(String bookId, String pdfPath)? onPdfDownloadComplete;
  Future<void> Function(String bookId)? onPdfFileDeleted;
  Future<void> Function(String personId, String photoPath)? onPhotoDownloaded;
  Future<void> Function(String fileId)? onPdfDownloadStarted;

  // ─── Init ──────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_downloadedKey) ?? [];
    _downloaded.addAll(saved);

    final savedPhotos = prefs.getStringList(_downloadedPhotosKey) ?? [];
    _downloadedPhotos.addAll(savedPhotos);

    final toRemove = <String>[];
    for (final id in _downloaded) {
      final file = await _fileFor(id);
      if (!await file.exists()) toRemove.add(id);
    }
    if (toRemove.isNotEmpty) {
      _downloaded.removeAll(toRemove);
      await _saveDownloaded();
      notifyListeners();
    }

    final photosToRemove = <String>[];
    for (final id in _downloadedPhotos) {
      final file = await _photoFileFor(id);
      if (!await file.exists()) photosToRemove.add(id);
    }
    if (photosToRemove.isNotEmpty) {
      _downloadedPhotos.removeAll(photosToRemove);
      await _saveDownloadedPhotos();
    }
  }

  // ─── Photo getters ─────────────────────────────────

  bool hasPhoto(String personId) =>
      _downloadedPhotos.contains(personId);

  String photoLocalPath(String personId, String appDocsPath) =>
      '$appDocsPath/teacher_photos/$personId.jpg';

  Future<String?> photoPath(String personId) async {
    if (!_downloadedPhotos.contains(personId)) return null;
    final file = await _photoFileFor(personId);
    if (await file.exists()) return file.path;
    _downloadedPhotos.remove(personId);
    await _saveDownloadedPhotos();
    return null;
  }

  // ─── Photo download (Silent — Bypasses Queue) ────────

  Future<void> downloadPhoto({
    required String personId,
    required String photoUrl,
  }) async {
    if (personId.isEmpty || photoUrl.isEmpty) return;
    if (_downloadedPhotos.contains(personId) ||
        _downloadingPhotos.contains(personId)) return;

    final uri = Uri.tryParse(photoUrl.trim());
    if (uri == null || uri.scheme != 'https') return;

    _downloadingPhotos.add(personId);

    try {
      final client = http.Client();
      final response =
          await client.get(uri).timeout(const Duration(seconds: 20));
      client.close();

      if (response.statusCode != 200) {
        _downloadingPhotos.remove(personId);
        return;
      }

      final contentType =
          (response.headers['content-type'] ?? '').toLowerCase();
      final isImage = contentType.startsWith('image/') ||
          contentType.contains('octet-stream') ||
          photoUrl.toLowerCase().endsWith('.jpg') ||
          photoUrl.toLowerCase().endsWith('.png');

      if (!isImage) {
        _downloadingPhotos.remove(personId);
        return;
      }

      final file = await _photoFileFor(personId);
      await file.writeAsBytes(response.bodyBytes);

      _downloadedPhotos.add(personId);
      _downloadingPhotos.remove(personId);
      await _saveDownloadedPhotos();

      if (onPhotoDownloaded != null) {
        onPhotoDownloaded!(personId, file.path).catchError((_) {});
      }

      notifyListeners();
    } catch (e) {
      _downloadingPhotos.remove(personId);
    }
  }

  Future<void> deletePhoto(String personId) async {
    try {
      final file = await _photoFileFor(personId);
      if (await file.exists()) await file.delete();
    } catch (_) {}
    _downloadedPhotos.remove(personId);
    await _saveDownloadedPhotos();
    notifyListeners();
  }

  // ─── Getters ───────────────────────────────────────

  bool isDownloaded(String fileId) => _downloaded.contains(fileId);
  bool isDownloading(String fileId) => _downloading[fileId] == true;
  bool isQueued(String fileId) =>
      _activeDownloads[fileId]?['status'] == 'queued';
  bool isPaused(String fileId) => _paused[fileId] == true;
  bool isAwaitingNetwork(String fileId) => _awaitingNetwork[fileId] == true;
  double progress(String fileId) => _progress[fileId] ?? 0;
  int get downloadedCount => _downloaded.length;
  bool get hasActiveDownloads => _activeDownloads.isNotEmpty;
  List<Map<String, dynamic>> get activeDownloads =>
      List<Map<String, dynamic>>.from(_activeDownloads.values);

  /// Number of user downloads currently actively streaming
  int get _activeUserDownloadCount {
    return _activeDownloads.values.where((d) {
      final status = d['status'] as String? ?? '';
      return status == 'downloading';
    }).length;
  }

  // ─── User Download Entry Point ──────────────────────

  Future<void> download({
    required String fileId,
    required String url,
    required Function(String error) onError,
    required VoidCallback onComplete,
    String? displayName,
    String? bookId,
    String? personId,
    String? personPhotoUrl,
  }) async {
    if (_activeDownloads.containsKey(fileId)) return;
    if (_downloaded.contains(fileId)) {
      onComplete();
      return;
    }

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
    _awaitingNetwork[fileId] = false;
    _progress[fileId] = 0;

    _retryParams[fileId] = _RetryParams(
      fileId: fileId,
      uri: uri,
      bookId: bookId,
      onError: onError,
      onComplete: onComplete,
    );

    // Pre-fetch related metadata (photos, TOC)
    if (fileId.startsWith('pdf_') && onPdfDownloadStarted != null) {
      onPdfDownloadStarted!(fileId).catchError((_) {});
    }

    if (personId != null &&
        personId.isNotEmpty &&
        personPhotoUrl != null &&
        personPhotoUrl.isNotEmpty) {
      downloadPhoto(personId: personId, photoUrl: personPhotoUrl);
    }

    // Check concurrency slot
    if (_activeUserDownloadCount < maxConcurrentDownloads) {
      // Start immediately
      _downloading[fileId] = true;
      _activeDownloads[fileId] = {
        'fileId': fileId,
        'displayName': displayName ?? fileId,
        'bookId': bookId ?? '',
        'progress': 0.0,
        'speedKbps': 0.0,
        'paused': false,
        'awaitingNetwork': false,
        'status': 'downloading',
        'startedAt': DateTime.now(),
        'downloadedMb': 0.0,
        'totalMb': null,
      };
      notifyListeners();

      await _executeDownload(
        fileId: fileId,
        uri: uri,
        bookId: bookId,
        onError: onError,
        onComplete: onComplete,
      );
    } else {
      // Add to queue
      _downloading[fileId] = false;
      _downloadQueue.add(fileId);
      _activeDownloads[fileId] = {
        'fileId': fileId,
        'displayName': displayName ?? fileId,
        'bookId': bookId ?? '',
        'progress': 0.0,
        'speedKbps': 0.0,
        'paused': false,
        'awaitingNetwork': false,
        'status': 'queued',
        'startedAt': DateTime.now(),
        'downloadedMb': 0.0,
        'totalMb': null,
      };
      notifyListeners();
    }
  }

  // ─── Queue Processor ────────────────────────────────

  void _processQueue() {
    while (_activeUserDownloadCount < maxConcurrentDownloads &&
        _downloadQueue.isNotEmpty) {
      final nextId = _downloadQueue.removeAt(0);
      final params = _retryParams[nextId];
      if (params != null && _activeDownloads.containsKey(nextId)) {
        _downloading[nextId] = true;
        _activeDownloads[nextId]!['status'] = 'downloading';
        notifyListeners();

        _executeDownload(
          fileId: nextId,
          uri: params.uri,
          bookId: params.bookId,
          onError: params.onError,
          onComplete: params.onComplete,
        );
      }
    }
  }

  // ─── Execute Stream Download ────────────────────────

  Future<void> _executeDownload({
    required String fileId,
    required Uri uri,
    required String? bookId,
    required Function(String error) onError,
    required VoidCallback onComplete,
  }) async {
    final file = await _fileFor(fileId);
    int startByte = 0;
    if (await file.exists()) startByte = await file.length();
    final savedOffset = await _readPartialOffset(fileId);
    if (savedOffset > 0 && savedOffset == startByte) {
      // Valid resume position
    } else {
      startByte = 0;
      if (await file.exists()) {
        try { await file.delete(); } catch (_) {}
      }
    }

    final client = http.Client();
    _activeClients[fileId] = client;

    try {
      final request = http.Request('GET', uri);
      if (startByte > 0) {
        request.headers['Range'] = 'bytes=$startByte-';
      }
      request.followRedirects = true;
      request.maxRedirects = 5;

      final response = await client.send(request);

      if (response.statusCode != 200 && response.statusCode != 206) {
        if (startByte > 0 && response.statusCode == 416) {
          client.close();
          _activeClients.remove(fileId);
          if (await file.exists()) await file.delete();
          await _clearPartialOffset(fileId);
          return _executeDownload(
            fileId: fileId, uri: uri, bookId: bookId,
            onError: onError, onComplete: onComplete,
          );
        }
        client.close();
        _activeClients.remove(fileId);
        _failDownload(fileId);
        onError('Server error: ${response.statusCode}');
        return;
      }

      final contentType =
          (response.headers['content-type'] ?? '').toLowerCase();
      if (contentType.contains('text/html') ||
          contentType.contains('application/json')) {
        client.close();
        _activeClients.remove(fileId);
        _failDownload(fileId);
        onError('This URL does not point to a downloadable file.');
        return;
      }

      final sink = response.statusCode == 206
          ? file.openWrite(mode: FileMode.append)
          : file.openWrite();
      _activeSinks[fileId] = sink;

      final contentLength = response.contentLength ?? 0;
      final total = response.statusCode == 206
          ? startByte + contentLength
          : contentLength;

      if (total > 0 && _activeDownloads.containsKey(fileId)) {
        _activeDownloads[fileId]!['totalMb'] = total / (1024 * 1024);
      }

      var received = startByte;
      var lastTime = DateTime.now();
      var lastReceived = received;

      _awaitingNetwork[fileId] = false;
      if (_activeDownloads.containsKey(fileId)) {
        _activeDownloads[fileId]!['awaitingNetwork'] = false;
        _activeDownloads[fileId]!['status'] = 'downloading';
      }
      notifyListeners();

      final completer = Completer<void>();

      final sub = response.stream.listen(
        (chunk) async {
          while (_paused[fileId] == true) {
            await Future.delayed(const Duration(milliseconds: 200));
            if (_downloading[fileId] != true) return;
          }

          try { sink.add(chunk); } catch (_) { return; }
          received += chunk.length;

          if (received % (256 * 1024) < chunk.length) {
            _writePartialOffset(fileId, received);
          }

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

          if (_activeDownloads.containsKey(fileId)) {
            _activeDownloads[fileId]!['downloadedMb'] =
                received / (1024 * 1024);
          }

          if (total > 0) {
            _progress[fileId] = received / total;
            if (_activeDownloads.containsKey(fileId)) {
              _activeDownloads[fileId]!['progress'] = _progress[fileId];
            }
          }
          notifyListeners();
        },
        onDone: () async {
          try { await sink.flush(); await sink.close(); } catch (_) {}
          _activeSinks.remove(fileId);
          client.close();
          _activeClients.remove(fileId);
          _activeSubs.remove(fileId);
          await _clearPartialOffset(fileId);

          if (total > 0 && received < total) {
            await _writePartialOffset(fileId, received);
            _failDownload(fileId);
            onError('Download incomplete. Tap download again to resume.');
            if (!completer.isCompleted) completer.complete();
            return;
          }

          _downloaded.add(fileId);
          await _saveDownloaded();
          _retryParams.remove(fileId);
          _completeCleanup(fileId);

          if (fileId.startsWith('pdf_') && onPdfDownloadComplete != null) {
            final pdfPath = (await _fileFor(fileId)).path;
            final extractBookId = bookId ?? fileId.replaceFirst('pdf_', '');
            onPdfDownloadComplete!(extractBookId, pdfPath).catchError((_) {});
          }

          onComplete();
          if (!completer.isCompleted) completer.complete();
        },
        onError: (err) async {
          try { await sink.flush(); await sink.close(); } catch (_) {}
          _activeSinks.remove(fileId);
          client.close();
          _activeClients.remove(fileId);
          _activeSubs.remove(fileId);

          try {
            final f = await _fileFor(fileId);
            if (await f.exists()) {
              await _writePartialOffset(fileId, await f.length());
            }
          } catch (_) {}

          _awaitingNetwork[fileId] = true;
          if (_activeDownloads.containsKey(fileId)) {
            _activeDownloads[fileId]!['awaitingNetwork'] = true;
            _activeDownloads[fileId]!['status'] = 'awaitingNetwork';
            _activeDownloads[fileId]!['speedKbps'] = 0.0;
          }
          notifyListeners();
          _scheduleRetry(fileId);
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: true,
      );

      _activeSubs[fileId] = sub;
      await completer.future;
    } catch (e) {
      _activeClients[fileId]?.close();
      _activeClients.remove(fileId);
      try { await _activeSinks[fileId]?.close(); } catch (_) {}
      _activeSinks.remove(fileId);
      _activeSubs.remove(fileId);

      try {
        final f = await _fileFor(fileId);
        if (await f.exists()) {
          await _writePartialOffset(fileId, await f.length());
        }
      } catch (_) {}

      if (_downloading[fileId] == true) {
        _awaitingNetwork[fileId] = true;
        if (_activeDownloads.containsKey(fileId)) {
          _activeDownloads[fileId]!['awaitingNetwork'] = true;
          _activeDownloads[fileId]!['status'] = 'awaitingNetwork';
          _activeDownloads[fileId]!['speedKbps'] = 0.0;
        }
        notifyListeners();
        _scheduleRetry(fileId);
      } else {
        _failDownload(fileId);
        onError('Download failed. Check your internet.');
      }
    }
  }

  // ─── Auto-retry ────────────────────────────────────

  void _scheduleRetry(String fileId) {
    _retryTimers[fileId]?.cancel();
    _retryTimers[fileId] = Timer(
        const Duration(seconds: 3), () => _attemptRetry(fileId));
  }

  Future<void> _attemptRetry(String fileId) async {
    _retryTimers.remove(fileId);
    if (_downloading[fileId] != true ||
        _awaitingNetwork[fileId] != true) return;
    final params = _retryParams[fileId];
    if (params == null) return;

    _awaitingNetwork[fileId] = false;
    if (_activeDownloads.containsKey(fileId)) {
      _activeDownloads[fileId]!['awaitingNetwork'] = false;
      _activeDownloads[fileId]!['status'] = 'downloading';
    }
    notifyListeners();

    await _executeDownload(
      fileId: fileId,
      uri: params.uri,
      bookId: params.bookId,
      onError: params.onError,
      onComplete: params.onComplete,
    );
  }

  // ─── Cancel ────────────────────────────────────────

  Future<void> cancelDownload(String fileId) async {
    _retryTimers[fileId]?.cancel();
    _retryTimers.remove(fileId);
    _retryParams.remove(fileId);
    _downloadQueue.remove(fileId);

    if (_downloading[fileId] == true || _awaitingNetwork[fileId] == true) {
      final sub = _activeSubs.remove(fileId);
      try { await sub?.cancel(); } catch (_) {}
      _activeClients.remove(fileId)?.close();
      try { await _activeSinks.remove(fileId)?.close(); } catch (_) {}
      try {
        final file = await _fileFor(fileId);
        if (await file.exists()) await file.delete();
      } catch (_) {}
      await _clearPartialOffset(fileId);
    }

    _cancelCleanup(fileId);
    _processQueue();
  }

  void _cancelCleanup(String fileId) {
    _downloading[fileId] = false;
    _paused[fileId] = false;
    _awaitingNetwork[fileId] = false;
    _progress.remove(fileId);
    _activeDownloads.remove(fileId);
    notifyListeners();
  }

  void _completeCleanup(String fileId) {
    _downloading[fileId] = false;
    _paused[fileId] = false;
    _awaitingNetwork[fileId] = false;
    _retryTimers[fileId]?.cancel();
    _retryTimers.remove(fileId);
    _activeDownloads.remove(fileId);
    _processQueue();
  }

  void _failDownload(String fileId) {
    _downloading[fileId] = false;
    _paused[fileId] = false;
    _awaitingNetwork[fileId] = false;
    _retryTimers[fileId]?.cancel();
    _retryTimers.remove(fileId);
    _progress.remove(fileId);
    _activeDownloads.remove(fileId);
    _processQueue();
    notifyListeners();
  }

  // ─── Pause / Resume ────────────────────────────────

  void pauseDownload(String fileId) {
    if (_activeDownloads[fileId] == null) return;
    _paused[fileId] = true;
    _downloading[fileId] = false;
    if (_activeDownloads.containsKey(fileId)) {
      _activeDownloads[fileId]!['paused'] = true;
      _activeDownloads[fileId]!['status'] = 'paused';
    }
    notifyListeners();
    _processQueue(); // Freed a slot!
  }

  void resumeDownload(String fileId) {
    final task = _activeDownloads[fileId];
    if (task == null) return;

    _paused[fileId] = false;
    if (_activeDownloads.containsKey(fileId)) {
      _activeDownloads[fileId]!['paused'] = false;
    }

    if (_activeUserDownloadCount < maxConcurrentDownloads) {
      _downloading[fileId] = true;
      _activeDownloads[fileId]!['status'] = 'downloading';
      notifyListeners();

      final params = _retryParams[fileId];
      if (params != null) {
        _executeDownload(
          fileId: fileId,
          uri: params.uri,
          bookId: params.bookId,
          onError: params.onError,
          onComplete: params.onComplete,
        );
      }
    } else {
      // Put back into queue
      _activeDownloads[fileId]!['status'] = 'queued';
      if (!_downloadQueue.contains(fileId)) {
        _downloadQueue.add(fileId);
      }
      notifyListeners();
    }
  }

  // ─── Delete ────────────────────────────────────────

  Future<void> deleteFile(String fileId) async {
    if (_downloading[fileId] == true ||
        _awaitingNetwork[fileId] == true ||
        _activeDownloads.containsKey(fileId)) {
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
    _awaitingNetwork.remove(fileId);
    await _saveDownloaded();
    if (fileId.startsWith('pdf_') && onPdfFileDeleted != null) {
      onPdfFileDeleted!(fileId.replaceFirst('pdf_', '')).catchError((_) {});
    }
    notifyListeners();
  }

  Future<void> deleteAll() async {
    final activeIds = List<String>.from(_activeDownloads.keys);
    for (final id in activeIds) await cancelDownload(id);

    final dir = await _downloadsDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create();
    }

    final prefs = await SharedPreferences.getInstance();
    final keys =
        prefs.getKeys().where((k) => k.startsWith(_partialPrefix));
    for (final k in keys) await prefs.remove(k);

    _downloaded.clear();
    _progress.clear();
    _downloading.clear();
    _paused.clear();
    _awaitingNetwork.clear();
    _activeDownloads.clear();
    _downloadQueue.clear();
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

  // ─── Partial offset ────────────────────────────────

  Future<int> _readPartialOffset(String fileId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_partialPrefix$fileId') ?? 0;
  }

  Future<void> _writePartialOffset(String fileId, int bytes) async {
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
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _photosDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/teacher_photos');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _fileFor(String fileId) async {
    final dir = await _downloadsDir();
    final ext = fileId.startsWith('pdf_') ? '.pdf' : '.mp3';
    return File('${dir.path}/$fileId$ext');
  }

  Future<File> _photoFileFor(String personId) async {
    final dir = await _photosDir();
    return File('${dir.path}/$personId.jpg');
  }

  Future<void> _saveDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_downloadedKey, _downloaded.toList());
  }

  Future<void> _saveDownloadedPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _downloadedPhotosKey, _downloadedPhotos.toList());
  }

  // ─── ID Helpers ────────────────────────────────────

  static String pdfId(String bookId) => 'pdf_$bookId';
  static String audioId(String b, String t, int p) =>
      'audio_${b}_${t}_$p';
  static String surahReciterAudioId(int n, String r, int p) =>
      'saudio_r_${n}_${r}_$p';
  static String surahTeacherAudioId(int n, String t, int p) =>
      'saudio_t_${n}_${t}_$p';

  static String formatSpeed(double kbps) {
    if (kbps >= 1024) {
      return '${(kbps / 1024).toStringAsFixed(1)} MB/s';
    }
    return '${kbps.toStringAsFixed(0)} KB/s';
  }

  static String formatMb(double mb) {
    if (mb < 1) {
      return '${(mb * 1024).toStringAsFixed(0)} KB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class _RetryParams {
  final String fileId;
  final Uri uri;
  final String? bookId;
  final Function(String error) onError;
  final VoidCallback onComplete;

  const _RetryParams({
    required this.fileId,
    required this.uri,
    this.bookId,
    required this.onError,
    required this.onComplete,
  });
}
