import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/translations.dart';

/// The splash screen shown when the app launches.
/// Uses the real app icon (assets/icon.png).
class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;

  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _fadeController;
  late AnimationController _dotsController;
  late AnimationController _exitController;

  late Animation<double> _iconScale;
  late Animation<double> _iconOpacity;
  late Animation<double> _bismillahOpacity;
  late Animation<Offset> _bismillahOffset;
  late Animation<double> _nameOpacity;
  late Animation<Offset> _nameOffset;
  late Animation<double> _badgeOpacity;
  late Animation<double> _badgeOffset;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _iconScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.elasticOut,
      ),
    );
    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _bismillahOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
      ),
    );
    _bismillahOffset = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
      ),
    );
    _nameOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.45, 0.8, curve: Curves.easeOut),
      ),
    );
    _nameOffset = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.45, 0.8, curve: Curves.easeOut),
      ),
    );
    _badgeOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
      ),
    );
    _badgeOffset = Tween<double>(begin: 8.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
      ),
    );

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _iconController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) _exitController.forward();
    });
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _fadeController.dispose();
    _dotsController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const splashBg = Color(0xFF013220);
    const splashDeep = Color(0xFF03140D);
    const splashGold = Color(0xFFFADCAC);

    return AnimatedBuilder(
      animation: _exitController,
      builder: (context, child) {
        return Opacity(
          opacity: 1.0 - _exitController.value,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [splashBg, splashDeep],
                stops: [0.0, 1.0],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── App Icon (real launcher icon) ──
                      AnimatedBuilder(
                        animation: _iconController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _iconOpacity.value,
                            child: Transform.scale(
                              scale: _iconScale.value,
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(22),
                                  border: Border.all(
                                    color: splashGold
                                        .withOpacity(0.35),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: splashGold
                                          .withOpacity(0.25),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  child: Image.asset(
                                    'assets/icon.png',
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => Container(
                                      color: splashGold
                                          .withOpacity(0.13),
                                      child: const Icon(
                                        Icons.menu_book_rounded,
                                        size: 44,
                                        color: splashGold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // ── Bismillah ──
                      AnimatedBuilder(
                        animation: _fadeController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _bismillahOpacity.value,
                            child: FractionalTranslation(
                              translation: _bismillahOffset.value,
                              child: Text(
                                T.bismillah.get('ar'),
                                textDirection: TextDirection.rtl,
                                style: AppText.arabic(
                                  color: splashGold,
                                  size: 14,
                                ).copyWith(
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // ── App Name ──
                      AnimatedBuilder(
                        animation: _fadeController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _nameOpacity.value,
                            child: FractionalTranslation(
                              translation: _nameOffset.value,
                              child: Text(
                                T.appName.get('ar'),
                                textDirection: TextDirection.rtl,
                                style: AppText.arabic(
                                  color: Colors.white,
                                  size: 32,
                                  weight: FontWeight.w700,
                                ).copyWith(
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // ── Pulsing Dots ──
                      AnimatedBuilder(
                        animation: Listenable.merge(
                          [_fadeController, _dotsController],
                        ),
                        builder: (context, child) {
                          if (_fadeController.value < 0.5) {
                            return const SizedBox(height: 8);
                          }
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(3, (i) {
                              final delay = i * 0.2;
                              final progress =
                                  (_dotsController.value - delay) %
                                      1.0;
                              final opacity = progress < 0.4
                                  ? 0.3 + (progress / 0.4) * 0.7
                                  : progress < 0.8
                                      ? 1.0 -
                                          ((progress - 0.4) / 0.4) *
                                              0.7
                                      : 0.3;
                              final scale = progress < 0.4
                                  ? 0.8 + (progress / 0.4) * 0.3
                                  : progress < 0.8
                                      ? 1.1 -
                                          ((progress - 0.4) / 0.4) *
                                              0.3
                                      : 0.8;
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: i < 2 ? 8 : 0,
                                ),
                                child: Opacity(
                                  opacity: opacity.clamp(0.0, 1.0),
                                  child: Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: splashGold,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ── Bottom Badge ──
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _fadeController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _badgeOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, _badgeOffset.value),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: splashGold.withOpacity(0.07),
                                borderRadius:
                                    BorderRadius.circular(20),
                                border: Border.all(
                                  color: splashGold.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.shield_outlined,
                                    size: 14,
                                    color: splashGold,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    T.rawdahProject.get('en'),
                                    style: const TextStyle(
                                      color: splashGold,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
