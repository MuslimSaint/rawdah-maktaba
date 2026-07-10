import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// Handles all audio playback for the app.
/// Wraps just_audio with clean state management.
/// Integrates with just_audio_background for
/// notification controls, lock screen, headphones.
///
/// Prev/Next behavior:
///   - The service stores the full parts list of the
///     currently playing teacher.
///   - Prev/next (from UI or notification or headphones)
///     computes the neighbor part number, builds the
///     matching audio file path via a caller-supplied
///     resolver, and loads that file.
///   - This means notification controls "just work" without
///     the UI being open.
class AudioService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  // ─── State ─────────────────────────────────────────
  String? _currentFileId;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  bool _isLoading = false;
  String? _error;

  // Metadata for notification display + mini player
  String? _currentBookId;
  String? _currentTeacherId;
  int? _currentPartNumber;
  String? _currentTitle;
  String? _currentSubtitle;
  String? _currentArtPath;

  // Full parts list of the currently loaded audio.
  // Used by prev/next (both UI + notification).
  List<int> _currentAllParts = const [];

  // Optional resolver — given a target part number,
  // returns a Future of (filePath, title). The caller
  // sets this once when it starts playing. Prev/next
  // uses it to load the next/previous part.
  Future<AudioResolution?> Function(int partNumber)?
      _partResolver;

  // ─── Getters ───────────────────────────────────────
  String? get currentFileId => _currentFileId;
  String? get currentBookId => _currentBookId;
  String? get currentTeacherId => _currentTeacherId;
  int? get currentPartNumber => _currentPartNumber;
  String? get currentTitle => _currentTitle;
  String? get currentSubtitle => _currentSubtitle;
  String? get currentArtPath => _currentArtPath;
  List<int> get currentAllParts => _currentAllParts;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  double get speed => _speed;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasActiveAudio => _currentFileId != null;

  double get progress => _duration.inMilliseconds > 0
      ? _position.inMilliseconds / _duration.inMilliseconds
      : 0;

  bool get hasNextPart {
    if (_currentPartNumber == null) return false;
    final idx = _currentAllParts.indexOf(_currentPartNumber!);
    return idx >= 0 && idx < _currentAllParts.length - 1;
  }

  bool get hasPreviousPart {
    if (_currentPartNumber == null) return false;
    final idx = _currentAllParts.indexOf(_currentPartNumber!);
    return idx > 0;
  }

  // ─── Init ──────────────────────────────────────────

  AudioService() {
    _initListeners();
  }

  void _initListeners() {
    _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _player.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });

    _player.playingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    _player.playerStateStream.listen((state) {
      _isLoading =
          state.processingState == ProcessingState.loading ||
              state.processingState ==
                  ProcessingState.buffering;

      // Auto-advance to next part when this one finishes.
      // If there's no next part, stop naturally.
      if (state.processingState ==
          ProcessingState.completed) {
        _isPlaying = false;
        _position = Duration.zero;
        _player.seek(Duration.zero);
        _player.pause();

        if (hasNextPart) {
          // Small delay so the "completed" event settles
          Future.delayed(
            const Duration(milliseconds: 300),
            () {
              if (hasNextPart) skipToNext();
            },
          );
        }
      }
      notifyListeners();
    });
  }

  // ─── Playback ──────────────────────────────────────

  /// Load and play an audio file from local path.
  /// Provide the FULL parts list + a resolver so prev/next
  /// can be triggered from anywhere (notification, headphones,
  /// mini player, full player).
  Future<void> playFile({
    required String filePath,
    required String fileId,
    required String bookId,
    required String teacherId,
    required int partNumber,
    required String title,
    required String subtitle,
    required List<int> allParts,
    required Future<AudioResolution?> Function(int partNumber)
        partResolver,
    String? artUri,
  }) async {
    try {
      _error = null;

      // Update parts context and resolver on every call.
      // This keeps navigation accurate even if the caller
      // is switching teachers between plays.
      _currentAllParts = List<int>.from(allParts);
      _partResolver = partResolver;

      // Same file already loaded — just resume if paused
      if (_currentFileId == fileId) {
        // Refresh metadata even for same file, in case
        // the caller changed teacher/book context.
        _currentBookId = bookId;
        _currentTeacherId = teacherId;
        _currentPartNumber = partNumber;
        _currentTitle = title;
        _currentSubtitle = subtitle;
        _currentArtPath = artUri;
        if (!_isPlaying) {
          await _player.play();
        }
        return;
      }

      // New file — load fresh
      _isLoading = true;
      notifyListeners();

      _currentFileId = fileId;
      _currentBookId = bookId;
      _currentTeacherId = teacherId;
      _currentPartNumber = partNumber;
      _currentTitle = title;
      _currentSubtitle = subtitle;
      _currentArtPath = artUri;

      // Wrap file in MediaItem for background/notification support.
      // The MediaItem's `id` uniquely identifies this track
      // for the system media notification.
      final source = AudioSource.uri(
        Uri.file(filePath),
        tag: MediaItem(
          id: fileId,
          title: title,
          album: subtitle,
          artUri:
              artUri != null ? Uri.file(artUri) : null,
        ),
      );

      await _player.setAudioSource(source);
      await _player.setSpeed(_speed);
      await _player.play();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Could not play audio. Please try again.';
      notifyListeners();
    }
  }

  /// Called when the audio player screen re-opens for the
  /// SAME file that's already playing. Does not restart audio.
  void ensureNotDisturbed(String fileId) {
    return;
  }

  /// Explicitly toggle play/pause.
  Future<void> togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  /// Skip to next part in the current teacher's parts list.
  /// Called by: UI buttons, phone notification, headphones,
  /// bluetooth remote, auto-advance on completion.
  Future<void> skipToNext() async {
    if (!hasNextPart) return;
    if (_partResolver == null) return;

    final idx = _currentAllParts.indexOf(_currentPartNumber!);
    final nextPart = _currentAllParts[idx + 1];

    final resolved = await _partResolver!(nextPart);
    if (resolved == null) return;

    await _switchToResolved(resolved, nextPart);
  }

  /// Skip to previous part in the current teacher's parts list.
  Future<void> skipToPrevious() async {
    if (!hasPreviousPart) return;
    if (_partResolver == null) return;

    final idx = _currentAllParts.indexOf(_currentPartNumber!);
    final prevPart = _currentAllParts[idx - 1];

    final resolved = await _partResolver!(prevPart);
    if (resolved == null) return;

    await _switchToResolved(resolved, prevPart);
  }

  Future<void> _switchToResolved(
      AudioResolution r, int partNumber) async {
    try {
      _isLoading = true;
      _currentFileId = r.fileId;
      _currentPartNumber = partNumber;
      _currentTitle = r.title;
      _currentSubtitle = r.subtitle;
      _currentArtPath = r.artPath;
      notifyListeners();

      final source = AudioSource.uri(
        Uri.file(r.filePath),
        tag: MediaItem(
          id: r.fileId,
          title: r.title,
          album: r.subtitle,
          artUri: r.artPath != null
              ? Uri.file(r.artPath!)
              : null,
        ),
      );

      await _player.setAudioSource(source);
      await _player.setSpeed(_speed);
      await _player.play();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Could not switch part. Please try again.';
      notifyListeners();
    }
  }

  /// Seek backward by seconds.
  Future<void> seekBack(int seconds) async {
    final newPos = _position - Duration(seconds: seconds);
    await _player.seek(
      newPos < Duration.zero ? Duration.zero : newPos,
    );
  }

  /// Seek forward by seconds.
  Future<void> seekForward(int seconds) async {
    final newPos = _position + Duration(seconds: seconds);
    await _player.seek(
      newPos > _duration ? _duration : newPos,
    );
  }

  /// Seek to specific position.
  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  /// Cycle playback speed: 0.75 → 1.0 → 1.25 → 1.5
  Future<void> cycleSpeed() async {
    const speeds = [0.75, 1.0, 1.25, 1.5];
    final currentIndex = speeds.indexOf(_speed);
    _speed = speeds[(currentIndex + 1) % speeds.length];
    await _player.setSpeed(_speed);
    notifyListeners();
  }

  /// Pause playback.
  Future<void> pause() async {
    await _player.pause();
  }

  /// Stop and clear current audio.
  /// This clears the notification too.
  Future<void> stop() async {
    await _player.stop();
    _currentFileId = null;
    _currentBookId = null;
    _currentTeacherId = null;
    _currentPartNumber = null;
    _currentTitle = null;
    _currentSubtitle = null;
    _currentArtPath = null;
    _currentAllParts = const [];
    _partResolver = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _isPlaying = false;
    notifyListeners();
  }

  // ─── Save/Restore position ─────────────────────────

  int get positionSeconds => _position.inSeconds;

  Future<void> restorePosition(int seconds) async {
    await _player.seek(Duration(seconds: seconds));
  }

  // ─── Cleanup ───────────────────────────────────────

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // ─── Format helpers ────────────────────────────────

  static String formatDuration(Duration d) {
    final m =
        d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s =
        d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// Result of resolving a part number to a playable audio file.
/// Returned by the resolver function passed to [AudioService.playFile].
class AudioResolution {
  final String filePath;
  final String fileId;
  final String title;
  final String subtitle;
  final String? artPath;

  const AudioResolution({
    required this.filePath,
    required this.fileId,
    required this.title,
    required this.subtitle,
    this.artPath,
  });
}
