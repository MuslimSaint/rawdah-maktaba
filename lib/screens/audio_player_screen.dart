import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';

/// Audio player screen — slides up from bottom.
/// Controls: back 10s, play/pause, forward 10s, speed.
class AudioPlayerScreen extends StatefulWidget {
  final Book book;
  final Teacher teacher;
  final int lessonNumber;

  const AudioPlayerScreen({
    super.key,
    required this.book,
    required this.teacher,
    required this.lessonNumber,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen>
    with TickerProviderStateMixin {
  // Playback state — will connect to just_audio in Chapter 8
  bool _isPlaying = false;
  double _position = 0; // seconds
  final double _duration = 1800; // 30 min placeholder
  double _speed = 1.0;

  // Speed options: 0.75 → 1.0 → 1.25 → 1.5 (no 2x)
  final List<double> _speeds = [0.75, 1.0, 1.25, 1.5];

  // Slide-up animation
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
  }

  void _seekBack() {
    setState(() {
      _position = (_position - 10).clamp(0, _duration);
    });
  }

  void _seekForward() {
    setState(() {
      _position = (_position + 10).clamp(0, _duration);
    });
  }

  void _cycleSpeed() {
    final currentIndex = _speeds.indexOf(_speed);
    final nextIndex = (currentIndex + 1) % _speeds.length;
    setState(() => _speed = _speeds[nextIndex]);
  }

  String _formatTime(double seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toInt().toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _lessonTitle {
    final arabicNumbers = [
      'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس',
      'السادس', 'السابع', 'الثامن', 'التاسع', 'العاشر',
      'الحادي عشر', 'الثاني عشر', 'الثالث عشر', 'الرابع عشر',
      'الخامس عشر', 'السادس عشر', 'السابع عشر', 'الثامن عشر',
      'التاسع عشر', 'العشرون',
    ];
    final arabicNum = widget.lessonNumber <= arabicNumbers.length
        ? arabicNumbers[widget.lessonNumber - 1]
        : '${widget.lessonNumber}';
    return 'الجزء $arabicNum';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);

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
                    // Close button
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
                          size: 22,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'NOW PLAYING',
                            style: AppText.label(color: c.textFaint),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _lessonTitle,
                            textDirection: TextDirection.rtl,
                            style: AppText.arabic(
                              color: c.textPrimary,
                              size: 14,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 38),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Book Cover ──
              Container(
                width: 200,
                height: 260,
                decoration: BoxDecoration(
                  color: c.brand.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: c.goldLine,
                    width: 1.5,
                  ),
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
                        size: 64,
                        color: c.brand,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Book + Teacher Info ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      _lessonTitle,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: AppText.arabic(
                        color: c.textPrimary,
                        size: 20,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.teacher.nameAr,
                      textDirection: TextDirection.rtl,
                      style: AppText.arabic(
                        color: c.goldText,
                        size: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Written by: ${widget.book.authorShort}',
                      textDirection: TextDirection.rtl,
                      style: AppText.arabic(
                        color: c.textMuted,
                        size: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

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
                        onChanged: (v) {
                          setState(() => _position = v);
                        },
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

              const SizedBox(height: 20),

              // ── Controls ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Speed button
                    GestureDetector(
                      onTap: _cycleSpeed,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.divider),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${_speed}x',
                          style: AppText.latin(
                            color: c.brand,
                            size: 13,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    // Back 10s
                    GestureDetector(
                      onTap: _seekBack,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: c.surface2,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.divider),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.replay_rounded,
                              size: 26,
                              color: c.textPrimary,
                            ),
                            Positioned(
                              bottom: 8,
                              child: Text(
                                '10',
                                style: AppText.latin(
                                  color: c.textPrimary,
                                  size: 8,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Play / Pause
                    GestureDetector(
                      onTap: _togglePlay,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 70,
                        height: 70,
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
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Forward 10s
                    GestureDetector(
                      onTap: _seekForward,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: c.surface2,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.divider),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.forward_rounded,
                              size: 26,
                              color: c.textPrimary,
                            ),
                            Positioned(
                              bottom: 8,
                              child: Text(
                                '10',
                                style: AppText.latin(
                                  color: c.textPrimary,
                                  size: 8,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Placeholder for balance
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
