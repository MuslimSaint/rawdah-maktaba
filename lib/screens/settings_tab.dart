import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final authService = AuthService();
    final user = authService.currentUser;
    final userName = user?.displayName ?? 'User';
    final userEmail = user?.email ?? '';

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
              bottom: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ── Top Bar ──────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base,
                  AppSpacing.base,
                  AppSpacing.base,
                  0,
                ),
                child: Text(
                  'Settings',
                  style: AppText.latin(
                    color: c.textPrimary,
                    size: 22,
                    weight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Profile ──────────────────────────
              _SectionLabel(
                  label: 'ACCOUNT', colors: c),
              const SizedBox(height: AppSpacing.sm),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base),
                child: _ProfileCard(
                  userName: userName,
                  userEmail: userEmail,
                  colors: c,
                  onSignOut: () =>
                      _signOut(context, state),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Appearance ───────────────────────
              _SectionLabel(
                  label: 'APPEARANCE', colors: c),
              const SizedBox(height: AppSpacing.sm),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: AppRadius.cardRadius,
                    border:
                        Border.all(color: c.divider),
                  ),
                  child: Column(
                    children: [
                      // Dark mode row — taller because
                      // it has two lines of text
                      _SettingsToggleRow(
                        icon: state.isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        title: 'Dark Mode',
                        subtitle: state.isDark
                            ? 'Dark theme active'
                            : 'Light theme active',
                        value: state.isDark,
                        onChanged: (_) =>
                            state.toggleTheme(),
                        colors: c,
                      ),

                      Divider(
                          color: c.divider,
                          height: 1,
                          indent: 16,
                          endIndent: 16),

                      // Language row
                      _LanguageRow(colors: c),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Connect ──────────────────────────
              _SectionLabel(
                  label: 'CONNECT', colors: c),
              const SizedBox(height: AppSpacing.sm),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base),
                child: GestureDetector(
                  onTap: () => _launchUrl(
                      'https://t.me/JUMadrasabot'),
                  child: Container(
                    padding: const EdgeInsets.all(
                        AppSpacing.base),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius:
                          AppRadius.cardRadius,
                      border: Border.all(
                          color: c.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(
                                    0xFF229ED9)
                                .withOpacity(0.12),
                            borderRadius:
                                AppRadius.buttonRadius,
                            border: Border.all(
                              color: const Color(
                                      0xFF229ED9)
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Color(0xFF229ED9),
                            size: 22,
                          ),
                        ),
                        const SizedBox(
                            width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'Rawdah · روضة',
                                style: AppText.latin(
                                  color:
                                      c.textPrimary,
                                  size: 14,
                                  weight:
                                      FontWeight.w700,
                                ),
                              ),
                              const SizedBox(
                                  height:
                                      AppSpacing.xs),
                              Text(
                                '@JUMadrasabot · Telegram',
                                style: AppText.latin(
                                  color: c.textMuted,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(
                                  height:
                                      AppSpacing.xs),
                              Text(
                                'Islamic Studies & University Materials',
                                style: AppText.latin(
                                  color: c.textFaint,
                                  size: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 16,
                          color: c.textFaint,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── FAQ ──────────────────────────────
              _SectionLabel(label: 'FAQ', colors: c),
              const SizedBox(height: AppSpacing.sm),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: AppRadius.cardRadius,
                    border:
                        Border.all(color: c.divider),
                  ),
                  child: Column(
                    children: [
                      _FaqItem(
                        number: 1,
                        question:
                            'Is everything in this app free?',
                        answer:
                            'Yes. All books and audio lessons in مكتبة الروضة are completely free. There is no premium plan, no subscription, and no hidden charges. Everything will always be free.',
                        colors: c,
                        isFirst: true,
                      ),
                      _FaqItem(
                        number: 2,
                        question:
                            'Do I need internet to use the app?',
                        answer:
                            'You need internet to download books and audio for the first time. After downloading, everything works fully offline — reading, listening, and tracking your progress.',
                        colors: c,
                      ),
                      _FaqItem(
                        number: 3,
                        question:
                            'How do I read a downloaded book?',
                        answer:
                            'Go to Library → tap a book → tap the PDF card to download. Once downloaded, tap anywhere on the card to open and read the book.',
                        colors: c,
                      ),
                      _FaqItem(
                        number: 4,
                        question:
                            'Will new books be added?',
                        answer:
                            'Yes. New books and audio lessons are added regularly. When you open the app with internet, your library updates automatically — no app update needed.',
                        colors: c,
                      ),
                      _FaqItem(
                        number: 5,
                        question:
                            'Are the books scholar-verified?',
                        answer:
                            'Yes. All books in مكتبة الروضة are authentic Islamic texts taught by qualified scholars. The audio explanations are provided by named scholars shown on each book\'s detail page.',
                        colors: c,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Privacy ──────────────────────────
              _SectionLabel(
                  label: 'PRIVACY & DATA',
                  colors: c),
              const SizedBox(height: AppSpacing.sm),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: AppRadius.cardRadius,
                    border:
                        Border.all(color: c.divider),
                  ),
                  child: Column(
                    children: [
                      _PrivacyItem(
                        title: 'What we collect',
                        content:
                            'We collect your name and email address when you create an account. This is the minimum required to provide you with a personal reading experience.',
                        colors: c,
                        isFirst: true,
                      ),
                      _PrivacyItem(
                        title:
                            'What we do NOT collect',
                        content:
                            'We do not collect your location, contacts, camera, microphone, or any personal device data. We do not sell or share your data with any third party.',
                        colors: c,
                      ),
                      _PrivacyItem(
                        title: 'Authentication',
                        content:
                            'Your account is secured through Firebase Authentication by Google. We do not store your password — it is handled entirely by Firebase.',
                        colors: c,
                      ),
                      _PrivacyItem(
                        title: 'Reading progress',
                        content:
                            'Your reading progress, downloaded files, and preferences are stored locally on your device. This data never leaves your phone without your knowledge.',
                        colors: c,
                      ),
                      _PrivacyItem(
                        title: 'Downloaded files',
                        content:
                            'Books and audio files you download are stored privately in your app\'s internal storage. Only this app can access them. You can delete them anytime from the Downloads tab.',
                        colors: c,
                      ),
                      _PrivacyItem(
                        title: 'Children',
                        content:
                            'This app is suitable for all ages. We do not knowingly collect data from children under 13 without parental consent.',
                        colors: c,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── About ────────────────────────────
              _SectionLabel(
                  label: 'ABOUT', colors: c),
              const SizedBox(height: AppSpacing.sm),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base),
                child: _AboutCard(colors: c),
              ),

              const SizedBox(height: AppSpacing.lg),

              Center(
                child: Text(
                  'Rawdah project for the Muslim Ummah',
                  style: AppText.latin(
                    color: c.textFaint,
                    size: 11,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri,
          mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _signOut(
      BuildContext context, AppState state) async {
    final c = AppColors(isDark: state.isDark);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
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
              color: c.textMuted, size: 13),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppText.latin(
                  color: c.textMuted, size: 14),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(true),
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
      ),
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

// ─── Profile Card ─────────────────────────────────────────
// Profile is the most important row — it gets its own
// card with a larger avatar and clear destructive action
// separation.

class _ProfileCard extends StatelessWidget {
  final String userName;
  final String userEmail;
  final AppColors colors;
  final VoidCallback onSignOut;

  const _ProfileCard({
    required this.userName,
    required this.userEmail,
    required this.colors,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
            color: c.goldLine, width: 1.5),
      ),
      child: Column(
        children: [
          // ── Identity row ──
          Padding(
            padding: const EdgeInsets.all(
                AppSpacing.base),
            child: Row(
              children: [
                // Larger avatar = higher importance
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.brand.withOpacity(0.12),
                    border: Border.all(
                      color:
                          c.brand.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    userName.isNotEmpty
                        ? userName[0].toUpperCase()
                        : 'U',
                    style: AppText.latin(
                      color: c.brand,
                      size: 24,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(
                    width: AppSpacing.md),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: AppText.latin(
                          color: c.textPrimary,
                          size: 16,
                          weight: FontWeight.w700,
                        ),
                      ),
                      if (userEmail.isNotEmpty) ...[
                        const SizedBox(
                            height: AppSpacing.xs),
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
              ],
            ),
          ),

          // ── Divider between identity and
          //    destructive action ──
          Divider(color: c.divider, height: 1),

          // ── Sign Out row — visually distinct from
          //    neutral settings rows ──
          GestureDetector(
            onTap: onSignOut,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.dangerBg,
                      borderRadius:
                          AppRadius.buttonRadius,
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      size: 16,
                      color: c.danger,
                    ),
                  ),
                  const SizedBox(
                      width: AppSpacing.md),
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
                    size: 16,
                    color:
                        c.danger.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Toggle Row ─────────────────────────────────

class _SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppColors colors;

  const _SettingsToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.brand.withOpacity(0.1),
              borderRadius: AppRadius.buttonRadius,
            ),
            child: Icon(icon,
                color: c.brand, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.latin(
                    color: c.textPrimary,
                    size: 14,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                    height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppText.latin(
                    color: c.textFaint,
                    size: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: c.brand,
          ),
        ],
      ),
    );
  }
}

// ─── Language Row ─────────────────────────────────────────

class _LanguageRow extends StatelessWidget {
  final AppColors colors;
  const _LanguageRow({required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.brand.withOpacity(0.1),
              borderRadius: AppRadius.buttonRadius,
            ),
            child: Icon(Icons.language_rounded,
                color: c.brand, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Language',
              style: AppText.latin(
                color: c.textPrimary,
                size: 14,
                weight: FontWeight.w600,
              ),
            ),
          ),
          _LangButton(
              code: 'ar', label: 'ع', colors: c),
          const SizedBox(width: AppSpacing.sm),
          _LangButton(
              code: 'en', label: 'A', colors: c),
          const SizedBox(width: AppSpacing.sm),
          _LangButton(
              code: 'am', label: 'አ', colors: c),
        ],
      ),
    );
  }
}

// ─── About Card ──────────────────────────────────────────
// Stats redesigned: ONE hero stat large and central,
// secondary stats in a compact 2-column row below.
// Footer items are small pills.

class _AboutCard extends StatelessWidget {
  final AppColors colors;
  const _AboutCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final state = AppState.of(context);
    final bookCount =
        state.catalogService.books.length;
    final downloadCount =
        state.downloadService.downloadedCount;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: c.divider),
      ),
      child: Column(
        children: [
          // App icon
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(18),
              border: Border.all(
                color: c.goldLine,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: c.brand.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(16),
              child: Image.asset(
                'assets/icon.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(
                  color: c.brand.withOpacity(0.15),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 30,
                    color: c.gold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'مكتبة الروضة',
            textDirection: TextDirection.rtl,
            style: AppText.arabic(
              color: c.goldText,
              size: 21,
              weight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            'Your personal Islamic library',
            style: AppText.latin(
              color: c.textMuted,
              size: 12,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Version pill
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs + 1,
            ),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: AppRadius.pillRadius,
              border: Border.all(color: c.divider),
            ),
            child: Text(
              'v1.0.0 · Free · No ads',
              style: AppText.latin(
                color: c.textMuted,
                size: 11,
                weight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          Divider(color: c.divider, height: 1),
          const SizedBox(height: AppSpacing.lg),

          // Description
          Text(
            'مكتبة الروضة is a free Islamic learning app built to make authentic knowledge accessible to every Muslim student. Browse verified PDF books, listen to scholar explanations, and track your learning — all offline after download.',
            textAlign: TextAlign.center,
            style: AppText.latin(
              color: c.textMuted,
              size: 12,
              height: 1.6,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          Divider(color: c.divider, height: 1),
          const SizedBox(height: AppSpacing.lg),

          // ── Hero stat — books in library ────────
          // The primary thing that communicates the
          // app's value. Large and central.
          Column(
            children: [
              Text(
                '$bookCount',
                style: AppText.latin(
                  color: c.brand,
                  size: 48,
                  weight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 13,
                    color: c.textMuted,
                  ),
                  const SizedBox(
                      width: AppSpacing.xs),
                  Text(
                    'Books in library',
                    style: AppText.latin(
                      color: c.textMuted,
                      size: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Secondary stats — compact 2-column ──
          Row(
            children: [
              Expanded(
                child: _SecondaryStatCell(
                  icon: Icons.headphones_rounded,
                  value: '7',
                  label: 'Teachers',
                  colors: c,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: c.divider,
              ),
              Expanded(
                child: _SecondaryStatCell(
                  icon: Icons.download_rounded,
                  value: '$downloadCount',
                  label: 'Downloads',
                  colors: c,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          Divider(color: c.divider, height: 1),
          const SizedBox(height: AppSpacing.md),

          // ── Footer pills ──────────────────────
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _FooterPill(
                icon: Icons.star_outline_rounded,
                label: 'Always free',
                colors: c,
              ),
              _FooterPill(
                icon: Icons.school_rounded,
                label: 'Rawdah · Est. 2025',
                colors: c,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecondaryStatCell extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final AppColors colors;

  const _SecondaryStatCell({
    required this.icon,
    required this.value,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: AppText.latin(
            color: c.textPrimary,
            size: 22,
            weight: FontWeight.w700,
            height: 1.0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 11, color: c.textFaint),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppText.latin(
                color: c.textFaint,
                size: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FooterPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppColors colors;

  const _FooterPill({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: c.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: c.textFaint),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppText.latin(
              color: c.textMuted,
              size: 11,
            ),
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base),
      child: Text(
        label,
        style: AppText.label(color: colors.textFaint),
      ),
    );
  }
}

// ─── Icon Box ────────────────────────────────────────────

class _IconBox extends StatelessWidget {
  final IconData icon;
  final AppColors colors;

  const _IconBox(
      {required this.icon, required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: c.brand.withOpacity(0.1),
        borderRadius: AppRadius.buttonRadius,
      ),
      child: Icon(icon, color: c.brand, size: 18),
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
          borderRadius: AppRadius.buttonRadius,
          border: Border.all(
            color: active ? c.brand : c.divider,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color:
                active ? Colors.white : c.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── FAQ Item ────────────────────────────────────────────
// Numbers added so questions feel structured.
// Expanded answer uses left-border accent.

class _FaqItem extends StatefulWidget {
  final int number;
  final String question;
  final String answer;
  final AppColors colors;
  final bool isFirst;
  final bool isLast;

  const _FaqItem({
    required this.number,
    required this.question,
    required this.answer,
    required this.colors,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;

    return Column(
      children: [
        if (!widget.isFirst)
          Divider(
            color: c.divider,
            height: 1,
            indent: AppSpacing.base,
            endIndent: AppSpacing.base,
          ),
        GestureDetector(
          onTap: () =>
              setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // Question number badge
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(
                          top: 1,
                          right: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color:
                            c.brand.withOpacity(0.1),
                        borderRadius:
                            AppRadius.pillRadius,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.number}',
                        style: AppText.latin(
                          color: c.brand,
                          size: 10,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.question,
                        style: AppText.latin(
                          color: c.textPrimary,
                          size: 13,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(
                        width: AppSpacing.sm),
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(
                          milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: c.textFaint,
                      ),
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(
                      height: AppSpacing.sm),
                  // Left-border accent on expanded
                  // answer — visually distinct from
                  // the question without being heavy.
                  Container(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.md,
                      top: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: c.brand
                              .withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      widget.answer,
                      style: AppText.latin(
                        color: c.textMuted,
                        size: 12,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Privacy Item ────────────────────────────────────────

class _PrivacyItem extends StatefulWidget {
  final String title;
  final String content;
  final AppColors colors;
  final bool isFirst;
  final bool isLast;

  const _PrivacyItem({
    required this.title,
    required this.content,
    required this.colors,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  State<_PrivacyItem> createState() =>
      _PrivacyItemState();
}

class _PrivacyItemState extends State<_PrivacyItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;

    return Column(
      children: [
        if (!widget.isFirst)
          Divider(
            color: c.divider,
            height: 1,
            indent: AppSpacing.base,
            endIndent: AppSpacing.base,
          ),
        GestureDetector(
          onTap: () =>
              setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: c.brand,
                    ),
                    const SizedBox(
                        width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppText.latin(
                          color: c.textPrimary,
                          size: 13,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(
                          milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: c.textFaint,
                      ),
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(
                      height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.md,
                      top: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: c.brand
                              .withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      widget.content,
                      style: AppText.latin(
                        color: c.textMuted,
                        size: 12,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
