import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';

/// PDF reader screen.
/// Opens a locally downloaded PDF file.
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
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  PDFViewController? _pdfController;

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
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius: BorderRadius.circular(11),
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
                  if (_isReady)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: c.divider),
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

            // ── Reading Progress Bar ──
            if (_isReady && _totalPages > 0) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _totalPages > 0
                        ? (_currentPage + 1) / _totalPages
                        : 0,
                    backgroundColor: c.surface2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(c.brand),
                    minHeight: 3,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // ── PDF Viewer ──
            Expanded(
              child: PDFView(
                filePath: widget.filePath,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: true,
                pageFling: false,
                pageSnap: false,
                fitPolicy: FitPolicy.WIDTH,
                onRender: (pages) {
                  setState(() {
                    _totalPages = pages ?? 0;
                    _isReady = true;
                  });
                },
                onViewCreated: (controller) {
                  _pdfController = controller;
                },
                onPageChanged: (page, total) {
                  setState(() {
                    _currentPage = page ?? 0;
                    _totalPages = total ?? 0;
                  });
                },
                onError: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
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
                },
              ),
            ),

            // ── Bottom Page Indicator ──
            if (_isReady)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
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
                      borderRadius: BorderRadius.circular(20),
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
