import 'dart:io';
import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/arabic_utils.dart';
import '../core/catalog_service.dart';
import '../core/download_service.dart';
import '../core/models.dart';
import '../core/theme.dart';
// FIX: import public TeacherAvatar
import 'book_detail_screen.dart' show TeacherAvatar;
import 'surah_audio_player_screen.dart';
// FIX: was show _ReciterAvatar — private, not exportable
// now show ReciterAvatar — public
import 'surah_detail_screen.dart' show ReciterAvatar;

enum SurahNarratorType { reciter, teacher }

class SurahLessonsScreen extends StatefulWidget {
  final SurahMeta meta;
  final SurahNarratorType narratorType;

  final Reciter? reciter;
  final ReciterAudio? reciterAudio;

  final Teacher? teacher;
  final TeacherAudio? teacherAudio;

  const SurahLessonsScreen.reciter({
    super.key,
    required this.meta,
    required Reciter this.reciter,
    required ReciterAudio this.reciterAudio,
  })  : narratorType = SurahNarratorType.reciter,
        teacher = null,
        teacherAudio = null;

  const SurahLessonsScreen.teacher({
    super.key,
    required this.meta,
    required Teacher this.teacher,
    required TeacherAudio this.teacherAudio,
  })  : narratorType = SurahNarratorType.teacher,
        reciter = null,
        reciterAudio = null;

  @override
  State<SurahLessonsScreen> createState() =>
      _SurahLessonsScreenState();
}

class _SurahLessonsScreenState
    extends State<SurahLessonsScreen> {
  late Map<int, bool> _completed;

  List<int> get _parts =>
      widget.narratorType == SurahNarratorType.reciter
          ? widget.reciterAudio!.parts
          : widget.teacherAudio!.parts;

  int get _totalParts => _parts.length;

  String get _narratorNameAr =>
      widget.narratorType == SurahNarratorType.reciter
          ? widget.reciter!.nameAr
          : widget.teacher!.nameAr;

  String get _narratorNameEn =>
      widget.narratorType == SurahNarratorType.reciter
          ? widget.reciter!.nameEn
          : widget.teacher!.nameEn;

  bool get _isReciter =>
      widget.narratorType == SurahNarratorType.reciter;

  @override
  void initState() {
    super.initState();
    _completed = {for (final p in _parts) p: false};
  }

  int get _completedCount =>
      _completed.values.where((v) => v).length;
  double get _progress =>
      _totalParts > 0 ? _completedCount / _totalParts : 0;

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);
    final accent = _isReciter ? c.goldText : c.brand;

    if (_totalParts == 0) {
      return Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                meta: widget.meta,
                narratorNameEn: _narratorNameEn,
                label: _isReciter
                    ? 'Recited by'
                    : 'Taught by',
                colors: c,
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
                          _isReciter
                              ? 'Recitations by this Qari are coming soon.'
                              : 'Tafseer by this teacher is coming soon.',
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
              meta: widget.meta,
              narratorNameEn: _narratorNameEn,
              label: _isReciter
                  ? 'Recited by'
                  : 'Taught by',
              colors: c,
            ),

            const SizedBox(height: AppSpacing.base),

            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base),
              child: Container(
                padding:
                    const EdgeInsets.all(AppSpacing.base),
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
                            if (_isReciter) {
                              // FIX: was _ReciterAvatar
                              // now ReciterAvatar (public)
                              return ReciterAvatar(
                                reciter: widget.reciter!,
                                downloadService:
                                    state.downloadService,
                                colors: c,
                                size: 52,
                              );
                            } else {
                              return TeacherAvatar(
                                teacher: widget.teacher!,
                                downloadService:
                                    state.downloadService,
                                colors: c,
                                size: 52,
                              );
                            }
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
                                _narratorNameAr,
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
                              Text(_narratorNameEn,
                                  style: AppText.latin(
                                      color: c.textMuted,
                                      size: 12)),
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
                            color: accent.withOpacity(0.1),
                            borderRadius:
                                AppRadius.listItemRadius,
                            border: Border.all(
                                color: accent
                                    .withOpacity(0.25)),
                          ),
                          child: Column(
                            children: [
                              Text('$_totalParts',
                                  style: AppText.latin(
                                    color: accent,
                                    size: 18,
                                    weight: FontWeight.w700,
                                  )),
                              Text('parts',
                                  style: AppText.latin(
                                      color: accent,
                                      size: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Progress',
                                style: AppText.latin(
                                    color: c.textMuted,
                                    size: 11)),
                            Text(
                              '$_completedCount / $_totalParts',
                              style: AppText.latin(
                                  color: accent,
                                  size: 11,
                                  weight: FontWeight.w700),
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
                                    Color>(accent),
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
                itemCount: _parts.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final partNumber = _parts[index];
                  final isDone =
                      _completed[partNumber] ?? false;

                  return _SurahLessonRow(
                    partNumber: partNumber,
                    displayIndex: index + 1,
                    totalParts: _totalParts,
                    isDone: isDone,
                    colors: c,
                    accent: accent,
                    meta: widget.meta,
                    isReciter: _isReciter,
                    reciterAudio: widget.reciterAudio,
                    teacherAudio: widget.teacherAudio,
                    reciter: widget.reciter,
                    teacher: widget.teacher,
                    downloadService: state.downloadService,
                    catalogService: state.catalogService,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _isReciter
                              ? SurahAudioPlayerScreen
                                  .reciter(
                                  meta: widget.meta,
                                  reciter: widget.reciter!,
                                  reciterAudio:
                                      widget.reciterAudio!,
                                  initialPartIndex: index,
                                )
                              : SurahAudioPlayerScreen
                                  .teacher(
                                  meta: widget.meta,
                                  teacher: widget.teacher!,
                                  teacherAudio:
                                      widget.teacherAudio!,
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
  final SurahMeta meta;
  final String narratorNameEn;
  final String label;
  final AppColors colors;

  const _TopBar({
    required this.meta,
    required this.narratorNameEn,
    required this.label,
    required this.colors,
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
                  meta.nameAr,
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
                  '$label: $narratorNameEn',
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

class _SurahLessonRow extends StatelessWidget {
  final int partNumber;
  final int displayIndex;
  final int totalParts;
  final bool isDone;
  final AppColors colors;
  final Color accent;
  final SurahMeta meta;
  final bool isReciter;
  final ReciterAudio? reciterAudio;
  final TeacherAudio? teacherAudio;
  final Reciter? reciter;
  final Teacher? teacher;
  final DownloadService downloadService;
  final CatalogService catalogService;
  final VoidCallback onTap;
  final VoidCallback onCompletedToggle;

  const _SurahLessonRow({
    required this.partNumber,
    required this.displayIndex,
    required this.totalParts,
    required this.isDone,
    required this.colors,
    required this.accent,
    required this.meta,
    required this.isReciter,
    required this.reciterAudio,
    required this.teacherAudio,
    required this.reciter,
    required this.teacher,
    required this.downloadService,
    required this.catalogService,
    required this.onTap,
    required this.onCompletedToggle,
  });

  String get _narratorId => isReciter
      ? reciterAudio!.reciterId
      : teacherAudio!.teacherId;

  String get _fileId => isReciter
      ? DownloadService.surahReciterAudioId(
          meta.number, _narratorId, partNumber)
      : DownloadService.surahTeacherAudioId(
          meta.number, _narratorId, partNumber);

  String get _audioUrl => isReciter
      ? catalogService.surahReciterUrlFor(
          surahNumber: meta.number,
          reciterAudio: reciterAudio!,
          partNumber: partNumber,
        )
      : catalogService.surahTeacherUrlFor(
          surahNumber: meta.number,
          teacherAudio: teacherAudio!,
          partNumber: partNumber,
        );

  String get _personId => isReciter
      ? reciterAudio!.reciterId
      : teacherAudio!.teacherId;

  String get _personPhotoUrl => isReciter
      ? (reciter?.photoUrl ?? '')
      : (teacher?.photoUrl ?? '');

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final lessonTitle =
        ArabicUtils.lessonTitle(partNumber);

    return ListenableBuilder(
      listenable: downloadService,
      builder: (context, _) {
        final isDownloaded =
            downloadService.isDownloaded(_fileId);
        final isDownloading =
            downloadService.isDownloading(_fileId);
        final progress =
            downloadService.progress(_fileId);

        return GestureDetector(
          onTap: isDownloaded ? onTap : null,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: AppRadius.cardRadius,
              border: Border.all(
                color: isDone
                    ? accent.withOpacity(0.3)
                    : c.divider,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: onCompletedToggle,
                      child: AnimatedContainer(
                        duration: const Duration(
                            milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isDone ? accent : c.surface2,
                          border: Border.all(
                            color: isDone ? accent : c.divider,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: isDone
                            ? const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: Colors.white)
                            : Text(
                                '$displayIndex',
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
                              color: isDone
                                  ? c.textMuted
                                  : c.textPrimary,
                              size: 15,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(
                              height: AppSpacing.xs),
                          Text(
                            '$displayIndex of $totalParts',
                            style: AppText.latin(
                                color: c.textFaint,
                                size: 11),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: AppSpacing.md),

                    GestureDetector(
                      onTap: () {
                        if (isDownloading) {
                          downloadService
                              .cancelDownload(_fileId);
                        } else if (isDownloaded) {
                          onTap();
                        } else {
                          downloadService.download(
                            fileId: _fileId,
                            url: _audioUrl,
                            displayName:
                                '${meta.nameAr} - $lessonTitle',
                            bookId: 'surah_${meta.number}',
                            personId: _personId,
                            personPhotoUrl: _personPhotoUrl,
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
                          color: isDownloading
                              ? c.dangerBg
                              : isDownloaded
                                  ? accent
                                  : accent.withOpacity(0.1),
                          border: Border.all(
                            color: isDownloading
                                ? c.danger.withOpacity(0.3)
                                : isDownloaded
                                    ? accent
                                    : accent.withOpacity(0.3),
                          ),
                        ),
                        child: isDownloading
                            ? Icon(Icons.close_rounded,
                                size: 18, color: c.danger)
                            : Icon(
                                isDownloaded
                                    ? Icons.play_arrow_rounded
                                    : Icons.download_rounded,
                                size: 20,
                                color: isDownloaded
                                    ? Colors.white
                                    : accent,
                              ),
                      ),
                    ),
                  ],
                ),

                if (isDownloading) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: AppRadius.pillRadius,
                    child: LinearProgressIndicator(
                      value:
                          progress > 0 ? progress : null,
                      backgroundColor: c.surface2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                              accent),
                      minHeight: 3,
                    ),
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
