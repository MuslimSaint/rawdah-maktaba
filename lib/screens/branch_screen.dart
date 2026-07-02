import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/catalog_service.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'book_detail_screen.dart';

/// Shows all books in a specific branch.
/// If branch has no books → shows professional Coming Soon screen.
class BranchScreen extends StatefulWidget {
  final Branch branch;
  final CatalogService catalogService;

  const BranchScreen({
    super.key,
    required this.branch,
    required this.catalogService,
  });

  @override
  State<BranchScreen> createState() => _BranchScreenState();
}

class _BranchScreenState extends State<BranchScreen> {
  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);

    return Directionality(
      textDirection: state.textDirection,
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    // Back button
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

                    // Branch name
                    Expanded(
                      child: Text(
                        widget.branch.nameFor(state.language),
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

              const SizedBox(height: 20),

              // ── Content ──
              Expanded(
                child: ListenableBuilder(
                  listenable: widget.catalogService,
                  builder: (context, _) {
                    final books = widget.catalogService
                        .booksInBranch(widget.branch.id);

                    // Coming Soon — no books in this branch
                    if (books.isEmpty) {
                      return _ComingSoon(
                        branch: widget.branch,
                        colors: c,
                        language: state.language,
                      );
                    }

                    // Book list
                    return ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: books.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return _BranchBookCard(
                          book: book,
                          colors: c,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BookDetailScreen(
                                  book: book,
                                  catalogService:
                                      widget.catalogService,
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
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: c.brand.withOpacity(0.08),
                borderRadius: BorderRadius.circular(28),
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

            const SizedBox(height: 24),

            Text(
              'Coming Soon',
              style: AppText.latin(
                color: c.textPrimary,
                size: 22,
                weight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Books for ${branch.nameFor(language)} are currently being prepared and verified by scholars.',
              textAlign: TextAlign.center,
              style: AppText.latin(
                color: c.textMuted,
                size: 14,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: c.goldLine,
                borderRadius: BorderRadius.circular(12),
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

// ─── Branch Book Card ────────────────────────────────────

class _BranchBookCard extends StatelessWidget {
  final Book book;
  final AppColors colors;
  final VoidCallback onTap;

  const _BranchBookCard({
    required this.book,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.divider),
        ),
        child: Row(
          children: [
            // Cover
            Container(
              width: 58,
              height: 78,
              decoration: BoxDecoration(
                color: c.brand.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: c.brand.withOpacity(0.2),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  book.localCoverAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 26,
                      color: c.brand,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (book.isNew || book.isRecentlyAdded)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: c.brand.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: c.brand.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'NEW',
                        style: AppText.label(color: c.brand),
                      ),
                    ),

                  Text(
                    book.titleAr,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: AppText.arabic(
                      color: c.textPrimary,
                      size: 15,
                      weight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    book.authorShort,
                    textDirection: TextDirection.rtl,
                    style: AppText.arabic(
                      color: c.goldText,
                      size: 12,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 12,
                        color: c.textFaint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${book.pages} pages',
                        style: AppText.latin(
                          color: c.textFaint,
                          size: 11,
                        ),
                      ),
                      if (book.hasAudio) ...[
                        const SizedBox(width: 10),
                        Icon(
                          Icons.headphones_rounded,
                          size: 12,
                          color: c.goldText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${book.audioParts} parts',
                          style: AppText.latin(
                            color: c.goldText,
                            size: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: c.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}
