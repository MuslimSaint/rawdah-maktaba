import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/theme.dart';

/// A beautiful full-width hero card for the two special
/// branches: Quran and Hadith. Used on the Home tab.
///
/// Two visual variants:
///   • BranchHeroStyle.quran  → gold/cream Islamic feel
///   • BranchHeroStyle.hadith → deep green scholarly feel
class BranchHeroCard extends StatelessWidget {
  final Branch branch;
  final BranchHeroStyle style;
  final AppColors colors;
  final String language;
  final int? bookCount;
  final VoidCallback onTap;

  const BranchHeroCard({
    super.key,
    required this.branch,
    required this.style,
    required this.colors,
    required this.language,
    required this.bookCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      BranchHeroStyle.quran => _QuranHero(
          branch: branch,
          colors: colors,
          language: language,
          bookCount: bookCount,
          onTap: onTap,
        ),
      BranchHeroStyle.hadith => _HadithHero(
          branch: branch,
          colors: colors,
          language: language,
          bookCount: bookCount,
          onTap: onTap,
        ),
    };
  }
}

enum BranchHeroStyle { quran, hadith }

// ─── Quran Hero (gold / cream Islamic feel) ────────────

class _QuranHero extends StatelessWidget {
  final Branch branch;
  final AppColors colors;
  final String language;
  final int? bookCount;
  final VoidCallback onTap;

  const _QuranHero({
    required this.branch,
    required this.colors,
    required this.language,
    required this.bookCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 108,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              c.goldLine,
              c.gold.withOpacity(0.35),
              c.goldLine,
            ],
          ),
          border: Border.all(
            color: c.goldText.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: c.goldText.withOpacity(0.15),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative background icon (subtle)
            Positioned(
              right: -14,
              bottom: -10,
              child: Opacity(
                opacity: 0.10,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 130,
                  color: c.goldText,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              child: Row(
                children: [
                  // Left: Mus'haf icon in gold circle
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.goldText.withOpacity(0.15),
                      border: Border.all(
                        color: c.goldText.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.import_contacts_rounded,
                      size: 30,
                      color: c.goldText,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Middle: name + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          branch.nameAr,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.arabic(
                            color: c.goldText,
                            size: 22,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          language == 'ar'
                              ? '١١٤ سورة'
                              : '114 Surahs',
                          textDirection: language == 'ar'
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          style: AppText.latin(
                            color:
                                c.goldText.withOpacity(0.75),
                            size: 12,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: c.goldText.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hadith Hero (deep green scholarly feel) ───────────

class _HadithHero extends StatelessWidget {
  final Branch branch;
  final AppColors colors;
  final String language;
  final int? bookCount;
  final VoidCallback onTap;

  const _HadithHero({
    required this.branch,
    required this.colors,
    required this.language,
    required this.bookCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final count = bookCount ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 108,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              c.brand,
              c.brandHover,
            ],
          ),
          border: Border.all(
            color: c.goldText.withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: c.brand.withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative background icon
            Positioned(
              right: -18,
              bottom: -14,
              child: Opacity(
                opacity: 0.14,
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 130,
                  color: c.gold,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              child: Row(
                children: [
                  // Left: hadith book icon in gold circle
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.gold.withOpacity(0.2),
                      border: Border.all(
                        color: c.gold.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 30,
                      color: c.gold,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Middle: name + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          branch.nameAr,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.arabic(
                            color: c.gold,
                            size: 22,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          count > 0
                              ? (language == 'ar'
                                  ? '$count كتاب'
                                  : '$count books')
                              : (language == 'ar'
                                  ? 'قريباً'
                                  : 'Coming soon'),
                          textDirection: language == 'ar'
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          style: AppText.latin(
                            color: c.gold.withOpacity(0.8),
                            size: 12,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: c.gold.withOpacity(0.85),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
