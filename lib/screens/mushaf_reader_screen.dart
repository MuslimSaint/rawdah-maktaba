import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../core/app_state.dart';
import '../core/bookmark_service.dart';
import '../core/download_service.dart';
import '../core/models.dart';
import '../core/quran_data.dart';
import '../core/theme.dart';

/// Dedicated Mus'haf reader.
class MushafReaderScreen extends StatefulWidget {
  final MushafEdition edition;

  const MushafReaderScreen({
    super.key,
    required this.edition,
  });

  @override
  State<MushafReaderScreen> createState() =>
      _MushafReaderScreenState();
}

class _MushafReaderScreenState
    extends State<MushafReaderScreen> {
  late final String _fileId;
  late final String _pdfKey;

  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  bool _showLoadingOverlay = true;
  String? _localPath;
  String? _errorMessage;

  PDFViewController? _pdfController;
  int _defaultPage = 0;

  final BookmarkService _bookmarkService =
      BookmarkService();

  @override
  void initState() {
    super.initState();

    _fileId = widget.edition.id == 'mushaf'
        ? 'pdf_mushaf'
        : 'pdf_mushaf_${widget.edition.id}';

    _pdfKey = widget.edition.id == 'mushaf'
        ? 'mushaf'
        : 'mushaf_${widget.edition.id}';

    _bookmarkService.init().then((_) {
      _bookmarkService.setActivePdf(_pdfKey);
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    final state = AppState.of(context);

    _defaultPage =
        state.mushafLastPageFor(widget.edition.id);
    _currentPage = _defaultPage;

    final downloadService = state.downloadService;

    if (downloadService.isDownloaded(_fileId)) {
      final path =
          await downloadService.localPath(_fileId);
      if (path != null && mounted) {
        setState(() => _localPath = path);
      }
      return;
    }

    if (widget.edition.pdfUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Mus\'haf PDF is not available. Please try again later.';
          _showLoadingOverlay = false;
        });
      }
      return;
    }

    await downloadService.download(
      fileId: _fileId,
      url: widget.edition.pdfUrl,
      displayName: widget.edition.titleAr,
      bookId: 'mushaf',
      onError: (msg) {
        if (mounted) {
          setState(() {
            _errorMessage = msg;
            _showLoadingOverlay = false;
          });
        }
      },
      onComplete: () async {
        final path =
            await downloadService.localPath(_fileId);
        if (path != null && mounted) {
          setState(() => _localPath = path);
        }
      },
    );
  }

  void _hideLoadingOverlay() {
    Future.delayed(
        const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _showLoadingOverlay = false);
      }
    });
  }

  Future<void> _onPageChanged(
      int page, int total) async {
    setState(() {
      _currentPage = page;
      _totalPages = total;
      _showLoadingOverlay = false;
    });
    await AppState.of(context)
        .setMushafLastPageFor(widget.edition.id, page);
  }

  void _jumpToPage(int page) {
    _pdfController?.setPage(page);
  }

  void _showSurahIndex() {
    final c =
        AppColors(isDark: AppState.of(context).isDark);
    final lang = AppState.of(context).language;

    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollController) {
            return _SurahIndexContent(
              edition: widget.edition,
              colors: c,
              language: lang,
              scrollController: scrollController,
              onSurahTap: (page) {
                Navigator.of(ctx).pop();
                _jumpToPage(page - 1);
              },
            );
          },
        );
      },
    );
  }

  void _showAddBookmarkDialog() {
    if (_bookmarkService.isBookmarked(_currentPage)) {
      final c = AppColors(
          isDark: AppState.of(context).isDark);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Page ${_currentPage + 1} is already bookmarked.',
            style: const TextStyle(fontSize: 13),
          ),
          backgroundColor: c.brand,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final controller = TextEditingController(
      text: 'Page ${_currentPage + 1}',
    );

    final c =
        AppColors(isDark: AppState.of(context).isDark);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
        ),
        title: Text(
          'Save Bookmark',
          style: AppText.latin(
            color: c.textPrimary,
            size: 16,
            weight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Name this bookmark (or keep the default):',
              style: AppText.latin(
                color: c.textMuted,
                size: 13,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              style: AppText.latin(
                color: c.textPrimary,
                size: 14,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: c.surface2,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.inputRadius,
                  borderSide:
                      BorderSide(color: c.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.inputRadius,
                  borderSide:
                      BorderSide(color: c.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.inputRadius,
                  borderSide: BorderSide(
                    color: c.goldText,
                    width: 1.5,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppText.latin(
                color: c.textMuted,
                size: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _bookmarkService.addBookmark(
                page: _currentPage,
                name: controller.text.trim(),
              );
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                SnackBar(
                  content: Text(
                    'Bookmark saved: ${controller.text.trim()}',
                    style: const TextStyle(
                        fontSize: 13),
                  ),
                  backgroundColor: c.brand,
                  duration:
                      const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              'Save',
              style: AppText.latin(
                color: c.goldText,
                size: 14,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookmarksSheet() {
    final c =
        AppColors(isDark: AppState.of(context).isDark);

    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (ctx) {
        return ListenableBuilder(
          listenable: _bookmarkService,
          builder: (ctx, _) {
            final bookmarks =
                _bookmarkService.bookmarks;

            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.base,
                AppSpacing.base,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.divider,
                        borderRadius:
                            AppRadius.pillRadius,
                      ),
                    ),
                  ),
                  const SizedBox(
                      height: AppSpacing.base),
                  Row(
                    children: [
                      Icon(
                          Icons.bookmark_rounded,
                          color: c.goldText,
                          size: 20),
                      const SizedBox(
                          width: AppSpacing.sm),
                      Text(
                        'Bookmarks',
                        style: AppText.latin(
                          color: c.textPrimary,
                          size: 16,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${bookmarks.length}',
                        style: AppText.latin(
                          color: c.goldText,
                          size: 14,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (bookmarks.isEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg),
                      child: Center(
                        child: Text(
                          'No bookmarks yet.\nTap the bookmark icon to save your position.',
                          textAlign: TextAlign.center,
                          style: AppText.latin(
                            color: c.textMuted,
                            size: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            MediaQuery.of(ctx)
                                    .size
                                    .height *
                                0.4,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: bookmarks.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(
                                height: AppSpacing.sm),
                        itemBuilder: (ctx, index) {
                          final bm = bookmarks[index];
                          return _BookmarkRow(
                            bookmark: bm,
                            colors: c,
                            onTap: () {
                              Navigator.of(ctx).pop();
                              _jumpToPage(bm.page);
                            },
                            onDelete: () {
                              _bookmarkService
                                  .removeBookmark(
                                      bm.page);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);
    final downloadService = state.downloadService;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──
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
                      width: AppSpacing.sm),

                  Expanded(
                    child: Text(
                      widget.edition.titleAr,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.arabic(
                        color: c.goldText,
                        size: 16,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // Surah index button
                  if (_isReady &&
                      !_showLoadingOverlay &&
                      widget.edition.hasContentTable)
                    GestureDetector(
                      onTap: _showSurahIndex,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: c.goldLine,
                          borderRadius:
                              AppRadius.buttonRadius,
                          border: Border.all(
                            color: c.goldText
                                .withOpacity(0.5),
                          ),
                        ),
                        child: Icon(
                          Icons.list_rounded,
                          size: 18,
                          color: c.goldText,
                        ),
                      ),
                    ),

                  const SizedBox(width: AppSpacing.sm),

                  // Add bookmark
                  if (_isReady && !_showLoadingOverlay)
                    GestureDetector(
                      onTap: _showAddBookmarkDialog,
                      child: ListenableBuilder(
                        listenable: _bookmarkService,
                        builder: (context, _) {
                          final isMarked =
                              _bookmarkService
                                  .isBookmarked(
                                      _currentPage);
                          return Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isMarked
                                  ? c.goldLine
                                  : c.surface2,
                              borderRadius:
                                  AppRadius.buttonRadius,
                              border: Border.all(
                                color: isMarked
                                    ? c.goldText
                                        .withOpacity(0.5)
                                    : c.divider,
                              ),
                            ),
                            child: Icon(
                              isMarked
                                  ? Icons
                                      .bookmark_rounded
                                  : Icons
                                      .bookmark_border_rounded,
                              size: 16,
                              color: isMarked
                                  ? c.goldText
                                  : c.textFaint,
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(width: AppSpacing.sm),

                  // Bookmarks list
                  if (_isReady && !_showLoadingOverlay)
                    GestureDetector(
                      onTap: _showBookmarksSheet,
                      child: ListenableBuilder(
                        listenable: _bookmarkService,
                        builder: (context, _) {
                          return Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: c.surface2,
                              borderRadius:
                                  AppRadius.buttonRadius,
                              border: Border.all(
                                  color: c.divider),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons
                                      .bookmarks_outlined,
                                  size: 16,
                                  color: c.textPrimary,
                                ),
                                if (_bookmarkService
                                        .count >
                                    0)
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration:
                                          BoxDecoration(
                                        color: c.goldText,
                                        shape:
                                            BoxShape.circle,
                                      ),
                                      alignment:
                                          Alignment.center,
                                      child: Text(
                                        '${_bookmarkService.count}',
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.white,
                                          fontSize: 8,
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(width: AppSpacing.sm),

                  // Page counter
                  if (_isReady && !_showLoadingOverlay)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm - 1,
                      ),
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius:
                            AppRadius.buttonRadius,
                        border: Border.all(
                            color: c.divider),
                      ),
                      child: Text(
                        '${_currentPage + 1}/$_totalPages',
                        style: AppText.latin(
                          color: c.textMuted,
                          size: 10,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Progress bar
            if (_isReady &&
                !_showLoadingOverlay &&
                _totalPages > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base),
                child: ClipRRect(
                  borderRadius: AppRadius.pillRadius,
                  child: LinearProgressIndicator(
                    value: _totalPages > 0
                        ? (_currentPage + 1) /
                            _totalPages
                        : 0,
                    backgroundColor: c.surface2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                            c.goldText),
                    minHeight: 3,
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.sm),

            // PDF viewer
            Expanded(
              child: Stack(
                children: [
                  if (_localPath != null)
                    PDFView(
                      key: ValueKey(_localPath),
                      filePath: _localPath!,
                      enableSwipe: true,
                      swipeHorizontal: true,
                      autoSpacing: false,
                      pageFling: true,
                      pageSnap: true,
                      fitPolicy: FitPolicy.BOTH,
                      defaultPage: _defaultPage,
                      onRender: (pages) {
                        setState(() {
                          _totalPages = pages ?? 0;
                          _isReady = true;
                          _currentPage = _defaultPage;
                        });
                        _hideLoadingOverlay();
                      },
                      onViewCreated: (controller) {
                        _pdfController = controller;
                      },
                      onPageChanged: (page, total) {
                        _onPageChanged(
                            page ?? 0, total ?? 0);
                      },
                      onError: (error) {
                        if (mounted) {
                          setState(() {
                            _showLoadingOverlay = false;
                            _errorMessage =
                                'Could not open Mus\'haf: $error';
                          });
                        }
                      },
                    ),

                  if (_showLoadingOverlay ||
                      _localPath == null)
                    _LoadingOverlay(
                      colors: c,
                      downloadService: downloadService,
                      fileId: _fileId,
                      title: widget.edition.titleAr,
                      errorMessage: _errorMessage,
                      defaultPage: _defaultPage,
                    ),
                ],
              ),
            ),

            // Bottom indicator
            if (_isReady && !_showLoadingOverlay)
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: c.card,
                  border: Border(
                    top: BorderSide(color: c.divider),
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                      vertical: AppSpacing.sm - 1,
                    ),
                    decoration: BoxDecoration(
                      color: c.goldLine,
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: c.goldText
                            .withOpacity(0.35),
                      ),
                    ),
                    child: Text(
                      '${widget.edition.titleAr} · Page ${_currentPage + 1} of $_totalPages',
                      textDirection: TextDirection.rtl,
                      style: AppText.arabic(
                        color: c.goldText,
                        size: 12,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Surah Index Content ──────────────────────────────────

class _SurahIndexContent extends StatelessWidget {
  final MushafEdition edition;
  final AppColors colors;
  final String language;
  final ScrollController scrollController;
  final void Function(int page) onSurahTap;

  const _SurahIndexContent({
    required this.edition,
    required this.colors,
    required this.language,
    required this.scrollController,
    required this.onSurahTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    final items = <_IndexItem>[];

    for (int i = 1; i <= 114; i++) {
      final meta = QuranSkeleton.byNumber(i);
      final page = edition.pageForSurah(i);
      if (meta != null && page != null) {
        items.add(_IndexItem(
          number: i,
          titleAr: meta.nameAr,
          transliteration:
              meta.transliterationFor(language),
          page: page,
          isExtra: false,
        ));
      }
    }

    for (final extra in edition.extras) {
      if (extra.page > 0 &&
          extra.titleAr.isNotEmpty) {
        items.add(_IndexItem(
          number: null,
          titleAr: extra.titleAr,
          transliteration: null,
          page: extra.page,
          isExtra: true,
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.base,
        AppSpacing.base,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.divider,
                borderRadius: AppRadius.pillRadius,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Icon(Icons.list_rounded,
                  color: c.goldText, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'فهرس السور',
                textDirection: TextDirection.rtl,
                style: AppText.arabic(
                  color: c.textPrimary,
                  size: 16,
                  weight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${items.length}',
                style: AppText.latin(
                  color: c.goldText,
                  size: 14,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Expanded(
            child: ListView.separated(
              controller: scrollController,
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm - 2),
              itemBuilder: (ctx, index) {
                final item = items[index];
                return _IndexRow(
                  item: item,
                  colors: c,
                  onTap: () => onSurahTap(item.page),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IndexItem {
  final int? number;
  final String titleAr;
  final String? transliteration;
  final int page;
  final bool isExtra;

  const _IndexItem({
    required this.number,
    required this.titleAr,
    required this.transliteration,
    required this.page,
    required this.isExtra,
  });
}

class _IndexRow extends StatelessWidget {
  final _IndexItem item;
  final AppColors colors;
  final VoidCallback onTap;

  const _IndexRow({
    required this.item,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: item.isExtra ? c.goldLine : c.surface2,
          // listItem radius for list rows
          borderRadius: AppRadius.listItemRadius,
          border: Border.all(
            color: item.isExtra
                ? c.goldText.withOpacity(0.35)
                : c.divider,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isExtra
                    ? c.goldText.withOpacity(0.2)
                    : c.goldLine,
                border: Border.all(
                  color: c.goldText.withOpacity(0.35),
                ),
              ),
              alignment: Alignment.center,
              child: item.number != null
                  ? Text(
                      '${item.number}',
                      style: AppText.latin(
                        color: c.goldText,
                        size: 10,
                        weight: FontWeight.w700,
                      ),
                    )
                  : Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: c.goldText,
                    ),
            ),

            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.titleAr,
                    textDirection: TextDirection.rtl,
                    style: AppText.arabic(
                      color: c.textPrimary,
                      size: 14,
                      weight: FontWeight.w700,
                    ),
                  ),
                  if (item.transliteration !=
                      null) ...[
                    const SizedBox(
                        height: AppSpacing.xs),
                    Text(
                      item.transliteration!,
                      style: AppText.latin(
                        color: c.textMuted,
                        size: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: c.goldLine,
                // pill radius for page number badge
                borderRadius: AppRadius.pillRadius,
                border: Border.all(
                  color: c.goldText.withOpacity(0.3),
                ),
              ),
              child: Text(
                '${item.page}',
                style: AppText.latin(
                  color: c.goldText,
                  size: 11,
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

// ─── Bookmark Row ─────────────────────────────────────────

class _BookmarkRow extends StatelessWidget {
  final PdfBookmark bookmark;
  final AppColors colors;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookmarkRow({
    required this.bookmark,
    required this.colors,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: AppRadius.listItemRadius,
          border: Border.all(color: c.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.goldLine,
                border: Border.all(
                  color: c.goldText.withOpacity(0.35),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${bookmark.page + 1}',
                style: AppText.latin(
                  color: c.goldText,
                  size: 11,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    bookmark.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.latin(
                      color: c.textPrimary,
                      size: 13,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Page ${bookmark.page + 1}',
                    style: AppText.latin(
                      color: c.textFaint,
                      size: 10,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.dangerBg,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 14,
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

// ─── Loading Overlay ──────────────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  final AppColors colors;
  final DownloadService downloadService;
  final String fileId;
  final String title;
  final String? errorMessage;
  final int defaultPage;

  const _LoadingOverlay({
    required this.colors,
    required this.downloadService,
    required this.fileId,
    required this.title,
    required this.errorMessage,
    required this.defaultPage,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    return ListenableBuilder(
      listenable: downloadService,
      builder: (context, _) {
        final isDownloading =
            downloadService.isDownloading(fileId);
        final progress =
            downloadService.progress(fileId);
        final percent = (progress * 100).toInt();

        return Container(
          color: c.bg,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(
                  AppSpacing.xl),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  if (errorMessage != null) ...[
                    Icon(
                      Icons.error_outline_rounded,
                      color: c.danger,
                      size: 48,
                    ),
                    const SizedBox(
                        height: AppSpacing.base),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppText.latin(
                        color: c.danger,
                        size: 13,
                        height: 1.5,
                      ),
                    ),
                  ] else if (isDownloading) ...[
                    SizedBox(
                      width: 60,
                      height: 60,
                      child:
                          CircularProgressIndicator(
                        value: progress > 0
                            ? progress
                            : null,
                        color: c.goldText,
                        strokeWidth: 3,
                        backgroundColor: c.surface2,
                      ),
                    ),
                    const SizedBox(
                        height: AppSpacing.lg),
                    Text(
                      'Downloading $title...',
                      textAlign: TextAlign.center,
                      textDirection:
                          TextDirection.rtl,
                      style: AppText.arabic(
                        color: c.textPrimary,
                        size: 15,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(
                        height: AppSpacing.sm - 2),
                    Text(
                      progress > 0
                          ? '$percent%'
                          : 'Connecting...',
                      style: AppText.latin(
                        color: c.goldText,
                        size: 13,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(
                        height: AppSpacing.md),
                    Text(
                      'This is a one-time download.',
                      textAlign: TextAlign.center,
                      style: AppText.latin(
                        color: c.textMuted,
                        size: 12,
                        height: 1.5,
                      ),
                    ),
                  ] else ...[
                    CircularProgressIndicator(
                      color: c.goldText,
                      strokeWidth: 2,
                    ),
                    const SizedBox(
                        height: AppSpacing.base),
                    Text(
                      defaultPage > 0
                          ? 'Opening to page ${defaultPage + 1}...'
                          : 'Loading Mus\'haf...',
                      style: AppText.latin(
                        color: c.textMuted,
                        size: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
