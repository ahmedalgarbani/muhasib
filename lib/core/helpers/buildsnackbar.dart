import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class AppToast {
  static void showSuccess(BuildContext context, String message) {
    buildSnackbar(context, message, color: Colors.green.shade700);
  }

  static void showError(BuildContext context, String message) {
    buildSnackbar(context, message, color: Colors.red.shade700);
  }

  static void showInfo(BuildContext context, String message) {
    buildSnackbar(context, message, color: Colors.blue.shade700);
  }

  static void showWarning(BuildContext context, String message) {
    buildSnackbar(context, message, color: Colors.orange.shade800);
  }
}

void buildSnackbar(BuildContext context, String message, {Color? color}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm10)),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
    content: Text(message.toString()),
    backgroundColor: color ?? Colors.red,
  ));
}
