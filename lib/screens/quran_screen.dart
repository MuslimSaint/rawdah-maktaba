import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/quran_data.dart';
import '../core/theme.dart';
import 'surah_detail_screen.dart';

/// The Quran screen — lists all 114 Surahs.
/// Optional Mus'haf full-book card at top.
/// Search bar filters by number, Arabic name, or transcription.
/// Tapping a Surah opens SurahDetailScreen.
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
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
    final lang = state.language;

    final results = QuranSkeleton.search(_query);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
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

            const SizedBox(height: 14),

            // ── Search bar ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20),
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
                          padding: const EdgeInsets.only(
                              right: 12),
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

            // ── Full Mus'haf card (if uploaded) ──
            ListenableBuilder(
              listenable: state.catalogService,
              builder: (context, _) {
                final mushafUrl =
                    state.catalogService.mushafPdfUrl;
                if (mushafUrl == null || _query.isNotEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 0, 20, 14),
                  child: _MushafCard(
                    colors: c,
                    onTap: () {
                      // For now, just show a message.
                      // TODO: route to full Mushaf PDF via
                      // BookDetail or a dedicated screen.
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Full Mus\'haf coming soon.',
                            style: AppText.latin(
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                          backgroundColor: c.brand,
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // ── Surah list ──
            Expanded(
              child: results.isEmpty
                  ? _NoResults(colors: c)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                          20, 0, 20, 24),
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final surah = results[index];
                        return _SurahRow(
                          surah: surah,
                          colors: c,
                          language: lang,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    SurahDetailScreen(
                                  meta: surah,
                                ),
                              ),
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

// ─── Mus'haf full-book card ──────────────────────────────

class _MushafCard extends StatelessWidget {
  final AppColors colors;
  final VoidCallback onTap;

  const _MushafCard({
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
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.brand, c.brandHover],
          ),
          border: Border.all(
            color: c.gold.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.gold.withOpacity(0.2),
                border: Border.all(
                  color: c.gold.withOpacity(0.5),
                ),
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                size: 22,
                color: c.gold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'المصحف الشريف',
                    textDirection: TextDirection.rtl,
                    style: AppText.arabic(
                      color: c.gold,
                      size: 15,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Full Mus\'haf — all 114 Surahs',
                    style: AppText.latin(
                      color: c.gold.withOpacity(0.85),
                      size: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: c.gold,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Surah Row ───────────────────────────────────────────

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
    final transliteration =
        surah.transliterationFor(language);

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
            // Number in decorative circle
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

            // Arabic name (+ transcription if non-Arabic UI)
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
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

// ─── No results ──────────────────────────────────────────

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
          Icon(
            Icons.search_off_rounded,
            size: 40,
            color: c.textFaint,
          ),
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
