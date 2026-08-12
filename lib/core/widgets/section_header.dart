import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_text_style.dart';

/// Standardized section title used across pages (Arabic RTL friendly).
class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget? trailingWidget;
  final TextStyle? titleStyle;
  final bool showChevron;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.trailingWidget,
    this.titleStyle,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: titleStyle ?? AppTextStyles.titleMedium,
          ),
          if (trailingWidget != null)
            trailingWidget!
          else if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          if (showChevron)
            const Icon(Icons.chevron_right, color: AppColors.primary, size: 16),
        ],
      ),
    );
  }
}
