import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/app_state.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI overlay (status bar) to be transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize app state (loads preferences from disk)
  final appState = AppState();
  await appState.init();

  runApp(RawdahApp(appState: appState));
}

/// Root widget of the app.
/// Provides AppState to the entire widget tree.
class RawdahApp extends StatelessWidget {
  final AppState appState;

  const RawdahApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return AppStateProvider(
      state: appState,
      child: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'مكتبة الروضة',
            theme: buildTheme(appState.isDark),
            home: const AppRouter(),
          );
        },
      ),
    );
  }
}

/// Handles the initial routing:
/// splash → welcome (first launch only)
/// splash → auth (not signed in)
/// splash → main (signed in)
class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _showSplash = true;
  bool _showWelcome = false;
  bool _showAuth = false;

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);

    // ── Splash ──
    if (_showSplash) {
      return SplashScreen(
        onDone: () {
          setState(() {
            _showSplash = false;
            if (state.isFirstLaunch) {
              _showWelcome = true;
            } else if (!state.isSignedIn) {
              _showAuth = true;
            }
            // else: go straight to main app
          });
        },
      );
    }

    // ── Welcome (first launch only) ──
    if (_showWelcome) {
      return WelcomeScreen(
        language: state.language,
        onBegin: () async {
          await state.markFirstLaunchComplete();
          setState(() {
            _showWelcome = false;
            _showAuth = true; // after welcome, always show auth
          });
        },
      );
    }

    // ── Auth (not signed in) ──
    if (_showAuth) {
      return AuthScreen(
        onAuthenticated: () async {
          await state.setSignedIn(true);
          setState(() {
            _showAuth = false;
          });
        },
      );
    }

    // ── Main App ──
    return const _MainPlaceholder();
  }
}

/// Temporary placeholder for the main app.
/// Will be replaced with real navigation shell in Chapter 4.
class _MainPlaceholder extends StatelessWidget {
  const _MainPlaceholder();

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);

    return Directionality(
      textDirection: state.textDirection,
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: c.brand.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: c.brand.withOpacity(0.3)),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 40,
                    color: c.brand,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'مكتبة الروضة',
                  textDirection: TextDirection.rtl,
                  style: AppText.arabic(
                    color: c.textPrimary,
                    size: 28,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Authentication working ✓',
                  style: AppText.latin(
                    color: c.textMuted,
                    size: 14,
                  ),
                ),
                const SizedBox(height: 40),

                // Theme + Language controls
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.divider),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            state.isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: c.brand,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Theme: ${state.isDark ? "Dark" : "Light"}',
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
                      const SizedBox(height: 12),
                      Divider(color: c.divider, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.language_rounded, color: c.brand),
                          const SizedBox(width: 12),
                          Text(
                            'Language: ${state.language.toUpperCase()}',
                            style: AppText.latin(
                              color: c.textPrimary,
                              size: 14,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          _LangButton(code: 'ar', label: 'ع'),
                          const SizedBox(width: 6),
                          _LangButton(code: 'en', label: 'A'),
                          const SizedBox(width: 6),
                          _LangButton(code: 'am', label: 'አ'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: c.divider, height: 1),
                      const SizedBox(height: 12),

                      // Sign out button for testing
                      GestureDetector(
                        onTap: () async {
                          await state.setSignedIn(false);
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const AppRouter(),
                              ),
                              (_) => false,
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 44,
                          decoration: BoxDecoration(
                            color: c.dangerBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: c.danger.withOpacity(0.3),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Sign Out (test)',
                            style: AppText.latin(
                              color: c.danger,
                              size: 14,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String code;
  final String label;

  const _LangButton({required this.code, required this.label});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);
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
