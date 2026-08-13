import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_state.dart';
import '../core/auth_service.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../main.dart';

/// Settings tab — fully catalog-driven for
/// Connect, FAQ, Privacy, About, and Credits.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);
    final authService = AuthService();
    final user = authService.currentUser;

    final isGuest = state.isGuest;
    final userName = isGuest
        ? 'Guest'
        : (user?.displayName ?? 'User');
    final userEmail =
        isGuest ? '' : (user?.email ?? '');

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: state.catalogService,
          builder: (context, _) {
            final settings =
                state.catalogService.settings;

            return SingleChildScrollView(
              padding: const EdgeInsets.only(
                  bottom: AppSpacing.xxl),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ── Header ──
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

                  // ── ACCOUNT ──
                  _SectionLabel(
                      label: 'ACCOUNT', colors: c),
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base),
                    child: _ProfileCard(
                      userName: userName,
                      userEmail: userEmail,
                      isGuest: isGuest,
                      colors: c,
                      onSignOut: () =>
                          _signOut(context, state),
                      onSignIn: () =>
                          _goToSignIn(context, state),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── APPEARANCE ──
                  _SectionLabel(
                      label: 'APPEARANCE', colors: c),
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base),
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius:
                            AppRadius.cardRadius,
                        border: Border.all(
                            color: c.divider),
                      ),
                      child: Column(
                        children: [
                          _SettingsToggleRow(
                            icon: state.isDark
                                ? Icons.dark_mode_rounded
                                : Icons
                                    .light_mode_rounded,
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
                          _LanguageRow(colors: c),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── CONNECT (catalog-driven) ──
                  if (settings
                      .connectLinks.isNotEmpty) ...[
                    _SectionLabel(
                        label: 'CONNECT', colors: c),
                    const SizedBox(
                        height: AppSpacing.sm),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal:
                                  AppSpacing.base),
                      child: Column(
                        children: settings.connectLinks
                            .map((link) => Padding(
                                  padding:
                                      const EdgeInsets
                                          .only(
                                          bottom:
                                              AppSpacing
                                                  .sm),
                                  child:
                                      _SocialLinkCard(
                                    link: link,
                                    colors: c,
                                    onTap: () =>
                                        _launchUrl(
                                            link.url),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(
                        height: AppSpacing.xl),
                  ],

                  // ── FAQ (catalog-driven) ──
                  if (settings.faq.isNotEmpty) ...[
                    _SectionLabel(
                        label: 'FAQ', colors: c),
                    const SizedBox(
                        height: AppSpacing.sm),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal:
                                  AppSpacing.base),
                      child: Container(
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius:
                              AppRadius.cardRadius,
                          border: Border.all(
                              color: c.divider),
                        ),
                        child: Column(
                          children: List.generate(
                            settings.faq.length,
                            (i) {
                              final entry =
                                  settings.faq[i];
                              return _FaqItem(
                                number: i + 1,
                                question:
                                    entry.question,
                                answer: entry.answer,
                                colors: c,
                                isFirst: i == 0,
                                isLast: i ==
                                    settings.faq
                                            .length -
                                        1,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                        height: AppSpacing.xl),
                  ],

                  // ── PRIVACY (catalog-driven) ──
                  if (settings.privacy.isNotEmpty) ...[
                    _SectionLabel(
                        label: 'PRIVACY & DATA',
                        colors: c),
                    const SizedBox(
                        height: AppSpacing.sm),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal:
                                  AppSpacing.base),
                      child: Container(
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius:
                              AppRadius.cardRadius,
                          border: Border.all(
                              color: c.divider),
                        ),
                        child: Column(
                          children: List.generate(
                            settings.privacy.length,
                            (i) {
                              final entry =
                                  settings.privacy[i];
                              return _PrivacyItem(
                                title: entry.title,
                                content:
                                    entry.content,
                                colors: c,
                                isFirst: i == 0,
                                isLast: i ==
                                    settings.privacy
                                            .length -
                                        1,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                        height: AppSpacing.xl),
                  ],

                  // ── ABOUT (catalog-driven text) ──
                  _SectionLabel(
                      label: 'ABOUT', colors: c),
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base),
                    child: _AboutCard(
                      colors: c,
                      aboutDescription:
                          settings.aboutDescription,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── CREDITS (catalog-driven) ──
                  if (settings.credits.isNotEmpty) ...[
                    _SectionLabel(
                        label:
                            'CREDITS & APPRECIATION',
                        colors: c),
                    const SizedBox(
                        height: AppSpacing.sm),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal:
                                  AppSpacing.base),
                      child: Container(
                        padding: const EdgeInsets
                            .all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius:
                              AppRadius.cardRadius,
                          border: Border.all(
                              color: c.goldLine,
                              width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons
                                      .favorite_rounded,
                                  color: c.goldText,
                                  size: 16,
                                ),
                                const SizedBox(
                                    width:
                                        AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'With gratitude to these scholars and channels whose content helped build this library.',
                                    style:
                                        AppText.latin(
                                      color:
                                          c.textMuted,
                                      size: 11,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                                height:
                                    AppSpacing.md),
                            ...settings.credits
                                .map((credit) =>
                                    Padding(
                                      padding:
                                          const EdgeInsets
                                              .only(
                                              bottom:
                                                  AppSpacing
                                                      .md),
                                      child:
                                          _CreditCard(
                                        credit: credit,
                                        colors: c,
                                        language: state
                                            .language,
                                        onLinkTap: (url) =>
                                            _launchUrl(
                                                url),
                                      ),
                                    ))
                                .toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                        height: AppSpacing.lg),
                  ],

                  Center(
                    child: Text(
                      'Rawdah project for the Muslim Ummah',
                      style: AppText.latin(
                          color: c.textFaint,
                          size: 11),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri,
            mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _signOut(
      BuildContext context, AppState state) async {
    final c = AppColors(isDark: state.isDark);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius),
        title: Text('Sign Out?',
            style: AppText.latin(
                color: c.textPrimary,
                size: 16,
                weight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to sign out?',
            style: AppText.latin(
                color: c.textMuted, size: 13)),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: AppText.latin(
                    color: c.textMuted, size: 14)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(true),
            child: Text('Sign Out',
                style: AppText.latin(
                    color: c.danger,
                    size: 14,
                    weight: FontWeight.w700)),
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

  Future<void> _goToSignIn(
      BuildContext context, AppState state) async {
    await state.clearGuest();
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

// ─── Social Link Card (used for CONNECT) ──────────────────

class _SocialLinkCard extends StatelessWidget {
  final SettingsLink link;
  final AppColors colors;
  final VoidCallback onTap;

  const _SocialLinkCard({
    required this.link,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final platform =
        _PlatformStyle.forPlatform(link.platform);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: c.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: platform.color.withOpacity(0.12),
                borderRadius:
                    AppRadius.buttonRadius,
                border: Border.all(
                  color:
                      platform.color.withOpacity(0.3),
                ),
              ),
              child: Icon(
                platform.icon,
                color: platform.color,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    link.name,
                    style: AppText.latin(
                      color: c.textPrimary,
                      size: 14,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(
                      height: AppSpacing.xs),
                  Text(
                    link.handle.isNotEmpty
                        ? '${link.handle} · ${platform.label}'
                        : platform.label,
                    style: AppText.latin(
                      color: c.textMuted,
                      size: 12,
                    ),
                  ),
                  if (link.description
                      .isNotEmpty) ...[
                    const SizedBox(
                        height: AppSpacing.xs),
                    Text(
                      link.description,
                      style: AppText.latin(
                        color: c.textFaint,
                        size: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded,
                size: 16, color: c.textFaint),
          ],
        ),
      ),
    );
  }
}

// ─── Credit Card ──────────────────────────────────────────

class _CreditCard extends StatelessWidget {
  final CreditEntry credit;
  final AppColors colors;
  final String language;
  final void Function(String url) onLinkTap;

  const _CreditCard({
    required this.credit,
    required this.colors,
    required this.language,
    required this.onLinkTap,
  });

  String _displayName() {
    if (language == 'ar' &&
        credit.nameAr.isNotEmpty) {
      return credit.nameAr;
    }
    if (credit.nameEn.isNotEmpty) {
      return credit.nameEn;
    }
    return credit.nameAr;
  }

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final name = _displayName();
    final isArabic =
        RegExp(r'[\u0600-\u06FF]').hasMatch(name);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: AppRadius.listItemRadius,
        border: Border.all(color: c.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color:
                      c.goldText.withOpacity(0.12),
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: c.goldText
                        .withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 16,
                  color: c.goldText,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  name,
                  textDirection: isArabic
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  textAlign: isArabic
                      ? TextAlign.right
                      : TextAlign.left,
                  style: isArabic
                      ? AppText.arabic(
                          color: c.textPrimary,
                          size: 14,
                          weight: FontWeight.w700,
                        )
                      : AppText.latin(
                          color: c.textPrimary,
                          size: 14,
                          weight: FontWeight.w700,
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Second-language name if different
          if (credit.nameAr.isNotEmpty &&
              credit.nameEn.isNotEmpty &&
              name != credit.nameAr) ...[
            Padding(
              padding: const EdgeInsets.only(
                  left: 40),
              child: Text(
                credit.nameAr,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: AppText.arabic(
                  color: c.textMuted,
                  size: 12,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ] else if (credit.nameAr.isNotEmpty &&
              credit.nameEn.isNotEmpty &&
              name != credit.nameEn) ...[
            Padding(
              padding: const EdgeInsets.only(
                  left: 40),
              child: Text(
                credit.nameEn,
                style: AppText.latin(
                  color: c.textMuted,
                  size: 12,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Links
          if (credit.links.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                  left: 40),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: credit.links
                    .map((link) => _CreditLinkChip(
                          link: link,
                          colors: c,
                          onTap: () =>
                              onLinkTap(link.url),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Credit Link Chip ─────────────────────────────────────

class _CreditLinkChip extends StatelessWidget {
  final SettingsLink link;
  final AppColors colors;
  final VoidCallback onTap;

  const _CreditLinkChip({
    required this.link,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final platform =
        _PlatformStyle.forPlatform(link.platform);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs + 3,
        ),
        decoration: BoxDecoration(
          color: platform.color.withOpacity(0.1),
          borderRadius: AppRadius.pillRadius,
          border: Border.all(
            color: platform.color.withOpacity(0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              platform.icon,
              size: 13,
              color: platform.color,
            ),
            const SizedBox(width: AppSpacing.xs + 1),
            Text(
              platform.label,
              style: AppText.latin(
                color: platform.color,
                size: 11,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Platform Style Helper ────────────────────────────────

class _PlatformStyle {
  final IconData icon;
  final Color color;
  final String label;

  const _PlatformStyle({
    required this.icon,
    required this.color,
    required this.label,
  });

  static _PlatformStyle forPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'telegram':
        return const _PlatformStyle(
          icon: Icons.send_rounded,
          color: Color(0xFF229ED9),
          label: 'Telegram',
        );
      case 'youtube':
        return const _PlatformStyle(
          icon: Icons.play_circle_fill_rounded,
          color: Color(0xFFFF0000),
          label: 'YouTube',
        );
      case 'instagram':
        return const _PlatformStyle(
          icon: Icons.camera_alt_rounded,
          color: Color(0xFFE1306C),
          label: 'Instagram',
        );
      case 'twitter':
      case 'x':
        return const _PlatformStyle(
          icon: Icons.alternate_email_rounded,
          color: Color(0xFF000000),
          label: 'X',
        );
      case 'facebook':
        return const _PlatformStyle(
          icon: Icons.facebook_rounded,
          color: Color(0xFF1877F2),
          label: 'Facebook',
        );
      case 'tiktok':
        return const _PlatformStyle(
          icon: Icons.music_note_rounded,
          color: Color(0xFF010101),
          label: 'TikTok',
        );
      case 'whatsapp':
        return const _PlatformStyle(
          icon: Icons.chat_rounded,
          color: Color(0xFF25D366),
          label: 'WhatsApp',
        );
      case 'website':
      default:
        return const _PlatformStyle(
          icon: Icons.language_rounded,
          color: Color(0xFF6B7280),
          label: 'Website',
        );
    }
  }
}

// ─── Profile Card ─────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String userName;
  final String userEmail;
  final bool isGuest;
  final AppColors colors;
  final VoidCallback onSignOut;
  final VoidCallback onSignIn;

  const _ProfileCard({
    required this.userName,
    required this.userEmail,
    required this.isGuest,
    required this.colors,
    required this.onSignOut,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: AppRadius.cardRadius,
        border:
            Border.all(color: c.goldLine, width: 1.5),
      ),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.all(AppSpacing.base),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isGuest
                        ? c.surface2
                        : c.brand.withOpacity(0.12),
                    border: Border.all(
                      color: isGuest
                          ? c.divider
                          : c.brand.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isGuest
                      ? Icon(
                          Icons.person_outline_rounded,
                          size: 26,
                          color: c.textMuted,
                        )
                      : Text(
                          userName.isNotEmpty
                              ? userName[0]
                                  .toUpperCase()
                              : 'U',
                          style: AppText.latin(
                            color: c.brand,
                            size: 24,
                            weight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(width: AppSpacing.md),
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
                      const SizedBox(
                          height: AppSpacing.xs),
                      if (isGuest)
                        Text(
                          'Sign in to sync your progress',
                          style: AppText.latin(
                            color: c.textMuted,
                            size: 12,
                          ),
                        )
                      else if (userEmail.isNotEmpty)
                        Text(
                          userEmail,
                          style: AppText.latin(
                            color: c.textMuted,
                            size: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(color: c.divider, height: 1),

          GestureDetector(
            onTap: isGuest ? onSignIn : onSignOut,
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
                      color: isGuest
                          ? c.brand.withOpacity(0.1)
                          : c.dangerBg,
                      borderRadius:
                          AppRadius.buttonRadius,
                    ),
                    child: Icon(
                      isGuest
                          ? Icons.login_rounded
                          : Icons.logout_rounded,
                      size: 16,
                      color: isGuest
                          ? c.brand
                          : c.danger,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    isGuest ? 'Sign In' : 'Sign Out',
                    style: AppText.latin(
                      color: isGuest
                          ? c.brand
                          : c.danger,
                      size: 14,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: isGuest
                        ? c.brand.withOpacity(0.5)
                        : c.danger.withOpacity(0.5),
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

// ─── Settings Toggle Row ──────────────────────────────────

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
                Text(title,
                    style: AppText.latin(
                        color: c.textPrimary,
                        size: 14,
                        weight: FontWeight.w600)),
                const SizedBox(
                    height: AppSpacing.xs),
                Text(subtitle,
                    style: AppText.latin(
                        color: c.textFaint,
                        size: 11)),
              ],
            ),
          ),
          Switch(
              value: value,
              onChanged: onChanged,
              activeColor: c.brand),
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
            child: Text('Language',
                style: AppText.latin(
                    color: c.textPrimary,
                    size: 14,
                    weight: FontWeight.w600)),
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

// ─── About Card ───────────────────────────────────────────

class _AboutCard extends StatelessWidget {
  final AppColors colors;
  final String aboutDescription;

  const _AboutCard({
    required this.colors,
    required this.aboutDescription,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final state = AppState.of(context);
    final bookCount =
        state.catalogService.books.length;
    final downloadCount =
        state.downloadService.downloadedCount;
    final teacherCount =
        state.catalogService.teachers.length;

    final versionLabel = state.appVersion.isNotEmpty
        ? 'v${state.appVersion}'
        : 'v1.0.2';

    final description = aboutDescription.isNotEmpty
        ? aboutDescription
        : 'مكتبة الروضة is a free Islamic learning app '
            'built to make authentic knowledge accessible to '
            'every Muslim student.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: c.divider),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(18),
              border: Border.all(
                  color: c.goldLine, width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: c.brand.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6))
              ],
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(16),
              child: Image.asset('assets/icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(
                        color: c.brand
                            .withOpacity(0.15),
                        child: Icon(
                            Icons.menu_book_rounded,
                            size: 30,
                            color: c.gold),
                      )),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('مكتبة الروضة',
              textDirection: TextDirection.rtl,
              style: AppText.arabic(
                  color: c.goldText,
                  size: 21,
                  weight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text('Your personal Islamic library',
              style: AppText.latin(
                  color: c.textMuted, size: 12)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs + 1),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: AppRadius.pillRadius,
              border: Border.all(color: c.divider),
            ),
            child: Text('$versionLabel · Free · No ads',
                style: AppText.latin(
                    color: c.textMuted,
                    size: 11,
                    weight: FontWeight.w600)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: c.divider, height: 1),
          const SizedBox(height: AppSpacing.lg),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppText.latin(
                color: c.textMuted,
                size: 12,
                height: 1.6),
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: c.divider, height: 1),
          const SizedBox(height: AppSpacing.lg),
          Column(
            children: [
              Text('$bookCount',
                  style: AppText.latin(
                      color: c.brand,
                      size: 48,
                      weight: FontWeight.w800,
                      height: 1.0)),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_rounded,
                      size: 13, color: c.textMuted),
                  const SizedBox(
                      width: AppSpacing.xs),
                  Text('Books in library',
                      style: AppText.latin(
                          color: c.textMuted,
                          size: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _SecondaryStatCell(
                    icon: Icons.headphones_rounded,
                    value: '$teacherCount',
                    label: 'Teachers',
                    colors: c),
              ),
              Container(
                  width: 1,
                  height: 40,
                  color: c.divider),
              Expanded(
                child: _SecondaryStatCell(
                    icon: Icons.download_rounded,
                    value: '$downloadCount',
                    label: 'Downloads',
                    colors: c),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: c.divider, height: 1),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _FooterPill(
                  icon: Icons.star_outline_rounded,
                  label: 'Always free',
                  colors: c),
              _FooterPill(
                  icon: Icons.school_rounded,
                  label: 'Rawdah · Est. 2025',
                  colors: c),
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
  const _SecondaryStatCell(
      {required this.icon,
      required this.value,
      required this.label,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value,
            style: AppText.latin(
                color: c.textPrimary,
                size: 22,
                weight: FontWeight.w700,
                height: 1.0)),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 11, color: c.textFaint),
            const SizedBox(width: AppSpacing.xs),
            Text(label,
                style: AppText.latin(
                    color: c.textFaint, size: 11)),
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
  const _FooterPill(
      {required this.icon,
      required this.label,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 1),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: c.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 11, color: c.textFaint),
          const SizedBox(width: AppSpacing.xs),
          Text(label,
              style: AppText.latin(
                  color: c.textMuted, size: 11)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final AppColors colors;
  const _SectionLabel(
      {required this.label,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base),
      child: Text(label,
          style:
              AppText.label(color: colors.textFaint)),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String code;
  final String label;
  final AppColors colors;
  const _LangButton(
      {required this.code,
      required this.label,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = colors;
    final active = state.language == code;
    return GestureDetector(
      onTap: () => state.setLanguage(code),
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active ? c.brand : c.surface2,
          borderRadius: AppRadius.buttonRadius,
          border: Border.all(
              color: active ? c.brand : c.divider),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                color: active
                    ? Colors.white
                    : c.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─── FAQ Item ─────────────────────────────────────────────

class _FaqItem extends StatefulWidget {
  final int number;
  final String question;
  final String answer;
  final AppColors colors;
  final bool isFirst;
  final bool isLast;
  const _FaqItem(
      {required this.number,
      required this.question,
      required this.answer,
      required this.colors,
      this.isFirst = false,
      this.isLast = false});
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
              endIndent: AppSpacing.base),
        GestureDetector(
          onTap: () => setState(
              () => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(
                          top: 1,
                          right: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: c.brand
                            .withOpacity(0.1),
                        borderRadius:
                            AppRadius.pillRadius,
                      ),
                      alignment: Alignment.center,
                      child: Text('${widget.number}',
                          style: AppText.latin(
                              color: c.brand,
                              size: 10,
                              weight:
                                  FontWeight.w700)),
                    ),
                    Expanded(
                        child: Text(
                            widget.question,
                            style: AppText.latin(
                                color:
                                    c.textPrimary,
                                size: 13,
                                weight: FontWeight
                                    .w600))),
                    const SizedBox(
                        width: AppSpacing.sm),
                    AnimatedRotation(
                      turns:
                          _expanded ? 0.25 : 0,
                      duration: const Duration(
                          milliseconds: 200),
                      child: Icon(
                          Icons
                              .chevron_right_rounded,
                          size: 18,
                          color: c.textFaint),
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
                        bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                            color: c.brand
                                .withOpacity(0.4),
                            width: 2),
                      ),
                    ),
                    child: Text(widget.answer,
                        style: AppText.latin(
                            color: c.textMuted,
                            size: 12,
                            height: 1.6)),
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

// ─── Privacy Item ─────────────────────────────────────────

class _PrivacyItem extends StatefulWidget {
  final String title;
  final String content;
  final AppColors colors;
  final bool isFirst;
  final bool isLast;
  const _PrivacyItem(
      {required this.title,
      required this.content,
      required this.colors,
      this.isFirst = false,
      this.isLast = false});
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
              endIndent: AppSpacing.base),
        GestureDetector(
          onTap: () => setState(
              () => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 14, color: c.brand),
                    const SizedBox(
                        width: AppSpacing.sm),
                    Expanded(
                        child: Text(widget.title,
                            style: AppText.latin(
                                color:
                                    c.textPrimary,
                                size: 13,
                                weight: FontWeight
                                    .w600))),
                    AnimatedRotation(
                      turns:
                          _expanded ? 0.25 : 0,
                      duration: const Duration(
                          milliseconds: 200),
                      child: Icon(
                          Icons
                              .chevron_right_rounded,
                          size: 18,
                          color: c.textFaint),
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
                        bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                            color: c.brand
                                .withOpacity(0.4),
                            width: 2),
                      ),
                    ),
                    child: Text(widget.content,
                        style: AppText.latin(
                            color: c.textMuted,
                            size: 12,
                            height: 1.6)),
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
