import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'branch_screen.dart';

/// Home tab — full implementation.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(colors: c),
              const SizedBox(height: 20),
              _StatsStrip(colors: c),
              const SizedBox(height: 20),
              _ContinueReading(colors: c),
              const SizedBox(height: 20),
              _DailyHadith(colors: c),
              const SizedBox(height: 20),
              _BranchesGrid(colors: c),
            ],
          ),
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

// ─── Stats Strip ────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final AppColors colors;
  const _StatsStrip({required this.colors});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListenableBuilder(
        listenable: state.catalogService,
        builder: (context, _) {
          final total = state.catalogService.books.length;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.goldLine, width: 1.5),
            ),
            child: Row(
              children: [
                _StatItem(
                  label: 'Completed',
                  value: '0',
                  icon: Icons.check_circle_outline_rounded,
                  colors: c,
                ),
                _StatDivider(colors: c),
                _StatItem(
                  label: 'Library',
                  value: '$total',
                  icon: Icons.menu_book_rounded,
                  colors: c,
                ),
                _StatDivider(colors: c),
                _StatItem(
                  label: 'Downloads',
                  value: '0',
                  icon: Icons.download_rounded,
                  colors: c,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final AppColors colors;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: c.brand),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppText.latin(
              color: c.textPrimary,
              size: 20,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppText.latin(color: c.textMuted, size: 11),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  final AppColors colors;
  const _StatDivider({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: colors.divider);
  }
}

// ─── Continue Reading ────────────────────────────────────

class _ContinueReading extends StatelessWidget {
  final AppColors colors;
  const _ContinueReading({required this.colors});

  @override
  Widget build(BuildContext context) {
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
              size: 15,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.goldLine, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 72,
                  decoration: BoxDecoration(
                    color: c.brand.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.brand.withOpacity(0.25)),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 26,
                    color: c.brand,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No book opened yet',
                        style: AppText.latin(
                          color: c.textMuted,
                          size: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap a book in the Library to start reading',
                        style: AppText.latin(
                          color: c.textFaint,
                          size: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0,
                          backgroundColor: c.surface2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(c.brand),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '0%',
                        style: AppText.latin(
                          color: c.textFaint,
                          size: 10,
                        ),
                      ),
                    ],
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

// ─── Daily Hadith ────────────────────────────────────────

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
                  size: 15,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
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
                    size: 10,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(18),
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
                  style: AppText.arabic(
                    color: c.textPrimary,
                    size: 16,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.goldLine,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hadith['source']!,
                    textDirection: TextDirection.rtl,
                    style: AppText.arabic(
                      color: c.goldText,
                      size: 12,
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

// ─── Branches Grid ───────────────────────────────────────

class _BranchesGrid extends StatelessWidget {
  final AppColors colors;
  const _BranchesGrid({required this.colors});

  static const List<Map<String, dynamic>> _branchIcons = [
    {'id': 'hadith', 'icon': Icons.menu_book_rounded},
    {'id': 'aqeedah', 'icon': Icons.verified_rounded},
    {'id': 'fiqh', 'icon': Icons.balance_rounded},
    {'id': 'seerah', 'icon': Icons.auto_stories_rounded},
    {'id': 'tafseer', 'icon': Icons.lightbulb_outline_rounded},
    {'id': 'arabic', 'icon': Icons.translate_rounded},
  ];

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
          const SizedBox(height: 10),
          ListenableBuilder(
            listenable: state.catalogService,
            builder: (context, _) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.55,
                ),
                itemCount: Catalog.branches.length,
                itemBuilder: (context, index) {
                  final branch = Catalog.branches[index];
                  final iconData = _branchIcons[index]['icon'] as IconData;
                  final count = state.catalogService
                      .bookCountForBranch(branch.id);

                  return _BranchCard(
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
                            catalogService: state.catalogService,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  final Branch branch;
  final IconData icon;
  final int count;
  final AppColors colors;
  final String language;
  final VoidCallback onTap;

  const _BranchCard({
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    color: hasBooks ? c.brand : c.textFaint,
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
                      borderRadius: BorderRadius.circular(6),
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
                    color: hasBooks ? c.textPrimary : c.textMuted,
                    size: 13,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  hasBooks ? '$count books' : 'Coming soon',
                  style: AppText.latin(
                    color: hasBooks ? c.brand : c.textFaint,
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
