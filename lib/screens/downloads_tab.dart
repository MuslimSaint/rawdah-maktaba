import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/theme.dart';

/// Downloads tab — placeholder until Chapter 8.
class DownloadsTab extends StatelessWidget {
  const DownloadsTab({super.key});

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
                    'Downloads',
                    style: AppText.latin(
                      color: c.textPrimary,
                      size: 22,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

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
                        Icons.download_rounded,
                        size: 34,
                        color: c.brand,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Downloads',
                      style: AppText.latin(
                        color: c.textPrimary,
                        size: 18,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Coming in Chapter 8',
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
