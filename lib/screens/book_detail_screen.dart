
import 'dart:io';
import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/catalog_service.dart';
import '../core/cover_service.dart';
import '../core/download_service.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/book_cover.dart';
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
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius: AppRadius.buttonRadius,
                        border: Border.all(color: c.divider),
                      ),
                      child: Icon(Icons.arrow_back_rounded, size: 18, color: c.textPrimary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Book Details',
                      style: AppText.latin(color: c.textPrimary, size: 18, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.base),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCard(book: book, colors: c, coverService: state.coverService, downloadService: state.downloadService),
                    const SizedBox(height: AppSpacing.lg),
                    _PdfSection(book: book, colors: c, downloadService: state.downloadService, coverService: state.coverService),
                    const SizedBox(height: AppSpacing.lg),
                    if (book.hasAudio && book.teacherAudio.isNotEmpty)
                      _TeachersSection(
                        book: book,
                        catalogService: catalogService,
                        colors: c,
                        language: state.language,
                        downloadService: state.downloadService,
                        onTeacherTap: (teacher) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LessonsScreen(book: book, teacher: teacher),
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

class _HeroCard extends StatelessWidget {
  final Book book;
  final AppColors colors;
  final CoverService coverService;
  final DownloadService downloadService;
  const _HeroCard({required this.book, required this.colors, required this.coverService, required this.downloadService});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return ListenableBuilder(
      listenable: Listenable.merge([coverService, downloadService]),
      builder: (context, _) {
        final realPages = coverService.pageCount(book.id);
        return Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(color: c.goldLine, width: 1.5),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookCoverWidget(book: book, width: 80, height: 108, borderRadius: AppRadius.input),
                  const SizedBox(width: AppSpacing.base),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (book.isNew || book.isRecentlyAdded)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                              decoration: BoxDecoration(
                                color: c.brand.withOpacity(0.12),
                                borderRadius: AppRadius.pillRadius,
                                border: Border.all(color: c.brand.withOpacity(0.3)),
                              ),
                              child: Text('NEW', style: AppText.label(color: c.brand)),
                            ),
                          ),
                        Text(book.titleAr, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: AppText.arabic(color: c.textPrimary, size: 16, weight: FontWeight.w700, height: 1.6)),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm - 2,
                          runSpacing: AppSpacing.xs,
                          alignment: WrapAlignment.end,
                          children: book.branches.map((branchId) {
                            final branch = Catalog.branches.firstWhere((b) => b.id == branchId, orElse: () => const Branch(id: '', nameEn: '', nameAr: '', nameAm: ''));
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                              decoration: BoxDecoration(color: c.brand.withOpacity(0.08), borderRadius: AppRadius.pillRadius, border: Border.all(color: c.brand.withOpacity(0.2))),
                              child: Text(branch.nameEn, style: AppText.latin(color: c.brand, size: 10, weight: FontWeight.w600)),
                            );
                          }).toList(),
                        ),
                        if (realPages != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            Icon(Icons.menu_book_outlined, size: 13, color: c.textFaint),
                            const SizedBox(width: AppSpacing.xs),
                            Text('$realPages pages', style: AppText.latin(color: c.textFaint, size: 12)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.base),
              Divider(color: c.divider, height: 1),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AUTHOR', style: AppText.label(color: c.textFaint)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(book.authorAr, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: AppText.arabic(color: c.goldText, size: 14, weight: FontWeight.w700)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(book.authorEn, textAlign: TextAlign.right, style: AppText.latin(color: c.textMuted, size: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PdfSection extends StatefulWidget {
  final Book book;
  final AppColors colors;
  final DownloadService downloadService;
  final CoverService coverService;
  const _PdfSection({required this.book, required this.colors, required this.downloadService, required this.coverService});
  @override
  State<_PdfSection> createState() => _PdfSectionState();
}

class _PdfSectionState extends State<_PdfSection> {
  String? _errorMessage;
  String get _fileId => DownloadService.pdfId(widget.book.id);

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return ListenableBuilder(
      listenable: Listenable.merge([widget.downloadService, widget.coverService]),
      builder: (context, _) {
        final isDownloaded = widget.downloadService.isDownloaded(_fileId);
        final isDownloading = widget.downloadService.isDownloading(_fileId);
        final progress = widget.downloadService.progress(_fileId);
        final hasUrl = widget.book.pdfUrl.isNotEmpty;
        final realPages = widget.coverService.pageCount(widget.book.id);
        final realSize = widget.coverService.fileSizeMb(widget.book.id);

        String? subtitle;
        if (realSize != null && realPages != null) {
          subtitle = '${CoverService.formatSize(realSize)} · $realPages pages';
        } else if (realSize != null) {
          subtitle = CoverService.formatSize(realSize);
        } else if (realPages != null) {
          subtitle = '$realPages pages';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PDF Book', style: AppText.latin(color: c.textPrimary, size: 15, weight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () async {
                if (isDownloaded && !isDownloading) {
                  final path = await widget.downloadService.localPath(_fileId);
                  if (path != null && context.mounted) Navigator.of(context).push(MaterialPageRoute(builder: (_) => PdfReaderScreen(book: widget.book, filePath: path)));
                } else if (!isDownloading && hasUrl) {
                  setState(() => _errorMessage = null);
                  widget.downloadService.download(fileId: _fileId, url: widget.book.pdfUrl, displayName: widget.book.titleAr, bookId: widget.book.id, onError: (e) => setState(() => _errorMessage = e), onComplete: () => setState(() {}));
                }
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(color: c.card, borderRadius: AppRadius.cardRadius, border: Border.all(color: isDownloaded ? c.brand.withOpacity(0.4) : c.goldLine, width: 1.5)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: isDownloaded ? c.brand : !hasUrl ? c.surface2 : c.brand.withOpacity(0.12), border: Border.all(color: isDownloaded ? c.brand : !hasUrl ? c.divider : c.brand.withOpacity(0.3), width: 1.5)),
                          child: isDownloading
                              ? Padding(padding: const EdgeInsets.all(14), child: CircularProgressIndicator(value: progress > 0 ? progress : null, strokeWidth: 2, color: c.brand))
                              : Icon(isDownloaded ? Icons.menu_book_rounded : !hasUrl ? Icons.hourglass_empty_rounded : Icons.download_rounded, size: 22, color: isDownloaded ? Colors.white : !hasUrl ? c.textFaint : c.brand),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isDownloaded ? 'Tap to Open Book' : isDownloading ? 'Downloading...' : !hasUrl ? 'Coming Soon' : 'Tap to Download', style: AppText.latin(color: isDownloaded ? c.brand : c.textPrimary, size: 14, weight: FontWeight.w700)),
                              if (subtitle != null) ...[const SizedBox(height: AppSpacing.xs), Text(subtitle, style: AppText.latin(color: c.textMuted, size: 12))],
                              if (isDownloaded) ...[const SizedBox(height: AppSpacing.xs), Text('Downloaded · Tap anywhere to read', style: AppText.latin(color: c.brand, size: 11))],
                            ],
                          ),
                        ),
                        if (isDownloading)
                          GestureDetector(onTap: () => widget.downloadService.cancelDownload(_fileId), child: Container(width: 34, height: 34, decoration: BoxDecoration(color: c.dangerBg, borderRadius: AppRadius.buttonRadius, border: Border.all(color: c.danger.withOpacity(0.3))), child: Icon(Icons.close_rounded, size: 16, color: c.danger)))
                        else
                          Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs), decoration: BoxDecoration(color: c.brand.withOpacity(0.1), borderRadius: AppRadius.pillRadius, border: Border.all(color: c.brand.withOpacity(0.25))), child: Text('Free', style: AppText.latin(color: c.brand, size: 12, weight: FontWeight.w700))),
                      ],
                    ),
                    if (isDownloading) ...[
                      const SizedBox(height: AppSpacing.md),
                      ClipRRect(borderRadius: AppRadius.pillRadius, child: LinearProgressIndicator(value: progress > 0 ? progress : null, backgroundColor: c.surface2, valueColor: AlwaysStoppedAnimation<Color>(c.brand), minHeight: 4)),
                      const SizedBox(height: AppSpacing.sm - 2),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(progress > 0 ? '${(progress * 100).toInt()}%' : 'Connecting...', style: AppText.latin(color: c.brand, size: 11, weight: FontWeight.w600)), Text('Tap × to cancel', style: AppText.latin(color: c.textFaint, size: 10))]),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(padding: const EdgeInsets.all(AppSpacing.sm), decoration: BoxDecoration(color: c.dangerBg, borderRadius: AppRadius.listItemRadius, border: Border.all(color: c.danger.withOpacity(0.3))), child: Row(children: [Icon(Icons.error_outline_rounded, color: c.danger, size: 14), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(_errorMessage!, style: AppText.latin(color: c.danger, size: 12))), GestureDetector(onTap: () => setState(() => _errorMessage = null), child: Icon(Icons.close_rounded, color: c.danger, size: 14))])),
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

class _TeachersSection extends StatelessWidget {
  final Book book;
  final CatalogService catalogService;
  final AppColors colors;
  final String language;
  final DownloadService downloadService;
  final Function(Teacher) onTeacherTap;
  const _TeachersSection({required this.book, required this.catalogService, required this.colors, required this.language, required this.downloadService, required this.onTeacherTap});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final teachers = book.teacherAudio.map((ta) => catalogService.teacherById(ta.teacherId)).whereType<Teacher>().toList();
    if (teachers.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TEACHING SCHOLARS', style: AppText.label(color: c.textFaint)),
        const SizedBox(height: AppSpacing.xs + 2),
        Text('These scholars provide audio explanations for this book.', style: AppText.latin(color: c.textMuted, size: 12, height: 1.5)),
        const SizedBox(height: AppSpacing.md),
        ...teachers.map((t) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: _TeacherCard(teacher: t, colors: c, language: language, downloadService: downloadService, onTap: () => onTeacherTap(t)))),
      ],
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final Teacher teacher;
  final AppColors colors;
  final String language;
  final DownloadService downloadService;
  final VoidCallback onTap;
  const _TeacherCard({required this.teacher, required this.colors, required this.language, required this.downloadService, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: c.card, borderRadius: AppRadius.cardRadius, border: Border.all(color: c.divider)),
        child: Row(
          children: [
            ListenableBuilder(listenable: downloadService, builder: (context, _) => TeacherAvatar(teacher: teacher, downloadService: downloadService, colors: c, size: 48)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(teacher.nameAr, textDirection: TextDirection.rtl, style: AppText.arabic(color: c.textPrimary, size: 14, weight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(teacher.nameFor(language), style: AppText.latin(color: c.textMuted, size: 12)),
                ],
              ),
            ),
            Container(width: 34, height: 34, decoration: BoxDecoration(color: c.goldLine, borderRadius: AppRadius.buttonRadius, border: Border.all(color: c.goldText.withOpacity(0.3))), child: Icon(Icons.headphones_rounded, size: 16, color: c.goldText)),
          ],
        ),
      ),
    );
  }
}

class TeacherAvatar extends StatelessWidget {
  final Teacher teacher;
  final DownloadService downloadService;
  final AppColors colors;
  final double size;
  const TeacherAvatar({super.key, required this.teacher, required this.downloadService, required this.colors, required this.size});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final state = AppState.of(context);
    final path = downloadService.photoLocalPath(teacher.id, state.appDocsPath);
    final file = File(path);

    if (downloadService.hasPhoto(teacher.id) && file.existsSync()) {
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.brand.withOpacity(0.25), width: 1.5)),
        child: ClipOval(child: Image.file(file, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _InitialsCircle(teacher: teacher, colors: c, size: size))),
      );
    }
    return _InitialsCircle(teacher: teacher, colors: c, size: size);
  }
}

class _InitialsCircle extends StatelessWidget {
  final Teacher teacher;
  final AppColors colors;
  final double size;
  const _InitialsCircle({required this.teacher, required this.colors, required this.size});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: c.brand.withOpacity(0.12), border: Border.all(color: c.brand.withOpacity(0.25))),
      alignment: Alignment.center,
      child: Text(teacher.initials, textDirection: TextDirection.rtl, style: AppText.arabic(color: c.brand, size: size * 0.28, weight: FontWeight.w700)),
    );
  }
}
