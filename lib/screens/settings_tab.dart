import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/auth_service.dart';
import '../core/theme.dart';
import 'main.dart';

/// Settings tab — placeholder until Chapter 9.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

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
                    'Settings',
                    style: AppText.latin(
                      color: c.textPrimary,
                      size: 22,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Quick controls ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.divider),
                ),
                child: Column(
                  children: [
                    // Theme toggle
                    Row(
                      children: [
                        Icon(
                          state.isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: c.brand,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Dark Mode',
                          style: AppText.latin(
                            color: c.textPrimary,
                            size: 14,
                            weight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: state.isDark,
                          onChanged: (_) => state.toggleTheme(),
                          activeColor: c.brand,
                        ),
                      ],
                    ),

                    Divider(color: c.divider, height: 20),

                    // Language selector
                    Row(
                      children: [
                        Icon(
                          Icons.language_rounded,
                          color: c.brand,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Language',
                          style: AppText.latin(
                            color: c.textPrimary,
                            size: 14,
                            weight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        _LangButton(code: 'ar', label: 'ع', colors: c),
                        const SizedBox(width: 6),
                        _LangButton(code: 'en', label: 'A', colors: c),
                        const SizedBox(width: 6),
                        _LangButton(code: 'am', label: 'አ', colors: c),
                      ],
                    ),

                    Divider(color: c.divider, height: 20),

                    // Sign out
                    GestureDetector(
                      onTap: () async {
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
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: c.danger,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Sign Out',
                            style: AppText.latin(
                              color: c.danger,
                              size: 14,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: c.textFaint,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Placeholder ──
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
                        Icons.settings_rounded,
                        size: 34,
                        color: c.brand,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Settings',
                      style: AppText.latin(
                        color: c.textPrimary,
                        size: 18,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Full settings coming in Chapter 9',
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
      child: Container(
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
