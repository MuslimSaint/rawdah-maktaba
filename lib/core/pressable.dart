import 'package:flutter/material.dart';

/// A reusable wrapper that adds a subtle press animation to any child.
///
/// On tap down: scales to 0.955 and reduces opacity to 0.82.
/// On tap up/cancel: returns to normal.
/// Animation duration: 130ms with easeOut curve.
///
/// Usage:
///   Pressable(
///     onTap: () { ... },
///     child: Container(...)
///   )
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final HitTestBehavior behavior;

  /// Scale value when pressed. Default 0.955.
  final double pressedScale;

  /// Opacity value when pressed. Default 0.82.
  final double pressedOpacity;

  /// Animation duration in milliseconds. Default 130ms.
  final int durationMs;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.behavior = HitTestBehavior.opaque,
    this.pressedScale = 0.955,
    this.pressedOpacity = 0.82,
    this.durationMs = 130,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: widget.durationMs);

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: duration,
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? widget.pressedOpacity : 1.0,
          duration: duration,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
