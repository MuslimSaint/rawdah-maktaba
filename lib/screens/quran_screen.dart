import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/quran_data.dart';
import '../core/theme.dart';
import 'surah_detail_screen.dart';
import 'mushaf_detail_screen.dart';
import 'quran_sub_branch_screen.dart';

/// The Quran screen — shows sub-branches from catalog.
class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
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
                      'القرآن الكريم',
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

            const SizedBox(height: 16),

            Expanded(
              child: ListenableBuilder(
                listenable: state.catalogService,
                builder: (context, _) {
                  final subs =
                      state.catalogService.quranSubBranches;

                  if (subs.isEmpty) {
                    return _SurahsList(colors: c);
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        20, 0, 20, 24),
                    itemCount: subs.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final sub = subs[index];
                      return _SubBranchCard(
                        sub: sub,
                        colors: c,
                        language: state.language,
                        onTap: () =>
                            _openSubBranch(context, sub),
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

  void _openSubBranch(
      BuildContext context, QuranSubBranch sub) {
    switch (sub.type) {
      case QuranSubBranchType.mushaf:
        // Open detail screen FIRST (not reader directly).
        // User sees Quran facts + intentionally taps download.
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MushafDetailScreen(sub: sub),
          ),
        );
        break;
      case QuranSubBranchType.surahs:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _SurahsListScreen(sub: sub),
          ),
        );
        break;
      case QuranSubBranchType.branch:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                QuranSubBranchScreen(sub: sub),
          ),
        );
        break;
      case QuranSubBranchType.unknown:
        break;
    }
  }
}

// ─── Sub-branch Card ─────────────────────────────────────

class _SubBranchCard extends StatelessWidget {
  final QuranSubBranch sub;
  final AppColors colors;
  final String language;
  final VoidCallback onTap;

  const _SubBranchCard({
    required this.sub,
    required this.colors,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    IconData icon;
    switch (sub.type) {
      case QuranSubBranchType.mushaf:
        icon = Icons.auto_stories_rounded;
        break;
      case QuranSubBranchType.surahs:
        icon = Icons.format_list_numbered_rounded;
        break;
      case QuranSubBranchType.branch:
        icon = Icons.menu_book_rounded;
        break;
      case QuranSubBranchType.unknown:
        icon = Icons.help_outline_rounded;
    }

    String subtitle;
    switch (sub.type) {
      case QuranSubBranchType.mushaf:
        subtitle = language == 'ar'
            ? 'القرآن الكريم كاملاً'
            : 'Complete Noble Quran';
        break;
      case QuranSubBranchType.surahs:
        subtitle = language == 'ar'
            ? '١١٤ سورة'
            : '114 Surahs';
        break;
      case QuranSubBranchType.branch:
        final count = sub.books.length;
        subtitle = language == 'ar'
            ? '$count كتاب'
            : '$count ${count == 1 ? 'book' : 'books'}';
        break;
      case QuranSubBranchType.unknown:
        subtitle = '';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.goldLine, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.goldLine,
                border: Border.all(
                  color: c.goldText.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, size: 24, color: c.goldText),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sub.titleAr,
                    textDirection: TextDirection.rtl,
                    style: AppText.arabic(
                      color: c.textPrimary,
                      size: 17,
                      weight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      textDirection: language == 'ar'
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: AppText.latin(
                        color: c.goldText,
                        size: 12,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: c.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Surahs list screen ──────────────────────────────────

class _SurahsListScreen extends StatefulWidget {
  final QuranSubBranch sub;
  const _SurahsListScreen({required this.sub});

  @override
  State<_SurahsListScreen> createState() =>
      _SurahsListScreenState();
}

class _SurahsListScreenState
    extends State<_SurahsListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

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
                      widget.sub.titleAr,
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
            const SizedBox(height: 14),
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
                    Icon(Icons.search_rounded,
                        size: 20, color: c.textFaint),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) =>
                            setState(() => _query = v),
                        style: AppText.latin(
                          color: c.textPrimary,
                          size: 14,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Search Surah by number or name...',
                          hintStyle: AppText.latin(
                            color: c.textFaint,
                            size: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        child: Padding(
                          padding:
                              const EdgeInsets.only(right: 12),
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
            const SizedBox(height: 14),
            Expanded(
              child: _SurahsList(colors: c, query: _query),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahsList extends StatelessWidget {
  final AppColors colors;
  final String query;

  const _SurahsList({
    required this.colors,
    this.query = '',
  });

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final lang = state.language;
    final results = QuranSkeleton.search(query);

    if (results.isEmpty) {
      return _NoResults(colors: colors);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final surah = results[index];
        return _SurahRow(
          surah: surah,
          colors: colors,
          language: lang,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    SurahDetailScreen(meta: surah),
              ),
            );
          },
        );
      },
    );
  }
}

class _SurahRow extends StatelessWidget {
  final SurahMeta surah;
  final AppColors colors;
  final String language;
  final VoidCallback onTap;

  const _SurahRow({
    required this.surah,
    required this.colors,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final transliteration = surah.transliterationFor(language);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.goldLine,
                border: Border.all(
                  color: c.goldText.withOpacity(0.35),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${surah.number}',
                style: AppText.latin(
                  color: c.goldText,
                  size: 13,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    surah.nameAr,
                    textDirection: TextDirection.rtl,
                    style: AppText.arabic(
                      color: c.textPrimary,
                      size: 17,
                      weight: FontWeight.w700,
                    ),
                  ),
                  if (transliteration != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      transliteration,
                      style: AppText.latin(
                        color: c.textMuted,
                        size: 11,
                      ),
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
  }
}

class _NoResults extends StatelessWidget {
  final AppColors colors;
  const _NoResults({required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 40, color: c.textFaint),
          const SizedBox(height: 12),
          Text(
            'No Surah found',
            style: AppText.latin(
              color: c.textPrimary,
              size: 14,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
