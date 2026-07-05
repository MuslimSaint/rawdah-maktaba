import 'dart:io';
import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';

/// Reusable book cover widget.
/// Shows extracted PDF cover if available,
/// falls back to placeholder if not downloaded yet.
class BookCoverWidget extends StatelessWidget {
  final Book book;
  final double width;
  final double height;
  final double borderRadius;

  const BookCoverWidget({
    super.key,
    required this.book,
    required this.width,
    required this.height,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);

    return ListenableBuilder(
      listenable: state.coverService,
      builder: (context, _) {
        final coverPath =
            state.coverService.coverPath(book.id);

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: c.brand.withOpacity(0.12),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: c.brand.withOpacity(0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: coverPath != null
                ? _RealCover(path: coverPath)
                : _Placeholder(book: book, colors: c),
          ),
        );
      },
    );
  }
}

/// Shows the real extracted PDF cover.
class _RealCover extends StatelessWidget {
  final String path;
  const _RealCover({required this.path});

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          _buildFallback(context),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);
    return Center(
      child: Icon(
        Icons.menu_book_rounded,
        color: c.brand,
      ),
    );
  }
}

/// Shows placeholder when cover not extracted yet.
class _Placeholder extends StatelessWidget {
  final Book book;
  final AppColors colors;
  const _Placeholder({required this.book, required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final isPdfDownloaded = AppState.of(context)
        .downloadService
        .isDownloaded('pdf_${book.id}');

    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.menu_book_rounded,
          size: 26,
          color: c.brand,
        ),
        // Show small download indicator if not downloaded
        if (!isPdfDownloaded)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: c.brand.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.download_rounded,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
