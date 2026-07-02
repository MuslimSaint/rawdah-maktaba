import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../core/download_service.dart';
import 'book_detail_screen.dart';

/// Downloads tab — shows all downloaded files with storage info.
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
    _loadData();
  }

  Future<void> _loadData() async {
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

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = AppColors(isDark: state.isDark);
        return AlertDialog(
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
            'All downloaded PDFs and audio files will be removed from your device.',
            style: AppText.latin(
              color: c.textMuted,
              size: 13,
            ),
          ),
          actions: [
            TextButton(
              onTap: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: AppText.latin(
                  color: c.textMuted,
                  size: 14,
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(false),
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
        );
      },
    );

    if (confirm == true) {
      await state.downloadService.deleteAll();
      await _loadData();
    }
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: c.dangerBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: c.danger.withOpacity(0.3),
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

            // ── Content ──
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
                        if (_downloadedFiles.isEmpty) {
                          return _EmptyState(colors: c);
                        }

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(
                              20, 0, 20, 24),
                          children: [
                            // ── Storage Card ──
                            _StorageCard(
                              totalMb: _totalStorageMb,
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

                            // ── File List ──
                            ..._downloadedFiles.map((file) {
                              final fileId =
                                  file['id'] as String;
                              final sizeMb =
                                  file['sizeMb'] as double;

                              // Get book from catalog
                              final book = _bookForFileId(
                                fileId,
                                state.catalogService.books,
                              );

                              return Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 10),
                                child: _DownloadedFileCard(
                                  fileId: fileId,
                                  book: book,
                                  sizeMb: sizeMb,
                                  colors: c,
                                  onDelete: () =>
                                      _deleteFile(fileId),
                                  onTap: book != null
                                      ? () {
                                          Navigator.of(context)
                                              .push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  BookDetailScreen(
                                                book: book,
                                                catalogService: state
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
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Book? _bookForFileId(String fileId, List<Book> books) {
    // fileId format: pdf_bookId or audio_bookId_teacherId_part
    String bookId;
    if (fileId.startsWith('pdf_')) {
      bookId = fileId.replaceFirst('pdf_', '');
    } else if (fileId.startsWith('audio_')) {
      final parts = fileId.split('_');
      bookId = parts.length > 1 ? parts[1] : '';
    } else {
      return null;
    }
    try {
      return books.firstWhere((b) => b.id == bookId);
    } catch (_) {
      return null;
    }
  }
}

// ─── Empty State ─────────────────────────────────────────

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
              'Books and audio you download will appear here for offline reading and listening.',
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

// ─── Storage Card ─────────────────────────────────────────

class _StorageCard extends StatelessWidget {
  final double totalMb;
  final AppColors colors;

  const _StorageCard({
    required this.totalMb,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    // Assume max reasonable storage = 500MB
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
              Icon(
                Icons.storage_rounded,
                size: 18,
                color: c.brand,
              ),
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
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: c.surface2,
              valueColor: AlwaysStoppedAnimation<Color>(c.brand),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Downloaded File Card ────────────────────────────────

class _DownloadedFileCard extends StatelessWidget {
  final String fileId;
  final Book? book;
  final double sizeMb;
  final AppColors colors;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const _DownloadedFileCard({
    required this.fileId,
    required this.book,
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
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: c.brand.withOpacity(0.1),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: c.brand.withOpacity(0.2),
                ),
              ),
              child: Icon(
                isPdf
                    ? Icons.picture_as_pdf_rounded
                    : Icons.headphones_rounded,
                size: 22,
                color: c.brand,
              ),
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (book != null) ...[
                    Text(
                      book!.titleAr,
                      textDirection: TextDirection.rtl,
                      style: AppText.arabic(
                        color: c.textPrimary,
                        size: 13,
                        weight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: c.brand.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          isPdf ? 'PDF' : 'Audio',
                          style: AppText.latin(
                            color: c.brand,
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
                          size: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: c.brand.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'Downloaded',
                          style: AppText.latin(
                            color: c.brand,
                            size: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Delete button
            GestureDetector(
              onTap: onDelete,
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
