import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_state.dart';
import '../core/bookmark_service.dart';
import '../core/models.dart';
import '../core/theme.dart';

/// PDF reader — horizontal swipe default with RTL page mapping.
/// Toggle to vertical scroll available.
class PdfReaderScreen extends StatefulWidget {
  final Book book;
  final String filePath;

  const PdfReaderScreen({
    super.key,
    required this.book,
    required this.filePath,
  });

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  static const _modeKey = 'pdf_reader_mode';

  int _currentRealPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  bool _showLoadingOverlay = true;

  PDFViewController? _pdfController;
  int _savedRealPage = 0;

  /// Default: horizontal (true). User can toggle.
  bool _horizontalMode = true;
  int _rebuildKey = 0;

  final BookmarkService _bookmarkService = BookmarkService();

  // ─── RTL Page Mapping ─────────────────────────────
  // In horizontal mode, we reverse page order so swiping
  // LEFT goes to the NEXT real page (Arabic reading direction).

  int _toViewerPage(int realPage) {
    if (!_horizontalMode || _totalPages <= 0) return realPage;
    return (_totalPages - 1) - realPage;
  }

  int _toRealPage(int viewerPage) {
    if (!_horizontalMode || _totalPages <= 0) return viewerPage;
    return (_totalPages - 1) - viewerPage;
  }

  @override
  void initState() {
    super.initState();
    _loadModePreference();
    _bookmarkService.init().then((_) {
      _bookmarkService.setActivePdf(widget.book.id);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = AppState.of(context);
      if (state.lastBookId == widget.book.id && state.lastBookPage > 0) {
        _savedRealPage = state.lastBookPage;
        _currentRealPage = _savedRealPage;
      }
    });
  }

  Future<void> _loadModePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_modeKey);
      if (saved != null && mounted) {
        setState(() => _horizontalMode = saved);
      }
    } catch (_) {}
  }

  Future<void> _saveModePreference(bool horizontal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_modeKey, horizontal);
    } catch (_) {}
  }

  void _toggleMode() {
    _savedRealPage = _currentRealPage;
    setState(() {
      _horizontalMode = !_horizontalMode;
      _showLoadingOverlay = true;
      _isReady = false;
      _rebuildKey++;
    });
    _saveModePreference(_horizontalMode);
  }

  void _hideLoadingOverlay() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _showLoadingOverlay = false);
    });
  }

  Future<void> _onViewerPageChanged(int viewerPage, int total) async {
    final realPage = _toRealPage(viewerPage);
    setState(() {
      _currentRealPage = realPage;
      _totalPages = total;
      _showLoadingOverlay = false;
    });
    final state = AppState.of(context);
    await state.setLastOpenedBook(
      bookId: widget.book.id,
      bookTitle: widget.book.titleAr,
      page: realPage,
      totalPages: total,
    );
  }

  void _jumpToRealPage(int realPage) {
    if (_totalPages <= 0) return;
    _pdfController?.setPage(_toViewerPage(realPage));
  }

  // ─── Bookmark dialog ──────────────────────────────

  void _showAddBookmarkDialog() {
    if (_bookmarkService.isBookmarked(_currentRealPage)) {
      final c = AppColors(isDark: AppState.of(context).isDark);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Page ${_currentRealPage + 1} is already bookmarked.',
              style: const TextStyle(fontSize: 13)),
          backgroundColor: c.brand,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final controller = TextEditingController(text: 'Page ${_currentRealPage + 1}');
    final c = AppColors(isDark: AppState.of(context).isDark);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Save Bookmark',
            style: AppText.latin(color: c.textPrimary, size: 16, weight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Name this bookmark (or keep the default):',
                style: AppText.latin(color: c.textMuted, size: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: AppText.latin(color: c.textPrimary, size: 14),
              decoration: InputDecoration(
                filled: true, fillColor: c.surface2,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.divider)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.divider)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.brand, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppText.latin(color: c.textMuted, size: 14)),
          ),
          TextButton(
            onPressed: () {
              _bookmarkService.addBookmark(page: _currentRealPage, name: controller.text.trim());
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Bookmark saved: ${controller.text.trim()}',
                    style: const TextStyle(fontSize: 13)),
                backgroundColor: c.brand, duration: const Duration(seconds: 2),
              ));
            },
            child: Text('Save',
                style: AppText.latin(color: c.brand, size: 14, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showBookmarksSheet() {
    final c = AppColors(isDark: AppState.of(context).isDark);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return ListenableBuilder(
          listenable: _bookmarkService,
          builder: (ctx, _) {
            final bookmarks = _bookmarkService.bookmarks;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Row(children: [
                    Icon(Icons.bookmark_rounded, color: c.brand, size: 20),
                    const SizedBox(width: 8),
                    Text('Bookmarks', style: AppText.latin(color: c.textPrimary, size: 16, weight: FontWeight.w700)),
                    const Spacer(),
                    Text('${bookmarks.length}', style: AppText.latin(color: c.brand, size: 14, weight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 12),
                  if (bookmarks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text(
                        'No bookmarks yet.\nTap the bookmark icon to save your position.',
                        textAlign: TextAlign.center,
                        style: AppText.latin(color: c.textMuted, size: 13, height: 1.5),
                      )),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
                      child: ListView.separated(
                        shrinkWrap: true, itemCount: bookmarks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, index) {
                          final bm = bookmarks[index];
                          return _BookmarkRow(bookmark: bm, colors: c,
                            onTap: () { Navigator.of(ctx).pop(); _jumpToRealPage(bm.page); },
                            onDelete: () => _bookmarkService.removeBookmark(bm.page),
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

    if (state.lastBookId == widget.book.id &&
        state.lastBookPage > 0 && _savedRealPage == 0) {
      _savedRealPage = state.lastBookPage;
      _currentRealPage = _savedRealPage;
    }

    // The defaultPage sent to PDFView must be in VIEWER coordinates
    final viewerDefaultPage = _totalPages > 0
        ? _toViewerPage(_savedRealPage)
        : _savedRealPage; // before render, totalPages=0, pass raw

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
                    child: Container(width: 38, height: 38,
                      decoration: BoxDecoration(color: c.surface2,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: c.divider)),
                      child: Icon(Icons.arrow_back_rounded, size: 18, color: c.textPrimary)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(widget.book.titleAr,
                      textDirection: TextDirection.rtl, textAlign: TextAlign.right,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: AppText.arabic(color: c.textPrimary, size: 15, weight: FontWeight.w700))),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _toggleMode,
                    child: Container(width: 34, height: 34,
                      decoration: BoxDecoration(color: c.surface2,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: c.divider)),
                      child: Icon(_horizontalMode ? Icons.view_carousel_rounded : Icons.view_day_rounded,
                          size: 16, color: c.textPrimary)),
                  ),
                  const SizedBox(width: 6),
                  if (_isReady && !_showLoadingOverlay)
                    GestureDetector(
                      onTap: _showAddBookmarkDialog,
                      child: ListenableBuilder(
                        listenable: _bookmarkService,
                        builder: (context, _) {
                          final isMarked = _bookmarkService.isBookmarked(_currentRealPage);
                          return Container(width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: isMarked ? c.brand.withOpacity(0.15) : c.surface2,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: isMarked ? c.brand.withOpacity(0.5) : c.divider)),
                            child: Icon(isMarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                size: 16, color: isMarked ? c.brand : c.textFaint));
                        },
                      ),
                    ),
                  const SizedBox(width: 6),
                  if (_isReady && !_showLoadingOverlay)
                    GestureDetector(
                      onTap: _showBookmarksSheet,
                      child: ListenableBuilder(
                        listenable: _bookmarkService,
                        builder: (context, _) {
                          return Container(width: 34, height: 34,
                            decoration: BoxDecoration(color: c.surface2,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: c.divider)),
                            child: Stack(alignment: Alignment.center, children: [
                              Icon(Icons.bookmarks_outlined, size: 16, color: c.textPrimary),
                              if (_bookmarkService.count > 0)
                                Positioned(top: 2, right: 2,
                                  child: Container(width: 14, height: 14,
                                    decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
                                    alignment: Alignment.center,
                                    child: Text('${_bookmarkService.count}',
                                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)))),
                            ]));
                        },
                      ),
                    ),
                  const SizedBox(width: 6),
                  if (_isReady && !_showLoadingOverlay)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(color: c.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: c.divider)),
                      child: Text('${_currentRealPage + 1}/$_totalPages',
                          style: AppText.latin(color: c.textMuted, size: 10, weight: FontWeight.w700)),
                    ),
                ],
              ),
            ),

            if (_isReady && !_showLoadingOverlay && _totalPages > 0) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _totalPages > 0 ? (_currentRealPage + 1) / _totalPages : 0,
                    backgroundColor: c.surface2,
                    valueColor: AlwaysStoppedAnimation<Color>(c.brand),
                    minHeight: 3),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // ── PDF Viewer ──
            Expanded(
              child: Stack(
                children: [
                  PDFView(
                    key: ValueKey('pdf_${_rebuildKey}_${_horizontalMode}'),
                    filePath: widget.filePath,
                    enableSwipe: true,
                    swipeHorizontal: _horizontalMode,
                    autoSpacing: !_horizontalMode,
                    pageFling: _horizontalMode,
                    pageSnap: _horizontalMode,
                    fitPolicy: FitPolicy.BOTH,
                    // In horizontal RTL mode, we reverse the starting position
                    defaultPage: _horizontalMode && _totalPages > 0
                        ? _toViewerPage(_savedRealPage)
                        : _savedRealPage,
                    onRender: (pages) {
                      final total = pages ?? 0;
                      setState(() {
                        _totalPages = total;
                        _isReady = true;
                        _currentRealPage = _savedRealPage;
                      });
                      // If horizontal, we need to jump to the correct viewer page
                      // AFTER render, because defaultPage might not have worked
                      // (totalPages was 0 when PDFView was built)
                      if (_horizontalMode && total > 0) {
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _pdfController?.setPage(_toViewerPage(_savedRealPage));
                        });
                      }
                      AppState.of(context).setLastOpenedBook(
                        bookId: widget.book.id,
                        bookTitle: widget.book.titleAr,
                        page: _savedRealPage,
                        totalPages: total,
                      );
                      _hideLoadingOverlay();
                    },
                    onViewCreated: (controller) {
                      _pdfController = controller;
                    },
                    onPageChanged: (page, total) {
                      _onViewerPageChanged(page ?? 0, total ?? 0);
                    },
                    onError: (error) {
                      if (mounted) {
                        setState(() => _showLoadingOverlay = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Could not open PDF: $error',
                              style: AppText.latin(color: Colors.white, size: 13)),
                          backgroundColor: c.danger));
                      }
                    },
                  ),

                  if (_showLoadingOverlay)
                    Container(
                      color: c.bg,
                      child: Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: c.brand, strokeWidth: 2),
                          const SizedBox(height: 16),
                          Text(_savedRealPage > 0
                              ? 'Opening to page ${_savedRealPage + 1}...'
                              : 'Loading...',
                              style: AppText.latin(color: c.textMuted, size: 13)),
                        ],
                      )),
                    ),
                ],
              ),
            ),

            if (_isReady && !_showLoadingOverlay)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: c.card,
                    border: Border(top: BorderSide(color: c.divider))),
                child: Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: c.surface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.divider)),
                  child: Text(
                    _horizontalMode
                        ? 'Page ${_currentRealPage + 1} of $_totalPages'
                        : 'Scroll · Page ${_currentRealPage + 1} of $_totalPages',
                    style: AppText.latin(color: c.textMuted, size: 12, weight: FontWeight.w600)),
                )),
              ),
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
  const _BookmarkRow({required this.bookmark, required this.colors,
      required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: c.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.divider)),
        child: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: c.brand.withOpacity(0.12),
                border: Border.all(color: c.brand.withOpacity(0.3))),
            alignment: Alignment.center,
            child: Text('${bookmark.page + 1}',
                style: AppText.latin(color: c.brand, size: 11, weight: FontWeight.w700))),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(bookmark.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: AppText.latin(color: c.textPrimary, size: 13, weight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('Page ${bookmark.page + 1}',
                  style: AppText.latin(color: c.textFaint, size: 10)),
            ],
          )),
          GestureDetector(
            onTap: onDelete,
            child: Container(width: 30, height: 30,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.dangerBg),
              child: Icon(Icons.delete_outline_rounded, size: 14, color: c.danger)),
          ),
        ]),
      ),
    );
  }
}
