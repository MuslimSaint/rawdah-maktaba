import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/quran_data.dart';
import '../core/theme.dart';
import '../widgets/book_cover.dart';
import '../widgets/branch_hero_card.dart';
import 'branch_screen.dart';
import 'book_detail_screen.dart';
import 'mushaf_reader_screen.dart';
import 'quran_screen.dart';
import 'surah_detail_screen.dart';

/// Home tab.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: state,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(
                  bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _TopBar(colors: c),

                  const SizedBox(
                      height: AppSpacing.base),

                  ListenableBuilder(
                    listenable: Listenable.merge([
                      state.catalogService,
                      state,
                    ]),
                    builder: (context, _) {
                      final a = state.catalogService
                          .activeAnnouncement;
                      if (a == null) {
                        return const SizedBox.shrink();
                      }

                      if (a.isUpdate) {
                        return _UpdateBanner(
                          announcement: a,
                          colors: c,
                        );
                      }

                      final fingerprint =
                          AppState.announcementFingerprint(
                              a.message, a.type);
                      if (state.isAnnouncementDismissed(
                          fingerprint)) {
                        return const SizedBox.shrink();
                      }
                      return _AnnouncementBanner(
                        announcement: a,
                        fingerprint: fingerprint,
                        colors: c,
                      );
                    },
                  ),

                  _DailyHadith(colors: c),

                  const SizedBox(
                      height: AppSpacing.xl),

                  _ContinueReading(colors: c),

                  const SizedBox(
                      height: AppSpacing.xl),

                  _BranchesSection(colors: c),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Update Banner ────────────────────────────────────────
//
// A special banner for type='update' announcements.
// Not dismissible. Shows download progress inside the
// banner. After download completes, shows Install button.
// The APK is downloaded silently outside the Downloads tab.
// On app restart, checks if APK already exists on disk
// and skips straight to Install Now if found.

enum _UpdateState { idle, downloading, done, error }

class _UpdateBanner extends StatefulWidget {
  final Announcement announcement;
  final AppColors colors;

  const _UpdateBanner({
    required this.announcement,
    required this.colors,
  });

  @override
  State<_UpdateBanner> createState() =>
      _UpdateBannerState();
}

class _UpdateBannerState
    extends State<_UpdateBanner> {
  // MethodChannel matching the one in MainActivity.kt
  static const _installChannel =
      MethodChannel('com.rawda.library/install');

  _UpdateState _state = _UpdateState.idle;
  double _progress = 0;
  String? _apkPath;
  String? _errorMsg;
  StreamSubscription<List<int>>? _sub;
  http.Client? _client;

  @override
  void initState() {
    super.initState();
    // Bug fix 3: on restart, check if APK already
    // downloaded and skip straight to Install Now.
    _checkExistingApk();
  }

  /// Checks if a previously downloaded APK still
  /// exists on disk. If it is large enough to be a
  /// real APK (> 1 MB), goes straight to done state.
  Future<void> _checkExistingApk() async {
    try {
      final appDir =
          await getApplicationDocumentsDirectory();
      final apkFile =
          File('${appDir.path}/rawdah_update.apk');
      if (await apkFile.exists()) {
        final size = await apkFile.length();
        if (size > 1024 * 1024) {
          // > 1 MB → treat as valid APK
          if (mounted) {
            setState(() {
              _apkPath = apkFile.path;
              _state = _UpdateState.done;
            });
          }
        }
      }
    } catch (_) {
      // If anything fails just stay in idle state
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _client?.close();
    super.dispose();
  }

  Future<void> _startDownload() async {
    if (_state == _UpdateState.downloading) return;
    if (!widget.announcement.hasDownloadUrl) return;

    setState(() {
      _state = _UpdateState.downloading;
      _progress = 0;
      _errorMsg = null;
    });

    try {
      final uri = Uri.parse(
          widget.announcement.downloadUrl.trim());
      if (uri.scheme != 'https') {
        setState(() {
          _state = _UpdateState.error;
          _errorMsg =
              'Invalid update URL. Must be https.';
        });
        return;
      }

      final appDir =
          await getApplicationDocumentsDirectory();
      final apkFile =
          File('${appDir.path}/rawdah_update.apk');
      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      _client = http.Client();
      final request = http.Request('GET', uri);
      request.followRedirects = true;
      request.maxRedirects = 5;

      final response = await _client!.send(request);

      if (response.statusCode != 200) {
        setState(() {
          _state = _UpdateState.error;
          _errorMsg =
              'Download failed: ${response.statusCode}';
        });
        return;
      }

      final total = response.contentLength ?? 0;
      int received = 0;
      final sink = apkFile.openWrite();

      final completer = Completer<void>();

      _sub = response.stream.listen(
        (chunk) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0 && mounted) {
            setState(() {
              _progress = received / total;
            });
          }
        },
        onDone: () async {
          await sink.flush();
          await sink.close();
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onError: (e) async {
          await sink.close();
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
        cancelOnError: true,
      );

      await completer.future;

      if (mounted) {
        setState(() {
          _state = _UpdateState.done;
          _apkPath = apkFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _UpdateState.error;
          _errorMsg =
              'Download failed. Check your internet.';
        });
      }
    } finally {
      _client?.close();
      _client = null;
    }
  }

  /// Bug fix 2: Use MethodChannel to invoke the native
  /// Android installer. The native side handles:
  ///   - Android 8+ install permission check
  ///   - FileProvider URI for Android 7+
  ///   - ACTION_VIEW intent with correct MIME type
  Future<void> _install() async {
    if (_apkPath == null) return;
    setState(() => _errorMsg = null);
    try {
      await _installChannel.invokeMethod(
        'installApk',
        {'path': _apkPath!},
      );
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.message ??
              'Could not open installer. Try again.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMsg =
              'Could not open installer. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final a = widget.announcement;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        0,
        AppSpacing.base,
        AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: c.card,
          border: Border(
            left: BorderSide(
                color: c.goldText, width: 3),
            top: BorderSide(
                color: c.goldText.withOpacity(0.2)),
            right: BorderSide(
                color: c.goldText.withOpacity(0.2)),
            bottom: BorderSide(
                color: c.goldText.withOpacity(0.2)),
          ),
          borderRadius: AppRadius.listItemRadius,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.system_update_rounded,
                  size: 18,
                  color: c.goldText,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    a.message,
                    style: AppText.latin(
                      color: c.textPrimary,
                      size: 13,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            if (_errorMsg != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorMsg!,
                style: AppText.latin(
                    color: c.danger, size: 11),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            if (_state == _UpdateState.idle &&
                a.hasDownloadUrl)
              GestureDetector(
                onTap: _startDownload,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [c.goldText, c.goldText],
                    ),
                    borderRadius:
                        AppRadius.buttonRadius,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_rounded,
                          size: 16,
                          color: c.isDark
                              ? Colors.black
                              : Colors.white),
                      const SizedBox(
                          width: AppSpacing.sm),
                      Text(
                        'Download Update',
                        style: AppText.latin(
                          color: c.isDark
                              ? Colors.black
                              : Colors.white,
                          size: 14,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_state == _UpdateState.downloading)
              ...[
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        AppRadius.pillRadius,
                    child: LinearProgressIndicator(
                      value: _progress > 0
                          ? _progress
                          : null,
                      backgroundColor: c.surface2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                              c.goldText),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(
                      height: AppSpacing.xs),
                  Text(
                    _progress > 0
                        ? '${(_progress * 100).toInt()}% — Downloading update...'
                        : 'Connecting...',
                    style: AppText.latin(
                      color: c.goldText,
                      size: 11,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            if (_state == _UpdateState.done) ...[
              GestureDetector(
                onTap: _install,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: c.brand,
                    borderRadius:
                        AppRadius.buttonRadius,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Icon(
                          Icons.install_mobile_rounded,
                          size: 16,
                          color: Colors.white),
                      const SizedBox(
                          width: AppSpacing.sm),
                      Text(
                        'Install Now',
                        style: AppText.latin(
                          color: Colors.white,
                          size: 14,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Tap Install Now — the system will guide you through installation.',
                style: AppText.latin(
                    color: c.textFaint, size: 11),
                textAlign: TextAlign.center,
              ),
            ],

            if (_state == _UpdateState.error &&
                a.hasDownloadUrl) ...[
              GestureDetector(
                onTap: _startDownload,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius:
                        AppRadius.buttonRadius,
                    border: Border.all(
                        color: c.divider),
                  ),
                  child: Center(
                    child: Text(
                      'Try Again',
                      style: AppText.latin(
                        color: c.textMuted,
                        size: 13,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Regular Announcement Banner ─────────────────────────

class _AnnouncementBanner extends StatelessWidget {
  final Announcement announcement;
  final String fingerprint;
  final AppColors colors;

  const _AnnouncementBanner({
    required this.announcement,
    required this.fingerprint,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final a = announcement;

    Color accentColor;
    IconData icon;

    switch (a.type) {
      case 'warning':
        accentColor = c.goldText;
        icon = Icons.warning_amber_rounded;
        break;
      case 'success':
        accentColor = c.brand;
        icon = Icons.check_circle_outline_rounded;
        break;
      default:
        accentColor = c.brand;
        icon = Icons.info_outline_rounded;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base,
          0,
          AppSpacing.base,
          AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: c.card,
          border: Border(
            left: BorderSide(
                color: accentColor, width: 3),
            top: BorderSide(
                color: accentColor.withOpacity(0.15)),
            right: BorderSide(
                color: accentColor.withOpacity(0.15)),
            bottom: BorderSide(
                color: accentColor.withOpacity(0.15)),
          ),
          borderRadius: AppRadius.listItemRadius,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: accentColor),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                a.message,
                style: AppText.latin(
                  color: c.textPrimary,
                  size: 13,
                  weight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                AppState.of(context)
                    .dismissAnnouncement(fingerprint);
              },
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: c.textFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top Bar ─────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final AppColors colors;
  const _TopBar({required this.colors});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base,
          AppSpacing.base,
          AppSpacing.base,
          0),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => state.toggleTheme(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: AppRadius.buttonRadius,
                border:
                    Border.all(color: c.divider),
              ),
              child: Icon(
                state.isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                size: 18,
                color: c.textMuted,
              ),
            ),
          ),
          Text(
            'مكتبة الروضة',
            textDirection: TextDirection.rtl,
            style: AppText.arabic(
              color: c.goldText,
              size: 22,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}

// ─── Daily Hadith ─────────────────────────────────────────

class _DailyHadith extends StatelessWidget {
  final AppColors colors;
  const _DailyHadith({required this.colors});

  static const List<Map<String, String>> _hadiths = [
    {
      'text':
          'مَنْ يُرِدِ اللَّهُ بِهِ خَيْرًا يُفَقِّهْهُ فِي الدِّينِ',
      'source': 'صحيح البخاري، صحيح مسلم',
    },
    {
      'text':
          'مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا، سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ.',
      'source': 'صحيح مسلم',
    },
    {
      'text':
          'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ.',
      'source': 'صحيح البخاري',
    },
    {
      'text':
          'إِنَّ الْمَلَائِكَةَ لَتَضَعُ أَجْنِحَتَهَا لِطَالِبِ الْعِلْمِ رِضًا بِمَا يَصْنَعُ.',
      'source': 'سنن الترمذي، سنن ابن ماجه',
    },
    {
      'text':
          'نَضَّرَ اللَّهُ امْرَأً سَمِعَ مِنَّا حَدِيثًا فَحَفِظَهُ حَتَّى يُبَلِّغَهُ كَمَا سَمِعَهُ.',
      'source': 'جامع الترمذي',
    },
    {
      'text':
          'إِنَّ اللَّهَ وَمَلَائِكَتَهُ وَأَهْلَ السَّمَاوَاتِ وَالْأَرْضِ، حَتَّى النَّمْلَةَ فِي جُحْرِهَا، وَحَتَّى الْحُوتَ، لَيُصَلُّونَ عَلَى مُعَلِّمِ النَّاسِ الْخَيْرَ.',
      'source': 'جامع الترمذي',
    },
    {
      'text':
          'الدُّنْيَا مَلْعُونَةٌ، مَلْعُونٌ مَا فِيهَا، إِلَّا ذِكْرَ اللَّهِ وَمَا وَالَاهُ، وَعَالِمًا أَوْ مُتَعَلِّمًا.',
      'source': 'جامع الترمذي',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final dayIndex = DateTime.now().weekday - 1;
    final hadith =
        _hadiths[dayIndex % _hadiths.length];

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Hadith of the Day',
                style: AppText.latin(
                  color: c.textPrimary,
                  size: 14,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm - 1,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: c.goldLine,
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Text(
                  'Daily',
                  style: AppText.latin(
                    color: c.goldText,
                    size: 9,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(
                AppSpacing.base),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: AppRadius.cardRadius,
              border: Border(
                left: BorderSide(
                    color: c.goldText, width: 3),
                top: BorderSide(color: c.divider),
                right: BorderSide(color: c.divider),
                bottom: BorderSide(color: c.divider),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  hadith['text']!,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.arabic(
                    color: c.textPrimary,
                    size: 14,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: c.goldLine,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Text(
                    hadith['source']!,
                    textDirection: TextDirection.rtl,
                    style: AppText.arabic(
                      color: c.goldText,
                      size: 11,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Continue Reading ─────────────────────────────────────

class _ContinueReading extends StatelessWidget {
  final AppColors colors;
  const _ContinueReading({required this.colors});

  static bool _isMushafId(String? bookId) =>
      bookId == 'mushaf';
  static bool _isSurahId(String? bookId) =>
      bookId != null && bookId.startsWith('surah_');
  static int? _surahNumberFromId(String? bookId) {
    if (bookId == null ||
        !bookId.startsWith('surah_')) return null;
    return int.tryParse(
        bookId.replaceFirst('surah_', ''));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = colors;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Continue Reading',
            style: AppText.latin(
              color: c.textPrimary,
              size: 14,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: state.hasLastBook
                ? () => _handleTap(context, state)
                : null,
            child: Container(
              padding: const EdgeInsets.all(
                  AppSpacing.md),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: AppRadius.cardRadius,
                border: Border.all(
                    color: c.goldLine, width: 1.5),
              ),
              child: state.hasLastBook
                  ? _LastBookContent(colors: c)
                  : _NoBookContent(colors: c),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(
      BuildContext context, AppState state) {
    final bookId = state.lastBookId;
    if (bookId == null) return;

    if (_isMushafId(bookId)) {
      final mushafSub = state
          .catalogService.quranSubBranches
          .where((sb) =>
              sb.type == QuranSubBranchType.mushaf)
          .firstOrNull;
      if (mushafSub != null &&
          mushafSub.editions.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MushafReaderScreen(
              edition: mushafSub.editions.first),
        ));
      }
      return;
    }

    if (_isSurahId(bookId)) {
      final num = _surahNumberFromId(bookId);
      if (num != null) {
        final meta = QuranSkeleton.byNumber(num);
        if (meta != null) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                SurahDetailScreen(meta: meta),
          ));
        }
      }
      return;
    }

    try {
      final book = state.catalogService.books
          .firstWhere((b) => b.id == bookId);
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => BookDetailScreen(
          book: book,
          catalogService: state.catalogService,
        ),
      ));
    } catch (_) {}
  }
}

class _LastBookContent extends StatelessWidget {
  final AppColors colors;
  const _LastBookContent({required this.colors});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = colors;

    final bookId = state.lastBookId;
    final isMushaf = bookId == 'mushaf';
    final isSurah = bookId != null &&
        bookId.startsWith('surah_');
    final isQuran = isMushaf || isSurah;

    Book? book;
    if (!isQuran) {
      try {
        book = state.catalogService.books
            .firstWhere((b) => b.id == bookId);
      } catch (_) {}
    }

    String displayName;
    if (isMushaf) {
      displayName = 'القرآن الكريم';
    } else if (isSurah) {
      final num = int.tryParse(
          bookId!.replaceFirst('surah_', ''));
      if (num != null) {
        final meta = QuranSkeleton.byNumber(num);
        displayName = meta != null
            ? 'سورة ${meta.nameAr}'
            : bookId;
      } else {
        displayName = bookId;
      }
    } else {
      displayName = state.lastBookTitle ?? '';
    }

    final progress = state.lastBookProgress;
    final currentPage = state.lastBookPage + 1;
    final totalPages = state.lastBookTotalPages;
    final accentColor =
        isQuran ? c.goldText : c.brand;

    return Row(
      children: [
        if (book != null)
          BookCoverWidget(
            book: book,
            width: 44,
            height: 58,
            borderRadius: AppRadius.input,
          )
        else
          Container(
            width: 44,
            height: 58,
            decoration: BoxDecoration(
              color: isQuran
                  ? c.goldLine
                  : c.brand.withOpacity(0.12),
              borderRadius: BorderRadius.circular(
                  AppRadius.input),
              border: Border.all(
                color: isQuran
                    ? c.goldText.withOpacity(0.35)
                    : c.brand.withOpacity(0.25),
              ),
            ),
            child: Icon(
              isQuran
                  ? Icons.import_contacts_rounded
                  : Icons.menu_book_rounded,
              size: 22,
              color: accentColor,
            ),
          ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.arabic(
                  color: c.textPrimary,
                  size: 13,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(Icons.auto_stories_rounded,
                      size: 11, color: accentColor),
                  const SizedBox(
                      width: AppSpacing.xs),
                  Text(
                    totalPages > 0
                        ? 'Page $currentPage of $totalPages'
                        : 'Page $currentPage',
                    style: AppText.latin(
                      color: accentColor,
                      size: 11,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _ReadingDotIndicator(
                progress: progress,
                accentColor: accentColor,
                bgColor: c.surface2,
              ),
            ],
          ),
        ),

        const SizedBox(width: AppSpacing.sm),
        Icon(Icons.chevron_right_rounded,
            size: 16, color: c.textFaint),
      ],
    );
  }
}

class _ReadingDotIndicator extends StatelessWidget {
  final double progress;
  final Color accentColor;
  final Color bgColor;

  const _ReadingDotIndicator({
    required this.progress,
    required this.accentColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    const totalDots = 10;
    final filledDots =
        (progress * totalDots).round().clamp(0, totalDots);

    return Row(
      children: List.generate(totalDots, (i) {
        final filled = i < filledDots;
        final isCurrent =
            i == filledDots - 1 && filledDots > 0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
                right: AppSpacing.xs),
            child: AnimatedContainer(
              duration:
                  const Duration(milliseconds: 300),
              height: isCurrent ? 6 : 4,
              decoration: BoxDecoration(
                color:
                    filled ? accentColor : bgColor,
                borderRadius: BorderRadius.circular(
                    AppRadius.pill),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _NoBookContent extends StatelessWidget {
  final AppColors colors;
  const _NoBookContent({required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Row(
      children: [
        Container(
          width: 44,
          height: 58,
          decoration: BoxDecoration(
            color: c.brand.withOpacity(0.08),
            borderRadius: BorderRadius.circular(
                AppRadius.input),
            border: Border.all(
                color: c.brand.withOpacity(0.2)),
          ),
          child: Icon(
            Icons.menu_book_rounded,
            size: 22,
            color: c.brand.withOpacity(0.5),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No book opened yet',
                  style: AppText.latin(
                      color: c.textMuted, size: 12)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                  'Tap a book in the Library to start',
                  style: AppText.latin(
                      color: c.textFaint, size: 10)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: List.generate(10, (i) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          right: AppSpacing.xs),
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius:
                              BorderRadius.circular(
                                  AppRadius.pill),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Branches Section ─────────────────────────────────────

class _BranchesSection extends StatelessWidget {
  final AppColors colors;
  const _BranchesSection({required this.colors});

  static const Map<String, IconData> _squareIcons =
      {
    'aqeedah': Icons.verified_rounded,
    'fiqh': Icons.balance_rounded,
    'arabic': Icons.translate_rounded,
    'seerah': Icons.auto_stories_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = colors;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Branches of Knowledge',
            style: AppText.latin(
              color: c.textPrimary,
              size: 15,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ListenableBuilder(
            listenable: state.catalogService,
            builder: (context, _) {
              final quranBranch = Catalog.branches
                  .firstWhere(
                      (b) => b.id == 'quran');
              final hadithBranch = Catalog.branches
                  .firstWhere(
                      (b) => b.id == 'hadith');
              final gridBranches = Catalog.branches
                  .where((b) =>
                      b.id != 'quran' &&
                      b.id != 'hadith')
                  .toList();

              return Column(
                children: [
                  BranchHeroCard(
                    branch: quranBranch,
                    style: BranchHeroStyle.quran,
                    colors: c,
                    language: state.language,
                    bookCount: null,
                    onTap: () =>
                        Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              const QuranScreen()),
                    ),
                  ),
                  const SizedBox(
                      height: AppSpacing.md),
                  BranchHeroCard(
                    branch: hadithBranch,
                    style: BranchHeroStyle.hadith,
                    colors: c,
                    language: state.language,
                    bookCount: state.catalogService
                        .bookCountForBranch('hadith'),
                    onTap: () =>
                        Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BranchScreen(
                          branch: hadithBranch,
                          catalogService:
                              state.catalogService,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                      height: AppSpacing.md),
                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.55,
                    ),
                    itemCount: gridBranches.length,
                    itemBuilder: (context, index) {
                      final branch =
                          gridBranches[index];
                      final iconData =
                          _squareIcons[branch.id] ??
                              Icons.category_rounded;
                      final count = state
                          .catalogService
                          .bookCountForBranch(
                              branch.id);

                      return _BranchSquareCard(
                        branch: branch,
                        icon: iconData,
                        count: count,
                        colors: c,
                        language: state.language,
                        onTap: () =>
                            Navigator.of(context)
                                .push(
                          MaterialPageRoute(
                            builder: (_) =>
                                BranchScreen(
                              branch: branch,
                              catalogService:
                                  state.catalogService,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BranchSquareCard extends StatelessWidget {
  final Branch branch;
  final IconData icon;
  final int count;
  final AppColors colors;
  final String language;
  final VoidCallback onTap;

  const _BranchSquareCard({
    required this.branch,
    required this.icon,
    required this.count,
    required this.colors,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final hasBooks = count > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: c.divider),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: hasBooks
                        ? c.brand.withOpacity(0.12)
                        : c.surface2,
                    borderRadius:
                        AppRadius.buttonRadius,
                    border: Border.all(
                      color: hasBooks
                          ? c.brand.withOpacity(0.25)
                          : c.divider,
                    ),
                  ),
                  child: Icon(icon,
                      size: 17,
                      color: hasBooks
                          ? c.brand
                          : c.textFaint),
                ),
                if (!hasBooks)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal:
                          AppSpacing.sm - 1,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius:
                          AppRadius.pillRadius,
                    ),
                    child: Text('Soon',
                        style: AppText.latin(
                            color: c.textFaint,
                            size: 9,
                            weight:
                                FontWeight.w700)),
                  ),
                if (hasBooks)
                  Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: c.textFaint),
              ],
            ),
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(branch.nameFor(language),
                    style: AppText.latin(
                        color: hasBooks
                            ? c.textPrimary
                            : c.textMuted,
                        size: 13,
                        weight: FontWeight.w700)),
                const SizedBox(
                    height: AppSpacing.xs),
                Text(
                    hasBooks
                        ? '$count books'
                        : 'Coming soon',
                    style: AppText.latin(
                        color: hasBooks
                            ? c.brand
                            : c.textFaint,
                        size: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
