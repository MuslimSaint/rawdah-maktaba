import 'dart:io';
import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/arabic_utils.dart';
import '../core/audio_service.dart';
import '../core/cover_service.dart';
import '../core/download_service.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'pdf_reader_screen.dart';
import 'surah_detail_screen.dart' show fakeBookForSurah;
import 'surah_lessons_screen.dart';

class SurahAudioPlayerScreen extends StatefulWidget {
  final SurahMeta meta;
  final SurahNarratorType narratorType;

  final Reciter? reciter;
  final ReciterAudio? reciterAudio;

  final Teacher? teacher;
  final TeacherAudio? teacherAudio;

  final int initialPartIndex;

  const SurahAudioPlayerScreen.reciter({
    super.key,
    required this.meta,
    required Reciter this.reciter,
    required ReciterAudio this.reciterAudio,
    required this.initialPartIndex,
  })  : narratorType = SurahNarratorType.reciter,
        teacher = null,
        teacherAudio = null;

  const SurahAudioPlayerScreen.teacher({
    super.key,
    required this.meta,
    required Teacher this.teacher,
    required TeacherAudio this.teacherAudio,
    required this.initialPartIndex,
  })  : narratorType = SurahNarratorType.teacher,
        reciter = null,
        reciterAudio = null;

  @override
  State<SurahAudioPlayerScreen> createState() =>
      _SurahAudioPlayerScreenState();
}

class _SurahAudioPlayerScreenState
    extends State<SurahAudioPlayerScreen> {
  late int _currentPartIndex;
  late AudioService _audioService;
  late DownloadService _downloadService;
  late CoverService _coverService;

  String? _errorMessage;

  bool get _isReciter =>
      widget.narratorType == SurahNarratorType.reciter;

  List<int> get _parts => _isReciter
      ? widget.reciterAudio!.parts
      : widget.teacherAudio!.parts;

  String get _narratorId => _isReciter
      ? widget.reciter!.id
      : widget.teacher!.id;

  String get _narratorNameAr => _isReciter
      ? widget.reciter!.nameAr
      : widget.teacher!.nameAr;

  String get _surahPdfFileId =>
      'pdf_surah_${widget.meta.number}';

  String get _surahCoverKey => 'surah_${widget.meta.number}';

  @override
  void initState() {
    super.initState();
    _currentPartIndex = widget.initialPartIndex;

    final state = AppState.of(context);
    _audioService = state.audioService;
    _downloadService = state.downloadService;
    _coverService = state.coverService;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_audioService.currentFileId != _currentFileId) {
        if (_audioService.currentFileId == null &&
            _isCurrentDownloaded) {
          _startPlayback();
        }
      }
    });
  }

  int get _currentPartNumber => _parts[_currentPartIndex];

  int get _totalParts => _parts.length;

  String get _currentFileId => _isReciter
      ? DownloadService.surahReciterAudioId(
          widget.meta.number,
          _narratorId,
          _currentPartNumber,
        )
      : DownloadService.surahTeacherAudioId(
          widget.meta.number,
          _narratorId,
          _currentPartNumber,
        );

  bool get _isCurrentDownloaded =>
      _downloadService.isDownloaded(_currentFileId);

  bool get _isPdfDownloaded =>
      _downloadService.isDownloaded(_surahPdfFileId);

  bool get _hasPdfUrl {
    final state = AppState.of(context);
    final surah = state.catalogService.quran
        .surahFor(widget.meta.number);
    return surah.hasPdf;
  }

  Future<AudioResolution?> _resolvePart(int partNumber) async {
    final fileId = _isReciter
        ? DownloadService.surahReciterAudioId(
            widget.meta.number, _narratorId, partNumber)
        : DownloadService.surahTeacherAudioId(
            widget.meta.number, _narratorId, partNumber);

    if (!_downloadService.isDownloaded(fileId)) return null;

    final path = await _downloadService.localPath(fileId);
    if (path == null) return null;

    final lessonTitle = ArabicUtils.lessonTitle(partNumber);
    final coverPath =
        _coverService.coverPath(_surahCoverKey);

    return AudioResolution(
      filePath: path,
      fileId: fileId,
      title: '${widget.meta.nameAr} — $lessonTitle',
      subtitle: _narratorNameAr,
      artPath: coverPath,
    );
  }

  Future<void> _startPlayback() async {
    if (!_isCurrentDownloaded) return;

    final resolved = await _resolvePart(_currentPartNumber);
    if (resolved == null) {
      if (mounted) {
        setState(() => _errorMessage =
            'Audio file not found. Please re-download.');
      }
      return;
    }

    await _audioService.playFile(
      filePath: resolved.filePath,
      fileId: resolved.fileId,
      bookId: 'surah_${widget.meta.number}',
      teacherId: _narratorId,
      partNumber: _currentPartNumber,
      title: resolved.title,
      subtitle: resolved.subtitle,
      artUri: resolved.artPath,
      allParts: _parts,
      partResolver: _resolvePart,
    );

    if (mounted && _audioService.error != null) {
      setState(() => _errorMessage = _audioService.error);
    }
  }

  Future<void> _previousLesson() async {
    if (_currentPartIndex <= 0) return;
    setState(() {
      _currentPartIndex--;
      _errorMessage = null;
    });
    await _audioService.skipToPrevious();
  }

  Future<void> _nextLesson() async {
    if (_currentPartIndex >= _totalParts - 1) return;
    setState(() {
      _currentPartIndex++;
      _errorMessage = null;
    });
    await _audioService.skipToNext();
  }

  Future<void> _onCoverTap() async {
    if (_isPdfDownloaded) {
      final path =
          await _downloadService.localPath(_surahPdfFileId);
      if (path != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PdfReaderScreen(
              book: fakeBookForSurah(widget.meta),
              filePath: path,
            ),
          ),
        );
      }
    } else {
      if (!_hasPdfUrl) return;
      final state = AppState.of(context);
      final surah = state.catalogService.quran
          .surahFor(widget.meta.number);
      final url =
          state.catalogService.surahPdfUrlFor(surah);
      _downloadService.download(
        fileId: _surahPdfFileId,
        url: url,
        displayName: widget.meta.nameAr,
        bookId: 'surah_${widget.meta.number}',
        onError: (_) {},
        onComplete: () {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);
    final hasPrev = _currentPartIndex > 0;
    final hasNext = _currentPartIndex < _totalParts - 1;

    final lessonTitle =
        ArabicUtils.lessonTitle(_currentPartNumber);

    final accent = _isReciter ? c.goldText : c.brand;
    final accentHover = _isReciter ? c.goldText : c.brandHover;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            state.audioService,
            state.downloadService,
            state.coverService,
          ]),
          builder: (context, _) {
            final isPlaying = _audioService.isPlaying;
            final position = _audioService.position;
            final duration = _audioService.duration;
            final speed = _audioService.speed;
            final isActive =
                _audioService.currentFileId ==
                    _currentFileId;
            final isLoading =
                isActive && _audioService.isLoading;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            Navigator.of(context).pop(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: c.surface2,
                            borderRadius:
                                BorderRadius.circular(11),
                            border: Border.all(
                                color: c.divider),
                          ),
                          child: Icon(
                            Icons
                                .keyboard_arrow_down_rounded,
                            size: 24,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'NOW PLAYING',
                              style: AppText.label(
                                  color: c.textFaint),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lessonTitle,
                              textDirection:
                                  TextDirection.rtl,
                              style: AppText.arabic(
                                color: c.textPrimary,
                                size: 15,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 38,
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius:
                              BorderRadius.circular(11),
                          border:
                              Border.all(color: c.divider),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${_currentPartIndex + 1}/$_totalParts',
                          style: AppText.latin(
                            color: c.textMuted,
                            size: 10,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                GestureDetector(
                  onTap: _onCoverTap,
                  child: _SurahCover(
                    meta: widget.meta,
                    coverService: _coverService,
                    surahCoverKey: _surahCoverKey,
                    colors: c,
                    accent: accent,
                    isPdfDownloaded: _isPdfDownloaded,
                    hasPdfUrl: _hasPdfUrl,
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        widget.meta.nameAr,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.arabic(
                          color: c.textPrimary,
                          size: 20,
                          weight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _narratorNameAr,
                        textDirection: TextDirection.rtl,
                        style: AppText.arabic(
                          color: accent,
                          size: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isReciter ? 'تلاوة' : 'تفسير',
                        textDirection: TextDirection.rtl,
                        style: AppText.arabic(
                          color: c.textMuted,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (!_isCurrentDownloaded) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius:
                            BorderRadius.circular(14),
                        border:
                            Border.all(color: c.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.download_rounded,
                            color: accent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Download this part from the previous screen to play it.',
                              style: AppText.latin(
                                color: c.textMuted,
                                size: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (_errorMessage != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.dangerBg,
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                c.danger.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: c.danger,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppText.latin(
                                color: c.danger,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context)
                            .copyWith(
                          activeTrackColor: accent,
                          inactiveTrackColor: c.surface2,
                          thumbColor: accent,
                          thumbShape:
                              const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          trackHeight: 4,
                          overlayShape:
                              SliderComponentShape.noOverlay,
                        ),
                        child: Slider(
                          value: isActive
                              ? position.inSeconds
                                  .toDouble()
                                  .clamp(
                                    0,
                                    duration.inSeconds > 0
                                        ? duration.inSeconds
                                            .toDouble()
                                        : 1,
                                  )
                              : 0,
                          min: 0,
                          max: duration.inSeconds > 0
                              ? duration.inSeconds
                                  .toDouble()
                              : 1,
                          onChanged: isActive
                              ? (v) {
                                  _audioService.seekTo(
                                    Duration(
                                        seconds: v.toInt()),
                                  );
                                }
                              : null,
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 8),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            Text(
                              isActive
                                  ? AudioService
                                      .formatDuration(
                                          position)
                                  : '00:00',
                              style: AppText.latin(
                                color: c.textFaint,
                                size: 11,
                              ),
                            ),
                            Text(
                              isActive &&
                                      duration.inSeconds >
                                          0
                                  ? AudioService
                                      .formatDuration(
                                          duration)
                                  : '--:--',
                              style: AppText.latin(
                                color: c.textFaint,
                                size: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceEvenly,
                    children: [
                      _ControlButton(
                        icon: Icons.skip_previous_rounded,
                        size: 26,
                        enabled: hasPrev,
                        colors: c,
                        onTap: _previousLesson,
                      ),
                      _SeekButton(
                        isForward: false,
                        colors: c,
                        onTap: isActive
                            ? () =>
                                _audioService.seekBack(10)
                            : null,
                      ),

                      GestureDetector(
                        onTap: _isCurrentDownloaded
                            ? () {
                                if (isActive) {
                                  _audioService
                                      .togglePlay();
                                } else {
                                  _startPlayback();
                                }
                              }
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(
                              milliseconds: 150),
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isCurrentDownloaded
                                  ? [accent, accentHover]
                                  : [
                                      c.textFaint,
                                      c.textFaint
                                    ],
                            ),
                            boxShadow: _isCurrentDownloaded
                                ? [
                                    BoxShadow(
                                      color: accent
                                          .withOpacity(
                                              0.4),
                                      blurRadius: 20,
                                      offset: const Offset(
                                          0, 6),
                                    ),
                                  ]
                                : null,
                          ),
                          child: isLoading
                              ? const Padding(
                                  padding:
                                      EdgeInsets.all(20),
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isActive && isPlaying
                                      ? Icons.pause_rounded
                                      : Icons
                                          .play_arrow_rounded,
                                  size: 34,
                                  color: Colors.white,
                                ),
                        ),
                      ),

                      _SeekButton(
                        isForward: true,
                        colors: c,
                        onTap: isActive
                            ? () => _audioService
                                .seekForward(10)
                            : null,
                      ),
                      _ControlButton(
                        icon: Icons.skip_next_rounded,
                        size: 26,
                        enabled: hasNext,
                        colors: c,
                        onTap: _nextLesson,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                GestureDetector(
                  onTap: isActive
                      ? () => _audioService.cycleSpeed()
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius:
                          BorderRadius.circular(12),
                      border:
                          Border.all(color: c.divider),
                    ),
                    child: Text(
                      'Speed: ${speed}x',
                      style: AppText.latin(
                        color: isActive
                            ? accent
                            : c.textFaint,
                        size: 13,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      24, 0, 24, 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: c.goldLine,
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            c.goldText.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: c.goldText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isActive && isPlaying
                                ? 'Audio continues in the background — control from the notification'
                                : 'Tap the cover to open or download the Surah PDF',
                            style: AppText.latin(
                              color: c.goldText,
                              size: 11,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SurahCover extends StatelessWidget {
  final SurahMeta meta;
  final CoverService coverService;
  final String surahCoverKey;
  final AppColors colors;
  final Color accent;
  final bool isPdfDownloaded;
  final bool hasPdfUrl;

  const _SurahCover({
    required this.meta,
    required this.coverService,
    required this.surahCoverKey,
    required this.colors,
    required this.accent,
    required this.isPdfDownloaded,
    required this.hasPdfUrl,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final coverPath = coverService.coverPath(surahCoverKey);

    return Container(
      width: 180,
      height: 240,
      decoration: BoxDecoration(
        color: c.goldText.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: c.goldText.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox.expand(
              child: coverPath != null
                  ? Image.file(
                      File(coverPath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _placeholder(c),
                    )
                  : _placeholder(c),
            ),
          ),
          if (hasPdfUrl)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPdfDownloaded
                            ? Icons.menu_book_rounded
                            : Icons.download_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPdfDownloaded
                            ? 'Open'
                            : 'Download',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder(AppColors c) {
    return Container(
      color: c.goldText.withOpacity(0.08),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 56,
            color: c.goldText,
          ),
          const SizedBox(height: 8),
          Text(
            meta.nameAr,
            textDirection: TextDirection.rtl,
            style: AppText.arabic(
              color: c.goldText,
              size: 16,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeekButton extends StatelessWidget {
  final bool isForward;
  final AppColors colors;
  final VoidCallback? onTap;

  const _SeekButton({
    required this.isForward,
    required this.colors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: c.surface2,
          shape: BoxShape.circle,
          border: Border.all(color: c.divider),
        ),
        child: Icon(
          isForward
              ? Icons.forward_10_rounded
              : Icons.replay_10_rounded,
          size: 28,
          color: onTap != null ? c.textPrimary : c.textFaint,
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool enabled;
  final AppColors colors;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.enabled,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled
              ? c.surface2
              : c.surface2.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? c.divider
                : c.divider.withOpacity(0.5),
          ),
        ),
        child: Icon(
          icon,
          size: size,
          color: enabled ? c.textPrimary : c.textFaint,
        ),
      ),
    );
  }
}
