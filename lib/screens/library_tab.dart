import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/theme.dart';

/// Library tab — placeholder until Chapter 6.
class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});

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
                    Text(
                      'Search books...',
                      style: AppText.latin(
                        color: c.textFaint,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Placeholder content ──
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: c.brand.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: c.brand.withOpacity(0.25),
                        ),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 34,
                        color: c.brand,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Library',
                      style: AppText.latin(
                        color: c.textPrimary,
                        size: 18,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Coming in Chapter 6',
                      style: AppText.latin(
                        color: c.textMuted,
                        size: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
