import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'audio_player_screen.dart';

/// Lessons screen — shows all audio parts for a book by a specific teacher.
class LessonsScreen extends StatefulWidget {
  final Book book;
  final Teacher teacher;

  const LessonsScreen({
    super.key,
    required this.book,
    required this.teacher,
  });

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  late List<bool> _completed;

  @override
  void initState() {
    super.initState();
    _completed = List.filled(widget.book.audioParts, false);
  }

  int get _completedCount => _completed.where((c) => c).length;

  double get _progress => widget.book.audioParts > 0
      ? _completedCount / widget.book.audioParts
      : 0;

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
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
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.book.titleAr,
                          textDirection: TextDirection.rtl,
                          style: AppText.arabic(
                            color: c.textPrimary,
                            size: 14,
                            weight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Taught by: ${widget.teacher.nameEn}',
                          style: AppText.latin(
                            color: c.goldText,
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

            // ── Teacher Hero Card ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.goldLine, width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.brand.withOpacity(0.12),
                            border: Border.all(
                              color: c.brand.withOpacity(0.25),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            widget.teacher.initials,
                            textDirection: TextDirection.rtl,
                            style: AppText.arabic(
                              color: c.brand,
                              size: 16,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.teacher.nameAr,
                                textDirection: TextDirection.rtl,
                                style: AppText.arabic(
                                  color: c.textPrimary,
                                  size: 15,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.teacher.nameEn,
                                style: AppText.latin(
                                  color: c.textMuted,
                                  size: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Parts count
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: c.brand.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: c.brand.withOpacity(0.25),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${widget.book.audioParts}',
                                style: AppText.latin(
                                  color: c.brand,
                                  size: 18,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'parts',
                                style: AppText.latin(
                                  color: c.brand,
                                  size: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Progress
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: AppText.latin(
                                color: c.textMuted,
                                size: 11,
                              ),
                            ),
                            Text(
                              '$_completedCount / ${widget.book.audioParts}',
                              style: AppText.latin(
                                color: c.brand,
                                size: 11,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: c.surface2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(c.brand),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Lesson List ──
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: widget.book.audioParts,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final lessonNum = index + 1;
                  final isDone = _completed[index];

                  return _LessonRow(
                    lessonNumber: lessonNum,
                    isDone: isDone,
                    colors: c,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AudioPlayerScreen(
                            book: widget.book,
                            teacher: widget.teacher,
                            lessonNumber: lessonNum,
                          ),
                        ),
                      );
                    },
                    onCompletedToggle: () {
                      setState(() {
                        _completed[index] = !_completed[index];
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Lesson Row ──────────────────────────────────────────

class _LessonRow extends StatefulWidget {
  final int lessonNumber;
  final bool isDone;
  final AppColors colors;
  final VoidCallback onTap;
  final VoidCallback onCompletedToggle;

  const _LessonRow({
    required this.lessonNumber,
    required this.isDone,
    required this.colors,
    required this.onTap,
    required this.onCompletedToggle,
  });

  @override
  State<_LessonRow> createState() => _LessonRowState();
}

class _LessonRowState extends State<_LessonRow> {
  String _downloadState = 'none';

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;

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

    final lessonTitle = 'الجزء $arabicNum';

    return GestureDetector(
      onTap: _downloadState == 'downloaded' ? widget.onTap : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.isDone
                ? c.brand.withOpacity(0.3)
                : c.divider,
          ),
        ),
        child: Row(
          children: [
            // Completion indicator
            GestureDetector(
              onTap: widget.onCompletedToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isDone ? c.brand : c.surface2,
                  border: Border.all(
                    color: widget.isDone ? c.brand : c.divider,
                  ),
                ),
                alignment: Alignment.center,
                child: widget.isDone
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      )
                    : Text(
                        '${widget.lessonNumber}',
                        style: AppText.latin(
                          color: c.textMuted,
                          size: 13,
                          weight: FontWeight.w700,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    lessonTitle,
                    textDirection: TextDirection.rtl,
                    style: AppText.arabic(
                      color: widget.isDone
                          ? c.textMuted
                          : c.textPrimary,
                      size: 15,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.headphones_rounded,
                        size: 11,
                        color: c.textFaint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Part ${widget.lessonNumber}',
                        style: AppText.latin(
                          color: c.textFaint,
                          size: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Download / Play button
            GestureDetector(
              onTap: () {
                if (_downloadState == 'none') {
                  setState(() => _downloadState = 'downloading');
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      setState(() => _downloadState = 'downloaded');
                    }
                  });
                } else if (_downloadState == 'downloaded') {
                  widget.onTap();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _downloadState == 'downloaded'
                      ? c.brand
                      : c.brand.withOpacity(0.1),
                  border: Border.all(
                    color: _downloadState == 'downloaded'
                        ? c.brand
                        : c.brand.withOpacity(0.3),
                  ),
                ),
                child: _downloadState == 'downloading'
                    ? Padding(
                        padding: const EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.brand,
                        ),
                      )
                    : Icon(
                        _downloadState == 'downloaded'
                            ? Icons.play_arrow_rounded
                            : Icons.download_rounded,
                        size: 20,
                        color: _downloadState == 'downloaded'
                            ? Colors.white
                            : c.brand,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
