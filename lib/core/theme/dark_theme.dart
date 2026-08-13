import 'package:flutter/material.dart';
import 'app_color.dart';

final ThemeData appDarkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  ),
  fontFamily: 'Tajawal',
  scaffoldBackgroundColor: AppColors.slate900,
);
