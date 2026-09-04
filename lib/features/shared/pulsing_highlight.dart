import 'package:flutter/material.dart';

/// Wraps [child] in a slow red pulse while [active] is true - used by the
/// rest timer's banner/overlay chip to make "near the end" / "over" states
/// visually distinct from an ordinary in-progress countdown, since a plain
/// static colour is easy to miss at a glance. Renders [child] completely
/// unmodified while inactive - starting/stopping the underlying
/// [AnimationController] only when needed, not running it uselessly the
/// whole time the countdown is otherwise ticking along normally.
class PulsingHighlight extends StatefulWidget {
  final bool active;
  final Widget child;

  const PulsingHighlight({super.key, required this.active, required this.child});

  @override
  State<PulsingHighlight> createState() => _PulsingHighlightState();
}

class _PulsingHighlightState extends State<PulsingHighlight>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PulsingHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && oldWidget.active) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    final errorColor = Theme.of(context).colorScheme.error;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => ColorFiltered(
        colorFilter: ColorFilter.mode(
          errorColor.withValues(alpha: 0.25 * _controller.value),
          BlendMode.srcATop,
        ),
        child: child,
      ),
    );
  }
}
