import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/app_state.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';

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
