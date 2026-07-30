import 'dart:io';
import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/audio_service.dart';
import '../core/models.dart';
import '../core/quran_data.dart';
import '../core/theme.dart';
import '../screens/audio_player_screen.dart';
import '../screens/surah_audio_player_screen.dart';

/// Persistent mini audio player.
class MiniAudioPlayer extends StatelessWidget {
  const MiniAudioPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);

    return ListenableBuilder(
      listenable: Listenable.merge([
        state.audioService,
        state.coverService,
      ]),
      builder: (context, _) {
        if (!state.audioService.hasActiveAudio) {
          return const SizedBox.shrink();
        }
        return _MiniPlayerBody(colors: c);
      },
    );
  }
}

class _MiniPlayerBody extends StatelessWidget {
  final AppColors colors;
  const _MiniPlayerBody({required this.colors});

  bool _isMushafAudio(String? bookId) => bookId == 'mushaf';
  bool _isSurahAudio(String? bookId) =>
      bookId != null && bookId.startsWith('surah_');

  void _openFullPlayer(BuildContext context) {
    final state = AppState.of(context);
    final bookId = state.audioService.currentBookId;
    final narratorId = state.audioService.currentTeacherId;
    final partNumber = state.audioService.currentPartNumber;
    if (bookId == null || narratorId == null || partNumber == null) {
      return;
    }

    if (_isSurahAudio(bookId)) {
      _openSurahPlayer(context, bookId, narratorId, partNumber);
      return;
    }
    _openBookPlayer(context, bookId, narratorId, partNumber);
  }

  void _openSurahPlayer(
    BuildContext context,
    String bookId,
    String narratorId,
    int partNumber,
  ) {
    final state = AppState.of(context);

    final surahNumStr = bookId.replaceFirst('surah_', '');
    final surahNum = int.tryParse(surahNumStr);
    if (surahNum == null) return;

    final meta = QuranSkeleton.byNumber(surahNum);
    if (meta == null) return;

    final surah = state.catalogService.quran.surahFor(surahNum);

    try {
      final reciterAudio =
          surah.reciters.firstWhere((r) => r.reciterId == narratorId);
      final reciter = state.catalogService.reciterById(narratorId);
      if (reciter != null) {
        final partIndex = reciterAudio.parts.indexOf(partNumber);
        if (partIndex < 0) return;
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => SurahAudioPlayerScreen.reciter(
              meta: meta,
              reciter: reciter,
              reciterAudio: reciterAudio,
              initialPartIndex: partIndex,
            ),
          ),
        );
        return;
      }
    } catch (_) {}

    try {
      final teacherAudio =
          surah.teachers.firstWhere((t) => t.teacherId == narratorId);
      final teacher = state.catalogService.teacherById(narratorId);
      if (teacher != null) {
        final partIndex = teacherAudio.parts.indexOf(partNumber);
        if (partIndex < 0) return;
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => SurahAudioPlayerScreen.teacher(
              meta: meta,
              teacher: teacher,
              teacherAudio: teacherAudio,
              initialPartIndex: partIndex,
            ),
          ),
        );
      }
    } catch (_) {}
  }

  void _openBookPlayer(
    BuildContext context,
    String bookId,
    String teacherId,
    int partNumber,
  ) {
    final state = AppState.of(context);

    Book? book;
    try {
      book =
          state.catalogService.books.firstWhere((b) => b.id == bookId);
    } catch (_) {
      for (final sub in state.catalogService.quranSubBranches) {
        try {
          book = sub.books.firstWhere((b) => b.id == bookId);
          break;
        } catch (_) {}
      }
    }
    if (book == null) return;

    final teacher = state.catalogService.teacherById(teacherId);
    if (teacher == null) return;
    final teacherAudio = book.audioForTeacher(teacherId);
    if (teacherAudio == null) return;
    final partIndex = teacherAudio.parts.indexOf(partNumber);
    if (partIndex < 0) return;

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => AudioPlayerScreen(
          book: book!,
          teacher: teacher,
          teacherAudio: teacherAudio,
          initialPartIndex: partIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final state = AppState.of(context);
    final audio = state.audioService;

    final isPlaying = audio.isPlaying;
    final isLoading = audio.isLoading;
    final position = audio.position;
    final duration = audio.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    final bookId = audio.currentBookId;
    final isMushaf = _isMushafAudio(bookId);
    final isSurah = _isSurahAudio(bookId);
    final isQuran = isMushaf || isSurah;

    String? surahCoverPath;
    if (isSurah && bookId != null) {
      surahCoverPath = state.coverService.coverPath(bookId);
    }
    final bookCoverPath = (!isQuran && bookId != null)
        ? state.coverService.coverPath(bookId)
        : null;

    final hasPrev = audio.hasPreviousPart;
    final hasNext = audio.hasNextPart;

    // ── THE FIX ──────────────────────────────────────────
    // The previous Stack + Positioned.fill approach failed
    // because the Padding widget above the GestureDetector
    // consumed all taps before they could reach the bottom
    // layer.
    //
    // Solution: InkWell wraps the entire content area at
    // the Material level. Flutter's gesture arena always
    // gives descendant GestureDetectors priority over an
    // ancestor InkWell, so every button still handles its
    // own tap independently. Any tap on the cover, title,
    // or empty space falls through to the InkWell and
    // opens the full player.
    // ─────────────────────────────────────────────────────
    return Material(
      elevation: 8,
      color: c.card,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar — sits outside the InkWell so it
          // is never accidentally tapped.
          SizedBox(
            height: 2,
            child: LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              backgroundColor: c.surface2,
              valueColor: AlwaysStoppedAnimation<Color>(c.brand),
              minHeight: 2,
            ),
          ),

          // Gold top border container.
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: c.goldLine, width: 1),
              ),
            ),
            // InkWell provides tap-anywhere-to-open.
            child: InkWell(
              onTap: () => _openFullPlayer(context),
              splashColor: c.brand.withOpacity(0.08),
              highlightColor: c.brand.withOpacity(0.04),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // ── Cover thumbnail ───────────────────
                    // No GestureDetector here — taps fall
                    // through to the InkWell above.
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: isQuran
                              ? c.goldText.withOpacity(0.1)
                              : c.brand.withOpacity(0.1),
                          border: Border.all(
                            color: isQuran
                                ? c.goldText.withOpacity(0.25)
                                : c.brand.withOpacity(0.25),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildCover(
                            c: c,
                            isMushaf: isMushaf,
                            isSurah: isSurah,
                            surahCoverPath: surahCoverPath,
                            bookCoverPath: bookCoverPath,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // ── Title + subtitle ──────────────────
                    // No GestureDetector — falls through.
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            audio.currentTitle ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.rtl,
                            style: AppText.arabic(
                              color: c.textPrimary,
                              size: 12,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            audio.currentSubtitle ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.rtl,
                            style: AppText.arabic(
                              color: c.goldText,
                              size: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),

                    // ── Prev button ───────────────────────
                    // GestureDetector wins over InkWell.
                    _MiniButton(
                      icon: Icons.skip_previous_rounded,
                      enabled: hasPrev,
                      colors: c,
                      onTap: hasPrev
                          ? () => audio.skipToPrevious()
                          : null,
                    ),

                    const SizedBox(width: 2),

                    // ── Play/Pause button ─────────────────
                    // GestureDetector wins over InkWell.
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => audio.togglePlay(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isQuran ? c.goldText : c.brand,
                        ),
                        child: isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                      ),
                    ),

                    const SizedBox(width: 2),

                    // ── Next button ───────────────────────
                    // GestureDetector wins over InkWell.
                    _MiniButton(
                      icon: Icons.skip_next_rounded,
                      enabled: hasNext,
                      colors: c,
                      onTap: hasNext
                          ? () => audio.skipToNext()
                          : null,
                    ),

                    const SizedBox(width: 4),

                    // ── Close button ──────────────────────
                    // GestureDetector wins over InkWell.
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => audio.stop(),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.surface2,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: c.textMuted,
                          size: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover({
    required AppColors c,
    required bool isMushaf,
    required bool isSurah,
    required String? surahCoverPath,
    required String? bookCoverPath,
  }) {
    if (isMushaf) {
      return Image.asset(
        'assets/mushaf.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.import_contacts_rounded,
          color: c.goldText,
          size: 20,
        ),
      );
    }

    if (isSurah) {
      if (surahCoverPath != null) {
        return Image.file(
          File(surahCoverPath),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.menu_book_rounded,
            color: c.goldText,
            size: 20,
          ),
        );
      }
      return Icon(
        Icons.menu_book_rounded,
        color: c.goldText,
        size: 20,
      );
    }

    if (bookCoverPath != null) {
      return Image.file(
        File(bookCoverPath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.headphones_rounded,
          color: c.brand,
          size: 20,
        ),
      );
    }
    return Icon(
      Icons.headphones_rounded,
      color: c.brand,
      size: 20,
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final AppColors colors;
  final VoidCallback? onTap;

  const _MiniButton({
    required this.icon,
    required this.enabled,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    // GestureDetector with opaque behavior intercepts its
    // own tap before the ancestor InkWell sees it.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(
          icon,
          color: enabled ? c.textPrimary : c.textFaint,
          size: 22,
        ),
      ),
    );
  }
}
