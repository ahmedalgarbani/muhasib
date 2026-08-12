import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';

/// Standardized Confirmation Dialog (e.g. for delete confirmations, save alerts).
class CustomConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final bool isDanger;
  final VoidCallback onConfirm;

  const CustomConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'تأكيد',
    this.cancelLabel = 'إلغاء',
    this.icon = Icons.warning_amber_rounded,
    this.isDanger = false,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = isDanger ? Colors.red : AppColors.primary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg20),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: themeColor, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: HasibButton(
                  label: cancelLabel,
                  onPressed: () => Navigator.of(context).pop(),
                  variant: HasibButtonVariant.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HasibButton(
                  label: confirmLabel,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  variant: isDanger
                      ? HasibButtonVariant.danger
                      : HasibButtonVariant.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
