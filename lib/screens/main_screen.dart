import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/audio_service.dart';
import '../core/cover_service.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'home_tab.dart';
import 'library_tab.dart';
import 'downloads_tab.dart';
import 'settings_tab.dart';
import 'audio_player_screen.dart';
import 'lessons_screen.dart';

/// Main app screen with bottom navigation bar.
/// Four tabs: Home, Library, Downloads, Settings.
/// Includes a mini audio player above the bottom nav
/// whenever audio is active — persistent across tabs.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeTab(),
    LibraryTab(),
    DownloadsTab(),
    SettingsTab(),
  ];

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Directionality(
        textDirection: state.textDirection,
        child: Scaffold(
          backgroundColor: c.bg,

          body: Stack(
            children: List.generate(_tabs.length, (index) {
              return Offstage(
                offstage: _currentIndex != index,
                child: _tabs[index],
              );
            }),
          ),

          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mini player above the nav bar
              _MiniPlayer(
                audioService: state.audioService,
                coverService: state.coverService,
                catalogService: state.catalogService,
                colors: c,
              ),

              // Bottom Navigation Bar
              _BottomNavBar(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
                colors: c,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mini Player ────────────────────────────────────────

class _MiniPlayer extends StatelessWidget {
  final AudioService audioService;
  final CoverService coverService;
  final dynamic catalogService; // CatalogService but avoid import cycle
  final AppColors colors;

  const _MiniPlayer({
    required this.audioService,
    required this.coverService,
    required this.catalogService,
    required this.colors,
  });

  void _openFullPlayer(BuildContext context) {
    final bookId = audioService.currentBookId;
    if (bookId == null) return;

    // Find the book
    Book? book;
    try {
      book = catalogService.books
          .firstWhere((b) => b.id == bookId);
    } catch (_) {
      return;
    }

    // Parse the audio fileId to figure out teacher + part
    // Format: audio_[bookId]_[teacherId]_[part]
    final fileId = audioService.currentFileId;
    if (fileId == null) return;
    final withoutPrefix = fileId.replaceFirst('audio_', '');
    final parts = withoutPrefix.split('_');
    if (parts.length < 3) return;

    // bookId may itself contain underscores — but in our data
    // it doesn't. Assume last two are teacherId and partNumber.
    final partNumber = int.tryParse(parts.last);
    if (partNumber == null) return;
    final teacherId = parts[parts.length - 2];

    final teacher = catalogService.teacherById(teacherId);
    if (teacher == null) return;

    final teacherAudio = book!.audioForTeacher(teacherId);
    if (teacherAudio == null) return;

    final partIndex = teacherAudio.parts.indexOf(partNumber);
    if (partIndex < 0) return;

    // Open the full audio player screen
    Navigator.of(context).push(
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

    return ListenableBuilder(
      listenable: Listenable.merge([
        audioService,
        coverService,
      ]),
      builder: (context, _) {
        if (!audioService.hasActiveAudio) {
          return const SizedBox.shrink();
        }

        final isPlaying = audioService.isPlaying;
        final isLoading = audioService.isLoading;
        final position = audioService.position;
        final duration = audioService.duration;
        final progress = duration.inMilliseconds > 0
            ? position.inMilliseconds /
                duration.inMilliseconds
            : 0.0;

        final bookId = audioService.currentBookId;
        final coverPath = bookId != null
            ? coverService.coverPath(bookId)
            : null;

        return Material(
          color: c.card,
          child: InkWell(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thin progress line at top
                  SizedBox(
                    height: 2,
                    child: LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      backgroundColor: c.surface2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                              c.brand),
                      minHeight: 2,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        // Cover thumbnail
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(8),
                            color: c.brand.withOpacity(0.1),
                            border: Border.all(
                              color:
                                  c.brand.withOpacity(0.25),
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
                                      Icons
                                          .headphones_rounded,
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

                        const SizedBox(width: 12),

                        // Title + subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                audioService.currentTitle ??
                                    '',
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                textDirection:
                                    TextDirection.rtl,
                                style: AppText.arabic(
                                  color: c.textPrimary,
                                  size: 12,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                audioService
                                        .currentSubtitle ??
                                    '',
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                textDirection:
                                    TextDirection.rtl,
                                style: AppText.arabic(
                                  color: c.goldText,
                                  size: 10,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Play / Pause button
                        GestureDetector(
                          onTap: () =>
                              audioService.togglePlay(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.brand,
                            ),
                            child: isLoading
                                ? const Padding(
                                    padding:
                                        EdgeInsets.all(10),
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

                        const SizedBox(width: 6),

                        // Close (stop) button
                        GestureDetector(
                          onTap: () => audioService.stop(),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.surface2,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: c.textMuted,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Bottom Navigation Bar ──────────────────────────────

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final AppColors colors;

  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    final tabs = [
      _NavTab(icon: Icons.home_rounded, label: 'Home'),
      _NavTab(icon: Icons.menu_book_rounded, label: 'Library'),
      _NavTab(icon: Icons.download_rounded, label: 'Downloads'),
      _NavTab(icon: Icons.settings_rounded, label: 'Settings'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(
          top: BorderSide(color: c.goldLine, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final active = currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 200),
                          height: 3,
                          width: active ? 24 : 0,
                          margin:
                              const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: c.brand,
                            borderRadius:
                                BorderRadius.circular(2),
                          ),
                        ),
                        Icon(
                          tab.icon,
                          size: 22,
                          color: active
                              ? c.brand
                              : c.textFaint,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: active
                                ? c.brand
                                : c.textFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final String label;
  const _NavTab({required this.icon, required this.label});
}
