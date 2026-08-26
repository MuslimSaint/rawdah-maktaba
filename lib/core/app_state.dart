import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import 'catalog_service.dart';
import 'content_table_service.dart';
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
  static const _keyIsGuest = 'user_is_guest';
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

  // MethodChannel for querying Android app version.
  static const _installChannel =
      MethodChannel('com.rawda.library/install');

  late SharedPreferences _prefs;
  String _appDocsPath = '';
  String _appVersion = '';

  // Fresh install default: always light mode (false)
  bool _isDark = false;
  String _language = 'en';
  bool _isFirstLaunch = true;
  bool _isSignedIn = false;
  bool _isGuest = false;

  String? _lastBookId;
  String? _lastBookTitle;
  int _lastBookPage = 0;
  int _lastBookTotalPages = 0;

  final Map<String, int> _mushafLastPages = {};
  bool _legacyMushafMigrated = false;

  final Set<String> _dismissedAnnouncements =
      <String>{};

  final CatalogService catalogService =
      CatalogService();
  final DownloadService downloadService =
      DownloadService();
  final AudioService audioService = AudioService();
  final FirestoreService firestoreService =
      FirestoreService();
  final CoverService coverService = CoverService();
  final ContentTableService contentTableService =
      ContentTableService();

  bool get isDark => _isDark;
  String get language => _language;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isSignedIn => _isSignedIn;
  bool get isGuest => _isGuest;
  String? get lastBookId => _lastBookId;
  String? get lastBookTitle => _lastBookTitle;
  int get lastBookPage => _lastBookPage;
  int get lastBookTotalPages => _lastBookTotalPages;
  String get appDocsPath => _appDocsPath;
  String get appVersion => _appVersion;

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
    final docs = await getApplicationDocumentsDirectory();
    _appDocsPath = docs.path;

    await _loadAppVersion();

    // Fresh install default is Light mode (false).
    // System dark mode is ignored on fresh install unless
    // explicitly saved by the user previously.
    final savedTheme = _prefs.getString(_keyThemeMode);
    if (savedTheme != null) {
      _isDark = savedTheme == 'dark';
    } else {
      _isDark = false;
    }

    _language =
        _prefs.getString(_keyLanguage) ?? 'en';
    _isFirstLaunch =
        _prefs.getBool(_keyFirstLaunch) ?? true;
    _isSignedIn =
        _prefs.getBool(_keyUserSignedIn) ?? false;
    _isGuest = _prefs.getBool(_keyIsGuest) ?? false;
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
    await contentTableService.init();

    downloadService.onPdfDownloadComplete =
        (bookId, pdfPath) => coverService.extractCover(
              bookId: bookId,
              pdfPath: pdfPath,
            );

    downloadService.onPdfFileDeleted =
        (bookId) async {
      await coverService.clearFor(bookId);
      await contentTableService.deleteToc(bookId);
    };

    downloadService.onPhotoDownloaded =
        (id, path) async {
      notifyListeners();
    };

    downloadService.onPdfDownloadStarted =
        (fileId) async {
      if (!catalogService.hasData) return;

      if (fileId.startsWith('pdf_surah_')) {
        final n = int.tryParse(
            fileId.replaceFirst('pdf_surah_', ''));
        if (n != null) {
          final surah =
              catalogService.quran.surahFor(n);
          for (final ra in surah.reciters) {
            final reciter =
                catalogService.reciterById(ra.reciterId);
            if (reciter != null && reciter.hasPhoto) {
              downloadService.downloadPhoto(
                personId: reciter.id,
                photoUrl: reciter.photoUrl,
              );
            }
          }
          for (final ta in surah.teachers) {
            final teacher =
                catalogService.teacherById(ta.teacherId);
            if (teacher != null && teacher.hasPhoto) {
              downloadService.downloadPhoto(
                personId: teacher.id,
                photoUrl: teacher.photoUrl,
              );
            }
          }
        }
      } else if (fileId.startsWith('pdf_') &&
          fileId != 'pdf_mushaf' &&
          !fileId.startsWith('pdf_mushaf_')) {
        final bookId =
            fileId.replaceFirst('pdf_', '');
        try {
          final book = catalogService.books
              .firstWhere((b) => b.id == bookId);

          for (final ta in book.teacherAudio) {
            final teacher =
                catalogService.teacherById(ta.teacherId);
            if (teacher != null && teacher.hasPhoto) {
              downloadService.downloadPhoto(
                personId: teacher.id,
                photoUrl: teacher.photoUrl,
              );
            }
          }

          if (book.hasContentTableUrl) {
            contentTableService.downloadToc(
              bookId: book.id,
              url: book.contentTableUrl,
            );
          }
        } catch (_) {}
      }
    };

    catalogService.addListener(_onCatalogLoaded);
    catalogService.load();
    if (_isSignedIn && !_isGuest) _syncFromCloud();
  }

  Future<void> _loadAppVersion() async {
    try {
      final v = await _installChannel
          .invokeMethod<String>('getAppVersion');
      _appVersion = v ?? '';
    } catch (_) {
      _appVersion = '';
    }
    catalogService.setCurrentAppVersion(_appVersion);
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

  // ─── Catalog loaded ────────────────────────────────

  bool _coverExtractionDone = false;

  void _onCatalogLoaded() {
    if (_coverExtractionDone) return;
    if (!catalogService.hasData) return;
    _coverExtractionDone = true;
    catalogService.removeListener(_onCatalogLoaded);
    _extractCoversForDownloadedBooks();
    _downloadMissingPhotos();
    _cleanOrphanedFiles();
    _downloadMissingTocs();
    _cleanupApkIfUpdated();
  }

  Future<void> _cleanupApkIfUpdated() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final apkFile =
          File('${cacheDir.path}/rawdah_update.apk');
      if (!await apkFile.exists()) return;

      final rawAnnouncement =
          catalogService.catalog?.announcement;
      final isActiveUpdate = rawAnnouncement != null &&
          rawAnnouncement.active &&
          rawAnnouncement.isUpdate &&
          rawAnnouncement.hasDownloadUrl;

      bool shouldDelete = false;

      if (!isActiveUpdate) {
        shouldDelete = true;
      } else if (_appVersion.isNotEmpty &&
          rawAnnouncement!.maxVersionToShow.isNotEmpty) {
        final cmp = catalogService.compareVersions(
            _appVersion, rawAnnouncement.maxVersionToShow);
        if (cmp > 0) {
          shouldDelete = true;
        }
      }

      if (shouldDelete) {
        await apkFile.delete();
        debugPrint(
            'Cached update APK deleted (user is up to date).');
      }
    } catch (e) {
      debugPrint('APK cleanup failed: $e');
    }
  }

  // ─── Cover extraction ──────────────────────────────

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

  // ─── TOC migration ─────────────────────────────────

  Future<void> _downloadMissingTocs() async {
    for (final book in catalogService.books) {
      if (!book.hasContentTableUrl) continue;
      if (contentTableService.hasCachedToc(book.id)) {
        continue;
      }
      if (!downloadService
          .isDownloaded('pdf_${book.id}')) continue;
      contentTableService.downloadToc(
        bookId: book.id,
        url: book.contentTableUrl,
      );
    }
  }

  // ─── Photo migration ───────────────────────────────

  Future<void> _downloadMissingPhotos() async {
    for (final teacher in catalogService.teachers) {
      if (!teacher.hasPhoto ||
          downloadService.hasPhoto(teacher.id)) continue;
      bool hasAudio = false;
      for (final book in catalogService.books) {
        final ta = book.audioForTeacher(teacher.id);
        if (ta == null) continue;
        for (final part in ta.parts) {
          if (downloadService.isDownloaded(
              DownloadService.audioId(
                  book.id, teacher.id, part))) {
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

    for (final reciter in catalogService.reciters) {
      if (!reciter.hasPhoto ||
          downloadService.hasPhoto(reciter.id)) continue;
      bool hasAudio = false;
      for (int n = 1; n <= 114; n++) {
        final surah =
            catalogService.quran.surahFor(n);
        for (final ra in surah.reciters) {
          if (ra.reciterId != reciter.id) continue;
          for (final part in ra.parts) {
            if (downloadService.isDownloaded(
                DownloadService.surahReciterAudioId(
                    n, reciter.id, part))) {
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

  // ─── Orphan cleanup ────────────────────────────────

  Future<void> _cleanOrphanedFiles() async {
    try {
      final validIds = _buildValidFileIds();
      final downloadedFiles =
          await downloadService.downloadedFiles();

      int deleted = 0;
      for (final file in downloadedFiles) {
        final fileId = file['id'] as String;
        if (!validIds.contains(fileId)) {
          await downloadService.deleteFile(fileId);
          deleted++;
        }
      }

      if (deleted > 0) {
        notifyListeners();
      }

      _cleanOrphanedReadingProgress(validIds);
    } catch (e) {
      debugPrint('Orphan cleanup failed: $e');
    }
  }

  Set<String> _buildValidFileIds() {
    final valid = <String>{};

    for (final book in catalogService.books) {
      valid.add('pdf_${book.id}');
      for (final ta in book.teacherAudio) {
        for (final part in ta.parts) {
          valid.add(DownloadService.audioId(
              book.id, ta.teacherId, part));
        }
      }
    }

    for (final sub
        in catalogService.quranSubBranches) {
      for (final book in sub.books) {
        valid.add('pdf_${book.id}');
        for (final ta in book.teacherAudio) {
          for (final part in ta.parts) {
            valid.add(DownloadService.audioId(
                book.id, ta.teacherId, part));
          }
        }
      }
    }

    for (int n = 1; n <= 114; n++) {
      valid.add('pdf_surah_$n');
      final surah = catalogService.quran.surahFor(n);
      for (final ra in surah.reciters) {
        for (final part in ra.parts) {
          valid.add(
              DownloadService.surahReciterAudioId(
                  n, ra.reciterId, part));
        }
      }
      for (final ta in surah.teachers) {
        for (final part in ta.parts) {
          valid.add(
              DownloadService.surahTeacherAudioId(
                  n, ta.teacherId, part));
        }
      }
    }

    for (final sub
        in catalogService.quranSubBranches) {
      for (final edition in sub.editions) {
        final fileId = edition.id == 'mushaf'
            ? 'pdf_mushaf'
            : 'pdf_mushaf_${edition.id}';
        valid.add(fileId);
      }
    }
    valid.add('pdf_mushaf');

    return valid;
  }

  void _cleanOrphanedReadingProgress(
      Set<String> validFileIds) {
    if (_lastBookId == null ||
        _lastBookId!.isEmpty) return;
    final pdfId = 'pdf_$_lastBookId';
    final isSurah =
        _lastBookId!.startsWith('surah_');
    final isMushaf = _lastBookId == 'mushaf';
    if (isSurah || isMushaf) return;
    if (!validFileIds.contains(pdfId)) {
      _lastBookId = null;
      _lastBookTitle = null;
      _lastBookPage = 0;
      _lastBookTotalPages = 0;
      _prefs.remove(_keyLastBookId);
      _prefs.remove(_keyLastBookTitle);
      _prefs.setInt(_keyLastBookPage, 0);
      _prefs.setInt(_keyLastBookTotalPages, 0);
      notifyListeners();
    }
  }

  // ─── Cloud Sync ────────────────────────────────────

  Future<void> _syncFromCloud() async {
    if (_isGuest) return;
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

  Future<void> setLanguage(String lang) async {
    if (_language == lang ||
        !['ar', 'en', 'am'].contains(lang)) return;
    _language = lang;
    await _prefs.setString(_keyLanguage, lang);
    notifyListeners();
  }

  Future<void> markFirstLaunchComplete() async {
    _isFirstLaunch = false;
    await _prefs.setBool(_keyFirstLaunch, false);
    notifyListeners();
  }

  // ─── Auth ──────────────────────────────────────────

  Future<void> setSignedIn(bool value) async {
    _isSignedIn = value;
    if (value) {
      _isGuest = false;
      await _prefs.setBool(_keyIsGuest, false);
    }
    await _prefs.setBool(_keyUserSignedIn, value);
    if (value) _syncFromCloud();
    notifyListeners();
  }

  Future<void> setGuest() async {
    _isGuest = true;
    _isSignedIn = false;
    await _prefs.setBool(_keyIsGuest, true);
    await _prefs.setBool(_keyUserSignedIn, false);
    notifyListeners();
  }

  Future<void> clearGuest() async {
    _isGuest = false;
    await _prefs.setBool(_keyIsGuest, false);
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

    if (!_isGuest) {
      firestoreService.saveReadingProgress(
        bookId: bookId,
        bookTitle: bookTitle,
        page: page,
        totalPages: totalPages,
      );
    }

    notifyListeners();
  }

  Future<void> updateReadingPage(
      int page, int totalPages) async {
    _lastBookPage = page;
    _lastBookTotalPages = totalPages;
    await _prefs.setInt(_keyLastBookPage, page);
    await _prefs.setInt(
        _keyLastBookTotalPages, totalPages);

    if (_lastBookId != null && !_isGuest) {
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

  // ─── Announcements ─────────────────────────────────

  static String announcementFingerprint(
          String message, String type) =>
      '${type}::${message.hashCode}';

  bool isAnnouncementDismissed(String fingerprint) =>
      _dismissedAnnouncements.contains(fingerprint);

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

  // ─── Access ────────────────────────────────────────

  static AppState of(BuildContext context) =>
      AppStateProvider.of(context);
}

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
