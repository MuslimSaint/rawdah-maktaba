import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central app state for theme, language, and user preferences.
/// Persists all changes to SharedPreferences automatically.
///
/// Usage:
///   final state = AppState.of(context);
///   state.toggleTheme();
///   state.setLanguage('ar');
class AppState extends ChangeNotifier {
  // ─── Storage keys ──────────────────────────────────
  static const _keyThemeMode = 'theme_mode';
  static const _keyLanguage = 'language';
  static const _keyFirstLaunch = 'first_launch';
  static const _keyUserSignedIn = 'user_signed_in';

  // ─── State ─────────────────────────────────────────
  late SharedPreferences _prefs;

  bool _isDark = false;
  String _language = 'en';
  bool _isFirstLaunch = true;
  bool _isSignedIn = false;

  // ─── Getters ───────────────────────────────────────
  bool get isDark => _isDark;
  String get language => _language;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isSignedIn => _isSignedIn;

  /// Returns the text direction based on current language.
  /// Arabic is RTL, English and Amharic are LTR.
  TextDirection get textDirection =>
      _language == 'ar' ? TextDirection.rtl : TextDirection.ltr;

  // ─── Initialization ────────────────────────────────

  /// Loads all preferences from disk.
  /// Must be called once at app startup before runApp().
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Load saved theme, or use system default on first launch
    final savedTheme = _prefs.getString(_keyThemeMode);
    if (savedTheme != null) {
      _isDark = savedTheme == 'dark';
    } else {
      // First launch: follow system preference
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _isDark = brightness == Brightness.dark;
    }

    // Load saved language, default to English
    _language = _prefs.getString(_keyLanguage) ?? 'en';

    // Load first launch flag
    _isFirstLaunch = _prefs.getBool(_keyFirstLaunch) ?? true;

    // Load sign-in status
    _isSignedIn = _prefs.getBool(_keyUserSignedIn) ?? false;
  }

  // ─── Theme ─────────────────────────────────────────

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    await _prefs.setString(_keyThemeMode, _isDark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    await _prefs.setString(_keyThemeMode, _isDark ? 'dark' : 'light');
    notifyListeners();
  }

  // ─── Language ──────────────────────────────────────

  Future<void> setLanguage(String lang) async {
    if (_language == lang) return;
    if (!['ar', 'en', 'am'].contains(lang)) return;
    _language = lang;
    await _prefs.setString(_keyLanguage, lang);
    notifyListeners();
  }

  // ─── First launch ──────────────────────────────────

  Future<void> markFirstLaunchComplete() async {
    _isFirstLaunch = false;
    await _prefs.setBool(_keyFirstLaunch, false);
    notifyListeners();
  }

  // ─── Auth ──────────────────────────────────────────

  Future<void> setSignedIn(bool value) async {
    _isSignedIn = value;
    await _prefs.setBool(_keyUserSignedIn, value);
    notifyListeners();
  }

  // ─── Access from widgets ───────────────────────────

  /// Convenience method to access AppState from any BuildContext.
  static AppState of(BuildContext context) {
    return AppStateProvider.of(context);
  }
}

/// InheritedNotifier that makes AppState available to the widget tree.
/// Widgets that call AppState.of(context) will rebuild when state changes.
class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
    assert(provider != null, 'No AppStateProvider found in widget tree');
    return provider!.notifier!;
  }
}
