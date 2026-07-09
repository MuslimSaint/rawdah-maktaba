import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';

/// PDF reader screen.
/// Supports two reading modes:
///   • Horizontal page-swipe (default — like a real book)
///   • Vertical scroll (classic)
/// User's choice is saved across app restarts.
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

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  static const _modeKey = 'pdf_reader_mode';

  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  bool _showLoadingOverlay = true;

  PDFViewController? _pdfController;
  int _defaultPage = 0;

  /// true = horizontal page swipe (default)
  /// false = vertical scroll
  bool _horizontalMode = true;

  /// Bumped every time the user toggles mode.
  /// Used as a ValueKey so PDFView rebuilds cleanly.
  int _rebuildKey = 0;

  @override
  void initState() {
    super.initState();
    _loadModePreference();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = AppState.of(context);
      if (state.lastBookId == widget.book.id &&
          state.lastBookPage > 0) {
        _defaultPage = state.lastBookPage;
        _currentPage = state.lastBookPage;
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
    // Preserve current page across mode switch
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
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _showLoadingOverlay = false);
      }
    });
  }

  Future<void> _onPageChanged(int page, int total) async {
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
                        border: Border.all(color: c.divider),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                  const SizedBox(width: 8),

                  // ── Mode toggle button ──
                  GestureDetector(
                    onTap: _toggleMode,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius:
                            BorderRadius.circular(11),
                        border: Border.all(color: c.divider),
                      ),
                      child: Icon(
                        _horizontalMode
                            ? Icons
                                .view_carousel_rounded
                            : Icons.view_day_rounded,
                        size: 18,
                        color: c.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  if (_isReady && !_showLoadingOverlay)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius:
                            BorderRadius.circular(10),
                        border:
                            Border.all(color: c.divider),
                      ),
                      child: Text(
                        '${_currentPage + 1} / $_totalPages',
                        style: AppText.latin(
                          color: c.textMuted,
                          size: 11,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Progress Bar ──
            if (_isReady &&
                !_showLoadingOverlay &&
                _totalPages > 0) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _totalPages > 0
                        ? (_currentPage + 1) / _totalPages
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

            // ── PDF Viewer + Loading Overlay ──
            Expanded(
              child: Stack(
                children: [
                  PDFView(
                    key: ValueKey(
                        'pdf_${_rebuildKey}_${_horizontalMode}'),
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
                      AppState.of(context).setLastOpenedBook(
                        bookId: widget.book.id,
                        bookTitle: widget.book.titleAr,
                        page: _defaultPage,
                        totalPages: pages ?? 0,
                      );
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
                        setState(() =>
                            _showLoadingOverlay = false);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not open PDF: $error',
                              style: AppText.latin(
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                            backgroundColor: c.danger,
                          ),
                        );
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
                              strokeWidth: 2,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _defaultPage > 0
                                  ? 'Opening to page ${_defaultPage + 1}...'
                                  : 'Loading...',
                              style: AppText.latin(
                                color: c.textMuted,
                                size: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Bottom Page Indicator ──
            if (_isReady && !_showLoadingOverlay)
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 10),
                decoration: BoxDecoration(
                  color: c.card,
                  border: Border(
                    top: BorderSide(color: c.divider),
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius:
                          BorderRadius.circular(20),
                      border:
                          Border.all(color: c.divider),
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
