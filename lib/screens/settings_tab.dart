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
          padding: const EdgeInsets.only(bottom: 40),
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
                      Container(
                        width: 50,
                        height: 50,
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
                            size: 22,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
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
                      GestureDetector(
                        onTap: () =>
                            _signOut(context, state),
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

              const SizedBox(height: 28),

              // ── APPEARANCE ──
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
                      // Theme
                      Row(
                        children: [
                          _IconBox(
                            icon: state.isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            colors: c,
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

                      // Language
                      Row(
                        children: [
                          _IconBox(
                            icon: Icons.language_rounded,
                            colors: c,
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
                              code: 'ar', label: 'ع', colors: c),
                          const SizedBox(width: 6),
                          _LangButton(
                              code: 'en', label: 'A', colors: c),
                          const SizedBox(width: 6),
                          _LangButton(
                              code: 'am', label: 'አ', colors: c),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── RAWDAH ON TELEGRAM ──
              _SectionLabel(label: 'CONNECT', colors: c),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => _launchUrl('https://t.me/JUMadrasabot'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: c.divider),
                    ),
                    child: Row(
                      children: [
                        // Telegram icon container
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF229ED9)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF229ED9)
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Color(0xFF229ED9),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rawdah · روضة',
                                style: AppText.latin(
                                  color: c.textPrimary,
                                  size: 14,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '@JUMadrasabot · Telegram Bot',
                                style: AppText.latin(
                                  color: c.textMuted,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
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

              const SizedBox(height: 28),

              // ── FAQ ──
              _SectionLabel(label: 'FAQ', colors: c),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: c.divider),
                  ),
                  child: Column(
                    children: [
                      _FaqItem(
                        question: 'Is everything in this app free?',
                        answer:
                            'Yes. All books and audio lessons in مكتبة الروضة are completely free. There is no premium plan, no subscription, and no hidden charges. Everything will always be free.',
                        colors: c,
                        isFirst: true,
                      ),
                      _FaqItem(
                        question: 'Do I need internet to use the app?',
                        answer:
                            'You need internet to download books and audio for the first time. After downloading, everything works fully offline — reading, listening, and tracking your progress.',
                        colors: c,
                      ),
                      _FaqItem(
                        question: 'How do I read a downloaded book?',
                        answer:
                            'Go to Library → tap a book → tap the PDF card area to download. Once downloaded, tap anywhere on the card to open and read the book.',
                        colors: c,
                      ),
                      _FaqItem(
                        question: 'Will new books be added?',
                        answer:
                            'Yes. New books and audio lessons are added regularly. When you open the app with internet, your library updates automatically — no app update needed.',
                        colors: c,
                      ),
                      _FaqItem(
                        question: 'Are the books scholar-verified?',
                        answer:
                            'Yes. All books in مكتبة الروضة are authentic Islamic texts taught by qualified scholars. The audio explanations are provided by named scholars shown on each book\'s detail page.',
                        colors: c,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── PRIVACY ──
              _SectionLabel(label: 'PRIVACY & DATA', colors: c),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _IconBox(
                            icon: Icons.shield_outlined,
                            colors: c,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Privacy Policy',
                            style: AppText.latin(
                              color: c.textPrimary,
                              size: 14,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(color: c.divider, height: 1),
                      const SizedBox(height: 14),

                      _PrivacySection(
                        title: 'What we collect',
                        content:
                            'We collect your name and email address when you create an account. This is the minimum required to provide you with a personal reading experience.',
                        colors: c,
                      ),

                      _PrivacySection(
                        title: 'What we do NOT collect',
                        content:
                            'We do not collect your location, contacts, camera, microphone, or any personal device data. We do not sell or share your data with any third party.',
                        colors: c,
                      ),

                      _PrivacySection(
                        title: 'Authentication',
                        content:
                            'Your account is secured through Firebase Authentication by Google. We do not store your password — it is handled entirely by Firebase.',
                        colors: c,
                      ),

                      _PrivacySection(
                        title: 'Reading progress',
                        content:
                            'Your reading progress, downloaded files, and preferences are stored locally on your device. This data never leaves your phone without your knowledge.',
                        colors: c,
                      ),

                      _PrivacySection(
                        title: 'Downloaded files',
                        content:
                            'Books and audio files you download are stored privately in your app\'s internal storage. Only this app can access them. You can delete them anytime from the Downloads tab.',
                        colors: c,
                      ),

                      _PrivacySection(
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

              const SizedBox(height: 28),

              // ── ABOUT ──
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
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [c.brand, c.brandHover],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: c.goldLine,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: c.brand.withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 32,
                          color: c.gold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        'مكتبة الروضة',
                        textDirection: TextDirection.rtl,
                        style: AppText.arabic(
                          color: c.goldText,
                          size: 22,
                          weight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Your personal Islamic library',
                        style: AppText.latin(
                          color: c.textMuted,
                          size: 13,
                        ),
                      ),

                      const SizedBox(height: 8),

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
                          'v1.0.0 · Free · No ads',
                          style: AppText.latin(
                            color: c.textMuted,
                            size: 11,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Divider(color: c.divider, height: 1),
                      const SizedBox(height: 16),

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

                      const SizedBox(height: 16),
                      Divider(color: c.divider, height: 1),
                      const SizedBox(height: 16),

                      // Stats
                      _AboutRow(
                        icon: Icons.menu_book_rounded,
                        label: 'Books in library',
                        value:
                            '${AppState.of(context).catalogService.books.length}',
                        colors: c,
                      ),
                      const SizedBox(height: 10),
                      _AboutRow(
                        icon: Icons.headphones_rounded,
                        label: 'Audio teachers',
                        value: '7',
                        colors: c,
                      ),
                      const SizedBox(height: 10),
                      _AboutRow(
                        icon: Icons.download_rounded,
                        label: 'Your downloads',
                        value:
                            '${AppState.of(context).downloadService.downloadedCount}',
                        colors: c,
                      ),
                      const SizedBox(height: 10),
                      _AboutRow(
                        icon: Icons.star_outline_rounded,
                        label: 'Admission',
                        value: 'Always free',
                        colors: c,
                      ),
                      const SizedBox(height: 10),
                      _AboutRow(
                        icon: Icons.school_rounded,
                        label: 'Rawdah Project',
                        value: 'Est. 2025',
                        colors: c,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Footer
              Center(
                child: Text(
                  'Made with ❤️ for the Muslim Ummah',
                  style: AppText.latin(
                    color: c.textFaint,
                    size: 11,
                  ),
                ),
              ),

              const SizedBox(height: 8),
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
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _signOut(
      BuildContext context, AppState state) async {
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
            style: AppText.latin(color: c.textMuted, size: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: AppText.latin(color: c.textMuted, size: 14),
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

// ─── Sub Widgets ─────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final AppColors colors;
  const _SectionLabel({required this.label, required this.colors});

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

class _IconBox extends StatelessWidget {
  final IconData icon;
  final AppColors colors;
  const _IconBox({required this.icon, required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: c.brand.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: c.brand, size: 18),
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
          style: AppText.latin(color: c.textMuted, size: 12),
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

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  final AppColors colors;
  final bool isFirst;
  final bool isLast;

  const _FaqItem({
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
            indent: 16,
            endIndent: 16,
          ),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
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
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: c.textFaint,
                      ),
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.answer,
                    style: AppText.latin(
                      color: c.textMuted,
                      size: 12,
                      height: 1.6,
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

class _PrivacySection extends StatelessWidget {
  final String title;
  final String content;
  final AppColors colors;
  final bool isLast;

  const _PrivacySection({
    required this.title,
    required this.content,
    required this.colors,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppText.latin(
            color: c.textPrimary,
            size: 13,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: AppText.latin(
            color: c.textMuted,
            size: 12,
            height: 1.6,
          ),
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          Divider(color: c.divider, height: 1),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
