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
import 'widgets/mini_audio_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Firebase.initializeApp();

  await JustAudioBackground.init(
    androidNotificationChannelId:
        'com.rawda.library.audio',
    androidNotificationChannelName: 'مكتبة الروضة',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'mipmap/ic_launcher',
  );

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

            // ── Persistent mini audio player overlay ──
            // Wraps every route in a Stack so the mini player
            // shows on top of ALL screens, not just tabs.
            builder: (context, child) {
              return _AppShell(child: child);
            },
          );
        },
      ),
    );
  }
}

/// Wraps every route with the persistent mini audio player.
/// The mini player only appears when audio is active AND
/// the user is past the pre-login screens.
class _AppShell extends StatelessWidget {
  final Widget? child;
  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);

    // Do not show mini player during pre-login flow.
    // Only show it once the user is fully signed in.
    final showMini = state.isSignedIn && !state.isFirstLaunch;

    return Stack(
      children: [
        child ?? const SizedBox.shrink(),
        if (showMini)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: const MiniAudioPlayer(),
          ),
      ],
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

    return const MainScreen();
  }
}
