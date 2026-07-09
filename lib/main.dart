import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'core/app_state.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';

// ─── Global error storage ──────────────────────────────
// Any error caught anywhere is stored here and shown on screen.
final List<String> _errorLog = [];

void _logError(String source, Object error, StackTrace? stack) {
  final entry = '[$source]\n$error\n\n${stack ?? "(no stack)"}';
  _errorLog.add(entry);
  debugPrint('══════════ ERROR CAUGHT ══════════');
  debugPrint(entry);
  debugPrint('═════════════════════════════════');
}

void main() {
  // Catch all Flutter framework errors (widget build errors, etc.)
  FlutterError.onError = (FlutterErrorDetails details) {
    _logError('FLUTTER', details.exception, details.stack);
  };

  // Catch all async errors outside Flutter
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } catch (e, s) {
      _logError('ORIENTATION', e, s);
    }

    try {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      );
    } catch (e, s) {
      _logError('STATUS_BAR', e, s);
    }

    try {
      await Firebase.initializeApp();
    } catch (e, s) {
      _logError('FIREBASE_INIT', e, s);
    }

    try {
      await JustAudioBackground.init(
        androidNotificationChannelId:
            'com.rawda.library.audio',
        androidNotificationChannelName: 'مكتبة الروضة',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      );
    } catch (e, s) {
      _logError('AUDIO_BACKGROUND_INIT', e, s);
    }

    AppState? appState;
    try {
      appState = AppState();
      await appState.init();
    } catch (e, s) {
      _logError('APP_STATE_INIT', e, s);
    }

    // Even if things failed, still try to run the app.
    // If there are errors, they'll be visible on screen.
    runApp(_RootApp(appState: appState));
  }, (error, stack) {
    _logError('UNCAUGHT_ZONE', error, stack);
    // Even if the zone catches something fatal, try to show
    // an error screen so the user isn't stuck on green.
    runApp(_ErrorApp(errors: _errorLog));
  });
}

// ─── Root App ──────────────────────────────────────────
// If there are ANY errors logged, show the diagnostic screen.
// Otherwise run the normal app.
class _RootApp extends StatelessWidget {
  final AppState? appState;
  const _RootApp({required this.appState});

  @override
  Widget build(BuildContext context) {
    if (_errorLog.isNotEmpty || appState == null) {
      return _ErrorApp(errors: _errorLog);
    }
    return RawdahApp(appState: appState!);
  }
}

// ─── Diagnostic Error App ──────────────────────────────
// Shows all caught errors clearly so we can fix them.
class _ErrorApp extends StatelessWidget {
  final List<String> errors;
  const _ErrorApp({required this.errors});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diagnostic',
      home: Scaffold(
        backgroundColor: const Color(0xFF1a1a1a),
        appBar: AppBar(
          backgroundColor: Colors.red.shade900,
          title: const Text(
            'App Startup Errors',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: errors.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'App failed to start but no error was captured.\n\n'
                      'This usually means AppState.init() returned null '
                      'or the app was killed by Android.\n\n'
                      'Please screenshot this and send it.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: errors.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900
                            .withOpacity(0.3),
                        border: Border.all(
                          color: Colors.red.shade400,
                        ),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Error ${i + 1} of ${errors.length}',
                            style: TextStyle(
                              color: Colors.red.shade300,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            errors[i],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontFamily: 'monospace',
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.red.shade700,
          icon: const Icon(Icons.info_outline,
              color: Colors.white),
          label: const Text(
            'Screenshot this screen',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () {},
        ),
      ),
    );
  }
}

/// Root widget of the normal app.
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
            _showAuth = true;
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
    return const MainScreen();
  }
}
