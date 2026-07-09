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
        height: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
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
              color: c.goldText.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative background icon
            Positioned(
              right: -10,
              bottom: -8,
              child: Opacity(
                opacity: 0.09,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 100,
                  color: c.goldText,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              child: Row(
                children: [
                  // Left: Mus'haf icon in gold circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.goldText.withOpacity(0.15),
                      border: Border.all(
                        color: c.goldText.withOpacity(0.4),
                        width: 1.3,
                      ),
                    ),
                    child: Icon(
                      Icons.import_contacts_rounded,
                      size: 22,
                      color: c.goldText,
                    ),
                  ),

                  const SizedBox(width: 12),

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
                            size: 18,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
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
                            size: 11,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
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
        height: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
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
              color: c.brand.withOpacity(0.22),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative background icon
            Positioned(
              right: -14,
              bottom: -10,
              child: Opacity(
                opacity: 0.13,
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 100,
                  color: c.gold,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              child: Row(
                children: [
                  // Left: hadith book icon in gold circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.gold.withOpacity(0.2),
                      border: Border.all(
                        color: c.gold.withOpacity(0.5),
                        width: 1.3,
                      ),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 22,
                      color: c.gold,
                    ),
                  ),

                  const SizedBox(width: 12),

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
                            size: 18,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
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
                            size: 11,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
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
