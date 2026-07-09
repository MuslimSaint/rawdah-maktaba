import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import 'home_tab.dart';
import 'library_tab.dart';
import 'downloads_tab.dart';
import 'settings_tab.dart';

/// Main app screen with bottom navigation bar.
/// Four tabs: Home, Library, Downloads, Settings.
/// Mini audio player lives at the app root — it shows above
/// this screen whenever audio is active. This screen just
/// adds bottom padding so the mini player doesn't overlap
/// the bottom nav bar.
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
    final hasActiveAudio = state.audioService.hasActiveAudio;

    // When audio is active, push the bottom nav UP by
    // the height of the mini player so it doesn't get
    // hidden underneath. Approx height: 60px.
    const miniPlayerHeight = 60.0;
    final bottomPadding =
        hasActiveAudio ? miniPlayerHeight : 0.0;

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
        child: ListenableBuilder(
          listenable: state.audioService,
          builder: (context, _) {
            final hasAudio =
                state.audioService.hasActiveAudio;
            final pushUp =
                hasAudio ? miniPlayerHeight : 0.0;

            return Scaffold(
              backgroundColor: c.bg,
              body: Stack(
                children: List.generate(_tabs.length,
                    (index) {
                  return Offstage(
                    offstage: _currentIndex != index,
                    child: _tabs[index],
                  );
                }),
              ),
              bottomNavigationBar: Padding(
                padding: EdgeInsets.only(bottom: pushUp),
                child: _BottomNavBar(
                  currentIndex: _currentIndex,
                  onTap: _onTabTapped,
                  colors: c,
                ),
              ),
            );
          },
        ),
      ),
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
