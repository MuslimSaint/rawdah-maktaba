import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_state.dart';
import '../core/bookmark_service.dart';
import '../core/content_table_service.dart';
import '../core/models.dart';
import '../core/theme.dart';

/// PDF reader — horizontal default with toggle,
/// universal bookmarks, and optional hierarchical
/// chapter index.
///
/// Content table source priority:
///   1. External TOC file (downloaded separately)
///   2. Embedded contentTable from catalog
///   3. No content table (button not shown)
///
/// Hierarchy is controlled entirely by the TOC JSON
/// file structure. Each entry may have a "children"
/// array. Depth is unlimited.
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
        return _ContentTableSheet(
          entries: entries,
          currentPageOneBased: _currentPage + 1,
          totalPages: _totalPages,
          colors: c,
          onTap: (page) {
            Navigator.of(ctx).pop();
            _jumpToPage(
                (page - 1).clamp(0, _totalPages - 1));
          },
        );
      },
    );
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

// ─── Content Table Sheet ─────────────────────────────────
//
// Stateful sheet that manages expansion state for
// hierarchical entries. Expansion state resets each
// time the sheet is opened (fresh session).

class _ContentTableSheet extends StatefulWidget {
  final List<ContentTableEntry> entries;
  final int currentPageOneBased;
  final int totalPages;
  final AppColors colors;
  final void Function(int page) onTap;

  const _ContentTableSheet({
    required this.entries,
    required this.currentPageOneBased,
    required this.totalPages,
    required this.colors,
    required this.onTap,
  });

  @override
  State<_ContentTableSheet> createState() =>
      _ContentTableSheetState();
}

class _ContentTableSheetState
    extends State<_ContentTableSheet> {
  /// Tracks which entries are currently expanded.
  /// Key = a stable path string like "0.2.1" that
  /// uniquely identifies an entry by its position
  /// in the tree.
  final Set<String> _expanded = <String>{};

  int _totalEntries(
      List<ContentTableEntry> list) {
    var count = 0;
    for (final e in list) {
      count += 1 + _totalEntries(e.children);
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final total = _totalEntries(widget.entries);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
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
                          '$total',
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
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                    16, 4, 16, 24),
                children: _buildTree(
                  entries: widget.entries,
                  parentPath: '',
                  depth: 0,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Recursively builds the flat list of rows to
  /// display, respecting the current expansion state.
  List<Widget> _buildTree({
    required List<ContentTableEntry> entries,
    required String parentPath,
    required int depth,
  }) {
    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final path = parentPath.isEmpty
          ? '$i'
          : '$parentPath.$i';
      final isExpanded = _expanded.contains(path);

      rows.add(_ContentTableRow(
        entry: entry,
        depth: depth,
        isExpanded: isExpanded,
        colors: widget.colors,
        isCurrentChapter: _isCurrentChapter(entry),
        onTap: () => widget.onTap(entry.page),
        onToggleExpand: entry.hasChildren
            ? () {
                setState(() {
                  if (isExpanded) {
                    _expanded.remove(path);
                  } else {
                    _expanded.add(path);
                  }
                });
              }
            : null,
      ));

      if (isExpanded && entry.hasChildren) {
        rows.addAll(_buildTree(
          entries: entry.children,
          parentPath: path,
          depth: depth + 1,
        ));
      }
    }
    return rows;
  }

  /// True if the current PDF page falls within
  /// this entry's range. For leaf entries, the
  /// range is [entry.page, next entry's page).
  /// For parent entries, the range spans until
  /// the next sibling at the same or shallower
  /// level.
  bool _isCurrentChapter(ContentTableEntry entry) {
    final cur = widget.currentPageOneBased;
    if (cur < entry.page) return false;
    final nextPage =
        _findNextPage(entry, widget.entries);
    if (nextPage == null) {
      return cur <= widget.totalPages;
    }
    return cur < nextPage;
  }

  /// Finds the page number of the entry that
  /// comes right after `target` in a flattened
  /// depth-first traversal. Returns null if
  /// `target` is the last entry.
  int? _findNextPage(
    ContentTableEntry target,
    List<ContentTableEntry> tree,
  ) {
    final flat = <ContentTableEntry>[];
    void flatten(List<ContentTableEntry> list) {
      for (final e in list) {
        flat.add(e);
        flatten(e.children);
      }
    }

    flatten(tree);
    final idx = flat.indexOf(target);
    if (idx < 0 || idx == flat.length - 1) {
      return null;
    }
    return flat[idx + 1].page;
  }
}

// ─── Content Table Row ───────────────────────────────────

class _ContentTableRow extends StatelessWidget {
  final ContentTableEntry entry;
  final int depth;
  final bool isExpanded;
  final AppColors colors;
  final bool isCurrentChapter;
  final VoidCallback onTap;
  final VoidCallback? onToggleExpand;

  const _ContentTableRow({
    required this.entry,
    required this.depth,
    required this.isExpanded,
    required this.colors,
    required this.isCurrentChapter,
    required this.onTap,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    // Progressive indent: 16 px per depth level.
    final leftPad = 4.0 + (depth * 16.0);

    return Padding(
      padding: EdgeInsets.only(
        left: leftPad,
        right: 4,
        bottom: 6,
      ),
      child: Row(
        children: [
          // Main tappable body: title + page badge
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isCurrentChapter
                      ? c.goldLine
                      : c.surface2,
                  borderRadius:
                      BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrentChapter
                        ? c.goldText.withOpacity(0.5)
                        : c.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.titleAr,
                        textDirection:
                            TextDirection.rtl,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
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
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3),
                      decoration: BoxDecoration(
                        color: isCurrentChapter
                            ? c.goldText
                                .withOpacity(0.15)
                            : c.card,
                        borderRadius:
                            BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrentChapter
                              ? c.goldText
                                  .withOpacity(0.3)
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
                      Icon(
                          Icons.play_arrow_rounded,
                          size: 14,
                          color: c.goldText),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Expand/retract chevron button (only when
          // this entry has children).
          if (onToggleExpand != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onToggleExpand,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isExpanded
                      ? c.brand.withOpacity(0.12)
                      : c.surface2,
                  borderRadius:
                      BorderRadius.circular(10),
                  border: Border.all(
                    color: isExpanded
                        ? c.brand.withOpacity(0.4)
                        : c.divider,
                  ),
                ),
                child: AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(
                      milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: isExpanded
                        ? c.brand
                        : c.textMuted,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Placeholder to keep alignment consistent
            // when there is no expand button.
            const SizedBox(width: 38),
          ],
        ],
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
