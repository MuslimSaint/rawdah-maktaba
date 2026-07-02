import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog_service.dart';

/// Central app state for theme, language, and user preferences.
/// Also holds the shared CatalogService instance.
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

  // ─── Shared CatalogService ─────────────────────────
  final CatalogService catalogService = CatalogService();

  // ─── Getters ───────────────────────────────────────
  bool get isDark => _isDark;
  String get language => _language;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isSignedIn => _isSignedIn;

  // Always LTR — Arabic text widgets handle their own direction
  TextDirection get textDirection => TextDirection.ltr;

  // ─── Initialization ────────────────────────────────

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final savedTheme = _prefs.getString(_keyThemeMode);
    if (savedTheme != null) {
      _isDark = savedTheme == 'dark';
    } else {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _isDark = brightness == Brightness.dark;
    }

    _language = _prefs.getString(_keyLanguage) ?? 'en';
    _isFirstLaunch = _prefs.getBool(_keyFirstLaunch) ?? true;
    _isSignedIn = _prefs.getBool(_keyUserSignedIn) ?? false;

    // Start loading catalog immediately after init
    catalogService.load();
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

  static AppState of(BuildContext context) {
    return AppStateProvider.of(context);
  }
}

/// InheritedNotifier that makes AppState available to the widget tree.
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
