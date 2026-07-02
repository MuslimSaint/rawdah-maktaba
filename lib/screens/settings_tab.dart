import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/auth_service.dart';
import '../core/theme.dart';
import '../main.dart';

/// Settings tab — full implementation.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);

    // Get user info from Firebase
    final authService = AuthService();
    final user = authService.currentUser;
    final userName = user?.displayName ?? 'User';
    final userEmail = user?.email ?? '';

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'Settings',
                  style: AppText.latin(
                    color: c.textPrimary,
                    size: 22,
                    weight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Profile Card ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: c.goldLine, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      // Avatar circle with initials
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.brand.withOpacity(0.12),
                          border: Border.all(
                            color: c.brand.withOpacity(0.25),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          userName.isNotEmpty
                              ? userName[0].toUpperCase()
                              : 'U',
                          style: AppText.latin(
                            color: c.brand,
                            size: 20,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Name + email
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: AppText.latin(
                                color: c.textPrimary,
                                size: 15,
                                weight: FontWeight.w700,
                              ),
                            ),
                            if (userEmail.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                userEmail,
                                style: AppText.latin(
                                  color: c.textMuted,
                                  size: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Sign Out button
                      GestureDetector(
                        onTap: () => _signOut(context, state),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: c.dangerBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: c.danger.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'Sign Out',
                            style: AppText.latin(
                              color: c.danger,
                              size: 12,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Appearance Section ──
              _SectionLabel(label: 'APPEARANCE', colors: c),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: c.divider),
                  ),
                  child: Column(
                    children: [
                      // Dark Mode toggle
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: c.brand.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              state.isDark
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              color: c.brand,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dark Mode',
                                  style: AppText.latin(
                                    color: c.textPrimary,
                                    size: 14,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  state.isDark
                                      ? 'Dark theme active'
                                      : 'Light theme active',
                                  style: AppText.latin(
                                    color: c.textFaint,
                                    size: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: state.isDark,
                            onChanged: (_) => state.toggleTheme(),
                            activeColor: c.brand,
                          ),
                        ],
                      ),

                      Divider(color: c.divider, height: 24),

                      // Language selector
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: c.brand.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.language_rounded,
                              color: c.brand,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Language',
                                  style: AppText.latin(
                                    color: c.textPrimary,
                                    size: 14,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _languageName(state.language),
                                  style: AppText.latin(
                                    color: c.textFaint,
                                    size: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _LangButton(
                            code: 'ar',
                            label: 'ع',
                            colors: c,
                          ),
                          const SizedBox(width: 6),
                          _LangButton(
                            code: 'en',
                            label: 'A',
                            colors: c,
                          ),
                          const SizedBox(width: 6),
                          _LangButton(
                            code: 'am',
                            label: 'አ',
                            colors: c,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── About Section ──
              _SectionLabel(label: 'ABOUT', colors: c),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: c.divider),
                  ),
                  child: Column(
                    children: [
                      // App icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [c.brand, c.brandHover],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: c.goldLine,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 30,
                          color: c.gold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // App name
                      Text(
                        'مكتبة الروضة',
                        textDirection: TextDirection.rtl,
                        style: AppText.arabic(
                          color: c.goldText,
                          size: 20,
                          weight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Islamic learning platform',
                        style: AppText.latin(
                          color: c.textMuted,
                          size: 13,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Version badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: c.divider),
                        ),
                        child: Text(
                          'v1.0.0 · Free',
                          style: AppText.latin(
                            color: c.textMuted,
                            size: 11,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Divider(color: c.divider, height: 1),

                      const SizedBox(height: 16),

                      // Info rows
                      _AboutRow(
                        icon: Icons.menu_book_rounded,
                        label: 'Books available',
                        value:
                            '${state.catalogService.books.length}',
                        colors: c,
                      ),
                      const SizedBox(height: 12),
                      _AboutRow(
                        icon: Icons.download_rounded,
                        label: 'Downloads',
                        value:
                            '${state.downloadService.downloadedCount}',
                        colors: c,
                      ),
                      const SizedBox(height: 12),
                      _AboutRow(
                        icon: Icons.shield_outlined,
                        label: 'Rawdah Project',
                        value: 'rawdah-maktaba',
                        colors: c,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _languageName(String code) {
    switch (code) {
      case 'ar':
        return 'العربية';
      case 'am':
        return 'አማርኛ';
      default:
        return 'English';
    }
  }

  Future<void> _signOut(BuildContext context, AppState state) async {
    final c = AppColors(isDark: state.isDark);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: c.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Sign Out?',
            style: AppText.latin(
              color: c.textPrimary,
              size: 16,
              weight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to sign out?',
            style: AppText.latin(
              color: c.textMuted,
              size: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: AppText.latin(
                  color: c.textMuted,
                  size: 14,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Sign Out',
                style: AppText.latin(
                  color: c.danger,
                  size: 14,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      final authService = AuthService();
      await authService.signOut();
      await state.setSignedIn(false);
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => AppStateProvider(
              state: state,
              child: const AppRouter(),
            ),
          ),
          (_) => false,
        );
      }
    }
  }
}

// ─── Section Label ───────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final AppColors colors;

  const _SectionLabel({
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        label,
        style: AppText.label(color: colors.textFaint),
      ),
    );
  }
}

// ─── Language Button ─────────────────────────────────────

class _LangButton extends StatelessWidget {
  final String code;
  final String label;
  final AppColors colors;

  const _LangButton({
    required this.code,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = colors;
    final active = state.language == code;

    return GestureDetector(
      onTap: () => state.setLanguage(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active ? c.brand : c.surface2,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: active ? c.brand : c.divider,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : c.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── About Row ───────────────────────────────────────────

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppColors colors;

  const _AboutRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    return Row(
      children: [
        Icon(icon, size: 16, color: c.textFaint),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppText.latin(
            color: c.textMuted,
            size: 12,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppText.latin(
            color: c.textPrimary,
            size: 12,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
