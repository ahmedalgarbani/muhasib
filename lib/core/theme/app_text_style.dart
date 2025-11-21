import 'package:flutter/material.dart';
import 'package:hasib_lib/theme/app_colors.dart';

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.gray800,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.gray800,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.gray700,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.gray700,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.gray500,
  );

  static const TextStyle buttonLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static const TextStyle radioActive = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.blue600,
  );

  static const TextStyle radioInactive = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.gray700,
  );
}
