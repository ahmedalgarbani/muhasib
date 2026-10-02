import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_color.dart';

class AppToast {
  static void showSuccess(BuildContext context, String message) {
    buildSnackbar(context, message, color: AppColors.emerald700);
  }

  static void showError(BuildContext context, String message) {
    buildSnackbar(context, message, color: AppColors.red700);
  }

  static void showInfo(BuildContext context, String message) {
    buildSnackbar(context, message, color: AppColors.blue700);
  }

  static void showWarning(BuildContext context, String message) {
    buildSnackbar(context, message, color: AppColors.amber800);
  }
}

void buildSnackbar(BuildContext context, String message, {Color? color}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm10)),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.only(bottom: 20, left: 12, right: 12),
    content: Text(message.toString()),
    backgroundColor: color ?? AppColors.error,
  ));
}
