import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'book_detail_screen.dart';

/// Library tab — uses shared CatalogService from AppState.
class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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

            const SizedBox(height: 12),

            // ── Search Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: c.divider),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: c.textFaint,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) {
                          setState(() => _searchQuery = v);
                        },
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
                          setState(() => _searchQuery = '');
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
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

            const SizedBox(height: 16),

            // ── Book List ──
            Expanded(
              child: ListenableBuilder(
                listenable: state.catalogService,
                builder: (context, _) {
                  // Loading
                  if (state.catalogService.isLoading &&
                      !state.catalogService.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: c.brand,
                        strokeWidth: 2,
                      ),
                    );
                  }

                  // Error
                  if (state.catalogService.error != null &&
                      !state.catalogService.hasData) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              size: 48,
                              color: c.textFaint,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No internet connection',
                              style: AppText.latin(
                                color: c.textPrimary,
                                size: 16,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please connect to load the book catalog.',
                              textAlign: TextAlign.center,
                              style: AppText.latin(
                                color: c.textMuted,
                                size: 13,
                              ),
                            ),
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTap: () =>
                                  state.catalogService.refresh(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: c.brand,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Try Again',
                                  style: AppText.latin(
                                    color: Colors.white,
                                    size: 14,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final books =
                      state.catalogService.search(_searchQuery);

                  if (books.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: c.textFaint,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No books found',
                            style: AppText.latin(
                              color: c.textPrimary,
                              size: 16,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search term',
                            style: AppText.latin(
                              color: c.textMuted,
                              size: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: books.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return _BookCard(
                        book: book,
                        colors: c,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BookDetailScreen(
                                book: book,
                                catalogService:
                                    state.catalogService,
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
                border:
                    Border.all(color: c.brand.withOpacity(0.2)),
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

                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ...book.branches.map((branchId) {
                        final branch = Catalog.branches.firstWhere(
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
      padding:
          const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isGold
            ? c.goldLine
            : c.brand.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
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
            const SizedBox(width: 3),
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
