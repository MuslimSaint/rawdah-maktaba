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
  static const _keyLegacyMushafLastPage =
      'mushaf_last_page';
  static const _keyMushafLastPagePrefix =
      'mushaf_last_page_';

  late SharedPreferences _prefs;

  bool _isDark = false;
  String _language = 'en';
  bool _isFirstLaunch = true;
  bool _isSignedIn = false;

  String? _lastBookId;
  String? _lastBookTitle;
  int _lastBookPage = 0;
  int _lastBookTotalPages = 0;

  final Map<String, int> _mushafLastPages = {};
  bool _legacyMushafMigrated = false;

  final Set<String> _dismissedAnnouncements =
      <String>{};

  // ─── Services ──────────────────────────────────────
  final CatalogService catalogService =
      CatalogService();
  final DownloadService downloadService =
      DownloadService();
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

  bool get hasLastBook =>
      _lastBookId != null && _lastBookId!.isNotEmpty;

  double get lastBookProgress =>
      _lastBookTotalPages > 0
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
      final brightness = WidgetsBinding.instance
          .platformDispatcher.platformBrightness;
      _isDark = brightness == Brightness.dark;
    }

    _language =
        _prefs.getString(_keyLanguage) ?? 'en';
    _isFirstLaunch =
        _prefs.getBool(_keyFirstLaunch) ?? true;
    _isSignedIn =
        _prefs.getBool(_keyUserSignedIn) ?? false;

    _lastBookId = _prefs.getString(_keyLastBookId);
    _lastBookTitle =
        _prefs.getString(_keyLastBookTitle);
    _lastBookPage =
        _prefs.getInt(_keyLastBookPage) ?? 0;
    _lastBookTotalPages =
        _prefs.getInt(_keyLastBookTotalPages) ?? 0;

    _migrateLegacyMushafLastPage();

    final dismissed = _prefs.getStringList(
            _keyDismissedAnnouncements) ??
        [];
    _dismissedAnnouncements.addAll(dismissed);

    await downloadService.init();
    await coverService.init();

    // ── Cover extraction on PDF download ──
    downloadService.onPdfDownloadComplete =
        (bookId, pdfPath) => coverService.extractCover(
              bookId: bookId,
              pdfPath: pdfPath,
            );

    // ── Cover cleanup on PDF delete ──
    downloadService.onPdfFileDeleted =
        (bookId) => coverService.clearFor(bookId);

    // ── Photo notification (UI refresh) ──
    // When a teacher/reciter photo finishes
    // downloading, notify listeners so any screen
    // currently showing that person updates its avatar.
    downloadService.onPhotoDownloaded =
        (personId, photoPath) async {
      notifyListeners();
    };

    catalogService.addListener(_onCatalogLoaded);
    catalogService.load();

    if (_isSignedIn) _syncFromCloud();
  }

  void _migrateLegacyMushafLastPage() {
    if (_legacyMushafMigrated) return;
    _legacyMushafMigrated = true;

    final legacy =
        _prefs.getInt(_keyLegacyMushafLastPage);
    if (legacy == null || legacy <= 0) return;

    const defaultEditionId = 'mushaf';
    final newKey =
        '$_keyMushafLastPagePrefix$defaultEditionId';
    if (_prefs.getInt(newKey) == null) {
      _prefs.setInt(newKey, legacy);
    }
    _prefs.remove(_keyLegacyMushafLastPage);
  }

  // ─── Auto-extract covers after catalog loads ───────

  bool _coverExtractionDone = false;

  void _onCatalogLoaded() {
    if (_coverExtractionDone) return;
    if (!catalogService.hasData) return;

    _coverExtractionDone = true;
    catalogService.removeListener(_onCatalogLoaded);
    _extractCoversForDownloadedBooks();

    // Also trigger photo downloads for any
    // teacher/reciter whose audio is already downloaded
    // but whose photo is not yet on disk.
    _downloadMissingPhotos();
  }

  Future<void> _extractCoversForDownloadedBooks()
      async {
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

    for (final sub
        in catalogService.quranSubBranches) {
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

  /// After catalog loads, check all teachers and
  /// reciters that have a photoUrl. If any audio from
  /// them is already downloaded but their photo is not,
  /// download their photo now silently.
  Future<void> _downloadMissingPhotos() async {
    // Teachers
    for (final teacher in catalogService.teachers) {
      if (!teacher.hasPhoto) continue;
      if (downloadService.hasPhoto(teacher.id)) {
        continue;
      }
      // Check if any audio from this teacher is
      // already downloaded.
      bool hasAudio = false;
      for (final book in catalogService.books) {
        final ta = book.audioForTeacher(teacher.id);
        if (ta == null) continue;
        for (final part in ta.parts) {
          final fid = DownloadService.audioId(
              book.id, teacher.id, part);
          if (downloadService.isDownloaded(fid)) {
            hasAudio = true;
            break;
          }
        }
        if (hasAudio) break;
      }
      if (hasAudio) {
        downloadService.downloadPhoto(
          personId: teacher.id,
          photoUrl: teacher.photoUrl,
        );
      }
    }

    // Reciters
    for (final reciter in catalogService.reciters) {
      if (!reciter.hasPhoto) continue;
      if (downloadService.hasPhoto(reciter.id)) {
        continue;
      }
      bool hasAudio = false;
      for (int n = 1; n <= 114; n++) {
        final surah =
            catalogService.quran.surahFor(n);
        for (final ra in surah.reciters) {
          if (ra.reciterId != reciter.id) continue;
          for (final part in ra.parts) {
            final fid =
                DownloadService.surahReciterAudioId(
                    n, reciter.id, part);
            if (downloadService.isDownloaded(fid)) {
              hasAudio = true;
              break;
            }
          }
          if (hasAudio) break;
        }
        if (hasAudio) break;
      }
      if (hasAudio) {
        downloadService.downloadPhoto(
          personId: reciter.id,
          photoUrl: reciter.photoUrl,
        );
      }
    }
  }

  // ─── Cloud Sync ────────────────────────────────────

  Future<void> _syncFromCloud() async {
    try {
      final cloudData =
          await firestoreService.syncOnLogin();
      if (cloudData == null) return;

      if (_lastBookId == null ||
          _lastBookId!.isEmpty) {
        final bookId =
            cloudData['lastBookId'] as String? ?? '';
        final bookTitle =
            cloudData['lastBookTitle'] as String? ??
                '';
        final page =
            cloudData['lastPage'] as int? ?? 0;
        final total =
            cloudData['totalPages'] as int? ?? 0;

        if (bookId.isNotEmpty) {
          _lastBookId = bookId;
          _lastBookTitle = bookTitle;
          _lastBookPage = page;
          _lastBookTotalPages = total;
          await _prefs.setString(
              _keyLastBookId, bookId);
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

    await _prefs.setString(_keyLastBookId, bookId);
    await _prefs.setString(
        _keyLastBookTitle, bookTitle);
    await _prefs.setInt(_keyLastBookPage, page);
    await _prefs.setInt(
        _keyLastBookTotalPages, totalPages);

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

  // ─── Mus'haf Position ──────────────────────────────

  int mushafLastPageFor(String editionId) {
    if (_mushafLastPages.containsKey(editionId)) {
      return _mushafLastPages[editionId]!;
    }
    final saved = _prefs.getInt(
            '$_keyMushafLastPagePrefix$editionId') ??
        0;
    _mushafLastPages[editionId] = saved;
    return saved;
  }

  Future<void> setMushafLastPageFor(
      String editionId, int page) async {
    if (page < 0) return;
    _mushafLastPages[editionId] = page;
    await _prefs.setInt(
      '$_keyMushafLastPagePrefix$editionId',
      page,
    );
    notifyListeners();
  }

  // ─── Announcement Dismissal ────────────────────────

  static String announcementFingerprint(
      String message, String type) {
    return '${type}::${message.hashCode}';
  }

  bool isAnnouncementDismissed(String fingerprint) {
    return _dismissedAnnouncements
        .contains(fingerprint);
  }

  Future<void> dismissAnnouncement(
      String fingerprint) async {
    if (_dismissedAnnouncements
        .contains(fingerprint)) return;
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
class AppStateProvider
    extends InheritedNotifier<AppState> {
  const AppStateProvider({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<
            AppStateProvider>();
    assert(
        provider != null, 'No AppStateProvider found');
    return provider!.notifier!;
  }
}
