import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog_service.dart';
import 'download_service.dart';
import 'audio_service.dart';
import 'firestore_service.dart';

/// Central app state for theme, language, and user preferences.
class AppState extends ChangeNotifier {
  static const _keyThemeMode = 'theme_mode';
  static const _keyLanguage = 'language';
  static const _keyFirstLaunch = 'first_launch';
  static const _keyUserSignedIn = 'user_signed_in';
  static const _keyLastBookId = 'last_book_id';
  static const _keyLastBookPage = 'last_book_page';
  static const _keyLastBookTitle = 'last_book_title';
  static const _keyLastBookTotalPages = 'last_book_total_pages';

  late SharedPreferences _prefs;

  bool _isDark = false;
  String _language = 'en';
  bool _isFirstLaunch = true;
  bool _isSignedIn = false;

  // ─── Last opened book ──────────────────────────────
  String? _lastBookId;
  String? _lastBookTitle;
  int _lastBookPage = 0;
  int _lastBookTotalPages = 0;

  // ─── Shared Services ───────────────────────────────
  final CatalogService catalogService = CatalogService();
  final DownloadService downloadService = DownloadService();
  final AudioService audioService = AudioService();
  final FirestoreService firestoreService = FirestoreService();

  // ─── Getters ───────────────────────────────────────
  bool get isDark => _isDark;
  String get language => _language;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isSignedIn => _isSignedIn;
  String? get lastBookId => _lastBookId;
  String? get lastBookTitle => _lastBookTitle;
  int get lastBookPage => _lastBookPage;
  int get lastBookTotalPages => _lastBookTotalPages;

  bool get hasLastBook =>
      _lastBookId != null && _lastBookId!.isNotEmpty;

  double get lastBookProgress => _lastBookTotalPages > 0
      ? _lastBookPage / _lastBookTotalPages
      : 0;

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

    // Load last opened book from local storage
    _lastBookId = _prefs.getString(_keyLastBookId);
    _lastBookTitle = _prefs.getString(_keyLastBookTitle);
    _lastBookPage = _prefs.getInt(_keyLastBookPage) ?? 0;
    _lastBookTotalPages =
        _prefs.getInt(_keyLastBookTotalPages) ?? 0;

    // Initialize services
    await downloadService.init();
    catalogService.load();

    // Sync from Firestore if signed in
    if (_isSignedIn) {
      _syncFromCloud();
    }
  }

  // ─── Cloud Sync ────────────────────────────────────

  /// Syncs reading progress from Firestore.
  /// Cloud data wins only if local has no data.
  Future<void> _syncFromCloud() async {
    try {
      final cloudData =
          await firestoreService.syncOnLogin();
      if (cloudData == null) return;

      // Only use cloud data if local has nothing
      if (_lastBookId == null || _lastBookId!.isEmpty) {
        final bookId =
            cloudData['lastBookId'] as String? ?? '';
        final bookTitle =
            cloudData['lastBookTitle'] as String? ?? '';
        final page = cloudData['lastPage'] as int? ?? 0;
        final total =
            cloudData['totalPages'] as int? ?? 0;

        if (bookId.isNotEmpty) {
          _lastBookId = bookId;
          _lastBookTitle = bookTitle;
          _lastBookPage = page;
          _lastBookTotalPages = total;

          // Save to local
          await _prefs.setString(_keyLastBookId, bookId);
          await _prefs.setString(
              _keyLastBookTitle, bookTitle);
          await _prefs.setInt(_keyLastBookPage, page);
          await _prefs.setInt(
              _keyLastBookTotalPages, total);
          notifyListeners();
        }
      }
    } catch (_) {
      // Silently fail — local data is fine
    }
  }

  // ─── Theme ─────────────────────────────────────────

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    await _prefs.setString(
        _keyThemeMode, _isDark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    await _prefs.setString(
        _keyThemeMode, _isDark ? 'dark' : 'light');
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
    if (value) {
      // Sync from cloud after sign in
      _syncFromCloud();
    }
    notifyListeners();
  }

  // ─── Reading Progress ──────────────────────────────

  Future<void> setLastOpenedBook({
    required String bookId,
    required String bookTitle,
    required int page,
    required int totalPages,
  }) async {
    _lastBookId = bookId;
    _lastBookTitle = bookTitle;
    _lastBookPage = page;
    _lastBookTotalPages = totalPages;

    // Save locally
    await _prefs.setString(_keyLastBookId, bookId);
    await _prefs.setString(_keyLastBookTitle, bookTitle);
    await _prefs.setInt(_keyLastBookPage, page);
    await _prefs.setInt(_keyLastBookTotalPages, totalPages);

    // Sync to cloud (non-blocking)
    firestoreService.saveReadingProgress(
      bookId: bookId,
      bookTitle: bookTitle,
      page: page,
      totalPages: totalPages,
    );

    notifyListeners();
  }

  Future<void> updateReadingPage(
      int page, int totalPages) async {
    _lastBookPage = page;
    _lastBookTotalPages = totalPages;
    await _prefs.setInt(_keyLastBookPage, page);
    await _prefs.setInt(_keyLastBookTotalPages, totalPages);

    // Sync to cloud (non-blocking)
    if (_lastBookId != null) {
      firestoreService.saveReadingProgress(
        bookId: _lastBookId!,
        bookTitle: _lastBookTitle ?? '',
        page: page,
        totalPages: totalPages,
      );
    }

    notifyListeners();
  }

  // ─── Access ────────────────────────────────────────

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
