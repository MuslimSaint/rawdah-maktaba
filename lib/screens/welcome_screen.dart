import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/translations.dart';
import '../core/pressable.dart';

/// The welcome screen shown only on the very first launch.
/// After the user taps "Begin Your Journey", it is never shown again.
class WelcomeScreen extends StatefulWidget {
  final String language;
  final VoidCallback onBegin;

  const WelcomeScreen({
    super.key,
    required this.language,
    required this.onBegin,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _featuresController;
  late AnimationController _buttonController;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _featuresController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Sequence: header → features → button
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _featuresController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _featuresController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const splashBg = Color(0xFF013220);
    const splashDeep = Color(0xFF03140D);
    const splashGold = Color(0xFFFADCAC);
    final lang = widget.language;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [splashBg, splashDeep],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),

                // Header
                AnimatedBuilder(
                  animation: _headerController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _headerController.value,
                      child: Transform.translate(
                        offset: Offset(0, 16 * (1 - _headerController.value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: splashGold.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: splashGold.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 42,
                          color: splashGold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        T.bismillah.get(lang),
                        textDirection: TextDirection.rtl,
                        style: AppText.arabic(
                          color: splashGold,
                          size: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        T.appName.get(lang),
                        textDirection: TextDirection.rtl,
                        style: AppText.arabic(
                          color: Colors.white,
                          size: 32,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        T.welcomeSubtitle.get(lang),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Features
                _AnimatedFeature(
                  controller: _featuresController,
                  delay: 0.0,
                  icon: Icons.menu_book_rounded,
                  title: T.feature1Title.get(lang),
                  subtitle: T.feature1Sub.get(lang),
                  goldColor: splashGold,
                ),
                const SizedBox(height: 12),
                _AnimatedFeature(
                  controller: _featuresController,
                  delay: 0.25,
                  icon: Icons.headphones_rounded,
                  title: T.feature2Title.get(lang),
                  subtitle: T.feature2Sub.get(lang),
                  goldColor: splashGold,
                ),
                const SizedBox(height: 12),
                _AnimatedFeature(
                  controller: _featuresController,
                  delay: 0.5,
                  icon: Icons.cloud_off_rounded,
                  title: T.feature3Title.get(lang),
                  subtitle: T.feature3Sub.get(lang),
                  goldColor: splashGold,
                ),

                const SizedBox(height: 40),

                // Begin button
                AnimatedBuilder(
                  animation: _buttonController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _buttonController.value,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - _buttonController.value)),
                        child: child,
                      ),
                    );
                  },
                  child: Pressable(
                    onTap: widget.onBegin,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFADCAC),
                            Color(0xFFD49830),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: splashGold.withOpacity(0.3),
                            blurRadius: 28,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        T.beginJourney.get(lang),
                        style: const TextStyle(
                          color: Color(0xFF051A10),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single feature card with staggered fade-in animation.
class _AnimatedFeature extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color goldColor;

  const _AnimatedFeature({
    required this.controller,
    required this.delay,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.goldColor,
  });

  @override
  Widget build(BuildContext context) {
    // Each feature animates within its own sub-interval
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0), curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: goldColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: goldColor.withOpacity(0.33),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: goldColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
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
