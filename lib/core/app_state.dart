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
  static const _keyLastBookTotalPages =
      'last_book_total_pages';
  static const _keyDismissedAnnouncements =
      'dismissed_announcements';
  static const _keyLegacyMushafLastPage =
      'mushaf_last_page';
  static const _keyMushafLastPagePrefix =
      'mushaf_last_page_';

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

  final Set<String> _dismissedAnnouncements =
      <String>{};

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

    final savedTheme = _prefs.getString(_keyThemeMode);
    if (savedTheme != null) {
      _isDark = savedTheme == 'dark';
    } else {
      _isDark = WidgetsBinding.instance
              .platformDispatcher.platformBrightness ==
          Brightness.dark;
    }

    _language = _prefs.getString(_keyLanguage) ?? 'en';
    _isFirstLaunch =
        _prefs.getBool(_keyFirstLaunch) ?? true;
    _isSignedIn =
        _prefs.getBool(_keyUserSignedIn) ?? false;
    _lastBookId = _prefs.getString(_keyLastBookId);
    _lastBookTitle = _prefs.getString(_keyLastBookTitle);
    _lastBookPage =
        _prefs.getInt(_keyLastBookPage) ?? 0;
    _lastBookTotalPages =
        _prefs.getInt(_keyLastBookTotalPages) ?? 0;

    _migrateLegacyMushafLastPage();

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

    downloadService.onPdfFileDeleted =
        (bookId) => coverService.clearFor(bookId);

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
    // Task 7: remove any downloaded files that no
    // longer exist in the catalog.
    _cleanOrphanedFiles();
  }

  // ─── Cover extraction ──────────────────────────────

  Future<void> _extractCoversForDownloadedBooks() async {
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
        final surah = catalogService.quran.surahFor(n);
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

  // ─── Orphan cleanup (Task 7) ───────────────────────
  //
  // After catalog loads, build the complete set of
  // file IDs that the catalog currently recognizes as
  // valid. Any downloaded file ID not in this set is
  // an orphan — it was removed from the catalog (book
  // deleted, teacher removed, parts reduced, etc.).
  //
  // Orphans are silently deleted from the device.
  //
  // What is included in the valid set:
  //   - book PDFs
  //   - book audio parts (all teachers × all parts)
  //   - Surah PDFs
  //   - Surah reciter audio parts
  //   - Surah teacher audio parts
  //   - Mushaf edition PDFs
  //   - Sub-branch book PDFs and their audio parts
  //
  // What is NOT included (never deleted):
  //   - Teacher/reciter photos (identity cache)
  //   - Mushaf PDFs marked as "mushaf" or "mushaf-bw"
  //     (these are long-lived user content, not removed
  //     silently — user must delete manually)

  Future<void> _cleanOrphanedFiles() async {
    try {
      final validIds = _buildValidFileIds();
      final downloadedFiles =
          await downloadService.downloadedFiles();

      int deleted = 0;
      for (final file in downloadedFiles) {
        final fileId = file['id'] as String;
        if (!validIds.contains(fileId)) {
          debugPrint(
            'Orphan cleanup: deleting $fileId '
            '(not in current catalog)',
          );
          await downloadService.deleteFile(fileId);
          deleted++;
        }
      }

      if (deleted > 0) {
        debugPrint(
            'Orphan cleanup: deleted $deleted file(s).');
        notifyListeners();
      } else {
        debugPrint(
            'Orphan cleanup: nothing to delete.');
      }

      // Also clean up reading progress if the last
      // opened book no longer exists in the catalog.
      _cleanOrphanedReadingProgress(validIds);
    } catch (e) {
      debugPrint('Orphan cleanup failed: $e');
    }
  }

  /// Builds the complete set of valid file IDs from the
  /// current catalog. Any downloaded file not in this
  /// set is considered an orphan.
  Set<String> _buildValidFileIds() {
    final valid = <String>{};

    // ── Regular books ──────────────────────────────
    for (final book in catalogService.books) {
      // Book PDF
      valid.add('pdf_${book.id}');

      // Book audio — every teacher × every part
      for (final ta in book.teacherAudio) {
        for (final part in ta.parts) {
          valid.add(DownloadService.audioId(
              book.id, ta.teacherId, part));
        }
      }
    }

    // ── Sub-branch books ───────────────────────────
    for (final sub in catalogService.quranSubBranches) {
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

    // ── Surah PDFs and audio ───────────────────────
    for (int n = 1; n <= 114; n++) {
      // Surah PDF
      valid.add('pdf_surah_$n');

      final surah = catalogService.quran.surahFor(n);

      // Surah reciter audio
      for (final ra in surah.reciters) {
        for (final part in ra.parts) {
          valid.add(DownloadService.surahReciterAudioId(
              n, ra.reciterId, part));
        }
      }

      // Surah teacher audio
      for (final ta in surah.teachers) {
        for (final part in ta.parts) {
          valid.add(DownloadService.surahTeacherAudioId(
              n, ta.teacherId, part));
        }
      }
    }

    // ── Mushaf edition PDFs ────────────────────────
    // These are kept in the valid set always —
    // Mushaf editions are long-lived user content.
    // Even if an edition is removed from the catalog,
    // we do NOT silently delete a 200MB Mus'haf the
    // user downloaded. They can delete it manually.
    for (final sub in catalogService.quranSubBranches) {
      for (final edition in sub.editions) {
        final fileId = edition.id == 'mushaf'
            ? 'pdf_mushaf'
            : 'pdf_mushaf_${edition.id}';
        valid.add(fileId);
      }
    }
    // Also keep the default edition even if not listed
    valid.add('pdf_mushaf');

    return valid;
  }

  /// If the last opened book no longer exists in the
  /// catalog, clear the reading progress so the
  /// Continue Reading section does not show a ghost.
  void _cleanOrphanedReadingProgress(
      Set<String> validFileIds) {
    if (_lastBookId == null || _lastBookId!.isEmpty) {
      return;
    }

    // Check if it was a regular book PDF
    final pdfId = 'pdf_$_lastBookId';
    // Check if it was a Surah
    final isSurah = _lastBookId!.startsWith('surah_');
    // Check if it was Mus'haf
    final isMushaf = _lastBookId == 'mushaf';

    // Surahs and Mushaf are always valid
    if (isSurah || isMushaf) return;

    // If the book PDF is not in the valid set, clear
    if (!validFileIds.contains(pdfId)) {
      debugPrint(
        'Orphan cleanup: clearing reading progress '
        'for removed book $_lastBookId',
      );
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
    try {
      final cloudData =
          await firestoreService.syncOnLogin();
      if (cloudData == null) return;
      if (_lastBookId == null ||
          _lastBookId!.isEmpty) {
        final bookId =
            cloudData['lastBookId'] as String? ?? '';
        final bookTitle =
            cloudData['lastBookTitle'] as String? ?? '';
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

  Future<void> setSignedIn(bool value) async {
    _isSignedIn = value;
    await _prefs.setBool(_keyUserSignedIn, value);
    if (value) _syncFromCloud();
    notifyListeners();
  }

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
    if (_dismissedAnnouncements.contains(fingerprint)) {
      return;
    }
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
