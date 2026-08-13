import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';

class ReviewInfoRowWidget extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final Color? valueColor;

  const ReviewInfoRowWidget({
    super.key,
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isHighlight
              ? const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                  height: 1.4,
                )
              : const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: AppColors.gray600,
                  height: 1.4,
                ),
        ),
        Text(
          value,
          style: isHighlight
              ? const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                  height: 1.4,
                ).copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                )
              : const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray900,
                  height: 1.5,
                ).copyWith(color: valueColor),
        ),
      ],
    );
  }
}
