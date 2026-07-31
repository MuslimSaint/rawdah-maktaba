import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles all file downloads — PDFs, audio files,
/// and teacher/reciter photos.
class DownloadService extends ChangeNotifier {
  final Map<String, double> _progress = {};
  final Map<String, bool> _downloading = {};
  final Set<String> _downloaded = {};
  final Map<String, bool> _paused = {};
  final Map<String, bool> _awaitingNetwork = {};
  final Map<String, _RetryParams> _retryParams = {};
  final Map<String, Timer> _retryTimers = {};
  final Map<String, Map<String, dynamic>>
      _activeDownloads = {};
  final Map<String, StreamSubscription<List<int>>>
      _activeSubs = {};
  final Map<String, IOSink> _activeSinks = {};
  final Map<String, http.Client>> _activeClients = {};

  // ── Photo state ──────────────────────────────────
  // Tracks which teacher/reciter photos have been
  // downloaded. Keyed by person ID (teacher or reciter).
  final Set<String> _downloadedPhotos = {};
  final Set<String> _downloadingPhotos = {};

  static const _downloadedKey = 'downloaded_files';
  static const _downloadedPhotosKey =
      'downloaded_photos';
  static const _partialPrefix = 'partial_bytes_';

  // ─── Callbacks ─────────────────────────────────────
  Future<void> Function(String bookId, String pdfPath)?
      onPdfDownloadComplete;
  Future<void> Function(String bookId)? onPdfFileDeleted;

  /// Called when a teacher/reciter photo is downloaded.
  /// Arg is the person ID (teacher or reciter id).
  Future<void> Function(String personId, String photoPath)?
      onPhotoDownloaded;

  // ─── Init ──────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved =
        prefs.getStringList(_downloadedKey) ?? [];
    _downloaded.addAll(saved);

    final savedPhotos =
        prefs.getStringList(_downloadedPhotosKey) ?? [];
    _downloadedPhotos.addAll(savedPhotos);

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

    // Verify photo files still exist on disk
    final photosToRemove = <String>[];
    for (final id in _downloadedPhotos) {
      final file = await _photoFileFor(id);
      if (!await file.exists()) {
        photosToRemove.add(id);
      }
    }
    if (photosToRemove.isNotEmpty) {
      _downloadedPhotos.removeAll(photosToRemove);
      await _saveDownloadedPhotos();
    }
  }

  // ─── Photo getters ─────────────────────────────────

  bool hasPhoto(String personId) =>
      _downloadedPhotos.contains(personId);

  Future<String?> photoPath(String personId) async {
    if (!_downloadedPhotos.contains(personId)) {
      return null;
    }
    final file = await _photoFileFor(personId);
    if (await file.exists()) return file.path;
    _downloadedPhotos.remove(personId);
    await _saveDownloadedPhotos();
    return null;
  }

  // ─── Photo download (background, silent) ───────────

  /// Downloads a teacher or reciter photo in the
  /// background. Silent — no progress tracking, no
  /// UI entry. Skips if already downloaded.
  /// Called automatically when audio download starts.
  Future<void> downloadPhoto({
    required String personId,
    required String photoUrl,
  }) async {
    if (personId.isEmpty) return;
    if (photoUrl.isEmpty) return;
    if (_downloadedPhotos.contains(personId)) return;
    if (_downloadingPhotos.contains(personId)) return;

    final uri = Uri.tryParse(photoUrl.trim());
    if (uri == null || uri.scheme != 'https') return;

    _downloadingPhotos.add(personId);

    try {
      final client = http.Client();
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 20));
      client.close();

      if (response.statusCode != 200) {
        _downloadingPhotos.remove(personId);
        return;
      }

      final contentType =
          (response.headers['content-type'] ?? '')
              .toLowerCase();
      // Accept any image content type
      if (!contentType.startsWith('image/') &&
          !contentType.contains('jpeg') &&
          !contentType.contains('jpg') &&
          !contentType.contains('png') &&
          !contentType.contains('webp')) {
        _downloadingPhotos.remove(personId);
        return;
      }

      final file = await _photoFileFor(personId);
      await file.writeAsBytes(response.bodyBytes);

      _downloadedPhotos.add(personId);
      _downloadingPhotos.remove(personId);
      await _saveDownloadedPhotos();

      if (onPhotoDownloaded != null) {
        onPhotoDownloaded!(personId, file.path)
            .catchError((_) {});
      }

      notifyListeners();
      debugPrint(
          'Photo downloaded for $personId → ${file.path}');
    } catch (e) {
      _downloadingPhotos.remove(personId);
      debugPrint(
          'Photo download failed for $personId: $e');
    }
  }

  /// Deletes the photo for a person. Called when
  /// all their audio is deleted (optional — photos
  /// are small so we keep them by default).
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

  bool isDownloaded(String fileId) =>
      _downloaded.contains(fileId);
  bool isDownloading(String fileId) =>
      _downloading[fileId] == true;
  bool isPaused(String fileId) =>
      _paused[fileId] == true;
  bool isAwaitingNetwork(String fileId) =>
      _awaitingNetwork[fileId] == true;
  double progress(String fileId) =>
      _progress[fileId] ?? 0;
  int get downloadedCount => _downloaded.length;
  bool get hasActiveDownloads =>
      _activeDownloads.isNotEmpty;
  List<Map<String, dynamic>> get activeDownloads =>
      _activeDownloads.values.toList();

  // ─── Download (public entry point) ─────────────────

  Future<void> download({
    required String fileId,
    required String url,
    required Function(String error) onError,
    required VoidCallback onComplete,
    String? displayName,
    String? bookId,
    // Photo download params — optional.
    // When provided, the photo is downloaded in
    // background as soon as this audio download starts.
    String? personId,
    String? personPhotoUrl,
  }) async {
    if (_downloading[fileId] == true) return;
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
      onError(
          'Only secure (https://) URLs are allowed.');
      return;
    }

    _paused[fileId] = false;
    _awaitingNetwork[fileId] = false;
    _downloading[fileId] = true;
    _progress[fileId] = 0;

    _activeDownloads[fileId] = {
      'fileId': fileId,
      'displayName': displayName ?? fileId,
      'bookId': bookId ?? '',
      'progress': 0.0,
      'speedKbps': 0.0,
      'paused': false,
      'awaitingNetwork': false,
      'startedAt': DateTime.now(),
    };

    _retryParams[fileId] = _RetryParams(
      fileId: fileId,
      uri: uri,
      bookId: bookId,
      onError: onError,
      onComplete: onComplete,
    );

    notifyListeners();

    // ── Trigger photo download immediately ──────────
    // Small, background, silent. Does not block audio.
    if (personId != null &&
        personId.isNotEmpty &&
        personPhotoUrl != null &&
        personPhotoUrl.isNotEmpty) {
      downloadPhoto(
        personId: personId,
        photoUrl: personPhotoUrl,
      );
    }

    await _executeDownload(
      fileId: fileId,
      uri: uri,
      bookId: bookId,
      onError: onError,
      onComplete: onComplete,
    );
  }

  // ─── Execute (internal) ────────────────────────────

  Future<void> _executeDownload({
    required String fileId,
    required Uri uri,
    required String? bookId,
    required Function(String error) onError,
    required VoidCallback onComplete,
  }) async {
    final file = await _fileFor(fileId);
    int startByte = 0;
    if (await file.exists()) {
      startByte = await file.length();
    }
    final savedOffset =
        await _readPartialOffset(fileId);
    if (savedOffset > 0 &&
        savedOffset == startByte) {
      // Resume from saved offset.
    } else {
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
        request.headers['Range'] =
            'bytes=$startByte-';
      }
      request.followRedirects = true;
      request.maxRedirects = 5;

      final response = await client.send(request);

      if (response.statusCode != 200 &&
          response.statusCode != 206) {
        if (startByte > 0 &&
            response.statusCode == 416) {
          client.close();
          _activeClients.remove(fileId);
          if (await file.exists()) await file.delete();
          await _clearPartialOffset(fileId);
          return _executeDownload(
            fileId: fileId,
            uri: uri,
            bookId: bookId,
            onError: onError,
            onComplete: onComplete,
          );
        }
        client.close();
        _activeClients.remove(fileId);
        _failDownload(fileId);
        onError(
            'Server error: ${response.statusCode}');
        return;
      }

      final contentType =
          (response.headers['content-type'] ?? '')
              .toLowerCase();
      if (contentType.contains('text/html') ||
          contentType.contains('application/json')) {
        client.close();
        _activeClients.remove(fileId);
        _failDownload(fileId);
        onError(
            'This URL does not point to a downloadable '
            'file. Use a direct link.');
        return;
      }

      final sink = response.statusCode == 206
          ? file.openWrite(mode: FileMode.append)
          : file.openWrite();
      _activeSinks[fileId] = sink;

      final contentLength =
          response.contentLength ?? 0;
      final total = response.statusCode == 206
          ? startByte + contentLength
          : contentLength;

      var received = startByte;
      var lastTime = DateTime.now();
      var lastReceived = received;

      _awaitingNetwork[fileId] = false;
      if (_activeDownloads.containsKey(fileId)) {
        _activeDownloads[fileId]![
            'awaitingNetwork'] = false;
      }
      notifyListeners();

      final completer = Completer<void>();

      final sub = response.stream.listen(
        (chunk) async {
          while (_paused[fileId] == true) {
            await Future.delayed(
                const Duration(milliseconds: 200));
            if (_downloading[fileId] != true) return;
          }

          try {
            sink.add(chunk);
          } catch (_) {
            return;
          }
          received += chunk.length;

          if (received % (256 * 1024) < chunk.length) {
            _writePartialOffset(fileId, received);
          }

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
              _activeDownloads[fileId]![
                  'speedKbps'] = kbps;
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

          if (total > 0 && received < total) {
            debugPrint(
                'Download incomplete for $fileId: '
                'received $received of $total bytes.');
            await _writePartialOffset(
                fileId, received);
            _failDownload(fileId);
            onError(
                'Download incomplete. '
                'Tap download again to resume.');
            if (!completer.isCompleted) {
              completer.complete();
            }
            return;
          }

          _downloaded.add(fileId);
          await _saveDownloaded();
          _retryParams.remove(fileId);
          _completeCleanup(fileId);
          notifyListeners();

          if (fileId.startsWith('pdf_') &&
              onPdfDownloadComplete != null) {
            final pdfPath =
                (await _fileFor(fileId)).path;
            final extractBookId =
                bookId ?? fileId.replaceFirst('pdf_', '');
            onPdfDownloadComplete!(
                    extractBookId, pdfPath)
                .catchError((_) {});
          }

          onComplete();
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onError: (err) async {
          try {
            await sink.flush();
            await sink.close();
          } catch (_) {}
          _activeSinks.remove(fileId);
          client.close();
          _activeClients.remove(fileId);
          _activeSubs.remove(fileId);

          try {
            final f = await _fileFor(fileId);
            if (await f.exists()) {
              await _writePartialOffset(
                  fileId, await f.length());
            }
          } catch (_) {}

          _awaitingNetwork[fileId] = true;
          if (_activeDownloads.containsKey(fileId)) {
            _activeDownloads[fileId]![
                'awaitingNetwork'] = true;
            _activeDownloads[fileId]![
                'speedKbps'] = 0.0;
          }
          notifyListeners();
          _scheduleRetry(fileId);

          if (!completer.isCompleted) {
            completer.complete();
          }
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

      try {
        final f = await _fileFor(fileId);
        if (await f.exists()) {
          await _writePartialOffset(
              fileId, await f.length());
        }
      } catch (_) {}

      if (_downloading[fileId] == true) {
        _awaitingNetwork[fileId] = true;
        if (_activeDownloads.containsKey(fileId)) {
          _activeDownloads[fileId]![
              'awaitingNetwork'] = true;
          _activeDownloads[fileId]![
              'speedKbps'] = 0.0;
        }
        notifyListeners();
        _scheduleRetry(fileId);
      } else {
        _failDownload(fileId);
        onError('Download failed. '
            'Check your internet and try again.');
      }
    }
  }

  // ─── Auto-retry ────────────────────────────────────

  void _scheduleRetry(String fileId) {
    _retryTimers[fileId]?.cancel();
    _retryTimers[fileId] = Timer(
      const Duration(seconds: 3),
      () => _attemptRetry(fileId),
    );
  }

  Future<void> _attemptRetry(String fileId) async {
    _retryTimers.remove(fileId);
    if (_downloading[fileId] != true) return;
    if (_awaitingNetwork[fileId] != true) return;

    final params = _retryParams[fileId];
    if (params == null) return;

    _awaitingNetwork[fileId] = false;
    if (_activeDownloads.containsKey(fileId)) {
      _activeDownloads[fileId]![
          'awaitingNetwork'] = false;
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

    final isActive = _downloading[fileId] == true ||
        _awaitingNetwork[fileId] == true;
    if (!isActive) return;

    final sub = _activeSubs.remove(fileId);
    try {
      await sub?.cancel();
    } catch (_) {}

    _activeClients.remove(fileId)?.close();

    try {
      final sink = _activeSinks.remove(fileId);
      await sink?.close();
    } catch (_) {}

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
  }

  void _failDownload(String fileId) {
    _downloading[fileId] = false;
    _paused[fileId] = false;
    _awaitingNetwork[fileId] = false;
    _retryTimers[fileId]?.cancel();
    _retryTimers.remove(fileId);
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
    if (_downloading[fileId] == true ||
        _awaitingNetwork[fileId] == true) {
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

    if (fileId.startsWith('pdf_') &&
        onPdfFileDeleted != null) {
      final bookId =
          fileId.replaceFirst('pdf_', '');
      onPdfFileDeleted!(bookId).catchError((_) {});
    }

    notifyListeners();
  }

  Future<void> deleteAll() async {
    final activeIds = {
      ..._downloading.keys,
      ..._awaitingNetwork.keys,
    }.toList();
    for (final id in activeIds) {
      if (_downloading[id] == true ||
          _awaitingNetwork[id] == true) {
        await cancelDownload(id);
      }
    }

    final dir = await _downloadsDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create();
    }

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith(_partialPrefix));
    for (final k in keys) {
      await prefs.remove(k);
    }

    _downloaded.clear();
    _progress.clear();
    _downloading.clear();
    _paused.clear();
    _awaitingNetwork.clear();
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
    await for (final entity
        in dir.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total / (1024 * 1024);
  }

  Future<List<Map<String, dynamic>>>
      downloadedFiles() async {
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

  Future<int> _readPartialOffset(
      String fileId) async {
    final prefs =
        await SharedPreferences.getInstance();
    return prefs.getInt('$_partialPrefix$fileId') ?? 0;
  }

  Future<void> _writePartialOffset(
      String fileId, int bytes) async {
    final prefs =
        await SharedPreferences.getInstance();
    await prefs.setInt(
        '$_partialPrefix$fileId', bytes);
  }

  Future<void> _clearPartialOffset(
      String fileId) async {
    final prefs =
        await SharedPreferences.getInstance();
    await prefs.remove('$_partialPrefix$fileId');
  }

  // ─── Helpers ───────────────────────────────────────

  Future<Directory> _downloadsDir() async {
    final appDir =
        await getApplicationDocumentsDirectory();
    final dir = Directory(
        '${appDir.path}/rawdah_downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _photosDir() async {
    final appDir =
        await getApplicationDocumentsDirectory();
    final dir = Directory(
        '${appDir.path}/teacher_photos');
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

  Future<File> _photoFileFor(
      String personId) async {
    final dir = await _photosDir();
    return File('${dir.path}/$personId.jpg');
  }

  Future<void> _saveDownloaded() async {
    final prefs =
        await SharedPreferences.getInstance();
    await prefs.setStringList(
        _downloadedKey, _downloaded.toList());
  }

  Future<void> _saveDownloadedPhotos() async {
    final prefs =
        await SharedPreferences.getInstance();
    await prefs.setStringList(
        _downloadedPhotosKey,
        _downloadedPhotos.toList());
  }

  // ─── ID Helpers ────────────────────────────────────

  static String pdfId(String bookId) =>
      'pdf_$bookId';

  static String audioId(
          String bookId, String teacherId, int part) =>
      'audio_${bookId}_${teacherId}_$part';

  static String surahReciterAudioId(
          int surahNumber,
          String reciterId,
          int part) =>
      'saudio_r_${surahNumber}_${reciterId}_$part';

  static String surahTeacherAudioId(
          int surahNumber,
          String teacherId,
          int part) =>
      'saudio_t_${surahNumber}_${teacherId}_$part';

  static String formatSpeed(double kbps) {
    if (kbps >= 1024) {
      return '${(kbps / 1024).toStringAsFixed(1)} MB/s';
    }
    return '${kbps.toStringAsFixed(0)} KB/s';
  }
}

// ─── Internal retry params ─────────────────────────────

class _RetryParams {
  final String fileId;
  final Uri uri;
  final String? bookId;
  final Function(String error) onError;
  final VoidCallback onComplete;

  const _RetryParams({
    required this.fileId,
    required this.uri,
    required this.bookId,
    required this.onError,
    required this.onComplete,
  });
}
