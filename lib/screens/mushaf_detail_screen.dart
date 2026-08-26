import 'dart:io';
import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/download_service.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/book_cover.dart';
import 'book_detail_screen.dart';
import 'mushaf_reader_screen.dart';

/// Detail screen for the Full Mus'haf sub-branch.
class MushafDetailScreen extends StatelessWidget {
  final QuranSubBranch sub;

  const MushafDetailScreen({
    super.key,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);
    final lang = state.language;

    final editions = sub.editions;
    final books = sub.books;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.base,
                AppSpacing.base,
                0,
              ),
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
                            AppRadius.buttonRadius,
                        border: Border.all(
                            color: c.divider),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(
                      width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      sub.titleAr,
                      textDirection:
                          TextDirection.rtl,
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

            const SizedBox(height: AppSpacing.base),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base,
                  0,
                  AppSpacing.base,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _QuranHeroCard(
                      colors: c,
                      language: lang,
                    ),
                    const SizedBox(
                        height: AppSpacing.lg),

                    if (editions.isNotEmpty) ...[
                      _SectionHeader(
                        titleEn: editions.length > 1
                            ? 'Mus\'haf Editions'
                            : 'Full Mus\'haf PDF',
                        titleAr: editions.length > 1
                            ? 'إصدارات المصحف'
                            : 'المصحف الشريف',
                        colors: c,
                        language: lang,
                      ),
                      const SizedBox(
                          height: AppSpacing.sm),
                      ...editions.map((ed) => Padding(
                            padding:
                                const EdgeInsets.only(
                                    bottom:
                                        AppSpacing.md),
                            child: _EditionCard(
                              edition: ed,
                              colors: c,
                              language: lang,
                              downloadService:
                                  state.downloadService,
                            ),
                          )),
                    ] else ...[
                      _NoEditions(colors: c),
                    ],

                    if (books.isNotEmpty) ...[
                      const SizedBox(
                          height: AppSpacing.lg),
                      _SectionHeader(
                        titleEn: 'Books',
                        titleAr: 'كتب',
                        colors: c,
                        language: lang,
                      ),
                      const SizedBox(
                          height: AppSpacing.sm),
                      ...books.map((b) => Padding(
                            padding:
                                const EdgeInsets.only(
                                    bottom:
                                        AppSpacing.md),
                            child: _BookCard(
                              book: b,
                              colors: c,
                            ),
                          )),
                    ],

                    if (editions.isNotEmpty) ...[
                      const SizedBox(
                          height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(
                            AppSpacing.md),
                        decoration: BoxDecoration(
                          color: c.goldLine,
                          borderRadius:
                              AppRadius.listItemRadius,
                          border: Border.all(
                            color: c.goldText
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .info_outline_rounded,
                              color: c.goldText,
                              size: 16,
                            ),
                            const SizedBox(
                                width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'A full Mus\'haf PDF can be between 100–300 MB depending on the edition. Make sure you have enough storage and a stable internet connection.',
                                style: AppText.latin(
                                  color: c.goldText,
                                  size: 11,
                                  weight:
                                      FontWeight.w600,
                                  height: 1.5,
                                ),
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
        ),
      ),
    );
  }
}

// ─── Quran Hero Card ─────────────────────────────────────

class _QuranHeroCard extends StatelessWidget {
  final AppColors colors;
  final String language;

  const _QuranHeroCard({
    required this.colors,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final isAr = language == 'ar';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardRadius,
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: c.goldText.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: c.goldText.withOpacity(0.2),
                  blurRadius: 16,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/mushaf.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(
                  color:
                      c.goldText.withOpacity(0.15),
                  child: Icon(
                    Icons.import_contacts_rounded,
                    size: 36,
                    color: c.goldText,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'القرآن الكريم',
            textDirection: TextDirection.rtl,
            style: AppText.arabic(
              color: c.goldText,
              size: 26,
              weight: FontWeight.w700,
              height: 1.4,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            'The Noble Quran',
            style: AppText.latin(
              color: c.goldText.withOpacity(0.8),
              size: 13,
              weight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: AppSpacing.base),
          Divider(
              color: c.goldText.withOpacity(0.2),
              height: 1),
          const SizedBox(height: AppSpacing.base),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
            children: [
              _FactChip(
                icon: Icons
                    .format_list_numbered_rounded,
                value: '114',
                label: isAr ? 'سورة' : 'Surahs',
                colors: c,
              ),
              _FactChip(
                icon: Icons.text_snippet_rounded,
                value: '6,236',
                label: isAr ? 'آية' : 'Ayat',
                colors: c,
              ),
              _FactChip(
                icon: Icons.access_time_rounded,
                value: '23',
                label: isAr ? 'سنة' : 'Years',
                colors: c,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
            children: [
              _FactChip(
                icon: Icons.location_on_outlined,
                value: '86',
                label: isAr ? 'مكية' : 'Meccan',
                colors: c,
              ),
              _FactChip(
                icon: Icons.location_on_outlined,
                value: '28',
                label: isAr ? 'مدنية' : 'Medinan',
                colors: c,
              ),
              _FactChip(
                icon: Icons.person_outline_rounded,
                value: isAr
                    ? 'محمد ﷺ'
                    : 'Muhammad ﷺ',
                label:
                    isAr ? 'أُنزل على' : 'Revealed to',
                colors: c,
                small: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final AppColors colors;
  final bool small;

  const _FactChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.colors,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Column(
      children: [
        Icon(icon, size: 16, color: c.goldText),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          textDirection: TextDirection.rtl,
          style: AppText.latin(
            color: c.goldText,
            size: small ? 11 : 14,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textDirection: TextDirection.rtl,
          style: AppText.latin(
            color: c.goldText.withOpacity(0.7),
            size: 10,
          ),
        ),
      ],
    );
  }
}

// ─── Section Header ───────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String titleEn;
  final String titleAr;
  final AppColors colors;
  final String language;

  const _SectionHeader({
    required this.titleEn,
    required this.titleAr,
    required this.colors,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final isAr = language == 'ar';
    return Text(
      isAr ? titleAr : titleEn,
      textDirection:
          isAr ? TextDirection.rtl : TextDirection.ltr,
      style: isAr
          ? AppText.arabic(
              color: c.textPrimary,
              size: 15,
              weight: FontWeight.w700,
            )
          : AppText.latin(
              color: c.textPrimary,
              size: 15,
              weight: FontWeight.w700,
            ),
    );
  }
}

// ─── No Editions ─────────────────────────────────────────

class _NoEditions extends StatelessWidget {
  final AppColors colors;
  const _NoEditions({required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: AppRadius.listItemRadius,
        border: Border.all(color: c.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty_rounded,
              color: c.textFaint, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'No Mus\'haf editions available yet. Check back soon.',
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

// ─── Edition Card ─────────────────────────────────────────

class _EditionCard extends StatefulWidget {
  final MushafEdition edition;
  final AppColors colors;
  final String language;
  final DownloadService downloadService;

  const _EditionCard({
    required this.edition,
    required this.colors,
    required this.language,
    required this.downloadService,
  });

  @override
  State<_EditionCard> createState() =>
      _EditionCardState();
}

class _EditionCardState extends State<_EditionCard> {
  String? _errorMessage;

  String get _fileId =>
      widget.edition.id == 'mushaf'
          ? 'pdf_mushaf'
          : 'pdf_mushaf_${widget.edition.id}';

  Future<void> _openReader(
      BuildContext context) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MushafReaderScreen(
          edition: widget.edition,
        ),
      ),
    );
  }

  Future<void> _startDownload() async {
    setState(() => _errorMessage = null);

    if (widget.edition.pdfUrl.isEmpty) {
      setState(() => _errorMessage =
          'This Mus\'haf edition is not available yet.');
      return;
    }

    await widget.downloadService.download(
      fileId: _fileId,
      url: widget.edition.pdfUrl,
      displayName: widget.edition.titleAr,
      bookId: 'mushaf',
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
    final isAr = widget.language == 'ar';

    return ListenableBuilder(
      listenable: widget.downloadService,
      builder: (context, _) {
        final isDownloaded =
            widget.downloadService
                .isDownloaded(_fileId);
        final isDownloading =
            widget.downloadService
                .isDownloading(_fileId);
        final isQueued = widget.downloadService.isQueued(_fileId);
        final isPaused = widget.downloadService.isPaused(_fileId);
        final isAwaiting = widget.downloadService.isAwaitingNetwork(_fileId);
        final progress =
            widget.downloadService.progress(_fileId);
        final hasUrl =
            widget.edition.pdfUrl.isNotEmpty;

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
                        ? '$percent% downloaded'
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
          onTap: () {
            if (isDownloaded && !isActive) {
              _openReader(context);
            } else if (!isActive && hasUrl) {
              _startDownload();
            }
          },
          child: Container(
            padding:
                const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: AppRadius.cardRadius,
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
                            : !hasUrl
                                ? c.surface2
                                : c.brand
                                    .withOpacity(0.12),
                        border: Border.all(
                          color: isDownloaded
                              ? c.brand
                              : !hasUrl
                                  ? c.divider
                                  : c.brand
                                      .withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: isActive
                          ? Padding(
                              padding:
                                  const EdgeInsets.all(
                                      14),
                              child:
                                  CircularProgressIndicator(
                                value: (progress > 0 && !isQueued && !isAwaiting)
                                    ? progress
                                    : null,
                                strokeWidth: 2,
                                color: c.brand,
                              ),
                            )
                          : Icon(
                              isDownloaded
                                  ? Icons
                                      .menu_book_rounded
                                  : !hasUrl
                                      ? Icons
                                          .hourglass_empty_rounded
                                      : Icons
                                          .download_rounded,
                              size: 22,
                              color: isDownloaded
                                  ? Colors.white
                                  : !hasUrl
                                      ? c.textFaint
                                      : c.brand,
                            ),
                    ),
                    const SizedBox(
                        width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: isAr
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.edition.titleAr,
                            textDirection:
                                TextDirection.rtl,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: AppText.arabic(
                              color: c.textPrimary,
                              size: 15,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(
                              height: AppSpacing.xs),
                          Text(
                            isDownloaded
                                ? 'Tap to Open'
                                : isActive
                                    ? statusLabel
                                    : !hasUrl
                                        ? 'Coming Soon'
                                        : 'Tap to Download',
                            style: AppText.latin(
                              color: isDownloaded
                                  ? c.brand
                                  : c.textMuted,
                              size: 11,
                              weight: FontWeight.w600,
                            ),
                          ),
                          if (isActive && speedKbps > 0 && !isPaused && !isQueued && !isAwaiting) ...[
                            const SizedBox(height: 2),
                            Text(DownloadService.formatSpeed(speedKbps), style: AppText.latin(color: c.brand, size: 11, weight: FontWeight.w600)),
                          ],
                        ],
                      ),
                    ),
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
                            width: 34, height: 34,
                            decoration: BoxDecoration(color: c.surface2, borderRadius: AppRadius.buttonRadius, border: Border.all(color: c.divider)),
                            child: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 18, color: c.textPrimary),
                          ),
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: () => widget
                            .downloadService
                            .cancelDownload(_fileId),
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
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: c.brand.withOpacity(0.1),
                          borderRadius:
                              AppRadius.pillRadius,
                          border: Border.all(
                            color: c.brand
                                .withOpacity(0.25),
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
                  ],
                ),

                if (isActive) ...[
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: AppRadius.pillRadius,
                    child: LinearProgressIndicator(
                      value: (progress > 0 && !isQueued && !isAwaiting)
                          ? progress
                          : null,
                      backgroundColor: c.surface2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(isPaused ? c.goldText : c.brand),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm - 2),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        statusLabel,
                        style: AppText.latin(
                          color: isPaused ? c.goldText : c.brand,
                          size: 11,
                          weight: FontWeight.w600,
                        ),
                      ),
                      if (sizeLabel.isNotEmpty)
                        Text(
                          sizeLabel,
                          style: AppText.latin(
                            color: c.textFaint,
                            size: 10,
                          ),
                        ),
                    ],
                  ),
                ],

                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(
                        AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: c.dangerBg,
                      borderRadius:
                          AppRadius.listItemRadius,
                      border: Border.all(
                        color:
                            c.danger.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                            Icons.error_outline_rounded,
                            color: c.danger,
                            size: 14),
                        const SizedBox(
                            width: AppSpacing.sm),
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
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Book Card ────────────────────────────────────────────

class _BookCard extends StatelessWidget {
  final Book book;
  final AppColors colors;

  const _BookCard({
    required this.book,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final state = AppState.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(
              book: book,
              catalogService: state.catalogService,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: c.divider),
        ),
        child: Row(
          children: [
            BookCoverWidget(
              book: book,
              width: 58,
              height: 78,
              borderRadius: AppRadius.input,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    book.titleAr,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.arabic(
                      color: c.textPrimary,
                      size: 14,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    book.authorShort,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.arabic(
                      color: c.textMuted,
                      size: 11,
                    ),
                  ),
                  if (book.teacherAudio.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.goldLine,
                        borderRadius:
                            AppRadius.pillRadius,
                        border: Border.all(
                          color: c.goldText
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.headphones_rounded,
                            size: 10,
                            color: c.goldText,
                          ),
                          const SizedBox(
                              width: AppSpacing.xs),
                          Text(
                            '${book.teacherAudio.length} teachers',
                            style: AppText.latin(
                              color: c.goldText,
                              size: 9,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
