import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/arabic_utils.dart';
import '../core/catalog_service.dart';
import '../core/download_service.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'pdf_reader_screen.dart';
import 'surah_lessons_screen.dart';
import 'surah_audio_player_screen.dart';

/// Surah detail screen — the equivalent of BookDetailScreen
/// but tailored for a Quran Surah.
class SurahDetailScreen extends StatelessWidget {
  final SurahMeta meta;

  const SurahDetailScreen({super.key, required this.meta});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            state.catalogService,
            state.downloadService,
          ]),
          builder: (context, _) {
            final surah = state.catalogService.quran
                .surahFor(meta.number);

            return Column(
              children: [
                // ── Top Bar ──
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
                            border:
                                Border.all(color: c.divider),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 18,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          meta.nameAr,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: AppText.arabic(
                            color: c.goldText,
                            size: 20,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                        20, 0, 20, 32),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _HeroCard(
                            meta: meta,
                            colors: c,
                            language: state.language),
                        const SizedBox(height: 20),
                        _PdfSection(
                          meta: meta,
                          surah: surah,
                          colors: c,
                          downloadService:
                              state.downloadService,
                          catalogService:
                              state.catalogService,
                        ),
                        const SizedBox(height: 20),
                        if (surah.hasReciters)
                          _RecitersSection(
                            surah: surah,
                            meta: meta,
                            catalogService:
                                state.catalogService,
                            downloadService:
                                state.downloadService,
                            colors: c,
                            language: state.language,
                          ),
                        if (surah.hasReciters &&
                            surah.hasTeachers)
                          const SizedBox(height: 20),
                        if (surah.hasTeachers)
                          _TeachersSection(
                            surah: surah,
                            meta: meta,
                            catalogService:
                                state.catalogService,
                            colors: c,
                            language: state.language,
                          ),
                        if (!surah.hasReciters &&
                            !surah.hasTeachers &&
                            !surah.hasPdf)
                          _NothingYet(colors: c),
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

// ─── Hero Card ───────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final SurahMeta meta;
  final AppColors colors;
  final String language;

  const _HeroCard({
    required this.meta,
    required this.colors,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final trans = meta.transliterationFor(language);
    final placeAr = meta.revelationPlace == 'meccan'
        ? 'مكية'
        : 'مدنية';
    final placeLatin = meta.revelationPlace == 'meccan'
        ? 'Meccan'
        : 'Medinan';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.goldLine,
            c.gold.withOpacity(0.28),
            c.goldLine,
          ],
        ),
        border: Border.all(
          color: c.goldText.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.goldText.withOpacity(0.15),
              border: Border.all(
                color: c.goldText.withOpacity(0.5),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${meta.number}',
              style: AppText.latin(
                color: c.goldText,
                size: 24,
                weight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            meta.nameAr,
            textDirection: TextDirection.rtl,
            style: AppText.arabic(
              color: c.goldText,
              size: 28,
              weight: FontWeight.w700,
              height: 1.4,
            ),
          ),

          if (trans != null) ...[
            const SizedBox(height: 4),
            Text(
              trans,
              style: AppText.latin(
                color: c.goldText.withOpacity(0.85),
                size: 14,
                weight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 14),
          Divider(color: c.goldText.withOpacity(0.2), height: 1),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MetaChip(
                icon: Icons.format_list_numbered_rounded,
                labelLatin: '${meta.ayahCount} Ayat',
                labelAr: '${meta.ayahCount} آية',
                colors: c,
                language: language,
              ),
              _MetaChip(
                icon: Icons.location_on_outlined,
                labelLatin: placeLatin,
                labelAr: placeAr,
                colors: c,
                language: language,
              ),
              _MetaChip(
                icon: Icons.numbers_rounded,
                labelLatin: '#${meta.revelationOrder}',
                labelAr: '#${meta.revelationOrder}',
                colors: c,
                language: language,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String labelLatin;
  final String labelAr;
  final AppColors colors;
  final String language;

  const _MetaChip({
    required this.icon,
    required this.labelLatin,
    required this.labelAr,
    required this.colors,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final label = language == 'ar' ? labelAr : labelLatin;
    return Column(
      children: [
        Icon(icon, size: 18, color: c.goldText),
        const SizedBox(height: 4),
        Text(
          label,
          textDirection: language == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          style: AppText.latin(
            color: c.goldText,
            size: 11,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── PDF Section ─────────────────────────────────────────

class _PdfSection extends StatefulWidget {
  final SurahMeta meta;
  final Surah surah;
  final AppColors colors;
  final DownloadService downloadService;
  final CatalogService catalogService;

  const _PdfSection({
    required this.meta,
    required this.surah,
    required this.colors,
    required this.downloadService,
    required this.catalogService,
  });

  @override
  State<_PdfSection> createState() => _PdfSectionState();
}

class _PdfSectionState extends State<_PdfSection> {
  String? _errorMessage;

  String get _fileId => 'pdf_surah_${widget.meta.number}';

  Future<void> _openPdf(BuildContext context) async {
    final path =
        await widget.downloadService.localPath(_fileId);
    if (!context.mounted) return;
    if (path == null) {
      setState(() => _errorMessage =
          'Could not open file. Please download again.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfReaderScreen(
          book: fakeBookForSurah(widget.meta),
          filePath: path,
        ),
      ),
    );
  }

  Future<void> _startDownload() async {
    setState(() => _errorMessage = null);
    final url = widget.surah.pdfUrl.isNotEmpty
        ? widget.surah.pdfUrl
        : widget.catalogService
            .surahPdfUrl(widget.meta.number);

    await widget.downloadService.download(
      fileId: _fileId,
      url: url,
      displayName: widget.meta.nameAr,
      bookId: 'surah_${widget.meta.number}',
      onError: (e) {
        if (mounted) setState(() => _errorMessage = e);
      },
      onComplete: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final isDownloaded =
        widget.downloadService.isDownloaded(_fileId);
    final isDownloading =
        widget.downloadService.isDownloading(_fileId);
    final progress =
        widget.downloadService.progress(_fileId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Surah PDF',
          style: AppText.latin(
            color: c.textPrimary,
            size: 15,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            if (isDownloaded && !isDownloading) {
              _openPdf(context);
            } else if (!isDownloading &&
                widget.surah.hasPdf) {
              _startDownload();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDownloaded
                    ? c.brand.withOpacity(0.4)
                    : c.goldLine,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDownloaded
                            ? c.brand
                            : widget.surah.hasPdf
                                ? c.brand.withOpacity(0.12)
                                : c.surface2,
                        border: Border.all(
                          color: isDownloaded
                              ? c.brand
                              : widget.surah.hasPdf
                                  ? c.brand.withOpacity(0.3)
                                  : c.divider,
                          width: 1.5,
                        ),
                      ),
                      child: isDownloading
                          ? Padding(
                              padding:
                                  const EdgeInsets.all(14),
                              child:
                                  CircularProgressIndicator(
                                value: progress > 0
                                    ? progress
                                    : null,
                                strokeWidth: 2,
                                color: c.brand,
                              ),
                            )
                          : Icon(
                              isDownloaded
                                  ? Icons.menu_book_rounded
                                  : widget.surah.hasPdf
                                      ? Icons
                                          .download_rounded
                                      : Icons
                                          .hourglass_empty_rounded,
                              size: 22,
                              color: isDownloaded
                                  ? Colors.white
                                  : widget.surah.hasPdf
                                      ? c.brand
                                      : c.textFaint,
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDownloaded
                                ? 'Tap to Open'
                                : isDownloading
                                    ? 'Downloading...'
                                    : widget.surah.hasPdf
                                        ? 'Tap to Download'
                                        : 'Coming Soon',
                            style: AppText.latin(
                              color: isDownloaded
                                  ? c.brand
                                  : c.textPrimary,
                              size: 14,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.surah.hasPdf
                                ? 'PDF of Surah ${widget.meta.number}'
                                : 'Not uploaded yet',
                            style: AppText.latin(
                              color: c.textMuted,
                              size: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isDownloading)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: c.brand.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                c.brand.withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          'Free',
                          style: AppText.latin(
                            color: c.brand,
                            size: 12,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (isDownloading)
                      GestureDetector(
                        onTap: () {
                          widget.downloadService
                              .cancelDownload(_fileId);
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: c.dangerBg,
                            borderRadius:
                                BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  c.danger.withOpacity(0.3),
                            ),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: c.danger,
                          ),
                        ),
                      ),
                  ],
                ),
                if (isDownloading) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value:
                          progress > 0 ? progress : null,
                      backgroundColor: c.surface2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                              c.brand),
                      minHeight: 4,
                    ),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: c.dangerBg,
                      borderRadius:
                          BorderRadius.circular(8),
                      border: Border.all(
                        color: c.danger.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: c.danger,
                          size: 14,
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
                        GestureDetector(
                          onTap: () => setState(() =>
                              _errorMessage = null),
                          child: Icon(
                            Icons.close_rounded,
                            color: c.danger,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Wraps a SurahMeta in a lightweight fake Book so the
/// existing PdfReaderScreen can accept it without changes.
/// Made public (no underscore) so surah_audio_player_screen
/// can also open the same PDF from the mushaf cover tap.
Book fakeBookForSurah(SurahMeta m) {
  return Book(
    id: 'surah_${m.number}',
    titleAr: m.nameAr,
    authorAr: 'القرآن الكريم',
    authorEn: 'The Noble Quran',
    authorShort: 'القرآن',
    branches: const ['quran'],
    pages: 0,
    pdfSizeMb: 0,
    hasAudio: false,
    teacherAudio: const [],
    isNew: false,
    pdfUrl: '',
    addedAt: DateTime.now(),
  );
}

// ─── Reciters Section ────────────────────────────────────
// Direct download & play — no lessons screen.

class _RecitersSection extends StatelessWidget {
  final Surah surah;
  final SurahMeta meta;
  final CatalogService catalogService;
  final DownloadService downloadService;
  final AppColors colors;
  final String language;

  const _RecitersSection({
    required this.surah,
    required this.meta,
    required this.catalogService,
    required this.downloadService,
    required this.colors,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    final reciterPairs = surah.reciters
        .map((ra) {
          final r = catalogService.reciterById(ra.reciterId);
          if (r == null) return null;
          return (reciter: r, audio: ra);
        })
        .whereType<({Reciter reciter, ReciterAudio audio})>()
        .toList();

    if (reciterPairs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.mic_rounded, size: 14, color: c.goldText),
            const SizedBox(width: 6),
            Text(
              'RECITERS',
              style: AppText.label(color: c.textFaint),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Beautiful recitations of this Surah.',
          style: AppText.latin(
            color: c.textMuted,
            size: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        ...reciterPairs.map((pair) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ReciterCard(
              reciter: pair.reciter,
              audio: pair.audio,
              meta: meta,
              catalogService: catalogService,
              downloadService: downloadService,
              colors: c,
              language: language,
            ),
          );
        }),
      ],
    );
  }
}

/// Reciter card with built-in download/play button.
/// Since each reciter has exactly 1 part, we skip the
/// lessons screen entirely.
class _ReciterCard extends StatefulWidget {
  final Reciter reciter;
  final ReciterAudio audio;
  final SurahMeta meta;
  final CatalogService catalogService;
  final DownloadService downloadService;
  final AppColors colors;
  final String language;

  const _ReciterCard({
    required this.reciter,
    required this.audio,
    required this.meta,
    required this.catalogService,
    required this.downloadService,
    required this.colors,
    required this.language,
  });

  @override
  State<_ReciterCard> createState() => _ReciterCardState();
}

class _ReciterCardState extends State<_ReciterCard> {
  /// The reciter's first part number (they typically have only 1).
  int get _partNumber => widget.audio.parts.isNotEmpty
      ? widget.audio.parts.first
      : 1;

  String get _fileId => DownloadService.surahReciterAudioId(
        widget.meta.number,
        widget.reciter.id,
        _partNumber,
      );

  String get _url => widget.catalogService.surahReciterUrl(
        surahNumber: widget.meta.number,
        reciterId: widget.reciter.id,
        partNumber: _partNumber,
      );

  void _openPlayer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurahAudioPlayerScreen.reciter(
          meta: widget.meta,
          reciter: widget.reciter,
          reciterAudio: widget.audio,
          initialPartIndex: 0,
        ),
      ),
    );
  }

  void _startDownload() {
    final lessonTitle = ArabicUtils.lessonTitle(_partNumber);
    widget.downloadService.download(
      fileId: _fileId,
      url: _url,
      displayName: '${widget.meta.nameAr} - $lessonTitle',
      bookId: 'surah_${widget.meta.number}',
      onError: (_) {},
      onComplete: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;

    return ListenableBuilder(
      listenable: widget.downloadService,
      builder: (context, _) {
        final isDownloaded =
            widget.downloadService.isDownloaded(_fileId);
        final isDownloading =
            widget.downloadService.isDownloading(_fileId);
        final progress =
            widget.downloadService.progress(_fileId);

        return GestureDetector(
          // Whole card is tappable only if downloaded → opens player
          onTap: isDownloaded ? _openPlayer : null,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.divider),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.goldLine,
                        border: Border.all(
                          color:
                              c.goldText.withOpacity(0.35),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.mic_rounded,
                        size: 20,
                        color: c.goldText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.reciter.nameAr,
                            textDirection: TextDirection.rtl,
                            style: AppText.arabic(
                              color: c.textPrimary,
                              size: 14,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.reciter
                                .nameFor(widget.language),
                            style: AppText.latin(
                              color: c.textMuted,
                              size: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Download / Play / Cancel button
                    GestureDetector(
                      onTap: () {
                        if (isDownloading) {
                          widget.downloadService
                              .cancelDownload(_fileId);
                        } else if (isDownloaded) {
                          _openPlayer();
                        } else {
                          _startDownload();
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
                                  ? c.goldText
                                  : c.goldText
                                      .withOpacity(0.12),
                          border: Border.all(
                            color: isDownloading
                                ? c.danger.withOpacity(0.3)
                                : isDownloaded
                                    ? c.goldText
                                    : c.goldText
                                        .withOpacity(0.3),
                          ),
                        ),
                        child: isDownloading
                            ? Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: c.danger,
                              )
                            : Icon(
                                isDownloaded
                                    ? Icons
                                        .play_arrow_rounded
                                    : Icons
                                        .download_rounded,
                                size: 20,
                                color: isDownloaded
                                    ? Colors.white
                                    : c.goldText,
                              ),
                      ),
                    ),
                  ],
                ),

                if (isDownloading) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      backgroundColor: c.surface2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                              c.goldText),
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

// ─── Teachers Section (Tafseer) ──────────────────────────
// Teachers keep the lessons screen flow (multiple parts).

class _TeachersSection extends StatelessWidget {
  final Surah surah;
  final SurahMeta meta;
  final CatalogService catalogService;
  final AppColors colors;
  final String language;

  const _TeachersSection({
    required this.surah,
    required this.meta,
    required this.catalogService,
    required this.colors,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    final teacherPairs = surah.teachers
        .map((ta) {
          final t = catalogService.teacherById(ta.teacherId);
          if (t == null) return null;
          return (teacher: t, audio: ta);
        })
        .whereType<({Teacher teacher, TeacherAudio audio})>()
        .toList();

    if (teacherPairs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.school_rounded,
                size: 14, color: c.brand),
            const SizedBox(width: 6),
            Text(
              'TEACHERS · TAFSEER',
              style: AppText.label(color: c.textFaint),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Scholars who explain and teach this Surah.',
          style: AppText.latin(
            color: c.textMuted,
            size: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        ...teacherPairs.map((pair) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TeacherCard(
              teacher: pair.teacher,
              audio: pair.audio,
              colors: c,
              language: language,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SurahLessonsScreen.teacher(
                      meta: meta,
                      teacher: pair.teacher,
                      teacherAudio: pair.audio,
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final Teacher teacher;
  final TeacherAudio audio;
  final AppColors colors;
  final String language;
  final VoidCallback onTap;

  const _TeacherCard({
    required this.teacher,
    required this.audio,
    required this.colors,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.brand.withOpacity(0.12),
                border: Border.all(
                  color: c.brand.withOpacity(0.25),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                teacher.initials,
                textDirection: TextDirection.rtl,
                style: AppText.arabic(
                  color: c.brand,
                  size: 14,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher.nameAr,
                    textDirection: TextDirection.rtl,
                    style: AppText.arabic(
                      color: c.textPrimary,
                      size: 14,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    teacher.nameFor(language),
                    style: AppText.latin(
                      color: c.textMuted,
                      size: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: c.brand.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: c.brand.withOpacity(0.25),
                ),
              ),
              child: Text(
                '${audio.totalParts} parts',
                style: AppText.latin(
                  color: c.brand,
                  size: 10,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nothing Yet ─────────────────────────────────────────

class _NothingYet extends StatelessWidget {
  final AppColors colors;
  const _NothingYet({required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.divider),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            color: c.textFaint,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Content for this Surah is being prepared. Please check back soon.',
              style: AppText.latin(
                color: c.textMuted,
                size: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
