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
/// Shows the Quran facts hero + a list of downloadable
/// Mus'haf editions + any bonus books.
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: c.divider),
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
                      sub.titleAr,
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuranHeroCard(
                      colors: c,
                      language: lang,
                    ),
                    const SizedBox(height: 20),

                    // ── Editions section ──
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
                      const SizedBox(height: 10),
                      ...editions.map((ed) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 12),
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

                    // ── Bonus books section ──
                    if (books.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _SectionHeader(
                        titleEn: 'Books',
                        titleAr: 'كتب',
                        colors: c,
                        language: lang,
                      ),
                      const SizedBox(height: 10),
                      ...books.map((b) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 12),
                            child: _BookCard(
                              book: b,
                              colors: c,
                            ),
                          )),
                    ],

                    // ── File size warning ──
                    if (editions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
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
                              color: c.goldText,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'A full Mus\'haf PDF can be between 100–300 MB depending on the edition. Make sure you have enough storage and a stable internet connection.',
                                style: AppText.latin(
                                  color: c.goldText,
                                  size: 11,
                                  weight: FontWeight.w600,
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

// ─── Quran Hero Card with Facts ──────────────────────────

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
      padding: const EdgeInsets.all(20),
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
                errorBuilder: (_, __, ___) => Container(
                  color: c.goldText.withOpacity(0.15),
                  child: Icon(
                    Icons.import_contacts_rounded,
                    size: 36,
                    color: c.goldText,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

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

          const SizedBox(height: 4),

          Text(
            'The Noble Quran',
            style: AppText.latin(
              color: c.goldText.withOpacity(0.8),
              size: 13,
              weight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),
          Divider(
              color: c.goldText.withOpacity(0.2), height: 1),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _FactChip(
                icon: Icons.format_list_numbered_rounded,
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

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                value: isAr ? 'محمد ﷺ' : 'Muhammad ﷺ',
                label: isAr ? 'أُنزل على' : 'Revealed to',
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
        const SizedBox(height: 4),
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

// ─── Section Header ──────────────────────────────────────

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

// ─── No Editions Placeholder ─────────────────────────────

class _NoEditions extends StatelessWidget {
  final AppColors colors;
  const _NoEditions({required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty_rounded,
              color: c.textFaint, size: 20),
          const SizedBox(width: 10),
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

// ─── Edition Card ────────────────────────────────────────

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
  State<_EditionCard> createState() => _EditionCardState();
}

class _EditionCardState extends State<_EditionCard> {
  String? _errorMessage;

  String get _fileId => widget.edition.id == 'mushaf'
      ? 'pdf_mushaf'
      : 'pdf_mushaf_${widget.edition.id}';

  Future<void> _openReader(BuildContext context) async {
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
            widget.downloadService.isDownloaded(_fileId);
        final isDownloading =
            widget.downloadService.isDownloading(_fileId);
        final progress =
            widget.downloadService.progress(_fileId);
        final hasUrl = widget.edition.pdfUrl.isNotEmpty;

        return GestureDetector(
          onTap: () {
            if (isDownloaded && !isDownloading) {
              _openReader(context);
            } else if (!isDownloading && hasUrl) {
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
                            : !hasUrl
                                ? c.surface2
                                : c.brand.withOpacity(0.12),
                        border: Border.all(
                          color: isDownloaded
                              ? c.brand
                              : !hasUrl
                                  ? c.divider
                                  : c.brand.withOpacity(0.3),
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
                                  : !hasUrl
                                      ? Icons
                                          .hourglass_empty_rounded
                                      : Icons.download_rounded,
                              size: 22,
                              color: isDownloaded
                                  ? Colors.white
                                  : !hasUrl
                                      ? c.textFaint
                                      : c.brand,
                            ),
                    ),
                    const SizedBox(width: 14),
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
                            overflow: TextOverflow.ellipsis,
                            style: AppText.arabic(
                              color: c.textPrimary,
                              size: 15,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isDownloaded
                                ? 'Tap to Open'
                                : isDownloading
                                    ? 'Downloading...'
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
                        borderRadius:
                            BorderRadius.circular(8),
                        border: Border.all(
                          color: c.brand.withOpacity(0.25),
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

                if (isDownloading) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      backgroundColor: c.surface2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                              c.brand),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        progress > 0
                            ? '${(progress * 100).toInt()}%'
                            : 'Connecting...',
                        style: AppText.latin(
                          color: c.brand,
                          size: 11,
                          weight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => widget.downloadService
                            .cancelDownload(_fileId),
                        child: Text(
                          'Cancel',
                          style: AppText.latin(
                            color: c.danger,
                            size: 11,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: c.dangerBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: c.danger.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: c.danger, size: 14),
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
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Book Card (regular books inside the Quran sub-branch) ──

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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.divider),
        ),
        child: Row(
          children: [
            BookCoverWidget(
              book: book,
              width: 58,
              height: 78,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
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
                  const SizedBox(height: 4),
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
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.goldLine,
                        borderRadius:
                            BorderRadius.circular(6),
                        border: Border.all(
                          color:
                              c.goldText.withOpacity(0.3),
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
                          const SizedBox(width: 3),
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
