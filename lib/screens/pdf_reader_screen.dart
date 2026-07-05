import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';

/// PDF reader screen.
/// Fixed: blank white screen on open for ALL pages including page 1.
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
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;

  // ← Key fix: always show loading until onRender fires
  // AND we've given enough time for the page to render visually
  bool _showLoadingOverlay = true;

  PDFViewController? _pdfController;
  int _defaultPage = 0;

  @override
  void initState() {
    super.initState();
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

  void _hideLoadingOverlay() {
    // Always wait at least 400ms after onRender
    // before hiding the overlay. This covers:
    // - Page 1: PDF renders but onPageChanged never fires
    // - Other pages: PDF jumps to saved page
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
      // Hide overlay as soon as any page change fires
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

    // Read saved page
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
                  const SizedBox(width: 14),
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
                  const SizedBox(width: 14),
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
                  // PDF always in widget tree
                  PDFView(
                    filePath: widget.filePath,
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: true,
                    pageFling: false,
                    pageSnap: false,
                    fitPolicy: FitPolicy.WIDTH,
                    defaultPage: _defaultPage,
                    onRender: (pages) {
                      setState(() {
                        _totalPages = pages ?? 0;
                        _isReady = true;
                        _currentPage = _defaultPage;
                      });

                      // Save opened book
                      AppState.of(context).setLastOpenedBook(
                        bookId: widget.book.id,
                        bookTitle: widget.book.titleAr,
                        page: _defaultPage,
                        totalPages: pages ?? 0,
                      );

                      // Always hide overlay after delay
                      // Works for ALL pages including page 1
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
                      // Hide overlay on error too
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

                  // ← Loading overlay — always shows until
                  // PDF is visually ready (all pages including 1)
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
                padding:
                    const EdgeInsets.symmetric(vertical: 10),
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
                      border: Border.all(color: c.divider),
                    ),
                    child: Text(
                      'Page ${_currentPage + 1} of $_totalPages',
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
