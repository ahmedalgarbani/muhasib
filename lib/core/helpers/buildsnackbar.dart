import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';

void buildSnackbar(BuildContext context, String message, {Color? color}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm10)),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
    content: Text(message.toString()),
    backgroundColor: color ?? Colors.red,
  ));
}
