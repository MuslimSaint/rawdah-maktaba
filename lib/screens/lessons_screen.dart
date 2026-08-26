import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/catalog_service.dart';
import '../core/download_service.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'audio_player_screen.dart';
import 'book_detail_screen.dart' show TeacherAvatar;

class LessonsScreen extends StatefulWidget {
  final Book book;
  final Teacher teacher;

  const LessonsScreen({
    super.key,
    required this.book,
    required this.teacher,
  });

  @override
  State<LessonsScreen> createState() =>
      _LessonsScreenState();
}

class _LessonsScreenState
    extends State<LessonsScreen> {
  late Map<int, bool> _completed;
  late TeacherAudio? _teacherAudio;

  @override
  void initState() {
    super.initState();
    _teacherAudio =
        widget.book.audioForTeacher(widget.teacher.id);
    _completed = {};
    if (_teacherAudio != null) {
      for (final part in _teacherAudio!.parts) {
        _completed[part] = false;
      }
    }
  }

  int get _completedCount =>
      _completed.values.where((v) => v).length;
  int get _totalParts =>
      _teacherAudio?.totalParts ?? 0;
  double get _progress =>
      _totalParts > 0
          ? _completedCount / _totalParts
          : 0;

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);

    if (_teacherAudio == null ||
        _teacherAudio!.parts.isEmpty) {
      return Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                book: widget.book,
                teacher: widget.teacher,
                colors: c,
                downloadService: state.downloadService,
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(
                        AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(Icons.headphones_rounded,
                            size: 48,
                            color: c.textFaint),
                        const SizedBox(
                            height: AppSpacing.base),
                        Text(
                          'No audio available yet',
                          style: AppText.latin(
                            color: c.textPrimary,
                            size: 16,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(
                            height: AppSpacing.sm),
                        Text(
                          'Audio lessons from this teacher are coming soon.',
                          textAlign: TextAlign.center,
                          style: AppText.latin(
                              color: c.textMuted,
                              size: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              book: widget.book,
              teacher: widget.teacher,
              colors: c,
              downloadService: state.downloadService,
            ),

            const SizedBox(height: AppSpacing.base),

            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base),
              child: Container(
                padding: const EdgeInsets.all(
                    AppSpacing.base),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(
                      color: c.goldLine, width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ListenableBuilder(
                          listenable:
                              state.downloadService,
                          builder: (context, _) {
                            return TeacherAvatar(
                              teacher: widget.teacher,
                              downloadService:
                                  state.downloadService,
                              colors: c,
                              size: 52,
                            );
                          },
                        ),
                        const SizedBox(
                            width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.teacher.nameAr,
                                textDirection:
                                    TextDirection.rtl,
                                style: AppText.arabic(
                                  color: c.textPrimary,
                                  size: 15,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(
                                  height: AppSpacing.xs),
                              Text(
                                widget.teacher.nameEn,
                                style: AppText.latin(
                                    color: c.textMuted,
                                    size: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color:
                                c.brand.withOpacity(0.1),
                            borderRadius:
                                AppRadius.listItemRadius,
                            border: Border.all(
                                color: c.brand
                                    .withOpacity(0.25)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$_totalParts',
                                style: AppText.latin(
                                  color: c.brand,
                                  size: 18,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text('parts',
                                  style: AppText.latin(
                                      color: c.brand,
                                      size: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                        height: AppSpacing.md),

                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            Text('Progress',
                                style: AppText.latin(
                                    color: c.textMuted,
                                    size: 11)),
                            Text(
                              '$_completedCount / $_totalParts',
                              style: AppText.latin(
                                  color: c.brand,
                                  size: 11,
                                  weight:
                                      FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(
                            height: AppSpacing.sm - 2),
                        ClipRRect(
                          borderRadius:
                              AppRadius.pillRadius,
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: c.surface2,
                            valueColor:
                                AlwaysStoppedAnimation<
                                    Color>(c.brand),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.base),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base,
                  0,
                  AppSpacing.base,
                  AppSpacing.lg,
                ),
                itemCount: _teacherAudio!.parts.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final partNumber =
                      _teacherAudio!.parts[index];
                  final isDone =
                      _completed[partNumber] ?? false;

                  return _LessonRow(
                    partNumber: partNumber,
                    displayIndex: index + 1,
                    totalParts: _totalParts,
                    isDone: isDone,
                    colors: c,
                    book: widget.book,
                    teacher: widget.teacher,
                    teacherAudio: _teacherAudio!,
                    downloadService:
                        state.downloadService,
                    catalogService: state.catalogService,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AudioPlayerScreen(
                            book: widget.book,
                            teacher: widget.teacher,
                            teacherAudio: _teacherAudio!,
                            initialPartIndex: index,
                          ),
                        ),
                      );
                    },
                    onCompletedToggle: () {
                      setState(() {
                        _completed[partNumber] =
                            !(_completed[partNumber] ??
                                false);
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final Book book;
  final Teacher teacher;
  final AppColors colors;
  final DownloadService downloadService;

  const _TopBar({
    required this.book,
    required this.teacher,
    required this.colors,
    required this.downloadService,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.base,
        AppSpacing.base,
        0,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: AppRadius.buttonRadius,
                border: Border.all(color: c.divider),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  size: 18, color: c.textPrimary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  book.titleAr,
                  textDirection: TextDirection.rtl,
                  style: AppText.arabic(
                    color: c.textPrimary,
                    size: 14,
                    weight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Taught by: ${teacher.nameEn}',
                  style: AppText.latin(
                      color: c.goldText, size: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonRow extends StatefulWidget {
  final int partNumber;
  final int displayIndex;
  final int totalParts;
  final bool isDone;
  final AppColors colors;
  final Book book;
  final Teacher teacher;
  final TeacherAudio teacherAudio;
  final DownloadService downloadService;
  final CatalogService catalogService;
  final VoidCallback onTap;
  final VoidCallback onCompletedToggle;

  const _LessonRow({
    required this.partNumber,
    required this.displayIndex,
    required this.totalParts,
    required this.isDone,
    required this.colors,
    required this.book,
    required this.teacher,
    required this.teacherAudio,
    required this.downloadService,
    required this.catalogService,
    required this.onTap,
    required this.onCompletedToggle,
  });

  @override
  State<_LessonRow> createState() => _LessonRowState();
}

class _LessonRowState extends State<_LessonRow> {
  String get _fileId => DownloadService.audioId(
        widget.book.id,
        widget.teacher.id,
        widget.partNumber,
      );

  String get _audioUrl =>
      widget.catalogService.audioUrlFor(
        bookId: widget.book.id,
        teacherAudio: widget.teacherAudio,
        partNumber: widget.partNumber,
      );

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final lessonTitle =
        widget.teacherAudio.nameForPart(widget.partNumber);

    return ListenableBuilder(
      listenable: widget.downloadService,
      builder: (context, _) {
        final isDownloaded =
            widget.downloadService.isDownloaded(_fileId);
        final isDownloading =
            widget.downloadService.isDownloading(_fileId);
        final isQueued = widget.downloadService.isQueued(_fileId);
        final isPaused = widget.downloadService.isPaused(_fileId);
        final isAwaiting = widget.downloadService.isAwaitingNetwork(_fileId);
        final progress =
            widget.downloadService.progress(_fileId);

        final activeList = widget.downloadService.activeDownloads;
        final activeData = activeList.firstWhere(
          (d) => d['fileId'] == _fileId,
          orElse: () => <String, dynamic>{},
        );
        final speedKbps = (activeData['speedKbps'] as double?) ?? 0.0;
        final downloadedMb = (activeData['downloadedMb'] as double?) ?? 0.0;
        final totalMb = activeData['totalMb'] as double?;

        final isActive = isDownloading || isQueued || isPaused || isAwaiting;

        final percent = (progress * 100).toInt();
        final String statusLabel = isQueued
            ? 'Waiting in queue…'
            : isAwaiting
                ? 'Waiting for network…'
                : isPaused
                    ? 'Paused'
                    : progress > 0
                        ? '$percent%'
                        : 'Connecting…';

        String sizeLabel = '';
        if (downloadedMb > 0) {
          if (totalMb != null && totalMb > 0) {
            sizeLabel = '${DownloadService.formatMb(downloadedMb)} / ${DownloadService.formatMb(totalMb)}';
          } else {
            sizeLabel = DownloadService.formatMb(downloadedMb);
          }
        }

        return GestureDetector(
          onTap: isDownloaded ? widget.onTap : null,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: AppRadius.cardRadius,
              border: Border.all(
                color: widget.isDone
                    ? c.brand.withOpacity(0.3)
                    : c.divider,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onCompletedToggle,
                      child: AnimatedContainer(
                        duration: const Duration(
                            milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isDone
                              ? c.brand
                              : c.surface2,
                          border: Border.all(
                            color: widget.isDone
                                ? c.brand
                                : c.divider,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: widget.isDone
                            ? const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: Colors.white)
                            : Text(
                                '${widget.displayIndex}',
                                style: AppText.latin(
                                  color: c.textMuted,
                                  size: 13,
                                  weight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.md),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          Text(
                            lessonTitle,
                            textDirection:
                                TextDirection.rtl,
                            style: AppText.arabic(
                              color: widget.isDone
                                  ? c.textMuted
                                  : c.textPrimary,
                              size: 15,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(
                              height: AppSpacing.xs),
                          Text(
                            isActive
                                ? statusLabel
                                : '${widget.displayIndex} of ${widget.totalParts}',
                            style: AppText.latin(
                                color: isActive
                                    ? (isPaused ? c.goldText : c.brand)
                                    : c.textFaint,
                                size: 11,
                                weight: isActive ? FontWeight.w600 : FontWeight.normal),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: AppSpacing.md),

                    if (isActive) ...[
                      if (!isQueued && !isAwaiting)
                        GestureDetector(
                          onTap: () {
                            if (isPaused) {
                              widget.downloadService.resumeDownload(_fileId);
                            } else {
                              widget.downloadService.pauseDownload(_fileId);
                            }
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: c.surface2,
                              borderRadius: AppRadius.buttonRadius,
                              border: Border.all(color: c.divider),
                            ),
                            child: Icon(
                              isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                              size: 16,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                      const SizedBox(width: AppSpacing.xs),
                      GestureDetector(
                        onTap: () => widget.downloadService.cancelDownload(_fileId),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: c.dangerBg,
                            borderRadius: AppRadius.buttonRadius,
                            border: Border.all(color: c.danger.withOpacity(0.3)),
                          ),
                          child: Icon(Icons.close_rounded, size: 16, color: c.danger),
                        ),
                      ),
                    ] else
                      GestureDetector(
                        onTap: () {
                          if (isDownloaded) {
                            widget.onTap();
                          } else {
                            widget.downloadService.download(
                              fileId: _fileId,
                              url: _audioUrl,
                              displayName:
                                  '${widget.book.titleAr} - $lessonTitle',
                              bookId: widget.book.id,
                              personId: widget.teacher.id,
                              personPhotoUrl:
                                  widget.teacher.photoUrl,
                              onError: (_) {},
                              onComplete: () {},
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(
                              milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDownloaded
                                ? c.brand
                                : c.brand
                                    .withOpacity(0.1),
                            border: Border.all(
                              color: isDownloaded
                                  ? c.brand
                                  : c.brand
                                      .withOpacity(0.3),
                            ),
                          ),
                          child: Icon(
                            isDownloaded
                                ? Icons
                                    .play_arrow_rounded
                                : Icons
                                    .download_rounded,
                            size: 20,
                            color: isDownloaded
                                ? Colors.white
                                : c.brand,
                          ),
                        ),
                      ),
                  ],
                ),

                if (isActive) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: AppRadius.pillRadius,
                    child: LinearProgressIndicator(
                      value: (progress > 0 && !isQueued && !isAwaiting) ? progress : null,
                      backgroundColor: c.surface2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(isPaused ? c.goldText : c.brand),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (speedKbps > 0 && !isPaused && !isQueued && !isAwaiting)
                            ? DownloadService.formatSpeed(speedKbps)
                            : statusLabel,
                        style: AppText.latin(color: c.textMuted, size: 10),
                      ),
                      if (sizeLabel.isNotEmpty)
                        Text(
                          sizeLabel,
                          style: AppText.latin(color: c.textFaint, size: 10),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
