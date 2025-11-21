import 'package:flutter/material.dart';

void buildSnackbar(BuildContext context, String message, {Color? color}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
    content: Text(message.toString()),
    backgroundColor: color ?? Colors.red,
  ));
}
