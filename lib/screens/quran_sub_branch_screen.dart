import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/cover_service.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/book_cover.dart';
import 'book_detail_screen.dart';

/// A Quran sub-branch of type "branch" — behaves like a
/// regular branch (e.g., Fiqh, Hadith). Lists the books
/// inside the sub-branch. Tapping a book opens the standard
/// BookDetailScreen.
class QuranSubBranchScreen extends StatelessWidget {
  final QuranSubBranch sub;

  const QuranSubBranchScreen({
    super.key,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
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
                      sub.titleAr,
                      textDirection: TextDirection.rtl,
                      style: AppText.arabic(
                        color: c.goldText,
                        size: 20,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: sub.books.isEmpty
                  ? _ComingSoon(sub: sub, colors: c)
                  : ListenableBuilder(
                      listenable: state.catalogService,
                      builder: (context, _) {
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              20, 0, 20, 24),
                          itemCount: sub.books.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final book = sub.books[index];
                            return _SubBranchBookCard(
                              book: book,
                              colors: c,
                              coverService: state.coverService,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        BookDetailScreen(
                                      book: book,
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

// ─── Coming Soon ─────────────────────────────────────────

class _ComingSoon extends StatelessWidget {
  final QuranSubBranch sub;
  final AppColors colors;

  const _ComingSoon({
    required this.sub,
    required this.colors,
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
              'Books for ${sub.titleAr} are currently being prepared and verified by scholars.',
              textAlign: TextAlign.center,
              style: AppText.latin(
                color: c.textMuted,
                size: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-branch Book Card ────────────────────────────────

class _SubBranchBookCard extends StatelessWidget {
  final Book book;
  final AppColors colors;
  final CoverService coverService;
  final VoidCallback onTap;

  const _SubBranchBookCard({
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
        final realPages = coverService.pageCount(book.id);
        final hasAudio =
            book.hasAudio && book.teacherAudio.isNotEmpty;

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
                BookCoverWidget(
                  book: book,
                  width: 58,
                  height: 78,
                  borderRadius: 10,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      if (book.isNew || book.isRecentlyAdded)
                        Container(
                          margin: const EdgeInsets.only(
                              bottom: 6),
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: c.brand.withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(5),
                            border: Border.all(
                              color: c.brand.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'NEW',
                            style:
                                AppText.label(color: c.brand),
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
                      if (realPages != null || hasAudio) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (realPages != null) ...[
                              Icon(
                                Icons.menu_book_outlined,
                                size: 12,
                                color: c.textFaint,
                              ),
                              const SizedBox(width: 4),
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
                              const SizedBox(width: 10),
                            if (hasAudio) ...[
                              Icon(
                                Icons.headphones_rounded,
                                size: 12,
                                color: c.goldText,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '$teacherCount ${teacherCount == 1 ? 'teacher' : 'teachers'} · $totalParts parts',
                                  style: AppText.latin(
                                    color: c.goldText,
                                    size: 11,
                                  ),
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
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
      },
    );
  }
}
