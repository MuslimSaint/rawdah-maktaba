import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import 'catalog_service.dart';
import 'download_service.dart';
import 'audio_service.dart';
import 'firestore_service.dart';
import 'cover_service.dart';
import 'models.dart';

/// Central app state.
class AppState extends ChangeNotifier {
  static const _keyThemeMode = 'theme_mode';
  static const _keyLanguage = 'language';
  static const _keyFirstLaunch = 'first_launch';
  static const _keyUserSignedIn = 'user_signed_in';
  static const _keyLastBookId = 'last_book_id';
  static const _keyLastBookPage = 'last_book_page';
  static const _keyLastBookTitle = 'last_book_title';
  static const _keyLastBookTotalPages = 'last_book_total_pages';
  static const _keyDismissedAnnouncements = 'dismissed_announcements';
  static const _keyLegacyMushafLastPage = 'mushaf_last_page';
  static const _keyMushafLastPagePrefix = 'mushaf_last_page_';

  late SharedPreferences _prefs;
  String _appDocsPath = '';

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

  final Set<String> _dismissedAnnouncements = <String>{};

  final CatalogService catalogService = CatalogService();
  final DownloadService downloadService = DownloadService();
  final AudioService audioService = AudioService();
  final FirestoreService firestoreService = FirestoreService();
  final CoverService coverService = CoverService();

  bool get isDark => _isDark;
  String get language => _language;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isSignedIn => _isSignedIn;
  String? get lastBookId => _lastBookId;
  String? get lastBookTitle => _lastBookTitle;
  int get lastBookPage => _lastBookPage;
  int get lastBookTotalPages => _lastBookTotalPages;
  String get appDocsPath => _appDocsPath;

  bool get hasLastBook => _lastBookId != null && _lastBookId!.isNotEmpty;
  double get lastBookProgress => _lastBookTotalPages > 0 ? _lastBookPage / _lastBookTotalPages : 0;
  TextDirection get textDirection => TextDirection.ltr;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final docs = await getApplicationDocumentsDirectory();
    _appDocsPath = docs.path;

    final savedTheme = _prefs.getString(_keyThemeMode);
    if (savedTheme != null) {
      _isDark = savedTheme == 'dark';
    } else {
      _isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }

    _language = _prefs.getString(_keyLanguage) ?? 'en';
    _isFirstLaunch = _prefs.getBool(_keyFirstLaunch) ?? true;
    _isSignedIn = _prefs.getBool(_keyUserSignedIn) ?? false;
    _lastBookId = _prefs.getString(_keyLastBookId);
    _lastBookTitle = _prefs.getString(_keyLastBookTitle);
    _lastBookPage = _prefs.getInt(_keyLastBookPage) ?? 0;
    _lastBookTotalPages = _prefs.getInt(_keyLastBookTotalPages) ?? 0;

    _migrateLegacyMushafLastPage();

    final dismissed = _prefs.getStringList(_keyDismissedAnnouncements) ?? [];
    _dismissedAnnouncements.addAll(dismissed);

    await downloadService.init();
    await coverService.init();

    downloadService.onPdfDownloadComplete = (bookId, pdfPath) => coverService.extractCover(bookId: bookId, pdfPath: pdfPath);
    downloadService.onPdfFileDeleted = (bookId) => coverService.clearFor(bookId);
    downloadService.onPhotoDownloaded = (id, path) async { notifyListeners(); };

    // ── NEW: Trigger related photo downloads when a PDF starts ──
    downloadService.onPdfDownloadStarted = (fileId) async {
      if (!catalogService.hasData) return;

      if (fileId.startsWith('pdf_surah_')) {
        final n = int.tryParse(fileId.replaceFirst('pdf_surah_', ''));
        if (n != null) {
          final surah = catalogService.quran.surahFor(n);
          // Reciters
          for (final ra in surah.reciters) {
            final reciter = catalogService.reciterById(ra.reciterId);
            if (reciter != null && reciter.hasPhoto) {
              downloadService.downloadPhoto(personId: reciter.id, photoUrl: reciter.photoUrl);
            }
          }
          // Teachers
          for (final ta in surah.teachers) {
            final teacher = catalogService.teacherById(ta.teacherId);
            if (teacher != null && teacher.hasPhoto) {
              downloadService.downloadPhoto(personId: teacher.id, photoUrl: teacher.photoUrl);
            }
          }
        }
      } else if (fileId.startsWith('pdf_') && fileId != 'pdf_mushaf') {
        final bookId = fileId.replaceFirst('pdf_', '');
        try {
          final book = catalogService.books.firstWhere((b) => b.id == bookId);
          for (final ta in book.teacherAudio) {
            final teacher = catalogService.teacherById(ta.teacherId);
            if (teacher != null && teacher.hasPhoto) {
              downloadService.downloadPhoto(personId: teacher.id, photoUrl: teacher.photoUrl);
            }
          }
        } catch (_) {}
      }
    };

    catalogService.addListener(_onCatalogLoaded);
    catalogService.load();
    if (_isSignedIn) _syncFromCloud();
  }

  void _migrateLegacyMushafLastPage() {
    if (_legacyMushafMigrated) return;
    _legacyMushafMigrated = true;
    final legacy = _prefs.getInt(_keyLegacyMushafLastPage);
    if (legacy == null || legacy <= 0) return;
    const defaultEditionId = 'mushaf';
    final newKey = '$_keyMushafLastPagePrefix$defaultEditionId';
    if (_prefs.getInt(newKey) == null) _prefs.setInt(newKey, legacy);
    _prefs.remove(_keyLegacyMushafLastPage);
  }

  bool _coverExtractionDone = false;
  void _onCatalogLoaded() {
    if (_coverExtractionDone) return;
    if (!catalogService.hasData) return;
    _coverExtractionDone = true;
    catalogService.removeListener(_onCatalogLoaded);
    _extractCoversForDownloadedBooks();
    _downloadMissingPhotos();
  }

  Future<void> _extractCoversForDownloadedBooks() async {
    final books = catalogService.books;
    for (final book in books) {
      final fileId = 'pdf_${book.id}';
      if (downloadService.isDownloaded(fileId) && !coverService.hasCover(book.id)) {
        final path = await downloadService.localPath(fileId);
        if (path != null) coverService.extractCover(bookId: book.id, pdfPath: path).catchError((_) {});
      }
    }
    for (final sub in catalogService.quranSubBranches) {
      for (final book in sub.books) {
        final fileId = 'pdf_${book.id}';
        if (downloadService.isDownloaded(fileId) && !coverService.hasCover(book.id)) {
          final path = await downloadService.localPath(fileId);
          if (path != null) coverService.extractCover(bookId: book.id, pdfPath: path).catchError((_) {});
        }
      }
    }
  }

  Future<void> _downloadMissingPhotos() async {
    for (final teacher in catalogService.teachers) {
      if (!teacher.hasPhoto || downloadService.hasPhoto(teacher.id)) continue;
      bool hasAudio = false;
      for (final book in catalogService.books) {
        final ta = book.audioForTeacher(teacher.id);
        if (ta == null) continue;
        for (final part in ta.parts) {
          if (downloadService.isDownloaded(DownloadService.audioId(book.id, teacher.id, part))) {
            hasAudio = true; break;
          }
        }
        if (hasAudio) break;
      }
      if (hasAudio) downloadService.downloadPhoto(personId: teacher.id, photoUrl: teacher.photoUrl);
    }
    for (final reciter in catalogService.reciters) {
      if (!reciter.hasPhoto || downloadService.hasPhoto(reciter.id)) continue;
      bool hasAudio = false;
      for (int n = 1; n <= 114; n++) {
        final surah = catalogService.quran.surahFor(n);
        for (final ra in surah.reciters) {
          if (ra.reciterId != reciter.id) continue;
          for (final part in ra.parts) {
            if (downloadService.isDownloaded(DownloadService.surahReciterAudioId(n, reciter.id, part))) {
              hasAudio = true; break;
            }
          }
          if (hasAudio) break;
        }
        if (hasAudio) break;
      }
      if (hasAudio) downloadService.downloadPhoto(personId: reciter.id, photoUrl: reciter.photoUrl);
    }
  }

  Future<void> _syncFromCloud() async {
    try {
      final cloudData = await firestoreService.syncOnLogin();
      if (cloudData == null) return;
      if (_lastBookId == null || _lastBookId!.isEmpty) {
        final bookId = cloudData['lastBookId'] as String? ?? '';
        final bookTitle = cloudData['lastBookTitle'] as String? ?? '';
        final page = cloudData['lastPage'] as int? ?? 0;
        final total = cloudData['totalPages'] as int? ?? 0;
        if (bookId.isNotEmpty) {
          _lastBookId = bookId; _lastBookTitle = bookTitle; _lastBookPage = page; _lastBookTotalPages = total;
          await _prefs.setString(_keyLastBookId, bookId); await _prefs.setString(_keyLastBookTitle, bookTitle);
          await _prefs.setInt(_keyLastBookPage, page); await _prefs.setInt(_keyLastBookTotalPages, total);
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    await _prefs.setString(_keyThemeMode, _isDark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    if (_language == lang || !['ar', 'en', 'am'].contains(lang)) return;
    _language = lang;
    await _prefs.setString(_keyLanguage, lang);
    notifyListeners();
  }

  Future<void> markFirstLaunchComplete() async {
    _isFirstLaunch = false;
    await _prefs.setBool(_keyFirstLaunch, false);
    notifyListeners();
  }

  Future<void> setSignedIn(bool value) async {
    _isSignedIn = value;
    await _prefs.setBool(_keyUserSignedIn, value);
    if (value) _syncFromCloud();
    notifyListeners();
  }

  Future<void> setLastOpenedBook({required String bookId, required String bookTitle, required int page, required int totalPages}) async {
    _lastBookId = bookId; _lastBookTitle = bookTitle; _lastBookPage = page; _lastBookTotalPages = totalPages;
    await _prefs.setString(_keyLastBookId, bookId); await _prefs.setString(_keyLastBookTitle, bookTitle);
    await _prefs.setInt(_keyLastBookPage, page); await _prefs.setInt(_keyLastBookTotalPages, totalPages);
    firestoreService.saveReadingProgress(bookId: bookId, bookTitle: bookTitle, page: page, totalPages: totalPages);
    notifyListeners();
  }

  Future<void> updateReadingPage(int page, int totalPages) async {
    _lastBookPage = page; _lastBookTotalPages = totalPages;
    await _prefs.setInt(_keyLastBookPage, page); await _prefs.setInt(_keyLastBookTotalPages, totalPages);
    if (_lastBookId != null) firestoreService.saveReadingProgress(bookId: _lastBookId!, bookTitle: _lastBookTitle ?? '', page: page, totalPages: totalPages);
    notifyListeners();
  }

  int mushafLastPageFor(String editionId) {
    if (_mushafLastPages.containsKey(editionId)) return _mushafLastPages[editionId]!;
    final saved = _prefs.getInt('$_keyMushafLastPagePrefix$editionId') ?? 0;
    _mushafLastPages[editionId] = saved;
    return saved;
  }

  Future<void> setMushafLastPageFor(String editionId, int page) async {
    if (page < 0) return;
    _mushafLastPages[editionId] = page;
    await _prefs.setInt('$_keyMushafLastPagePrefix$editionId', page);
    notifyListeners();
  }

  static String announcementFingerprint(String message, String type) => '${type}::${message.hashCode}';
  bool isAnnouncementDismissed(String fingerprint) => _dismissedAnnouncements.contains(fingerprint);
  Future<void> dismissAnnouncement(String fingerprint) async {
    if (_dismissedAnnouncements.contains(fingerprint)) return;
    _dismissedAnnouncements.add(fingerprint);
    await _prefs.setStringList(_keyDismissedAnnouncements, _dismissedAnnouncements.toList());
    notifyListeners();
  }

  static AppState of(BuildContext context) => AppStateProvider.of(context);
}

class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({super.key, required AppState state, required super.child}) : super(notifier: state);
  static AppState of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
    assert(provider != null, 'No AppStateProvider found');
    return provider!.notifier!;
  }
}
