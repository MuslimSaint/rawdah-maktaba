import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/quran_data.dart';
import '../core/theme.dart';
import '../widgets/book_cover.dart';
import '../widgets/branch_hero_card.dart';
import 'branch_screen.dart';
import 'book_detail_screen.dart';
import 'mushaf_reader_screen.dart';
import 'quran_screen.dart';
import 'surah_detail_screen.dart';

/// Home tab.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: state,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(colors: c),
                  const SizedBox(height: 18),

                  ListenableBuilder(
                    listenable: Listenable.merge([
                      state.catalogService,
                      state,
                    ]),
                    builder: (context, _) {
                      final a = state
                          .catalogService.activeAnnouncement;
                      if (a == null) {
                        return const SizedBox.shrink();
                      }
                      final fingerprint =
                          AppState.announcementFingerprint(
                              a.message, a.type);
                      if (state.isAnnouncementDismissed(
                          fingerprint)) {
                        return const SizedBox.shrink();
                      }
                      return _AnnouncementBanner(
                        announcement: a,
                        fingerprint: fingerprint,
                        colors: c,
                      );
                    },
                  ),

                  _DailyHadith(colors: c),
                  const SizedBox(height: 18),

                  _ContinueReading(colors: c),
                  const SizedBox(height: 22),

                  _BranchesSection(colors: c),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Announcement Banner ─────────────────────────────────

class _AnnouncementBanner extends StatelessWidget {
  final Announcement announcement;
  final String fingerprint;
  final AppColors colors;

  const _AnnouncementBanner({
    required this.announcement,
    required this.fingerprint,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final a = announcement;

    Color bgColor;
    Color textColor;
    IconData icon;

    switch (a.type) {
      case 'warning':
        bgColor = c.goldLine;
        textColor = c.goldText;
        icon = Icons.warning_amber_rounded;
        break;
      case 'success':
        bgColor = c.brand.withOpacity(0.1);
        textColor = c.brand;
        icon = Icons.check_circle_outline_rounded;
        break;
      default:
        bgColor = c.brand.withOpacity(0.08);
        textColor = c.brand;
        icon = Icons.info_outline_rounded;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: textColor.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                a.message,
                style: AppText.latin(
                  color: textColor,
                  size: 13,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                AppState.of(context)
                    .dismissAnnouncement(fingerprint);
              },
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top Bar ────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final AppColors colors;
  const _TopBar({required this.colors});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => state.toggleTheme(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: c.divider),
              ),
              child: Icon(
                state.isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                size: 18,
                color: c.textMuted,
              ),
            ),
          ),
          Text(
            'مكتبة الروضة',
            textDirection: TextDirection.rtl,
            style: AppText.arabic(
              color: c.goldText,
              size: 22,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}

// ─── Daily Hadith (compact) ──────────────────────────────

class _DailyHadith extends StatelessWidget {
  final AppColors colors;
  const _DailyHadith({required this.colors});

  static const List<Map<String, String>> _hadiths = [
    {
      'text':
          'مَنْ يُرِدِ اللَّهُ بِهِ خَيْرًا يُفَقِّهْهُ فِي الدِّينِ',
      'source': 'صحيح البخاري، صحيح مسلم',
    },
    {
      'text':
          'مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا، سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ.',
      'source': 'صحيح مسلم',
    },
    {
      'text': 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ.',
      'source': 'صحيح البخاري',
    },
    {
      'text':
          'إِنَّ الْمَلَائِكَةَ لَتَضَعُ أَجْنِحَتَهَا لِطَالِبِ الْعِلْمِ رِضًا بِمَا يَصْنَعُ.',
      'source': 'سنن الترمذي، سنن ابن ماجه',
    },
    {
      'text':
          'نَضَّرَ اللَّهُ امْرَأً سَمِعَ مِنَّا حَدِيثًا فَحَفِظَهُ حَتَّى يُبَلِّغَهُ كَمَا سَمِعَهُ.',
      'source': 'جامع الترمذي',
    },
    {
      'text':
          'إِنَّ اللَّهَ وَمَلَائِكَتَهُ وَأَهْلَ السَّمَاوَاتِ وَالْأَرْضِ، حَتَّى النَّمْلَةَ فِي جُحْرِهَا، وَحَتَّى الْحُوتَ، لَيُصَلُّونَ عَلَى مُعَلِّمِ النَّاسِ الْخَيْرَ.',
      'source': 'جامع الترمذي',
    },
    {
      'text':
          'الدُّنْيَا مَلْعُونَةٌ، مَلْعُونٌ مَا فِيهَا، إِلَّا ذِكْرَ اللَّهِ وَمَا وَالَاهُ، وَعَالِمًا أَوْ مُتَعَلِّمًا.',
      'source': 'جامع الترمذي',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final dayIndex = DateTime.now().weekday - 1;
    final hadith = _hadiths[dayIndex % _hadiths.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Hadith of the Day',
                style: AppText.latin(
                  color: c.textPrimary,
                  size: 14,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: c.goldLine,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Daily',
                  style: AppText.latin(
                    color: c.goldText,
                    size: 9,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(color: c.goldText, width: 3),
                top: BorderSide(color: c.divider),
                right: BorderSide(color: c.divider),
                bottom: BorderSide(color: c.divider),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hadith['text']!,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.arabic(
                    color: c.textPrimary,
                    size: 14,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: c.goldLine,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hadith['source']!,
                    textDirection: TextDirection.rtl,
                    style: AppText.arabic(
                      color: c.goldText,
                      size: 11,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Continue Reading (compact) ──────────────────────────
// Handles: regular books, Mus'haf editions, and Surahs.

class _ContinueReading extends StatelessWidget {
  final AppColors colors;
  const _ContinueReading({required this.colors});

  static bool _isMushafId(String? bookId) =>
      bookId == 'mushaf';

  static bool _isSurahId(String? bookId) =>
      bookId != null && bookId.startsWith('surah_');

  static int? _surahNumberFromId(String? bookId) {
    if (bookId == null || !bookId.startsWith('surah_')) {
      return null;
    }
    return int.tryParse(bookId.replaceFirst('surah_', ''));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Continue Reading',
            style: AppText.latin(
              color: c.textPrimary,
              size: 14,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: state.hasLastBook
                ? () => _handleTap(context, state)
                : null,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: c.goldLine, width: 1.5),
              ),
              child: state.hasLastBook
                  ? _LastBookContent(colors: c)
                  : _NoBookContent(colors: c),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, AppState state) {
    final bookId = state.lastBookId;
    if (bookId == null) return;

    // ── Mus'haf ──
    if (_isMushafId(bookId)) {
      // Find the mushaf sub-branch, then open its first
      // (default) edition. The first edition is always
      // the one with id "mushaf" for backward compat.
      final mushafSub = state.catalogService.quranSubBranches
          .where((sb) => sb.type == QuranSubBranchType.mushaf)
          .firstOrNull;
      if (mushafSub != null && mushafSub.editions.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MushafReaderScreen(
              edition: mushafSub.editions.first,
            ),
          ),
        );
      }
      return;
    }

    // ── Surah ──
    if (_isSurahId(bookId)) {
      final num = _surahNumberFromId(bookId);
      if (num != null) {
        final meta = QuranSkeleton.byNumber(num);
        if (meta != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SurahDetailScreen(meta: meta),
            ),
          );
        }
      }
      return;
    }

    // ── Regular book ──
    try {
      final book = state.catalogService.books
          .firstWhere((b) => b.id == bookId);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookDetailScreen(
            book: book,
            catalogService: state.catalogService,
          ),
        ),
      );
    } catch (_) {
      // Book not found in catalog — silently ignore
    }
  }
}

class _LastBookContent extends StatelessWidget {
  final AppColors colors;
  const _LastBookContent({required this.colors});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = colors;

    final bookId = state.lastBookId;
    final isMushaf = bookId == 'mushaf';
    final isSurah =
        bookId != null && bookId.startsWith('surah_');
    final isQuran = isMushaf || isSurah;

    // Try to find regular book
    Book? book;
    if (!isQuran) {
      try {
        book = state.catalogService.books.firstWhere(
          (b) => b.id == bookId,
        );
      } catch (_) {}
    }

    // Resolve display name
    String displayName;
    if (isMushaf) {
      displayName = 'القرآن الكريم';
    } else if (isSurah) {
      final num = int.tryParse(
          bookId!.replaceFirst('surah_', ''));
      if (num != null) {
        final meta = QuranSkeleton.byNumber(num);
        displayName =
            meta != null ? 'سورة ${meta.nameAr}' : bookId;
      } else {
        displayName = bookId;
      }
    } else {
      displayName = state.lastBookTitle ?? '';
    }

    final progress = state.lastBookProgress;
    final percent = (progress * 100).toInt();

    return Row(
      children: [
        // Icon / cover
        if (book != null)
          BookCoverWidget(
            book: book,
            width: 44,
            height: 58,
            borderRadius: 8,
          )
        else
          Container(
            width: 44,
            height: 58,
            decoration: BoxDecoration(
              color: isQuran
                  ? c.goldLine
                  : c.brand.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isQuran
                    ? c.goldText.withOpacity(0.35)
                    : c.brand.withOpacity(0.25),
              ),
            ),
            child: Icon(
              isQuran
                  ? Icons.import_contacts_rounded
                  : Icons.menu_book_rounded,
              size: 22,
              color: isQuran ? c.goldText : c.brand,
            ),
          ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.arabic(
                  color: c.textPrimary,
                  size: 13,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Page ${state.lastBookPage + 1}'
                '${state.lastBookTotalPages > 0 ? ' of ${state.lastBookTotalPages}' : ''}',
                style: AppText.latin(
                    color: c.textMuted, size: 10),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: c.surface2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isQuran ? c.goldText : c.brand,
                  ),
                  minHeight: 3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$percent%',
                style: AppText.latin(
                  color: isQuran ? c.goldText : c.brand,
                  size: 9,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 6),
        Icon(
          Icons.chevron_right_rounded,
          size: 16,
          color: c.textFaint,
        ),
      ],
    );
  }
}

class _NoBookContent extends StatelessWidget {
  final AppColors colors;
  const _NoBookContent({required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Row(
      children: [
        Container(
          width: 44,
          height: 58,
          decoration: BoxDecoration(
            color: c.brand.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: c.brand.withOpacity(0.25)),
          ),
          child: Icon(
            Icons.menu_book_rounded,
            size: 22,
            color: c.brand,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No book opened yet',
                style: AppText.latin(
                    color: c.textMuted, size: 12),
              ),
              const SizedBox(height: 3),
              Text(
                'Tap a book in the Library to start',
                style: AppText.latin(
                    color: c.textFaint, size: 10),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0,
                  backgroundColor: c.surface2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(c.brand),
                  minHeight: 3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Branches Section (Heroes + Grid) ────────────────────

class _BranchesSection extends StatelessWidget {
  final AppColors colors;
  const _BranchesSection({required this.colors});

  static const Map<String, IconData> _squareIcons = {
    'aqeedah': Icons.verified_rounded,
    'fiqh': Icons.balance_rounded,
    'arabic': Icons.translate_rounded,
    'seerah': Icons.auto_stories_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Branches of Knowledge',
            style: AppText.latin(
              color: c.textPrimary,
              size: 15,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: state.catalogService,
            builder: (context, _) {
              final quranBranch = Catalog.branches
                  .firstWhere((b) => b.id == 'quran');
              final hadithBranch = Catalog.branches
                  .firstWhere((b) => b.id == 'hadith');
              final gridBranches = Catalog.branches
                  .where((b) =>
                      b.id != 'quran' && b.id != 'hadith')
                  .toList();

              return Column(
                children: [
                  BranchHeroCard(
                    branch: quranBranch,
                    style: BranchHeroStyle.quran,
                    colors: c,
                    language: state.language,
                    bookCount: null,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const QuranScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  BranchHeroCard(
                    branch: hadithBranch,
                    style: BranchHeroStyle.hadith,
                    colors: c,
                    language: state.language,
                    bookCount: state.catalogService
                        .bookCountForBranch('hadith'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BranchScreen(
                            branch: hadithBranch,
                            catalogService:
                                state.catalogService,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.55,
                    ),
                    itemCount: gridBranches.length,
                    itemBuilder: (context, index) {
                      final branch = gridBranches[index];
                      final iconData =
                          _squareIcons[branch.id] ??
                              Icons.category_rounded;
                      final count = state.catalogService
                          .bookCountForBranch(branch.id);

                      return _BranchSquareCard(
                        branch: branch,
                        icon: iconData,
                        count: count,
                        colors: c,
                        language: state.language,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BranchScreen(
                                branch: branch,
                                catalogService:
                                    state.catalogService,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BranchSquareCard extends StatelessWidget {
  final Branch branch;
  final IconData icon;
  final int count;
  final AppColors colors;
  final String language;
  final VoidCallback onTap;

  const _BranchSquareCard({
    required this.branch,
    required this.icon,
    required this.count,
    required this.colors,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final hasBooks = count > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hasBooks
                        ? c.brand.withOpacity(0.12)
                        : c.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasBooks
                          ? c.brand.withOpacity(0.25)
                          : c.divider,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: hasBooks
                        ? c.brand
                        : c.textFaint,
                  ),
                ),
                if (!hasBooks)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius:
                          BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Soon',
                      style: AppText.latin(
                        color: c.textFaint,
                        size: 9,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (hasBooks)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: c.textFaint,
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branch.nameFor(language),
                  style: AppText.latin(
                    color: hasBooks
                        ? c.textPrimary
                        : c.textMuted,
                    size: 13,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  hasBooks
                      ? '$count books'
                      : 'Coming soon',
                  style: AppText.latin(
                    color:
                        hasBooks ? c.brand : c.textFaint,
                    size: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
