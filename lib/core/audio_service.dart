import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// Handles all audio playback for the app.
/// Wraps just_audio with clean state management.
/// Integrates with just_audio_background for
/// notification controls, lock screen, headphones.
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
  String? _currentTitle;
  String? _currentSubtitle;

  // ─── Getters ───────────────────────────────────────
  String? get currentFileId => _currentFileId;
  String? get currentBookId => _currentBookId;
  String? get currentTitle => _currentTitle;
  String? get currentSubtitle => _currentSubtitle;
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

  // ─── Init ──────────────────────────────────────────

  AudioService() {
    _initListeners();
  }

  void _initListeners() {
    // Position updates
    _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    // Duration updates
    _player.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });

    // Playing state
    _player.playingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    // Player state (loading, buffering, etc.)
    _player.playerStateStream.listen((state) {
      _isLoading =
          state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;

      // Auto-stop at end
      if (state.processingState ==
          ProcessingState.completed) {
        _isPlaying = false;
        _position = Duration.zero;
        _player.seek(Duration.zero);
        _player.pause();
      }
      notifyListeners();
    });
  }

  // ─── Playback ──────────────────────────────────────

  /// Load and play an audio file from local path.
  /// This is called when the user EXPLICITLY wants to start
  /// playing (tapped play button, tapped lesson, etc.)
  /// If same file is already loaded → just resumes/plays.
  /// Does NOT auto-toggle pause.
  Future<void> playFile({
    required String filePath,
    required String fileId,
    required String bookId,
    required String title,
    required String subtitle,
    String? artUri,
  }) async {
    try {
      _error = null;

      // Same file already loaded — just resume if paused
      if (_currentFileId == fileId) {
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
      _currentTitle = title;
      _currentSubtitle = subtitle;

      // Wrap file in MediaItem for background/notification support
      final source = AudioSource.uri(
        Uri.file(filePath),
        tag: MediaItem(
          id: fileId,
          title: title,
          album: subtitle,
          artUri: artUri != null ? Uri.file(artUri) : null,
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
  /// SAME file that's already playing. Does NOT stop or
  /// restart audio — just ensures state is in sync.
  /// This is the KEY fix for the "audio pauses on return" bug.
  void ensureNotDisturbed(String fileId) {
    // If same file — do nothing, let audio continue.
    // If different file — also do nothing here. The user
    // needs to explicitly play the new file via playFile().
    // This method exists purely to make intent explicit at
    // the call site.
    return;
  }

  /// Explicitly toggle play/pause. Called only from user
  /// tapping the play/pause button.
  Future<void> togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
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
    _currentTitle = null;
    _currentSubtitle = null;
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
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
