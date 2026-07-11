import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog_service.dart';
import 'download_service.dart';
import 'audio_service.dart';
import 'firestore_service.dart';
import 'cover_service.dart';

/// Central app state.
class AppState extends ChangeNotifier {
  static const _keyThemeMode = 'theme_mode';
  static const _keyLanguage = 'language';
  static const _keyFirstLaunch = 'first_launch';
  static const _keyUserSignedIn = 'user_signed_in';
  static const _keyLastBookId = 'last_book_id';
  static const _keyLastBookPage = 'last_book_page';
  static const _keyLastBookTitle = 'last_book_title';
  static const _keyLastBookTotalPages =
      'last_book_total_pages';
  static const _keyDismissedAnnouncements =
      'dismissed_announcements';

  /// Local-only last page for the Full Mus'haf.
  /// Independent of the Firebase-synced reading progress.
  static const _keyMushafLastPage = 'mushaf_last_page';

  late SharedPreferences _prefs;

  bool _isDark = false;
  String _language = 'en';
  bool _isFirstLaunch = true;
  bool _isSignedIn = false;

  String? _lastBookId;
  String? _lastBookTitle;
  int _lastBookPage = 0;
  int _lastBookTotalPages = 0;

  /// Last page the user was on in the Full Mus'haf.
  /// Stored locally only. Zero means "not started yet."
  int _mushafLastPage = 0;

  final Set<String> _dismissedAnnouncements = <String>{};

  // ─── Shared Services ───────────────────────────────
  final CatalogService catalogService = CatalogService();
  final DownloadService downloadService = DownloadService();
  final AudioService audioService = AudioService();
  final FirestoreService firestoreService =
      FirestoreService();
  final CoverService coverService = CoverService();

  // ─── Getters ───────────────────────────────────────
  bool get isDark => _isDark;
  String get language => _language;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isSignedIn => _isSignedIn;
  String? get lastBookId => _lastBookId;
  String? get lastBookTitle => _lastBookTitle;
  int get lastBookPage => _lastBookPage;
  int get lastBookTotalPages => _lastBookTotalPages;

  int get mushafLastPage => _mushafLastPage;

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
      final brightness = WidgetsBinding
          .instance.platformDispatcher.platformBrightness;
      _isDark = brightness == Brightness.dark;
    }

    _language = _prefs.getString(_keyLanguage) ?? 'en';
    _isFirstLaunch =
        _prefs.getBool(_keyFirstLaunch) ?? true;
    _isSignedIn =
        _prefs.getBool(_keyUserSignedIn) ?? false;

    _lastBookId = _prefs.getString(_keyLastBookId);
    _lastBookTitle = _prefs.getString(_keyLastBookTitle);
    _lastBookPage = _prefs.getInt(_keyLastBookPage) ?? 0;
    _lastBookTotalPages =
        _prefs.getInt(_keyLastBookTotalPages) ?? 0;

    _mushafLastPage =
        _prefs.getInt(_keyMushafLastPage) ?? 0;

    final dismissed = _prefs
            .getStringList(_keyDismissedAnnouncements) ??
        [];
    _dismissedAnnouncements.addAll(dismissed);

    await downloadService.init();
    await coverService.init();

    downloadService.onPdfDownloadComplete =
        (bookId, pdfPath) => coverService.extractCover(
              bookId: bookId,
              pdfPath: pdfPath,
            );

    catalogService.addListener(_onCatalogLoaded);
    catalogService.load();

    if (_isSignedIn) _syncFromCloud();
  }

  // ─── Auto-extract covers after catalog loads ───────

  bool _coverExtractionDone = false;

  void _onCatalogLoaded() {
    if (_coverExtractionDone) return;
    if (!catalogService.hasData) return;

    _coverExtractionDone = true;
    catalogService.removeListener(_onCatalogLoaded);
    _extractCoversForDownloadedBooks();
  }

  Future<void> _extractCoversForDownloadedBooks() async {
    // Extract covers for regular books
    final books = catalogService.books;
    for (final book in books) {
      final fileId = 'pdf_${book.id}';
      if (downloadService.isDownloaded(fileId) &&
          !coverService.hasCover(book.id)) {
        final path =
            await downloadService.localPath(fileId);
        if (path != null) {
          coverService
              .extractCover(
                bookId: book.id,
                pdfPath: path,
              )
              .catchError((_) {});
        }
      }
    }

    // Also extract covers for books inside Quran sub-branches
    // (like Tafseer books).
    for (final sub in catalogService.quranSubBranches) {
      for (final book in sub.books) {
        final fileId = 'pdf_${book.id}';
        if (downloadService.isDownloaded(fileId) &&
            !coverService.hasCover(book.id)) {
          final path =
              await downloadService.localPath(fileId);
          if (path != null) {
            coverService
                .extractCover(
                  bookId: book.id,
                  pdfPath: path,
                )
                .catchError((_) {});
          }
        }
      }
    }
  }

  // ─── Cloud Sync ────────────────────────────────────

  Future<void> _syncFromCloud() async {
    try {
      final cloudData =
          await firestoreService.syncOnLogin();
      if (cloudData == null) return;

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
          await _prefs.setString(_keyLastBookId, bookId);
          await _prefs.setString(
              _keyLastBookTitle, bookTitle);
          await _prefs.setInt(_keyLastBookPage, page);
          await _prefs.setInt(
              _keyLastBookTotalPages, total);
          notifyListeners();
        }
      }
    } catch (_) {}
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
    if (value) _syncFromCloud();
    notifyListeners();
  }

  // ─── Reading Progress (books, synced to Firebase) ──

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

    await _prefs.setString(_keyLastBookId, bookId);
    await _prefs.setString(_keyLastBookTitle, bookTitle);
    await _prefs.setInt(_keyLastBookPage, page);
    await _prefs.setInt(_keyLastBookTotalPages, totalPages);

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
    await _prefs.setInt(
        _keyLastBookTotalPages, totalPages);

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

  // ─── Mus'haf Position (local only, no Firebase) ────

  /// Saves the current Full Mus'haf reading page locally.
  /// This is INTENTIONALLY not synced to Firebase because
  /// the Mus'haf is a special local-first reading experience.
  Future<void> setMushafLastPage(int page) async {
    if (page < 0) return;
    _mushafLastPage = page;
    await _prefs.setInt(_keyMushafLastPage, page);
    notifyListeners();
  }

  // ─── Announcement Dismissal ────────────────────────

  static String announcementFingerprint(
      String message, String type) {
    return '${type}::${message.hashCode}';
  }

  bool isAnnouncementDismissed(String fingerprint) {
    return _dismissedAnnouncements.contains(fingerprint);
  }

  Future<void> dismissAnnouncement(String fingerprint) async {
    if (_dismissedAnnouncements.contains(fingerprint)) return;
    _dismissedAnnouncements.add(fingerprint);
    await _prefs.setStringList(
      _keyDismissedAnnouncements,
      _dismissedAnnouncements.toList(),
    );
    notifyListeners();
  }

  Future<void> clearDismissedAnnouncements() async {
    _dismissedAnnouncements.clear();
    await _prefs.remove(_keyDismissedAnnouncements);
    notifyListeners();
  }

  // ─── Access ────────────────────────────────────────

  static AppState of(BuildContext context) {
    return AppStateProvider.of(context);
  }
}

/// InheritedNotifier that makes AppState available.
class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<
            AppStateProvider>();
    assert(
        provider != null, 'No AppStateProvider found');
    return provider!.notifier!;
  }
}
