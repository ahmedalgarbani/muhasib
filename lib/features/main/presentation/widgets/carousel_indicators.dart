import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class CarouselIndicators extends StatelessWidget {
  final int count;
  final int activeIndex;

  const CarouselIndicators({
    super.key,
    required this.count,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: activeIndex == index ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: activeIndex == index ? Colors.blue : Colors.grey[300],
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
      ),
    );
  }
}
