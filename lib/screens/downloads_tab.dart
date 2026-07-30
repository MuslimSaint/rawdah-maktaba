import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/quran_data.dart';
import '../core/theme.dart';
import '../core/download_service.dart';
import '../widgets/book_cover.dart';
import 'book_detail_screen.dart';

/// Downloads tab — active downloads + completed downloads.
class DownloadsTab extends StatefulWidget {
  const DownloadsTab({super.key});

  @override
  State<DownloadsTab> createState() => _DownloadsTabState();
}

class _DownloadsTabState extends State<DownloadsTab> {
  double _totalStorageMb = 0;
  List<Map<String, dynamic>> _downloadedFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      AppState.of(context)
          .downloadService
          .addListener(_onDownloadChanged);
    });
  }

  @override
  void dispose() {
    try {
      AppState.of(context)
          .downloadService
          .removeListener(_onDownloadChanged);
    } catch (_) {}
    super.dispose();
  }

  void _onDownloadChanged() => _loadData();

  Future<void> _loadData() async {
    if (!mounted) return;
    final state = AppState.of(context);
    final storage =
        await state.downloadService.totalStorageMb();
    final files =
        await state.downloadService.downloadedFiles();
    if (mounted) {
      setState(() {
        _totalStorageMb = storage;
        _downloadedFiles = files;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFile(String fileId) async {
    final state = AppState.of(context);
    await state.downloadService.deleteFile(fileId);
    await _loadData();
  }

  Future<void> _deleteAll() async {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete All Downloads?',
          style: AppText.latin(
            color: c.textPrimary,
            size: 16,
            weight: FontWeight.w700,
          ),
        ),
        content: Text(
          'All downloaded PDFs and audio files will be removed.',
          style: AppText.latin(color: c.textMuted, size: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppText.latin(
                  color: c.textMuted, size: 14),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete All',
              style: AppText.latin(
                color: c.danger,
                size: 14,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await state.downloadService.deleteAll();
      await _loadData();
    }
  }

  // ─── Name resolution ────────────────────────────────

  /// Returns a clean Arabic display name for any fileId.
  ///
  /// Handles all 6 file ID formats:
  ///   pdf_mushaf            → القرآن الكريم
  ///   pdf_mushaf_<id>       → edition titleAr
  ///   pdf_surah_N           → سورة <name>
  ///   pdf_<bookId>          → book.titleAr (via catalog)
  ///   saudio_r_N_reciterId_part → سورة <name> — <reciter>
  ///   saudio_t_N_teacherId_part → سورة <name> — <teacher> (تفسير)
  ///   audio_bookId_teacherId_part → book.titleAr — الجزء N
  String _displayName(
    String fileId,
    AppState state,
  ) {
    // ── Full Mus'haf (default edition) ──
    if (fileId == 'pdf_mushaf') {
      return 'المصحف الشريف';
    }

    // ── Other Mus'haf editions: pdf_mushaf_<editionId> ──
    if (fileId.startsWith('pdf_mushaf_')) {
      final editionId =
          fileId.replaceFirst('pdf_mushaf_', '');
      // Try to find the edition in the catalog.
      for (final sub
          in state.catalogService.quranSubBranches) {
        for (final ed in sub.editions) {
          if (ed.id == editionId) {
            return ed.titleAr;
          }
        }
      }
      return 'المصحف الشريف';
    }

    // ── Surah PDF: pdf_surah_N ──
    if (fileId.startsWith('pdf_surah_')) {
      final numStr =
          fileId.replaceFirst('pdf_surah_', '');
      final n = int.tryParse(numStr);
      if (n != null && n >= 1 && n <= 114) {
        final meta = QuranSkeleton.byNumber(n);
        if (meta != null) return 'سورة ${meta.nameAr}';
      }
      return 'سورة $numStr';
    }

    // ── Surah reciter audio: saudio_r_N_reciterId_part ──
    if (fileId.startsWith('saudio_r_')) {
      // Format: saudio_r_<surahNum>_<reciterId>_<part>
      final rest = fileId.replaceFirst('saudio_r_', '');
      final parts = rest.split('_');
      if (parts.length >= 3) {
        final n = int.tryParse(parts[0]);
        final reciterId = parts[1];
        if (n != null && n >= 1 && n <= 114) {
          final meta = QuranSkeleton.byNumber(n);
          final reciter =
              state.catalogService.reciterById(reciterId);
          if (meta != null && reciter != null) {
            return 'سورة ${meta.nameAr} — ${reciter.nameAr}';
          }
          if (meta != null) {
            return 'سورة ${meta.nameAr}';
          }
        }
      }
    }

    // ── Surah teacher audio: saudio_t_N_teacherId_part ──
    if (fileId.startsWith('saudio_t_')) {
      // Format: saudio_t_<surahNum>_<teacherId>_<part>
      final rest = fileId.replaceFirst('saudio_t_', '');
      final parts = rest.split('_');
      if (parts.length >= 3) {
        final n = int.tryParse(parts[0]);
        final teacherId = parts[1];
        if (n != null && n >= 1 && n <= 114) {
          final meta = QuranSkeleton.byNumber(n);
          final teacher =
              state.catalogService.teacherById(teacherId);
          if (meta != null && teacher != null) {
            return 'سورة ${meta.nameAr} — ${teacher.nameAr} (تفسير)';
          }
          if (meta != null) {
            return 'سورة ${meta.nameAr}';
          }
        }
      }
    }

    // ── Book audio: audio_bookId_teacherId_part ──
    if (fileId.startsWith('audio_')) {
      // Format: audio_<bookId>_<teacherId>_<part>
      // bookId may itself contain underscores (e.g. aqidah-muslimin
      // never has underscores but some future id might).
      // Strategy: last token = part number (int),
      // second-to-last = teacherId (known from catalog),
      // everything in between = bookId.
      final rest = fileId.replaceFirst('audio_', '');
      final tokens = rest.split('_');
      if (tokens.length >= 3) {
        final part = int.tryParse(tokens.last);
        if (part != null) {
          // Walk backward: find a teacherId that matches.
          // teacherIds never have underscores in current data.
          final possibleTeacherId =
              tokens[tokens.length - 2];
          final teacher = state.catalogService
              .teacherById(possibleTeacherId);
          // bookId = everything before the teacherId token.
          final bookId = tokens
              .sublist(0, tokens.length - 2)
              .join('_');
          Book? book;
          try {
            book = state.catalogService.books
                .firstWhere((b) => b.id == bookId);
          } catch (_) {}
          if (book != null) {
            final ordinal = _arabicOrdinal(part);
            return '${book.titleAr} — $ordinal';
          }
        }
      }
    }

    // ── Regular book PDF: pdf_<bookId> ──
    if (fileId.startsWith('pdf_')) {
      final bookId = fileId.replaceFirst('pdf_', '');
      Book? book;
      try {
        book = state.catalogService.books
            .firstWhere((b) => b.id == bookId);
      } catch (_) {}
      if (book != null) return book.titleAr;
    }

    // Fallback: raw fileId.
    return fileId;
  }

  /// Badge label for a fileId.
  String _badgeLabel(String fileId) {
    if (fileId == 'pdf_mushaf' ||
        fileId.startsWith('pdf_mushaf_') ||
        fileId.startsWith('pdf_surah_') ||
        fileId.startsWith('saudio_r_') ||
        fileId.startsWith('saudio_t_')) {
      return 'Quran';
    }
    if (fileId.startsWith('pdf_')) return 'PDF';
    if (fileId.startsWith('audio_')) return 'Audio';
    return 'File';
  }

  /// Badge color — gold for Quran, brand for everything else.
  bool _isQuranFile(String fileId) {
    return fileId == 'pdf_mushaf' ||
        fileId.startsWith('pdf_mushaf_') ||
        fileId.startsWith('pdf_surah_') ||
        fileId.startsWith('saudio_r_') ||
        fileId.startsWith('saudio_t_');
  }

  /// English subtitle for Quran files (transliteration or
  /// edition name). Null for non-Quran files.
  String? _subtitle(String fileId, AppState state) {
    if (fileId == 'pdf_mushaf') {
      return 'The Noble Mus\'haf';
    }
    if (fileId.startsWith('pdf_mushaf_')) {
      final editionId =
          fileId.replaceFirst('pdf_mushaf_', '');
      for (final sub
          in state.catalogService.quranSubBranches) {
        for (final ed in sub.editions) {
          if (ed.id == editionId) return ed.titleEn;
        }
      }
      return null;
    }
    if (fileId.startsWith('pdf_surah_')) {
      final numStr =
          fileId.replaceFirst('pdf_surah_', '');
      final n = int.tryParse(numStr);
      if (n != null) {
        final meta = QuranSkeleton.byNumber(n);
        return meta?.nameTransliteration;
      }
    }
    return null;
  }

  Book? _bookForFileId(String fileId, List<Book> books) {
    if (!fileId.startsWith('pdf_')) return null;
    if (fileId == 'pdf_mushaf' ||
        fileId.startsWith('pdf_mushaf_') ||
        fileId.startsWith('pdf_surah_')) return null;
    final bookId = fileId.replaceFirst('pdf_', '');
    try {
      return books.firstWhere((b) => b.id == bookId);
    } catch (_) {
      return null;
    }
  }

  /// Arabic ordinal for audio part numbers.
  static String _arabicOrdinal(int n) {
    const ordinals = [
      '',
      'الجزء الأول',
      'الجزء الثاني',
      'الجزء الثالث',
      'الجزء الرابع',
      'الجزء الخامس',
      'الجزء السادس',
      'الجزء السابع',
      'الجزء الثامن',
      'الجزء التاسع',
      'الجزء العاشر',
    ];
    if (n >= 1 && n <= 10) return ordinals[n];
    return 'الجزء $n';
  }

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
              padding:
                  const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Downloads',
                    style: AppText.latin(
                      color: c.textPrimary,
                      size: 22,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (_downloadedFiles.isNotEmpty)
                    GestureDetector(
                      onTap: _deleteAll,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: c.dangerBg,
                          borderRadius:
                              BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                c.danger.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 14,
                              color: c.danger,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Delete All',
                              style: AppText.latin(
                                color: c.danger,
                                size: 12,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: c.brand,
                        strokeWidth: 2,
                      ),
                    )
                  : ListenableBuilder(
                      listenable: state.downloadService,
                      builder: (context, _) {
                        final activeDownloads = state
                            .downloadService.activeDownloads;
                        final hasActive =
                            activeDownloads.isNotEmpty;
                        final hasCompleted =
                            _downloadedFiles.isNotEmpty;

                        if (!hasActive && !hasCompleted) {
                          return _EmptyState(colors: c);
                        }

                        return ListView(
                          padding:
                              const EdgeInsets.fromLTRB(
                                  20, 0, 20, 24),
                          children: [
                            // ── Active Downloads ──
                            if (hasActive) ...[
                              Text(
                                'Downloading Now',
                                style: AppText.latin(
                                  color: c.textPrimary,
                                  size: 15,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...activeDownloads
                                  .map((active) {
                                final fileId = active[
                                    'fileId'] as String;
                                final bookId = active[
                                    'bookId'] as String;
                                final prog = active[
                                    'progress'] as double;
                                final speed = active[
                                        'speedKbps']
                                    as double;
                                final paused =
                                    active['paused']
                                        as bool? ??
                                    false;
                                final awaiting =
                                    active['awaitingNetwork']
                                        as bool? ??
                                    false;

                                // Use our resolver,
                                // not the raw displayName.
                                final name = _displayName(
                                    fileId, state);

                                Book? book;
                                if (bookId.isNotEmpty) {
                                  try {
                                    book = state
                                        .catalogService
                                        .books
                                        .firstWhere((b) =>
                                            b.id == bookId);
                                  } catch (_) {}
                                }

                                return Padding(
                                  padding:
                                      const EdgeInsets.only(
                                          bottom: 10),
                                  child:
                                      _ActiveDownloadCard(
                                    fileId: fileId,
                                    book: book,
                                    displayName: name,
                                    progress: prog,
                                    speedKbps: speed,
                                    isPaused: paused,
                                    isAwaitingNetwork:
                                        awaiting,
                                    colors: c,
                                    onCancel: () => state
                                        .downloadService
                                        .cancelDownload(
                                            fileId),
                                    onPause: () => state
                                        .downloadService
                                        .pauseDownload(
                                            fileId),
                                    onResume: () => state
                                        .downloadService
                                        .resumeDownload(
                                            fileId),
                                  ),
                                );
                              }),
                              const SizedBox(height: 20),
                            ],

                            // ── Completed ──
                            if (hasCompleted) ...[
                              _StorageCard(
                                totalMb: _totalStorageMb,
                                fileCount:
                                    _downloadedFiles.length,
                                colors: c,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Downloaded Files',
                                style: AppText.latin(
                                  color: c.textPrimary,
                                  size: 15,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ..._downloadedFiles
                                  .map((file) {
                                final fileId =
                                    file['id'] as String;
                                final sizeMb =
                                    file['sizeMb'] as double;
                                final book =
                                    _bookForFileId(
                                  fileId,
                                  state.catalogService
                                      .books,
                                );
                                final name =
                                    _displayName(
                                        fileId, state);
                                final sub =
                                    _subtitle(
                                        fileId, state);
                                final isQuran =
                                    _isQuranFile(fileId);
                                final badge =
                                    _badgeLabel(fileId);

                                return Padding(
                                  padding:
                                      const EdgeInsets.only(
                                          bottom: 10),
                                  child:
                                      _DownloadedFileCard(
                                    fileId: fileId,
                                    book: book,
                                    displayName: name,
                                    subtitle: sub,
                                    badgeLabel: badge,
                                    isQuranFile: isQuran,
                                    sizeMb: sizeMb,
                                    colors: c,
                                    onDelete: () =>
                                        _deleteFile(fileId),
                                    onTap: book != null
                                        ? () {
                                            Navigator.of(
                                                    context)
                                                .push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    BookDetailScreen(
                                                  book: book,
                                                  catalogService:
                                                      state
                                                          .catalogService,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                  ),
                                );
                              }),
                            ],
                          ],
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

// ─── Active Download Card ─────────────────────────────

class _ActiveDownloadCard extends StatelessWidget {
  final String fileId;
  final Book? book;
  final String displayName;
  final double progress;
  final double speedKbps;
  final bool isPaused;
  final bool isAwaitingNetwork;
  final AppColors colors;
  final VoidCallback onCancel;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const _ActiveDownloadCard({
    required this.fileId,
    required this.book,
    required this.displayName,
    required this.progress,
    required this.speedKbps,
    required this.isPaused,
    required this.isAwaitingNetwork,
    required this.colors,
    required this.onCancel,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final isPdf = fileId.startsWith('pdf_');
    final percent = (progress * 100).toInt();
    final isQuran = fileId == 'pdf_mushaf' ||
        fileId.startsWith('pdf_mushaf_') ||
        fileId.startsWith('pdf_surah_') ||
        fileId.startsWith('saudio_r_') ||
        fileId.startsWith('saudio_t_');

    // Determine status color and label.
    final Color statusColor = isAwaitingNetwork
        ? c.textMuted
        : isPaused
            ? c.goldText
            : c.brand;

    final String statusLabel = isAwaitingNetwork
        ? 'Waiting for network…'
        : isPaused
            ? 'Paused'
            : progress > 0
                ? '$percent% downloaded'
                : 'Connecting…';

    final String hintLabel = isAwaitingNetwork
        ? 'Will resume automatically · × to cancel'
        : isPaused
            ? 'Tap ▶ to resume'
            : 'Tap ∥ to pause · × to cancel';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAwaitingNetwork
              ? c.textFaint.withOpacity(0.3)
              : isPaused
                  ? c.goldText.withOpacity(0.4)
                  : c.brand.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Cover / icon
              if (book != null)
                BookCoverWidget(
                  book: book!,
                  width: 46,
                  height: 46,
                  borderRadius: 10,
                )
              else
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isQuran
                        ? c.goldLine
                        : c.brand.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: isQuran
                          ? c.goldText.withOpacity(0.35)
                          : c.brand.withOpacity(0.25),
                    ),
                  ),
                  child: Icon(
                    isQuran
                        ? Icons.import_contacts_rounded
                        : isPdf
                            ? Icons.picture_as_pdf_rounded
                            : Icons.headphones_rounded,
                    size: 22,
                    color:
                        isQuran ? c.goldText : c.brand,
                  ),
                ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.arabic(
                        color: c.textPrimary,
                        size: 13,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        // Status badge
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isAwaitingNetwork
                                ? c.surface2
                                : isQuran
                                    ? c.goldLine
                                    : c.brand
                                        .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(5),
                          ),
                          child: Text(
                            isAwaitingNetwork
                                ? 'Offline'
                                : isQuran
                                    ? 'Quran'
                                    : isPdf
                                        ? 'PDF'
                                        : 'Audio',
                            style: AppText.latin(
                              color: isAwaitingNetwork
                                  ? c.textMuted
                                  : isQuran
                                      ? c.goldText
                                      : c.brand,
                              size: 10,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // Speed (only when actively downloading)
                        if (speedKbps > 0 &&
                            !isPaused &&
                            !isAwaitingNetwork) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.speed_rounded,
                            size: 11,
                            color: c.textFaint,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            DownloadService.formatSpeed(
                                speedKbps),
                            style: AppText.latin(
                              color: c.textFaint,
                              size: 11,
                            ),
                          ),
                        ],
                        // Network waiting spinner
                        if (isAwaitingNetwork) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 11,
                            height: 11,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: c.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Pause/resume button — hidden when awaiting network
              if (!isAwaitingNetwork) ...[
                GestureDetector(
                  onTap: isPaused ? onResume : onPause,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius:
                          BorderRadius.circular(10),
                      border:
                          Border.all(color: c.divider),
                    ),
                    child: Icon(
                      isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      size: 18,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Cancel button — always visible
              GestureDetector(
                onTap: onCancel,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: c.dangerBg,
                    borderRadius: BorderRadius.circular(10),
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
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isAwaitingNetwork
                  ? null // indeterminate when waiting
                  : progress > 0
                      ? progress
                      : null,
              backgroundColor: c.surface2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isAwaitingNetwork
                    ? c.textFaint
                    : isPaused
                        ? c.goldText
                        : c.brand,
              ),
              minHeight: 5,
            ),
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                statusLabel,
                style: AppText.latin(
                  color: statusColor,
                  size: 11,
                  weight: FontWeight.w600,
                ),
              ),
              Text(
                hintLabel,
                style: AppText.latin(
                  color: c.textFaint,
                  size: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppColors colors;
  const _EmptyState({required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: c.brand.withOpacity(0.08),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: c.brand.withOpacity(0.18),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.download_rounded,
                size: 40,
                color: c.brand.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No downloads yet',
              style: AppText.latin(
                color: c.textPrimary,
                size: 20,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Books and audio you download will appear here.',
              textAlign: TextAlign.center,
              style: AppText.latin(
                color: c.textMuted,
                size: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Storage Card ────────────────────────────────────

class _StorageCard extends StatelessWidget {
  final double totalMb;
  final int fileCount;
  final AppColors colors;

  const _StorageCard({
    required this.totalMb,
    required this.fileCount,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final progress = (totalMb / 500).clamp(0.0, 1.0);
    final display = totalMb < 1
        ? '${(totalMb * 1024).toStringAsFixed(0)} KB'
        : '${totalMb.toStringAsFixed(1)} MB';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.goldLine, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage_rounded,
                  size: 18, color: c.brand),
              const SizedBox(width: 8),
              Text(
                'Storage Used',
                style: AppText.latin(
                  color: c.textPrimary,
                  size: 14,
                  weight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                display,
                style: AppText.latin(
                  color: c.brand,
                  size: 14,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$fileCount file${fileCount == 1 ? '' : 's'} downloaded',
            style: AppText.latin(
                color: c.textMuted, size: 11),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: c.surface2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(c.brand),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Downloaded File Card ────────────────────────────

class _DownloadedFileCard extends StatelessWidget {
  final String fileId;
  final Book? book;
  final String displayName;
  final String? subtitle;
  final String badgeLabel;
  final bool isQuranFile;
  final double sizeMb;
  final AppColors colors;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const _DownloadedFileCard({
    required this.fileId,
    required this.book,
    required this.displayName,
    required this.subtitle,
    required this.badgeLabel,
    required this.isQuranFile,
    required this.sizeMb,
    required this.colors,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final isPdf = fileId.startsWith('pdf_');
    final sizeDisplay = sizeMb < 1
        ? '${(sizeMb * 1024).toStringAsFixed(0)} KB'
        : '${sizeMb.toStringAsFixed(1)} MB';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.divider),
        ),
        child: Row(
          children: [
            // Cover or icon
            if (book != null && isPdf)
              BookCoverWidget(
                book: book!,
                width: 46,
                height: 58,
                borderRadius: 8,
              )
            else
              Container(
                width: 46,
                height: 58,
                decoration: BoxDecoration(
                  color: isQuranFile
                      ? c.goldLine
                      : c.brand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isQuranFile
                        ? c.goldText.withOpacity(0.35)
                        : c.brand.withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  isQuranFile
                      ? Icons.import_contacts_rounded
                      : isPdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.headphones_rounded,
                  size: 22,
                  color: isQuranFile
                      ? c.goldText
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
                    displayName,
                    textDirection: TextDirection.rtl,
                    style: AppText.arabic(
                      color: c.textPrimary,
                      size: 13,
                      weight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppText.latin(
                        color: c.textMuted,
                        size: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isQuranFile
                              ? c.goldLine
                              : c.brand.withOpacity(0.08),
                          borderRadius:
                              BorderRadius.circular(5),
                        ),
                        child: Text(
                          badgeLabel,
                          style: AppText.latin(
                            color: isQuranFile
                                ? c.goldText
                                : c.brand,
                            size: 10,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sizeDisplay,
                        style: AppText.latin(
                            color: c.textFaint,
                            size: 11),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle_rounded,
                          size: 12, color: c.brand),
                      const SizedBox(width: 3),
                      Text(
                        'On device',
                        style: AppText.latin(
                            color: c.brand, size: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: c.dangerBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: c.danger.withOpacity(0.3)),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: c.danger,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
