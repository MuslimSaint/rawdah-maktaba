import 'dart:io';
import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/arabic_utils.dart';
import '../core/catalog_service.dart';
import '../core/download_service.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'book_detail_screen.dart' show TeacherAvatar;
import 'pdf_reader_screen.dart';
import 'surah_lessons_screen.dart';
import 'surah_audio_player_screen.dart';

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
          listenable: Listenable.merge([state.catalogService, state.downloadService]),
          builder: (context, _) {
            final surah = state.catalogService.quran.surahFor(meta.number);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base, AppSpacing.base, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(color: c.surface2, borderRadius: AppRadius.buttonRadius, border: Border.all(color: c.divider)),
                          child: Icon(Icons.arrow_back_rounded, size: 18, color: c.textPrimary),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(meta.nameAr, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: AppText.arabic(color: c.goldText, size: 20, weight: FontWeight.w700))),
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
                        _HeroCard(meta: meta, colors: c, language: state.language),
                        const SizedBox(height: AppSpacing.lg),
                        _PdfSection(meta: meta, surah: surah, colors: c, downloadService: state.downloadService, catalogService: state.catalogService),
                        const SizedBox(height: AppSpacing.lg),
                        if (surah.hasReciters) _RecitersSection(surah: surah, meta: meta, catalogService: state.catalogService, downloadService: state.downloadService, colors: c, language: state.language),
                        if (surah.hasReciters && surah.hasTeachers) const SizedBox(height: AppSpacing.lg),
                        if (surah.hasTeachers) _TeachersSection(surah: surah, meta: meta, catalogService: state.catalogService, downloadService: state.downloadService, colors: c, language: state.language),
                        if (!surah.hasReciters && !surah.hasTeachers && !surah.hasPdf) _NothingYet(colors: c),
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

class _HeroCard extends StatelessWidget {
  final SurahMeta meta;
  final AppColors colors;
  final String language;
  const _HeroCard({required this.meta, required this.colors, required this.language});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final trans = meta.transliterationFor(language);
    final placeAr = meta.revelationPlace == 'meccan' ? 'مكية' : 'مدنية';
    final placeLatin = meta.revelationPlace == 'meccan' ? 'Meccan' : 'Medinan';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(borderRadius: AppRadius.cardRadius, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.goldLine, c.gold.withOpacity(0.28), c.goldLine]), border: Border.all(color: c.goldText.withOpacity(0.4), width: 1.5)),
      child: Column(
        children: [
          Container(
            width: 76, height: 76,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.goldText.withOpacity(0.5), width: 2), boxShadow: [BoxShadow(color: c.goldText.withOpacity(0.2), blurRadius: 14)]),
            child: ClipOval(child: Image.asset('assets/mushaf.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: c.goldText.withOpacity(0.15), alignment: Alignment.center, child: Icon(Icons.import_contacts_rounded, size: 32, color: c.goldText)))),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(meta.nameAr, textDirection: TextDirection.rtl, style: AppText.arabic(color: c.goldText, size: 28, weight: FontWeight.w700, height: 1.4)),
          if (trans != null) ...[const SizedBox(height: AppSpacing.xs), Text(trans, style: AppText.latin(color: c.goldText.withOpacity(0.85), size: 14, weight: FontWeight.w600))],
          const SizedBox(height: AppSpacing.md),
          Divider(color: c.goldText.withOpacity(0.2), height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MetaChip(icon: Icons.format_list_numbered_rounded, labelLatin: '${meta.ayahCount} Ayat', labelAr: '${meta.ayahCount} آية', colors: c, language: language),
              _MetaChip(icon: Icons.location_on_outlined, labelLatin: placeLatin, labelAr: placeAr, colors: c, language: language),
              _MetaChip(icon: Icons.numbers_rounded, labelLatin: '#${meta.revelationOrder}', labelAr: '#${meta.revelationOrder}', colors: c, language: language),
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
  const _MetaChip({required this.icon, required this.labelLatin, required this.labelAr, required this.colors, required this.language});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final label = language == 'ar' ? labelAr : labelLatin;
    return Column(
      children: [
        Icon(icon, size: 18, color: c.goldText),
        const SizedBox(height: AppSpacing.xs),
        Text(label, textDirection: language == 'ar' ? TextDirection.rtl : TextDirection.ltr, style: AppText.latin(color: c.goldText, size: 11, weight: FontWeight.w600)),
      ],
    );
  }
}

class _PdfSection extends StatefulWidget {
  final SurahMeta meta;
  final Surah surah;
  final AppColors colors;
  final DownloadService downloadService;
  final CatalogService catalogService;
  const _PdfSection({required this.meta, required this.surah, required this.colors, required this.downloadService, required this.catalogService});

  @override
  State<_PdfSection> createState() => _PdfSectionState();
}

class _PdfSectionState extends State<_PdfSection> {
  String? _errorMessage;
  String get _fileId => 'pdf_surah_${widget.meta.number}';

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return ListenableBuilder(
      listenable: widget.downloadService,
      builder: (context, _) {
        final isDownloaded = widget.downloadService.isDownloaded(_fileId);
        final isDownloading = widget.downloadService.isDownloading(_fileId);
        final progress = widget.downloadService.progress(_fileId);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Surah PDF', style: AppText.latin(color: c.textPrimary, size: 15, weight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () async {
                if (isDownloaded && !isDownloading) {
                  final path = await widget.downloadService.localPath(_fileId);
                  if (path != null && context.mounted) Navigator.of(context).push(MaterialPageRoute(builder: (_) => PdfReaderScreen(book: fakeBookForSurah(widget.meta), filePath: path)));
                } else if (!isDownloading && widget.surah.hasPdf) {
                  setState(() => _errorMessage = null);
                  widget.downloadService.download(fileId: _fileId, url: widget.catalogService.surahPdfUrlFor(widget.surah), displayName: widget.meta.nameAr, bookId: 'surah_${widget.meta.number}', onError: (e) => setState(() => _errorMessage = e), onComplete: () => setState(() {}));
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
                          decoration: BoxDecoration(shape: BoxShape.circle, color: isDownloaded ? c.brand : widget.surah.hasPdf ? c.brand.withOpacity(0.12) : c.surface2, border: Border.all(color: isDownloaded ? c.brand : widget.surah.hasPdf ? c.brand.withOpacity(0.3) : c.divider, width: 1.5)),
                          child: isDownloading
                              ? Padding(padding: const EdgeInsets.all(14), child: CircularProgressIndicator(value: progress > 0 ? progress : null, strokeWidth: 2, color: c.brand))
                              : Icon(isDownloaded ? Icons.menu_book_rounded : widget.surah.hasPdf ? Icons.download_rounded : Icons.hourglass_empty_rounded, size: 22, color: isDownloaded ? Colors.white : widget.surah.hasPdf ? c.brand : c.textFaint),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isDownloaded ? 'Tap to Open' : isDownloading ? 'Downloading...' : widget.surah.hasPdf ? 'Tap to Download' : 'Coming Soon', style: AppText.latin(color: isDownloaded ? c.brand : c.textPrimary, size: 14, weight: FontWeight.w700)),
                              const SizedBox(height: AppSpacing.xs),
                              Text(widget.surah.hasPdf ? 'PDF of Surah ${widget.meta.number}' : 'Not uploaded yet', style: AppText.latin(color: c.textMuted, size: 12)),
                            ],
                          ),
                        ),
                        if (!isDownloading) Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs), decoration: BoxDecoration(color: c.brand.withOpacity(0.1), borderRadius: AppRadius.pillRadius, border: Border.all(color: c.brand.withOpacity(0.25))), child: Text('Free', style: AppText.latin(color: c.brand, size: 12, weight: FontWeight.w700))),
                        if (isDownloading) GestureDetector(onTap: () => widget.downloadService.cancelDownload(_fileId), child: Container(width: 34, height: 34, decoration: BoxDecoration(color: c.dangerBg, borderRadius: AppRadius.buttonRadius, border: Border.all(color: c.danger.withOpacity(0.3))), child: Icon(Icons.close_rounded, size: 16, color: c.danger))),
                      ],
                    ),
                    if (isDownloading) ...[const SizedBox(height: AppSpacing.md), ClipRRect(borderRadius: AppRadius.pillRadius, child: LinearProgressIndicator(value: progress > 0 ? progress : null, backgroundColor: c.surface2, valueColor: AlwaysStoppedAnimation<Color>(c.brand), minHeight: 4))],
                    if (_errorMessage != null) ...[const SizedBox(height: AppSpacing.sm), Container(padding: const EdgeInsets.all(AppSpacing.sm), decoration: BoxDecoration(color: c.dangerBg, borderRadius: AppRadius.listItemRadius, border: Border.all(color: c.danger.withOpacity(0.3))), child: Row(children: [Icon(Icons.error_outline_rounded, color: c.danger, size: 14), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(_errorMessage!, style: AppText.latin(color: c.danger, size: 12))), GestureDetector(onTap: () => setState(() => _errorMessage = null), child: Icon(Icons.close_rounded, color: c.danger, size: 14))]))],
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

class _RecitersSection extends StatelessWidget {
  final Surah surah;
  final SurahMeta meta;
  final CatalogService catalogService;
  final DownloadService downloadService;
  final AppColors colors;
  final String language;
  const _RecitersSection({required this.surah, required this.meta, required this.catalogService, required this.downloadService, required this.colors, required this.language});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final pairs = surah.reciters.map((ra) {
      final r = catalogService.reciterById(ra.reciterId);
      return r != null ? (reciter: r, audio: ra) : null;
    }).whereType<({Reciter reciter, ReciterAudio audio})>().toList();
    if (pairs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(Icons.mic_rounded, size: 14, color: c.goldText), const SizedBox(width: AppSpacing.sm - 2), Text('RECITERS', style: AppText.label(color: c.textFaint))]),
        const SizedBox(height: AppSpacing.xs + 2),
        Text('Beautiful recitations of this Surah.', style: AppText.latin(color: c.textMuted, size: 12, height: 1.5)),
        const SizedBox(height: AppSpacing.sm),
        ...pairs.map((p) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: _ReciterCard(reciter: p.reciter, audio: p.audio, meta: meta, catalogService: catalogService, downloadService: downloadService, colors: c, language: language))),
      ],
    );
  }
}

class _ReciterCard extends StatelessWidget {
  final Reciter reciter;
  final ReciterAudio audio;
  final SurahMeta meta;
  final CatalogService catalogService;
  final DownloadService downloadService;
  final AppColors colors;
  final String language;
  const _ReciterCard({required this.reciter, required this.audio, required this.meta, required this.catalogService, required this.downloadService, required this.colors, required this.language});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final part = audio.parts.isNotEmpty ? audio.parts.first : 1;
    final fileId = DownloadService.surahReciterAudioId(meta.number, reciter.id, part);
    return ListenableBuilder(
      listenable: downloadService,
      builder: (context, _) {
        final isDownloaded = downloadService.isDownloaded(fileId);
        final isDownloading = downloadService.isDownloading(fileId);
        final progress = downloadService.progress(fileId);
        return GestureDetector(
          onTap: isDownloaded ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SurahAudioPlayerScreen.reciter(meta: meta, reciter: reciter, reciterAudio: audio, initialPartIndex: 0))) : null,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: c.card, borderRadius: AppRadius.cardRadius, border: Border.all(color: c.divider)),
            child: Column(
              children: [
                Row(
                  children: [
                    ReciterAvatar(reciter: reciter, downloadService: downloadService, colors: c, size: 44),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(reciter.nameAr, textDirection: TextDirection.rtl, style: AppText.arabic(color: c.textPrimary, size: 14, weight: FontWeight.w700)), const SizedBox(height: AppSpacing.xs), Text(reciter.nameFor(language), style: AppText.latin(color: c.textMuted, size: 12))])),
                    const SizedBox(width: AppSpacing.sm),
                    GestureDetector(
                      onTap: () {
                        if (isDownloading) { downloadService.cancelDownload(fileId); }
                        else if (isDownloaded) { Navigator.of(context).push(MaterialPageRoute(builder: (_) => SurahAudioPlayerScreen.reciter(meta: meta, reciter: reciter, reciterAudio: audio, initialPartIndex: 0))); }
                        else { downloadService.download(fileId: fileId, url: catalogService.surahReciterUrlFor(surahNumber: meta.number, reciterAudio: audio, partNumber: part), displayName: '${meta.nameAr} - Recitation', bookId: 'surah_${meta.number}', personId: reciter.id, personPhotoUrl: reciter.photoUrl, onError: (_) {}, onComplete: () {}); }
                      },
                      child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: isDownloading ? c.dangerBg : isDownloaded ? c.goldText : c.goldText.withOpacity(0.12), border: Border.all(color: isDownloading ? c.danger.withOpacity(0.3) : isDownloaded ? c.goldText : c.goldText.withOpacity(0.3))), child: isDownloading ? Icon(Icons.close_rounded, size: 18, color: c.danger) : Icon(isDownloaded ? Icons.play_arrow_rounded : Icons.download_rounded, size: 20, color: isDownloaded ? Colors.white : c.goldText)),
                    ),
                  ],
                ),
                if (isDownloading) ...[const SizedBox(height: AppSpacing.sm), ClipRRect(borderRadius: AppRadius.pillRadius, child: LinearProgressIndicator(value: progress > 0 ? progress : null, backgroundColor: c.surface2, valueColor: AlwaysStoppedAnimation<Color>(c.goldText), minHeight: 3))],
              ],
            ),
          ),
        );
      },
    );
  }
}

class ReciterAvatar extends StatelessWidget {
  final Reciter reciter;
  final DownloadService downloadService;
  final AppColors colors;
  final double size;
  const ReciterAvatar({super.key, required this.reciter, required this.downloadService, required this.colors, required this.size});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final state = AppState.of(context);
    final path = downloadService.photoLocalPath(reciter.id, state.appDocsPath);
    final file = File(path);

    if (downloadService.hasPhoto(reciter.id) && file.existsSync()) {
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.goldText.withOpacity(0.4), width: 1.5)),
        child: ClipOval(child: Image.file(file, fit: BoxFit.cover, errorBuilder: (_, __, ___) => MicCircle(colors: c, size: size))),
      );
    }
    return MicCircle(colors: c, size: size);
  }
}

class MicCircle extends StatelessWidget {
  final AppColors colors;
  final double size;
  const MicCircle({super.key, required this.colors, required this.size});
  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: c.goldLine, border: Border.all(color: c.goldText.withOpacity(0.35))), alignment: Alignment.center, child: Icon(Icons.mic_rounded, size: size * 0.45, color: c.goldText));
  }
}

class _TeachersSection extends StatelessWidget {
  final Surah surah;
  final SurahMeta meta;
  final CatalogService catalogService;
  final DownloadService downloadService;
  final AppColors colors;
  final String language;
  const _TeachersSection({required this.surah, required this.meta, required this.catalogService, required this.downloadService, required this.colors, required this.language});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final pairs = surah.teachers.map((ta) {
      final t = catalogService.teacherById(ta.teacherId);
      return t != null ? (teacher: t, audio: ta) : null;
    }).whereType<({Teacher teacher, TeacherAudio audio})>().toList();
    if (pairs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(Icons.school_rounded, size: 14, color: c.brand), const SizedBox(width: AppSpacing.sm - 2), Text('TEACHERS · TAFSEER', style: AppText.label(color: c.textFaint))]),
        const SizedBox(height: AppSpacing.xs + 2),
        Text('Scholars who explain and teach this Surah.', style: AppText.latin(color: c.textMuted, size: 12, height: 1.5)),
        const SizedBox(height: AppSpacing.sm),
        ...pairs.map((p) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: _SurahTeacherCard(teacher: p.teacher, audio: p.audio, colors: c, language: language, downloadService: downloadService, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SurahLessonsScreen.teacher(meta: meta, teacher: p.teacher, teacherAudio: p.audio)))))),
      ],
    );
  }
}

class _SurahTeacherCard extends StatelessWidget {
  final Teacher teacher;
  final TeacherAudio audio;
  final AppColors colors;
  final String language;
  final DownloadService downloadService;
  final VoidCallback onTap;
  const _SurahTeacherCard({required this.teacher, required this.audio, required this.colors, required this.language, required this.downloadService, required this.onTap});

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
            ListenableBuilder(listenable: downloadService, builder: (context, _) => TeacherAvatar(teacher: teacher, downloadService: downloadService, colors: c, size: 44)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(teacher.nameAr, textDirection: TextDirection.rtl, style: AppText.arabic(color: c.textPrimary, size: 14, weight: FontWeight.w700)), const SizedBox(height: AppSpacing.xs), Text(teacher.nameFor(language), style: AppText.latin(color: c.textMuted, size: 12))])),
            Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs), decoration: BoxDecoration(color: c.brand.withOpacity(0.1), borderRadius: AppRadius.pillRadius, border: Border.all(color: c.brand.withOpacity(0.25))), child: Text('${audio.totalParts} parts', style: AppText.latin(color: c.brand, size: 10, weight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }
}

class _NothingYet extends StatelessWidget {
  final AppColors colors;
  const _NothingYet({required this.colors});
  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: c.card, borderRadius: AppRadius.cardRadius, border: Border.all(color: c.divider)), child: Row(children: [Icon(Icons.hourglass_empty_rounded, color: c.textFaint, size: 24), const SizedBox(width: AppSpacing.md), Expanded(child: Text('Content for this Surah is being prepared. Please check back soon.', style: AppText.latin(color: c.textMuted, size: 13, height: 1.5)))]));
  }
}
