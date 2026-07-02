import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';

/// Audio player screen — slides up from bottom.
/// Controls: prev lesson, back 10s, play/pause, forward 10s, next lesson.
/// Speed cycling: 0.75x → 1x → 1.25x → 1.5x
class AudioPlayerScreen extends StatefulWidget {
  final Book book;
  final Teacher teacher;
  final int lessonNumber;
  final int totalLessons;

  const AudioPlayerScreen({
    super.key,
    required this.book,
    required this.teacher,
    required this.lessonNumber,
    required this.totalLessons,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen>
    with TickerProviderStateMixin {
  bool _isPlaying = false;
  double _position = 0;
  final double _duration = 1800;
  double _speed = 1.0;
  late int _currentLesson;

  final List<double> _speeds = [0.75, 1.0, 1.25, 1.5];

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _currentLesson = widget.lessonNumber;

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _togglePlay() => setState(() => _isPlaying = !_isPlaying);

  void _seekBack() =>
      setState(() => _position = (_position - 10).clamp(0, _duration));

  void _seekForward() =>
      setState(() => _position = (_position + 10).clamp(0, _duration));

  void _previousLesson() {
    if (_currentLesson > 1) {
      setState(() {
        _currentLesson--;
        _position = 0;
        _isPlaying = false;
      });
    }
  }

  void _nextLesson() {
    if (_currentLesson < widget.totalLessons) {
      setState(() {
        _currentLesson++;
        _position = 0;
        _isPlaying = false;
      });
    }
  }

  void _cycleSpeed() {
    final nextIndex = (_speeds.indexOf(_speed) + 1) % _speeds.length;
    setState(() => _speed = _speeds[nextIndex]);
  }

  String _formatTime(double seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toInt().toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _lessonTitle(int num) {
    final arabicNumbers = [
      'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس',
      'السادس', 'السابع', 'الثامن', 'التاسع', 'العاشر',
      'الحادي عشر', 'الثاني عشر', 'الثالث عشر', 'الرابع عشر',
      'الخامس عشر', 'السادس عشر', 'السابع عشر', 'الثامن عشر',
      'التاسع عشر', 'العشرون',
    ];
    final arabicNum = num <= arabicNumbers.length
        ? arabicNumbers[num - 1]
        : '$num';
    return 'الجزء $arabicNum';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);
    final hasPrev = _currentLesson > 1;
    final hasNext = _currentLesson < widget.totalLessons;

    return SlideTransition(
      position: _slideAnimation,
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    // Close / pull down
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: c.divider),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 24,
                          color: c.textPrimary,
                        ),
                      ),
                    ),

                    // Title
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'NOW PLAYING',
                            style: AppText.label(color: c.textFaint),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _lessonTitle(_currentLesson),
                            textDirection: TextDirection.rtl,
                            style: AppText.arabic(
                              color: c.textPrimary,
                              size: 15,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Lesson counter
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: c.divider),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$_currentLesson/${widget.totalLessons}',
                        style: AppText.latin(
                          color: c.textMuted,
                          size: 10,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Book Cover ──
              Container(
                width: 180,
                height: 240,
                decoration: BoxDecoration(
                  color: c.brand.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.goldLine, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: c.brand.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    widget.book.localCoverAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 56,
                        color: c.brand,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Book + Teacher Info ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      widget.book.titleAr,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.arabic(
                        color: c.textPrimary,
                        size: 17,
                        weight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.teacher.nameAr,
                      textDirection: TextDirection.rtl,
                      style: AppText.arabic(
                        color: c.goldText,
                        size: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'تأليف: ${widget.book.authorShort}',
                      textDirection: TextDirection.rtl,
                      style: AppText.arabic(
                        color: c.textMuted,
                        size: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Seek Bar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: c.brand,
                        inactiveTrackColor: c.surface2,
                        thumbColor: c.brand,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        trackHeight: 4,
                        overlayShape: SliderComponentShape.noOverlay,
                      ),
                      child: Slider(
                        value: _position,
                        min: 0,
                        max: _duration,
                        onChanged: (v) => setState(() => _position = v),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(_position),
                            style: AppText.latin(
                              color: c.textFaint,
                              size: 11,
                            ),
                          ),
                          Text(
                            _formatTime(_duration),
                            style: AppText.latin(
                              color: c.textFaint,
                              size: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Main Controls Row ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Previous lesson
                    _ControlButton(
                      icon: Icons.skip_previous_rounded,
                      size: 26,
                      enabled: hasPrev,
                      colors: c,
                      onTap: _previousLesson,
                    ),

                    // Back 10s
                    _SeekButton(
                      seconds: 10,
                      isForward: false,
                      colors: c,
                      onTap: _seekBack,
                    ),

                    // Play / Pause
                    GestureDetector(
                      onTap: _togglePlay,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [c.brand, c.brandHover],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: c.brand.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Forward 10s
                    _SeekButton(
                      seconds: 10,
                      isForward: true,
                      colors: c,
                      onTap: _seekForward,
                    ),

                    // Next lesson
                    _ControlButton(
                      icon: Icons.skip_next_rounded,
                      size: 26,
                      enabled: hasNext,
                      colors: c,
                      onTap: _nextLesson,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Speed Button ──
              GestureDetector(
                onTap: _cycleSpeed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.divider),
                  ),
                  child: Text(
                    'Speed: ${_speed}x',
                    style: AppText.latin(
                      color: c.brand,
                      size: 13,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ── Mini Player Note ──
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: c.goldLine,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: c.goldText.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: c.goldText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can read while listening — mini player coming soon',
                          style: AppText.latin(
                            color: c.goldText,
                            size: 11,
                            weight: FontWeight.w600,
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
      ),
    );
  }
}

// ─── Seek Button ─────────────────────────────────────────

class _SeekButton extends StatelessWidget {
  final int seconds;
  final bool isForward;
  final AppColors colors;
  final VoidCallback onTap;

  const _SeekButton({
    required this.seconds,
    required this.isForward,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: c.surface2,
          shape: BoxShape.circle,
          border: Border.all(color: c.divider),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              isForward
                  ? Icons.forward_10_rounded
                  : Icons.replay_10_rounded,
              size: 28,
              color: c.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Control Button (prev/next lesson) ───────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool enabled;
  final AppColors colors;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.enabled,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled ? c.surface2 : c.surface2.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? c.divider : c.divider.withOpacity(0.5),
          ),
        ),
        child: Icon(
          icon,
          size: size,
          color: enabled ? c.textPrimary : c.textFaint,
        ),
      ),
    );
  }
}
