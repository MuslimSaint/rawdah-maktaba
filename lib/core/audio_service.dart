import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Handles all audio playback for the app.
/// Wraps just_audio with clean state management.
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

  // ─── Getters ───────────────────────────────────────
  String? get currentFileId => _currentFileId;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  double get speed => _speed;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get progress =>
      _duration.inMilliseconds > 0
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
      _isLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;

      // Auto-stop at end
      if (state.processingState == ProcessingState.completed) {
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
  Future<void> playFile({
    required String filePath,
    required String fileId,
  }) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      // If same file — just toggle play/pause
      if (_currentFileId == fileId) {
        await togglePlay();
        return;
      }

      // New file — load it
      _currentFileId = fileId;
      await _player.setFilePath(filePath);
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

  /// Toggle play/pause.
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
  Future<void> stop() async {
    await _player.stop();
    _currentFileId = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _isPlaying = false;
    notifyListeners();
  }

  // ─── Save/Restore position ─────────────────────────

  /// Returns current position in seconds for saving.
  int get positionSeconds => _position.inSeconds;

  /// Restore saved position.
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
