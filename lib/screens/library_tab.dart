import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/book_cover.dart';
import 'book_detail_screen.dart';

/// Library tab — full book catalog with search.
class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() =>
      _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.base,
                AppSpacing.base,
                0,
              ),
              child: Row(
                children: [
                  Text(
                    'Library',
                    style: AppText.latin(
                      color: c.textPrimary,
                      size: 22,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Search Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: c.card,
                  // listItem radius — search bar is
                  // a compact interactive element
                  borderRadius:
                      AppRadius.listItemRadius,
                  border: Border.all(color: c.divider),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                        width: AppSpacing.md),
                    Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: c.textFaint,
                    ),
                    const SizedBox(
                        width: AppSpacing.sm + 2),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(
                            () => _searchQuery = v),
                        style: AppText.latin(
                          color: c.textPrimary,
                          size: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search books...',
                          hintStyle: AppText.latin(
                            color: c.textFaint,
                            size: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(
                              () => _searchQuery = '');
                        },
                        child: Padding(
                          padding:
                              const EdgeInsets.only(
                                  right: AppSpacing.md),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: c.textFaint,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.base),

            // ── Book List ──
            Expanded(
              child: ListenableBuilder(
                listenable: state.catalogService,
                builder: (context, _) {
                  if (state.catalogService.isLoading &&
                      !state.catalogService.hasData) {
                    return Center(
                      child:
                          CircularProgressIndicator(
                        color: c.brand,
                        strokeWidth: 2,
                      ),
                    );
                  }

                  if (state.catalogService.error !=
                          null &&
                      !state.catalogService.hasData) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(
                            AppSpacing.xl),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              size: 48,
                              color: c.textFaint,
                            ),
                            const SizedBox(
                                height: AppSpacing.base),
                            Text(
                              'No internet connection',
                              style: AppText.latin(
                                color: c.textPrimary,
                                size: 16,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(
                                height: AppSpacing.sm),
                            Text(
                              'Please connect to load the book catalog.',
                              textAlign:
                                  TextAlign.center,
                              style: AppText.latin(
                                color: c.textMuted,
                                size: 13,
                              ),
                            ),
                            const SizedBox(
                                height: AppSpacing.lg),
                            GestureDetector(
                              onTap: () => state
                                  .catalogService
                                  .refresh(),
                              child: Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal:
                                      AppSpacing.lg,
                                  vertical:
                                      AppSpacing.md,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: c.brand,
                                  borderRadius:
                                      AppRadius
                                          .buttonRadius,
                                ),
                                child: Text(
                                  'Try Again',
                                  style: AppText.latin(
                                    color: Colors.white,
                                    size: 14,
                                    weight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final books = state.catalogService
                      .search(_searchQuery);

                  if (books.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: c.textFaint,
                          ),
                          const SizedBox(
                              height: AppSpacing.base),
                          Text(
                            'No books found',
                            style: AppText.latin(
                              color: c.textPrimary,
                              size: 16,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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
                      return _BookCard(
                        book: books[index],
                        colors: c,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  BookDetailScreen(
                                book: books[index],
                                catalogService: state
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

// ─── Book Card ───────────────────────────────────────────

class _BookCard extends StatelessWidget {
  final Book book;
  final AppColors colors;
  final VoidCallback onTap;

  const _BookCard({
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
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: c.card,
          // Large content card → card radius
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

            const SizedBox(width: AppSpacing.md),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  if (book.isNew ||
                      book.isRecentlyAdded)
                    Container(
                      margin: const EdgeInsets.only(
                          bottom: AppSpacing.sm - 2),
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            c.brand.withOpacity(0.12),
                        // pill radius for tags/badges
                        borderRadius:
                            AppRadius.pillRadius,
                        border: Border.all(
                          color:
                              c.brand.withOpacity(0.3),
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
                    textDirection: TextDirection.rtl,
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
                    textDirection: TextDirection.rtl,
                    style: AppText.arabic(
                      color: c.goldText,
                      size: 12,
                    ),
                  ),

                  const SizedBox(
                      height: AppSpacing.sm),

                  Wrap(
                    spacing: AppSpacing.sm - 2,
                    runSpacing: AppSpacing.xs,
                    children: [
                      ...book.branches.map((branchId) {
                        final branch =
                            Catalog.branches
                                .firstWhere(
                          (b) => b.id == branchId,
                          orElse: () => const Branch(
                            id: '',
                            nameEn: '',
                            nameAr: '',
                            nameAm: '',
                          ),
                        );
                        return _Tag(
                          label: branch.nameEn,
                          colors: c,
                          isGold: false,
                        );
                      }),
                      if (book.hasAudio)
                        _Tag(
                          label: 'Audio',
                          colors: c,
                          isGold: true,
                          icon: Icons.headphones_rounded,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),
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

class _Tag extends StatelessWidget {
  final String label;
  final AppColors colors;
  final bool isGold;
  final IconData? icon;

  const _Tag({
    required this.label,
    required this.colors,
    required this.isGold,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: isGold
            ? c.goldLine
            : c.brand.withOpacity(0.08),
        // pill radius for all tags/chips
        borderRadius: AppRadius.pillRadius,
        border: Border.all(
          color: isGold
              ? c.goldText.withOpacity(0.3)
              : c.brand.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 10,
              color: isGold ? c.goldText : c.brand,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppText.latin(
              color: isGold ? c.goldText : c.brand,
              size: 10,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
