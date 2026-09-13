import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_spacing.dart';

/// Standardized Modal Dialog layout for forms, prompts, and selections.
class CustomDialog extends StatelessWidget {
  final Object title;
  final String? subtitle;
  final IconData? icon;
  final Color headerColor;
  final Widget content;
  final List<Widget>? actions;
  final double maxWidth;
  final ShapeBorder? shape;

  const CustomDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.headerColor = AppColors.primary,
    required this.content,
    this.actions,
    this.maxWidth = 520,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        shape:
            shape ??
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg20),
            ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg20),
                  ),
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          title is Widget
                              ? title as Widget
                              : Text(
                                  title.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          if (subtitle != null && subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      tooltip: 'إغلاق',
                    ),
                  ],
                ),
              ),
              // Body Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: content,
                ),
              ),
              // Actions Footer
              if (actions != null && actions!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (actions!.length == 1) {
                        return actions!.first;
                      }

                      if (constraints.maxWidth < 300) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (int i = 0; i < actions!.length; i++) ...[
                              if (i > 0) const SizedBox(height: 8),
                              actions![i],
                            ],
                          ],
                        );
                      }

                      return Row(
                        children: [
                          for (int i = 0; i < actions!.length; i++) ...[
                            if (i > 0) const SizedBox(width: 12),
                            Expanded(child: actions![i]),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
