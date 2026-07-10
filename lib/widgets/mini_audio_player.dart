import 'dart:io';
import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/arabic_utils.dart';
import '../core/audio_service.dart';
import '../core/download_service.dart';
import '../core/theme.dart';
import '../screens/audio_player_screen.dart';

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

  void _openFullPlayer(BuildContext context) {
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
          builder: (_) => AudioPlayerScreen(
            book: book,
            teacher: teacher,
            teacherAudio: teacherAudio,
            initialPartIndex: partIndex,
          ),
        ),
      );
    } catch (_) {}
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

    final hasPrev = audio.hasPreviousPart;
    final hasNext = audio.hasNextPart;

    return Material(
      elevation: 8,
      color: c.card,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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

                  _MiniButton(
                    icon: Icons.skip_previous_rounded,
                    enabled: hasPrev,
                    colors: c,
                    onTap: hasPrev
                        ? () => audio.skipToPrevious()
                        : null,
                  ),

                  const SizedBox(width: 2),

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
                                  : Icons
                                      .play_arrow_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                    ),
                  ),

                  const SizedBox(width: 2),

                  _MiniButton(
                    icon: Icons.skip_next_rounded,
                    enabled: hasNext,
                    colors: c,
                    onTap: hasNext
                        ? () => audio.skipToNext()
                        : null,
                  ),

                  const SizedBox(width: 4),

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
