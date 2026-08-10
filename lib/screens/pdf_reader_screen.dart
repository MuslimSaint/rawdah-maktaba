import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_state.dart';
import '../core/bookmark_service.dart';
import '../core/content_table_service.dart';
import '../core/models.dart';
import '../core/theme.dart';

/// PDF reader — horizontal default with toggle,
/// universal bookmarks, and optional chapter index.
///
/// Content table source priority (Task 6):
///   1. External TOC file (downloaded separately)
///   2. Embedded contentTable from catalog
///   3. No content table (button not shown)
class PdfReaderScreen extends StatefulWidget {
  final Book book;
  final String filePath;

  const PdfReaderScreen({
    super.key,
    required this.book,
    required this.filePath,
  });

  @override
  State<PdfReaderScreen> createState() =>
      _PdfReaderScreenState();
}

class _PdfReaderScreenState
    extends State<PdfReaderScreen> {
  static const _modeKey = 'pdf_reader_mode';

  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  bool _showLoadingOverlay = true;

  PDFViewController? _pdfController;
  int _defaultPage = 0;

  bool _horizontalMode = true;
  int _rebuildKey = 0;

  final BookmarkService _bookmarkService =
      BookmarkService();

  /// The effective content table — resolved once after
  /// the PDF renders. Can come from external file or
  /// embedded catalog data.
  List<ContentTableEntry>? _resolvedContentTable;
  bool _contentTableResolved = false;

  @override
  void initState() {
    super.initState();
    _loadModePreference();
    _bookmarkService.init().then((_) {
      _bookmarkService.setActivePdf(widget.book.id);
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted) return;
      final state = AppState.of(context);
      if (state.lastBookId == widget.book.id &&
          state.lastBookPage > 0) {
        _defaultPage = state.lastBookPage;
        _currentPage = state.lastBookPage;
      }
    });
  }

  // ─── Resolve content table ─────────────────────

  /// Resolves the effective content table using the
  /// ContentTableService priority chain. Called once
  /// after the PDF is ready.
  Future<void> _resolveContentTable() async {
    if (_contentTableResolved) return;
    _contentTableResolved = true;

    if (!mounted) return;
    final state = AppState.of(context);

    final entries = await state.contentTableService
        .getEffectiveToc(widget.book);

    if (mounted) {
      setState(() {
        _resolvedContentTable = entries;
      });
    }
  }

  /// Whether the content table button should be shown.
  bool get _hasContentTable =>
      _resolvedContentTable != null &&
      _resolvedContentTable!.isNotEmpty;

  // ─── Mode preference ───────────────────────────

  Future<void> _loadModePreference() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();
      final saved = prefs.getBool(_modeKey);
      if (saved != null && mounted) {
        setState(() => _horizontalMode = saved);
      }
    } catch (_) {}
  }

  Future<void> _saveModePreference(
      bool horizontal) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();
      await prefs.setBool(_modeKey, horizontal);
    } catch (_) {}
  }

  void _toggleMode() {
    _defaultPage = _currentPage;
    setState(() {
      _horizontalMode = !_horizontalMode;
      _showLoadingOverlay = true;
      _isReady = false;
      _rebuildKey++;
    });
    _saveModePreference(_horizontalMode);
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

    final state = AppState.of(context);
    await state.setLastOpenedBook(
      bookId: widget.book.id,
      bookTitle: widget.book.titleAr,
      page: page,
      totalPages: total,
    );
  }

  void _jumpToPage(int page) {
    _pdfController?.setPage(page);
  }

  // ─── Content table sheet ───────────────────────

  void _showContentTableSheet() {
    if (!_hasContentTable) return;
    final c =
        AppColors(isDark: AppState.of(context).isDark);
    final entries = _resolvedContentTable!;

    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 16, 20, 0),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: c.divider,
                            borderRadius:
                                BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons
                                .format_list_bulleted_rounded,
                            color: c.goldText,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'فهرس المحتويات',
                            textDirection:
                                TextDirection.rtl,
                            style: AppText.arabic(
                              color: c.textPrimary,
                              size: 16,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: c.goldLine,
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${entries.length}',
                              style: AppText.latin(
                                color: c.goldText,
                                size: 11,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: c.divider),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(
                        20, 4, 20, 24),
                    itemCount: entries.length,
                    itemBuilder: (ctx, index) {
                      final entry = entries[index];
                      final zeroPage = entry.page - 1;

                      return _ContentTableRow(
                        entry: entry,
                        index: index,
                        colors: c,
                        isCurrentChapter:
                            _isCurrentChapter(
                                index, entries),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _jumpToPage(zeroPage.clamp(
                              0, _totalPages - 1));
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isCurrentChapter(
      int index, List<ContentTableEntry> entries) {
    final currentOneBased = _currentPage + 1;
    final thisPage = entries[index].page;
    final nextPage = index + 1 < entries.length
        ? entries[index + 1].page
        : _totalPages + 1;
    return currentOneBased >= thisPage &&
        currentOneBased < nextPage;
  }

  // ─── Bookmark dialogs ──────────────────────────

  void _showAddBookmarkDialog() {
    if (_bookmarkService.isBookmarked(_currentPage)) {
      final c =
          AppColors(isDark: AppState.of(context).isDark);
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
          borderRadius: BorderRadius.circular(20),
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
                  color: c.textMuted, size: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: AppText.latin(
                  color: c.textPrimary, size: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: c.surface2,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: c.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: c.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: c.brand, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: AppText.latin(
                    color: c.textMuted, size: 14)),
          ),
          TextButton(
            onPressed: () {
              _bookmarkService.addBookmark(
                page: _currentPage,
                name: controller.text.trim(),
              );
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(
                content: Text(
                    'Bookmark saved: ${controller.text.trim()}',
                    style: const TextStyle(
                        fontSize: 13)),
                backgroundColor: c.brand,
                duration: const Duration(seconds: 2),
              ));
            },
            child: Text('Save',
                style: AppText.latin(
                    color: c.brand,
                    size: 14,
                    weight: FontWeight.w700)),
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
            top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return ListenableBuilder(
          listenable: _bookmarkService,
          builder: (ctx, _) {
            final bookmarks =
                _bookmarkService.bookmarks;

            return Padding(
              padding: const EdgeInsets.fromLTRB(
                  20, 16, 20, 24),
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
                            BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.bookmark_rounded,
                          color: c.brand, size: 20),
                      const SizedBox(width: 8),
                      Text('Bookmarks',
                          style: AppText.latin(
                              color: c.textPrimary,
                              size: 16,
                              weight:
                                  FontWeight.w700)),
                      const Spacer(),
                      Text('${bookmarks.length}',
                          style: AppText.latin(
                              color: c.brand,
                              size: 14,
                              weight:
                                  FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (bookmarks.isEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                              vertical: 24),
                      child: Center(
                        child: Text(
                          'No bookmarks yet.\nTap the bookmark icon to save your position.',
                          textAlign: TextAlign.center,
                          style: AppText.latin(
                              color: c.textMuted,
                              size: 13,
                              height: 1.5),
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
                            const SizedBox(height: 8),
                        itemBuilder: (ctx, index) {
                          final bm =
                              bookmarks[index];
                          return _BookmarkRow(
                            bookmark: bm,
                            colors: c,
                            onTap: () {
                              Navigator.of(ctx)
                                  .pop();
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

  // ─── Build ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);

    if (state.lastBookId == widget.book.id &&
        state.lastBookPage > 0 &&
        _defaultPage == 0) {
      _defaultPage = state.lastBookPage;
      _currentPage = state.lastBookPage;
    }

    final showControls =
        _isReady && !_showLoadingOverlay;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
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
                        border: Border.all(
                            color: c.divider),
                      ),
                      child: Icon(
                          Icons.arrow_back_rounded,
                          size: 18,
                          color: c.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.book.titleAr,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.arabic(
                        color: c.textPrimary,
                        size: 15,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Content table button — shown when
                  // resolved content table is available.
                  if (_hasContentTable && showControls)
                    GestureDetector(
                      onTap: _showContentTableSheet,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: c.goldLine,
                          borderRadius:
                              BorderRadius.circular(9),
                          border: Border.all(
                              color: c.goldText
                                  .withOpacity(0.4)),
                        ),
                        child: Icon(
                          Icons
                              .format_list_bulleted_rounded,
                          size: 16,
                          color: c.goldText,
                        ),
                      ),
                    ),

                  if (_hasContentTable && showControls)
                    const SizedBox(width: 6),

                  // Mode toggle
                  GestureDetector(
                    onTap: _toggleMode,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius:
                            BorderRadius.circular(9),
                        border: Border.all(
                            color: c.divider),
                      ),
                      child: Icon(
                        _horizontalMode
                            ? Icons
                                .view_carousel_rounded
                            : Icons.view_day_rounded,
                        size: 16,
                        color: c.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Add bookmark
                  if (showControls)
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
                                  ? c.brand
                                      .withOpacity(0.15)
                                  : c.surface2,
                              borderRadius:
                                  BorderRadius.circular(
                                      9),
                              border: Border.all(
                                color: isMarked
                                    ? c.brand
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
                                  ? c.brand
                                  : c.textFaint,
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(width: 6),

                  // Bookmarks list
                  if (showControls)
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
                                  BorderRadius.circular(
                                      9),
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
                                    color: c.textPrimary),
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
                                        color: c.brand,
                                        shape: BoxShape
                                            .circle,
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

                  const SizedBox(width: 6),

                  // Page counter
                  if (showControls)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius:
                            BorderRadius.circular(10),
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
            if (showControls && _totalPages > 0) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _totalPages > 0
                        ? (_currentPage + 1) /
                            _totalPages
                        : 0,
                    backgroundColor: c.surface2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                            c.brand),
                    minHeight: 3,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // PDF Viewer
            Expanded(
              child: Stack(
                children: [
                  PDFView(
                    key: ValueKey(
                        'pdf_${_rebuildKey}_$_horizontalMode'),
                    filePath: widget.filePath,
                    enableSwipe: true,
                    swipeHorizontal: _horizontalMode,
                    autoSpacing: !_horizontalMode,
                    pageFling: _horizontalMode,
                    pageSnap: _horizontalMode,
                    fitPolicy: FitPolicy.BOTH,
                    defaultPage: _defaultPage,
                    onRender: (pages) {
                      setState(() {
                        _totalPages = pages ?? 0;
                        _isReady = true;
                        _currentPage = _defaultPage;
                      });
                      AppState.of(context)
                          .setLastOpenedBook(
                        bookId: widget.book.id,
                        bookTitle: widget.book.titleAr,
                        page: _defaultPage,
                        totalPages: pages ?? 0,
                      );
                      _hideLoadingOverlay();

                      // Resolve content table now that
                      // we know the total pages and the
                      // ContentTableService is ready.
                      _resolveContentTable();
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
                        setState(() =>
                            _showLoadingOverlay =
                                false);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content: Text(
                            'Could not open PDF: $error',
                            style: AppText.latin(
                                color: Colors.white,
                                size: 13),
                          ),
                          backgroundColor: c.danger,
                        ));
                      }
                    },
                  ),

                  if (_showLoadingOverlay)
                    Container(
                      color: c.bg,
                      child: Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                                color: c.brand,
                                strokeWidth: 2),
                            const SizedBox(height: 16),
                            Text(
                              _defaultPage > 0
                                  ? 'Opening to page ${_defaultPage + 1}...'
                                  : 'Loading...',
                              style: AppText.latin(
                                  color: c.textMuted,
                                  size: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom indicator
            if (showControls)
              Container(
                padding:
                    const EdgeInsets.symmetric(
                        vertical: 10),
                decoration: BoxDecoration(
                  color: c.card,
                  border: Border(
                      top: BorderSide(color: c.divider)),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(color: c.divider),
                    ),
                    child: Text(
                      _horizontalMode
                          ? 'Swipe · Page ${_currentPage + 1} of $_totalPages'
                          : 'Scroll · Page ${_currentPage + 1} of $_totalPages',
                      style: AppText.latin(
                        color: c.textMuted,
                        size: 12,
                        weight: FontWeight.w600,
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

// ─── Content Table Row ───────────────────────────────────

class _ContentTableRow extends StatelessWidget {
  final ContentTableEntry entry;
  final int index;
  final AppColors colors;
  final bool isCurrentChapter;
  final VoidCallback onTap;

  const _ContentTableRow({
    required this.entry,
    required this.index,
    required this.colors,
    required this.isCurrentChapter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrentChapter
              ? c.goldLine
              : c.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentChapter
                ? c.goldText.withOpacity(0.5)
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
                color: isCurrentChapter
                    ? c.goldText.withOpacity(0.15)
                    : c.brand.withOpacity(0.08),
                border: Border.all(
                  color: isCurrentChapter
                      ? c.goldText.withOpacity(0.4)
                      : c.brand.withOpacity(0.2),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: AppText.latin(
                  color: isCurrentChapter
                      ? c.goldText
                      : c.brand,
                  size: 11,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    entry.titleAr,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.arabic(
                      color: isCurrentChapter
                          ? c.goldText
                          : c.textPrimary,
                      size: 13,
                      weight: isCurrentChapter
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  ),
                  if (entry.hasEnglish) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.titleEn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.latin(
                        color: isCurrentChapter
                            ? c.goldText
                                .withOpacity(0.8)
                            : c.textMuted,
                        size: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCurrentChapter
                    ? c.goldText.withOpacity(0.15)
                    : c.card,
                borderRadius:
                    BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrentChapter
                      ? c.goldText.withOpacity(0.3)
                      : c.divider,
                ),
              ),
              child: Text(
                'p. ${entry.page}',
                style: AppText.latin(
                  color: isCurrentChapter
                      ? c.goldText
                      : c.textFaint,
                  size: 10,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            if (isCurrentChapter) ...[
              const SizedBox(width: 6),
              Icon(Icons.play_arrow_rounded,
                  size: 14, color: c.goldText),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Bookmark Row ────────────────────────────────────────

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
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.brand.withOpacity(0.12),
                border: Border.all(
                    color: c.brand.withOpacity(0.3)),
              ),
              alignment: Alignment.center,
              child: Text('${bookmark.page + 1}',
                  style: AppText.latin(
                      color: c.brand,
                      size: 11,
                      weight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(bookmark.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.latin(
                          color: c.textPrimary,
                          size: 13,
                          weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Page ${bookmark.page + 1}',
                      style: AppText.latin(
                          color: c.textFaint,
                          size: 10)),
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
                    color: c.dangerBg),
                child: Icon(
                    Icons.delete_outline_rounded,
                    size: 14,
                    color: c.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
