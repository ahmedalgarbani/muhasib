import 'package:flutter/material.dart';

/// Staggered entrance: fades and slides in each child with a sequential
/// delay using a single shared [AnimationController].
///
/// Respects the platform "reduce motion" accessibility setting.
class StaggeredEntrance extends StatefulWidget {
  final List<Widget> children;
  final Duration duration;
  final double slideOffset;

  const StaggeredEntrance({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 900),
    this.slideOffset = 28,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _buildAnimations();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant StaggeredEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children.length != widget.children.length) {
      _buildAnimations();
      if (_controller.isCompleted) {
        setState(() {});
      }
    }
  }

  void _buildAnimations() {
    final count = widget.children.length;
    _animations = List.generate(count, (i) {
      final start = (count <= 1) ? 0.0 : (i / count).clamp(0.0, 0.6);
      final end = ((i + 2.4) / count).clamp(start + 0.05, 1.0);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Column(children: widget.children);
    }
    return Column(
      children: [
        for (var i = 0; i < widget.children.length; i++)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _animations[i],
              builder: (context, child) {
                final t = _animations[i].value;
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, widget.slideOffset * (1 - t)),
                    child: child,
                  ),
                );
              },
              child: widget.children[i],
            ),
          ),
      ],
    );
  }
}
