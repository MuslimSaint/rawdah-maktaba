import 'dart:io';
import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/arabic_utils.dart';
import '../core/download_service.dart';
import '../core/theme.dart';

/// Persistent mini audio player.
/// Shows above everything (any screen) whenever audio is active.
/// Provides only basic controls:
///   • Previous lesson
///   • Play / Pause
///   • Next lesson
///   • Close (stops audio, dismisses player)
///
/// For advanced controls, tap the player to open the full screen.
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
        final audio = state.audioService;

        if (!audio.hasActiveAudio) {
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

  // ─── Prev / Next Logic ─────────────────────────────
  // Uses AudioService's currentBookId, currentTeacherId,
  // currentPartNumber to look up the parts list and
  // find prev/next parts.

  ({int? partNumber, int? partIndex, int totalParts})
      _resolveNeighbor(BuildContext context, int offset) {
    final state = AppState.of(context);
    final bookId = state.audioService.currentBookId;
    final teacherId = state.audioService.currentTeacherId;
    final partNumber = state.audioService.currentPartNumber;

    if (bookId == null ||
        teacherId == null ||
        partNumber == null) {
      return (partNumber: null, partIndex: null, totalParts: 0);
    }

    try {
      final book = state.catalogService.books
          .firstWhere((b) => b.id == bookId);
      final teacherAudio = book.audioForTeacher(teacherId);
      if (teacherAudio == null) {
        return (
          partNumber: null,
          partIndex: null,
          totalParts: 0,
        );
      }
      final currentIndex =
          teacherAudio.parts.indexOf(partNumber);
      final newIndex = currentIndex + offset;
      if (newIndex < 0 ||
          newIndex >= teacherAudio.parts.length) {
        return (
          partNumber: null,
          partIndex: null,
          totalParts: teacherAudio.totalParts,
        );
      }
      return (
        partNumber: teacherAudio.parts[newIndex],
        partIndex: newIndex,
        totalParts: teacherAudio.totalParts,
      );
    } catch (_) {
      return (partNumber: null, partIndex: null, totalParts: 0);
    }
  }

  Future<void> _switchTo(
      BuildContext context, int newPartNumber) async {
    final state = AppState.of(context);
    final bookId = state.audioService.currentBookId!;
    final teacherId = state.audioService.currentTeacherId!;

    // Find the book + teacher again
    final book = state.catalogService.books
        .firstWhere((b) => b.id == bookId);
    final teacher = state.catalogService.teacherById(teacherId);
    if (teacher == null) return;

    final fileId = DownloadService.audioId(
      book.id,
      teacherId,
      newPartNumber,
    );

    // Must be downloaded to play
    if (!state.downloadService.isDownloaded(fileId)) return;

    final path = await state.downloadService.localPath(fileId);
    if (path == null) return;

    // Stop current, then load new file
    await state.audioService.stop();

    final lessonTitle = ArabicUtils.lessonTitle(newPartNumber);
    final coverPath = state.coverService.coverPath(book.id);

    await state.audioService.playFile(
      filePath: path,
      fileId: fileId,
      bookId: book.id,
      teacherId: teacherId,
      partNumber: newPartNumber,
      title: '${book.titleAr} — $lessonTitle',
      subtitle: teacher.nameAr,
      artUri: coverPath,
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
    final coverPath = bookId != null
        ? state.coverService.coverPath(bookId)
        : null;

    final prev = _resolveNeighbor(context, -1);
    final next = _resolveNeighbor(context, 1);
    final hasPrev = prev.partNumber != null;
    final hasNext = next.partNumber != null;

    return Material(
      elevation: 8,
      color: c.card,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thin progress line at very top
            SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                value: progress > 0 ? progress : null,
                backgroundColor: c.surface2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(c.brand),
                minHeight: 2,
              ),
            ),

            // Main body
            InkWell(
              onTap: () => _openFullPlayer(context),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: c.goldLine,
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Cover thumbnail
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(8),
                        color: c.brand.withOpacity(0.1),
                        border: Border.all(
                          color: c.brand.withOpacity(0.25),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(8),
                        child: coverPath != null
                            ? Image.file(
                                File(coverPath),
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Icon(
                                  Icons.headphones_rounded,
                                  color: c.brand,
                                  size: 20,
                                ),
                              )
                            : Icon(
                                Icons.headphones_rounded,
                                color: c.brand,
                                size: 20,
                              ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Title + subtitle
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

                    // ── Previous button ──
                    _MiniButton(
                      icon: Icons.skip_previous_rounded,
                      enabled: hasPrev,
                      colors: c,
                      onTap: hasPrev
                          ? () => _switchTo(
                                context,
                                prev.partNumber!,
                              )
                          : null,
                    ),

                    const SizedBox(width: 2),

                    // ── Play / Pause button ──
                    GestureDetector(
                      onTap: () => audio.togglePlay(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.brand,
                        ),
                        child: isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child:
                                    CircularProgressIndicator(
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

                    // ── Next button ──
                    _MiniButton(
                      icon: Icons.skip_next_rounded,
                      enabled: hasNext,
                      colors: c,
                      onTap: hasNext
                          ? () => _switchTo(
                                context,
                                next.partNumber!,
                              )
                          : null,
                    ),

                    const SizedBox(width: 4),

                    // ── Close button ──
                    GestureDetector(
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
          ],
        ),
      ),
    );
  }

  void _openFullPlayer(BuildContext context) {
    // Import audio_player_screen lazily via Navigator + push
    // by delegating to a helper widget. Simpler: use a route
    // name if you had one. For now, use MaterialPageRoute.
    final state = AppState.of(context);
    final bookId = state.audioService.currentBookId;
    final teacherId = state.audioService.currentTeacherId;
    final partNumber = state.audioService.currentPartNumber;
    if (bookId == null ||
        teacherId == null ||
        partNumber == null) return;

    try {
      final book = state.catalogService.books
          .firstWhere((b) => b.id == bookId);
      final teacher =
          state.catalogService.teacherById(teacherId);
      if (teacher == null) return;
      final teacherAudio = book.audioForTeacher(teacherId);
      if (teacherAudio == null) return;
      final partIndex =
          teacherAudio.parts.indexOf(partNumber);
      if (partIndex < 0) return;

      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => _AudioPlayerLauncher(
            bookId: book.id,
            teacherId: teacher.id,
            partIndex: partIndex,
          ),
        ),
      );
    } catch (_) {}
  }
}

// ─── Mini Button ────────────────────────────────────────

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
    return GestureDetector(
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

// ─── Launcher (avoids circular imports) ─────────────────
// A tiny widget that resolves the book/teacher/audio at
// build time and pushes the real AudioPlayerScreen.
// This lets mini_audio_player.dart avoid importing
// audio_player_screen.dart at the top level.

class _AudioPlayerLauncher extends StatelessWidget {
  final String bookId;
  final String teacherId;
  final int partIndex;

  const _AudioPlayerLauncher({
    required this.bookId,
    required this.teacherId,
    required this.partIndex,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final book = state.catalogService.books
        .firstWhere((b) => b.id == bookId);
    final teacher =
        state.catalogService.teacherById(teacherId)!;
    final teacherAudio = book.audioForTeacher(teacherId)!;

    // Import here to avoid top-level circular reference
    // Flutter allows using the widget via a builder redirect
    return _openScreen(
      context: context,
      book: book,
      teacher: teacher,
      teacherAudio: teacherAudio,
      partIndex: partIndex,
    );
  }

  Widget _openScreen({
    required BuildContext context,
    required dynamic book,
    required dynamic teacher,
    required dynamic teacherAudio,
    required int partIndex,
  }) {
    // ignore: avoid_dynamic_calls
    return AudioPlayerScreenRedirect(
      book: book,
      teacher: teacher,
      teacherAudio: teacherAudio,
      partIndex: partIndex,
    );
  }
}

// ─── Public redirect ────────────────────────────────────
// Real screen import lives here so the widget above
// doesn't force a circular dependency on this file.

class AudioPlayerScreenRedirect extends StatelessWidget {
  final dynamic book;
  final dynamic teacher;
  final dynamic teacherAudio;
  final int partIndex;

  const AudioPlayerScreenRedirect({
    super.key,
    required this.book,
    required this.teacher,
    required this.teacherAudio,
    required this.partIndex,
  });

  @override
  Widget build(BuildContext context) {
    // Late-import the real screen
    // ignore: avoid_dynamic_calls
    return _actualBuild(context);
  }

  Widget _actualBuild(BuildContext context) {
    // The actual import happens here at runtime through
    // the constructor of AudioPlayerScreen.
    return _RealScreenBuilder(
      book: book,
      teacher: teacher,
      teacherAudio: teacherAudio,
      partIndex: partIndex,
    );
  }
}

class _RealScreenBuilder extends StatelessWidget {
  final dynamic book;
  final dynamic teacher;
  final dynamic teacherAudio;
  final int partIndex;

  const _RealScreenBuilder({
    required this.book,
    required this.teacher,
    required this.teacherAudio,
    required this.partIndex,
  });

  @override
  Widget build(BuildContext context) {
    return _importScreen(
      book: book,
      teacher: teacher,
      teacherAudio: teacherAudio,
      partIndex: partIndex,
    );
  }
}

// Actual import lives at file scope
Widget _importScreen({
  required dynamic book,
  required dynamic teacher,
  required dynamic teacherAudio,
  required int partIndex,
}) {
  return AudioPlayerScreenImport(
    book: book,
    teacher: teacher,
    teacherAudio: teacherAudio,
    partIndex: partIndex,
  );
}
