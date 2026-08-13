import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class QuantityButtonWidget extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const QuantityButtonWidget({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary : AppColors.grey200,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isPrimary ? Colors.white : AppColors.grey900,
          size: 28,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
