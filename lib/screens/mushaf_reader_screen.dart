import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../core/app_state.dart';
import '../core/download_service.dart';
import '../core/models.dart';
import '../core/theme.dart';

/// Dedicated reader for the Full Mus'haf sub-branch.
///
/// Behavior:
///   • Downloads the sub-branch's PDF if not present (auto).
///   • Opens the PDF at the last locally-saved page.
///   • Saves position locally on every page turn (no Firebase).
///   • Extra features (bookmarks, keep-screen-on, etc.) added
///     in a follow-up batch — this file exposes the plumbing.
class MushafReaderScreen extends StatefulWidget {
  final QuranSubBranch sub;

  const MushafReaderScreen({
    super.key,
    required this.sub,
  });

  @override
  State<MushafReaderScreen> createState() =>
      _MushafReaderScreenState();
}

class _MushafReaderScreenState
    extends State<MushafReaderScreen> {
  static const _fileId = 'pdf_mushaf';

  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  bool _showLoadingOverlay = true;
  String? _localPath;
  String? _errorMessage;

  PDFViewController? _pdfController;
  int _defaultPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    final state = AppState.of(context);

    // Read the saved local last page BEFORE loading the PDF.
    _defaultPage = state.mushafLastPage;
    _currentPage = _defaultPage;

    final downloadService = state.downloadService;

    // Already downloaded?
    if (downloadService.isDownloaded(_fileId)) {
      final path = await downloadService.localPath(_fileId);
      if (path != null && mounted) {
        setState(() => _localPath = path);
      }
      return;
    }

    // Not downloaded — start download
    if (widget.sub.pdfUrl.isEmpty) {
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
      url: widget.sub.pdfUrl,
      displayName: widget.sub.titleAr,
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
    // Persist locally — no Firebase.
    await AppState.of(context).setMushafLastPage(page);
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
                      widget.sub.titleAr,
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

            // Progress bar
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
                            c.goldText),
                    minHeight: 3,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // PDF viewer + overlays
            Expanded(
              child: Stack(
                children: [
                  // Only build PDFView once we have a path
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

                  // Loading / progress overlay
                  if (_showLoadingOverlay ||
                      _localPath == null)
                    _LoadingOverlay(
                      colors: c,
                      downloadService: downloadService,
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
                      color: c.goldLine,
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            c.goldText.withOpacity(0.35),
                      ),
                    ),
                    child: Text(
                      'Mus\'haf · Page ${_currentPage + 1} of $_totalPages',
                      style: AppText.latin(
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

// ─── Loading Overlay ─────────────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  final AppColors colors;
  final DownloadService downloadService;
  final String? errorMessage;
  final int defaultPage;

  const _LoadingOverlay({
    required this.colors,
    required this.downloadService,
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
            downloadService.isDownloading('pdf_mushaf');
        final progress =
            downloadService.progress('pdf_mushaf');
        final percent = (progress * 100).toInt();

        return Container(
          color: c.bg,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (errorMessage != null) ...[
                    Icon(
                      Icons.error_outline_rounded,
                      color: c.danger,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
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
                      child: CircularProgressIndicator(
                        value: progress > 0 ? progress : null,
                        color: c.goldText,
                        strokeWidth: 3,
                        backgroundColor: c.surface2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Downloading Mus\'haf...',
                      style: AppText.latin(
                        color: c.textPrimary,
                        size: 15,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
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
                    const SizedBox(height: 12),
                    Text(
                      'This is a one-time download. After this, the Mus\'haf opens instantly.',
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
                    const SizedBox(height: 16),
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
