import 'package:flutter/material.dart';
import 'package:muhasib/features/sales/presentation/widgets/sale_form.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isFullWidth;
  final double? height;

  const SecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isFullWidth = true,
    this.height = 56,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.grey300, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isFullWidth ? AppSpacing.lg : AppSpacing.xl,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: AppSpacing.sm)],
            Text(
              text,
              style: AppTextStyles.button.copyWith(color: AppColors.grey900),
            ),
          ],
        ),
      ),
    );
  }
}
