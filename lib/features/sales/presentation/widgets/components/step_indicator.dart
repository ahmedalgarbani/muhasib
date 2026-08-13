import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_spacing.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isEven) {
            final stepIndex = index ~/ 2;
            final isActive = currentStep >= stepIndex + 1;
            final isCompleted = currentStep > stepIndex + 1;

            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? AppColors.primary
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : Text(
                              '${stepIndex + 1}',
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : AppColors.gray600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[stepIndex],
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.gray600, height: 1.4).copyWith(
                      color: isActive ? AppColors.primary : AppColors.gray600,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          } else {
            final isActive = currentStep > (index ~/ 2) + 1;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 28),
                color: isActive
                    ? AppColors.primary
                    : Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
              ),
            );
          }
        }),
      ),
    );
  }
}
