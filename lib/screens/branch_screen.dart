import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/catalog_service.dart';
import '../core/cover_service.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/book_cover.dart';
import 'book_detail_screen.dart';
import 'quran_screen.dart';

/// Shows all books in a specific branch.
class BranchScreen extends StatefulWidget {
  final Branch branch;
  final CatalogService catalogService;

  const BranchScreen({
    super.key,
    required this.branch,
    required this.catalogService,
  });

  @override
  State<BranchScreen> createState() =>
      _BranchScreenState();
}

class _BranchScreenState
    extends State<BranchScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.branch.id == 'quran') {
      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const QuranScreen(),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);

    if (widget.branch.id == 'quran') {
      return Scaffold(
        backgroundColor: c.bg,
        body: const SizedBox.shrink(),
      );
    }

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
                      width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      widget.branch
                          .nameFor(state.language),
                      style: AppText.latin(
                        color: c.textPrimary,
                        size: 20,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            Expanded(
              child: ListenableBuilder(
                listenable: widget.catalogService,
                builder: (context, _) {
                  final books = widget.catalogService
                      .booksInBranch(
                          widget.branch.id);

                  if (books.isEmpty) {
                    return _ComingSoon(
                      branch: widget.branch,
                      colors: c,
                      language: state.language,
                    );
                  }

                  return ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(
                      AppSpacing.base,
                      0,
                      AppSpacing.base,
                      AppSpacing.lg,
                    ),
                    itemCount: books.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(
                            height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return _BranchBookCard(
                        book: book,
                        colors: c,
                        coverService:
                            state.coverService,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  BookDetailScreen(
                                book: book,
                                catalogService: widget
                                    .catalogService,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Coming Soon ─────────────────────────────────────────

class _ComingSoon extends StatelessWidget {
  final Branch branch;
  final AppColors colors;
  final String language;

  const _ComingSoon({
    required this.branch,
    required this.colors,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: c.brand.withOpacity(0.08),
                borderRadius: AppRadius.cardRadius,
                border: Border.all(
                  color: c.brand.withOpacity(0.18),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                size: 40,
                color: c.brand.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Coming Soon',
              style: AppText.latin(
                color: c.textPrimary,
                size: 22,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Books for ${branch.nameFor(language)} are currently being prepared and verified by scholars.',
              textAlign: TextAlign.center,
              style: AppText.latin(
                color: c.textMuted,
                size: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: c.goldLine,
                borderRadius: AppRadius.listItemRadius,
                border: Border.all(
                  color: c.goldText.withOpacity(0.3),
                ),
              ),
              child: Text(
                'We will notify you when books are available',
                textAlign: TextAlign.center,
                style: AppText.latin(
                  color: c.goldText,
                  size: 12,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Branch Book Card ─────────────────────────────────────

class _BranchBookCard extends StatelessWidget {
  final Book book;
  final AppColors colors;
  final CoverService coverService;
  final VoidCallback onTap;

  const _BranchBookCard({
    required this.book,
    required this.colors,
    required this.coverService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    final totalParts = book.teacherAudio
        .fold(0, (sum, t) => sum + t.totalParts);
    final teacherCount = book.teacherAudio.length;

    return ListenableBuilder(
      listenable: coverService,
      builder: (context, _) {
        final realPages =
            coverService.pageCount(book.id);
        final hasAudio = book.hasAudio &&
            book.teacherAudio.isNotEmpty;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: AppRadius.cardRadius,
              border: Border.all(color: c.divider),
            ),
            child: Row(
              children: [
                BookCoverWidget(
                  book: book,
                  width: 58,
                  height: 78,
                  borderRadius: AppRadius.input,
                ),
                const SizedBox(
                    width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      if (book.isNew ||
                          book.isRecentlyAdded)
                        Container(
                          margin: const EdgeInsets.only(
                            bottom: AppSpacing.sm - 2,
                          ),
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: c.brand
                                .withOpacity(0.12),
                            borderRadius:
                                AppRadius.pillRadius,
                            border: Border.all(
                              color: c.brand
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'NEW',
                            style: AppText.label(
                                color: c.brand),
                          ),
                        ),
                      Text(
                        book.titleAr,
                        textDirection:
                            TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: AppText.arabic(
                          color: c.textPrimary,
                          size: 15,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(
                          height: AppSpacing.xs),
                      Text(
                        book.authorShort,
                        textDirection:
                            TextDirection.rtl,
                        style: AppText.arabic(
                          color: c.goldText,
                          size: 12,
                        ),
                      ),
                      if (realPages != null ||
                          hasAudio) ...[
                        const SizedBox(
                            height: AppSpacing.sm),
                        Row(
                          children: [
                            if (realPages != null) ...[
                              Icon(
                                Icons
                                    .menu_book_outlined,
                                size: 12,
                                color: c.textFaint,
                              ),
                              const SizedBox(
                                  width:
                                      AppSpacing.xs),
                              Text(
                                '$realPages pages',
                                style: AppText.latin(
                                  color: c.textFaint,
                                  size: 11,
                                ),
                              ),
                            ],
                            if (realPages != null &&
                                hasAudio)
                              const SizedBox(
                                  width:
                                      AppSpacing.sm),
                            if (hasAudio) ...[
                              Icon(
                                Icons
                                    .headphones_rounded,
                                size: 12,
                                color: c.goldText,
                              ),
                              const SizedBox(
                                  width:
                                      AppSpacing.xs),
                              Flexible(
                                child: Text(
                                  '$teacherCount ${teacherCount == 1 ? 'teacher' : 'teachers'} · $totalParts parts',
                                  style: AppText.latin(
                                    color: c.goldText,
                                    size: 11,
                                  ),
                                  overflow: TextOverflow
                                      .ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(
                    width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: c.textFaint,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
