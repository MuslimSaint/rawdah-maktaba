import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/catalog_service.dart';
import '../core/download_service.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'lessons_screen.dart';
import 'pdf_reader_screen.dart';

/// Full book detail screen.
class BookDetailScreen extends StatelessWidget {
  final Book book;
  final CatalogService catalogService;

  const BookDetailScreen({
    super.key,
    required this.book,
    required this.catalogService,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──
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
                      'Book Details',
                      style: AppText.latin(
                        color: c.textPrimary,
                        size: 18,
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
                    _HeroCard(book: book, colors: c),
                    const SizedBox(height: 20),
                    _PdfSection(
                      book: book,
                      colors: c,
                      downloadService: state.downloadService,
                    ),
                    const SizedBox(height: 20),
                    if (book.hasAudio && book.teacherIds.isNotEmpty)
                      _TeachersSection(
                        book: book,
                        catalogService: catalogService,
                        colors: c,
                        language: state.language,
                        onTeacherTap: (teacher) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LessonsScreen(
                                book: book,
                                teacher: teacher,
                              ),
                            ),
                          );
                        },
                      ),
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

// ─── Hero Card ───────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final Book book;
  final AppColors colors;

  const _HeroCard({required this.book, required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.goldLine, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 108,
                decoration: BoxDecoration(
                  color: c.brand.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.brand.withOpacity(0.2)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    book.localCoverAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 36,
                        color: c.brand,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (book.isNew || book.isRecentlyAdded)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: c.brand.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: c.brand.withOpacity(0.3),
                            ),
                          ),
                          child:
                              Text('NEW', style: AppText.label(color: c.brand)),
                        ),
                      ),
                    Text(
                      book.titleAr,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppText.arabic(
                        color: c.textPrimary,
                        size: 16,
                        weight: FontWeight.w700,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      alignment: WrapAlignment.end,
                      children: book.branches.map((branchId) {
                        final branch = Catalog.branches.firstWhere(
                          (b) => b.id == branchId,
                          orElse: () => const Branch(
                            id: '',
                            nameEn: '',
                            nameAr: '',
                            nameAm: '',
                          ),
                        );
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: c.brand.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: c.brand.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            branch.nameEn,
                            style: AppText.latin(
                              color: c.brand,
                              size: 10,
                              weight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.menu_book_outlined,
                            size: 13, color: c.textFaint),
                        const SizedBox(width: 4),
                        Text(
                          '${book.pages} pages',
                          style:
                              AppText.latin(color: c.textFaint, size: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: c.divider, height: 1),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AUTHOR', style: AppText.label(color: c.textFaint)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      book.authorAr,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppText.arabic(
                        color: c.goldText,
                        size: 14,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.authorEn,
                      textAlign: TextAlign.right,
                      style: AppText.latin(color: c.textMuted, size: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── PDF Section ─────────────────────────────────────────

class _PdfSection extends StatefulWidget {
  final Book book;
  final AppColors colors;
  final DownloadService downloadService;

  const _PdfSection({
    required this.book,
    required this.colors,
    required this.downloadService,
  });

  @override
  State<_PdfSection> createState() => _PdfSectionState();
}

class _PdfSectionState extends State<_PdfSection> {
  String? _errorMessage;

  String get _fileId => DownloadService.pdfId(widget.book.id);

  Future<void> _openBook(BuildContext context) async {
    // First check DownloadService
    if (!widget.downloadService.isDownloaded(_fileId)) {
      setState(() => _errorMessage =
          'File not found. Please download again.');
      return;
    }

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
          book: widget.book,
          filePath: path,
        ),
      ),
    );
  }

  Future<void> _startDownload() async {
    setState(() => _errorMessage = null);
    await widget.downloadService.download(
      fileId: _fileId,
      url: widget.book.pdfUrl,
      displayName: widget.book.titleAr,
      bookId: widget.book.id,
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

    return ListenableBuilder(
      listenable: widget.downloadService,
      builder: (context, _) {
        final isDownloaded =
            widget.downloadService.isDownloaded(_fileId);
        final isDownloading =
            widget.downloadService.isDownloading(_fileId);
        final progress =
            widget.downloadService.progress(_fileId);
        final hasUrl = widget.book.pdfUrl.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PDF Book',
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
                  _openBook(context);
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
                        // Status circle
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
                                  child: CircularProgressIndicator(
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
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                isDownloaded
                                    ? 'Tap to Open Book'
                                    : isDownloading
                                        ? 'Downloading...'
                                        : !hasUrl
                                            ? 'Coming Soon'
                                            : 'Tap to Download',
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
                                '${widget.book.pdfSizeMb} MB · ${widget.book.pages} pages',
                                style: AppText.latin(
                                  color: c.textMuted,
                                  size: 12,
                                ),
                              ),
                              if (isDownloaded) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Downloaded · Tap anywhere to read',
                                  style: AppText.latin(
                                    color: c.brand,
                                    size: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Cancel button when downloading
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
                                  color: c.danger.withOpacity(0.3),
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: c.danger,
                              ),
                            ),
                          )
                        else
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

                    // Progress bar + speed
                    if (isDownloading) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress > 0 ? progress : null,
                          backgroundColor: c.surface2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(c.brand),
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
                          Text(
                            'Tap × to cancel',
                            style: AppText.latin(
                              color: c.textFaint,
                              size: 10,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Error
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
                              onTap: () => setState(
                                  () => _errorMessage = null),
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
      },
    );
  }
}

// ─── Teachers Section ────────────────────────────────────

class _TeachersSection extends StatelessWidget {
  final Book book;
  final CatalogService catalogService;
  final AppColors colors;
  final String language;
  final Function(Teacher) onTeacherTap;

  const _TeachersSection({
    required this.book,
    required this.catalogService,
    required this.colors,
    required this.language,
    required this.onTeacherTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    final teachers = book.teacherIds
        .map((id) => catalogService.teacherById(id))
        .where((t) => t != null)
        .cast<Teacher>()
        .toList();

    if (teachers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TEACHING SCHOLARS',
            style: AppText.label(color: c.textFaint)),
        const SizedBox(height: 6),
        Text(
          'These scholars provide audio explanations for this book.',
          style: AppText.latin(
            color: c.textMuted,
            size: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ...teachers.map((teacher) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TeacherCard(
              teacher: teacher,
              colors: c,
              language: language,
              onTap: () => onTeacherTap(teacher),
            ),
          );
        }),
      ],
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final Teacher teacher;
  final AppColors colors;
  final String language;
  final VoidCallback onTap;

  const _TeacherCard({
    required this.teacher,
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
                border: Border.all(color: c.brand.withOpacity(0.25)),
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
                    style:
                        AppText.latin(color: c.textMuted, size: 12),
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: c.goldLine,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: c.goldText.withOpacity(0.3)),
              ),
              child: Icon(Icons.headphones_rounded,
                  size: 16, color: c.goldText),
            ),
          ],
        ),
      ),
    );
  }
}
