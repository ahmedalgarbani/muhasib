import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';

/// Lightweight shimmer skeleton shown while dashboard data loads.
/// Mimics the default home layout (balance card, quick access grid,
/// recent actions list) to minimize layout shift.
class HomeSkeletonLoader extends StatefulWidget {
  const HomeSkeletonLoader({super.key});

  @override
  State<HomeSkeletonLoader> createState() => _HomeSkeletonLoaderState();
}

class _HomeSkeletonLoaderState extends State<HomeSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF334155) : AppSkeletonColors.base;
    final highlight =
        isDark ? const Color(0xFF475569) : AppSkeletonColors.highlight;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [base, highlight, base],
          transform: _SlidingGradientTransform(percent: _controller.value),
        ).createShader(bounds),
        child: child,
      ),
      child: Column(
        children: [
          _card(
            child: Column(
              children: [
                _bone(width: 120, height: 14),
                const SizedBox(height: 14),
                _bone(width: double.infinity, height: 28),
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _bone(width: 80, height: 16),
                ),
              ],
            ),
            height: 130,
          ),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_bone(width: 90, height: 14), _bone(width: 52, height: 14)],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (var i = 0; i < 4; i++) _tile(),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (var i = 0; i < 4; i++) _tile(),
                  ],
                ),
              ],
            ),
            height: 190,
          ),
          _card(
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _bone(width: 100, height: 14),
                ),
                const SizedBox(height: 16),
                ...List.generate(3, (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          _bone(width: 40, height: 40, radius: AppRadius.md),
                          const SizedBox(width: 10),
                          Expanded(child: _bone(width: double.infinity, height: 12)),
                          const SizedBox(width: 10),
                          _bone(width: 60, height: 12),
                        ],
                      ),
                    )),
              ],
            ),
            height: 220,
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child, required double height}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg20),
      ),
      child: child,
    );
  }

  Widget _tile() {
    return Column(
      children: [
        _bone(width: 48, height: 48, radius: AppRadius.lg),
        const SizedBox(height: 6),
        _bone(width: 36, height: 9),
      ],
    );
  }

  Widget _bone({double? width, required double height, double? radius}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius ?? AppRadius.sm),
      ),
    );
  }
}

class AppSkeletonColors {
  static const base = Color(0xFFE2E8F0);
  static const highlight = Color(0xFFF8FAFC);
}

class _SlidingGradientTransform extends GradientTransform {
  final double percent;

  const _SlidingGradientTransform({required this.percent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (2 * percent - 1.6), 0, 0);
  }
}
