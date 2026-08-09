import 'package:animations/animations.dart';
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
          final baseTheme = buildTheme(appState.isDark);

          // Attach the shared-axis liquid transition so
          // every route push feels fluid and professional.
          final themeWithTransitions = baseTheme.copyWith(
            pageTransitionsTheme:
                const PageTransitionsTheme(
              builders: {
                TargetPlatform.android:
                    _SharedAxisPageTransitionsBuilder(),
                TargetPlatform.iOS:
                    _SharedAxisPageTransitionsBuilder(),
              },
            ),
          );

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'مكتبة الروضة',
            theme: themeWithTransitions,
            home: const AppRouter(),
            builder: (context, child) {
              return _AppShell(child: child);
            },
          );
        },
      ),
    );
  }
}

/// Liquid page transition using SharedAxisTransition
/// (horizontal shared axis — pages slide in from the
/// right and out to the left simultaneously with a
/// coordinated fade, creating a fluid "liquid" feel).
///
/// Uses the `animations` package from the Flutter team.
class _SharedAxisPageTransitionsBuilder
    extends PageTransitionsBuilder {
  const _SharedAxisPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: SharedAxisTransitionType.horizontal,
      // fillColor is transparent so the background
      // of the destination screen shows through during
      // the transition rather than flashing white/black.
      fillColor: Colors.transparent,
      child: child,
    );
  }
}

/// Wraps every route with the persistent mini audio player.
///
/// Shows for authenticated users AND guest users —
/// both can download and play audio.
class _AppShell extends StatelessWidget {
  final Widget? child;
  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);

    // Show mini player if the user has passed auth
    // (either signed in OR in guest mode) and is past
    // the first-launch/splash screens.
    final showMini =
        (state.isSignedIn || state.isGuest) &&
            !state.isFirstLaunch;

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
            } else if (!state.isSignedIn &&
                !state.isGuest) {
              // Neither signed in nor guest — show auth
              _showAuth = true;
            }
            // else: returning signed-in user or
            // returning guest → go straight to MainScreen
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
          // onAuthenticated is called both when a real
          // account sign-in succeeds AND when the user
          // taps Continue as Guest.
          //
          // In the guest case, AppState.setGuest() has
          // already been called inside AuthScreen, so
          // state.isGuest is already true here.
          // We must NOT call setSignedIn(true) for guests.
          if (!state.isGuest) {
            await state.setSignedIn(true);
          }
          setState(() {
            _showAuth = false;
          });
        },
      );
    }

    return const MainScreen();
  }
}
