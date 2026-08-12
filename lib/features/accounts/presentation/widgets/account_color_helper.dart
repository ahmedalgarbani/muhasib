import 'package:flutter/material.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/core/theme/app_color.dart';

/// Helper class for account colors based on type and master status
class AccountColorHelper {
  // Private constructor to prevent instantiation
  AccountColorHelper._();

  /// Returns (backgroundColor, borderColor, iconColor) for an account
  static ({Color background, Color border, Color icon}) getColors(
    AccountEntity account,
  ) {
    // Master accounts always get yellow/amber colors
    if (account.isMaster) {
      return (
        background: AppColors.amber100,
        border: AppColors.warning,
        icon: AppColors.warning,
      );
    }

    // Sub accounts get colors based on their type
    return switch (account.type) {
      0 => (
        background: AppColors.green100,
        border: AppColors.success,
        icon: AppColors.success,
      ), // أصول - Green
      1 => (
        background: AppColors.red100,
        border: AppColors.error,
        icon: AppColors.error,
      ), // خصوم - Red
      2 => (
        background: AppColors.indigo100,
        border: AppColors.indigo500,
        icon: AppColors.indigo500,
      ), // إيرادات - Indigo
      3 => (
        background: AppColors.green100,
        border: AppColors.success,
        icon: AppColors.success,
      ), // مصروفات - Green
      4 => (
        background: AppColors.red100,
        border: AppColors.error,
        icon: AppColors.error,
      ), // أخرى - Red
      _ => (
        background: Colors.grey[100]!,
        border: Colors.grey[400]!,
        icon: Colors.grey[600]!,
      ), // Default
    };
  }
}
