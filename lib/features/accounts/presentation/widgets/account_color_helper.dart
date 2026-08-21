import 'package:flutter/material.dart';
import 'package:muhasib/core/enums/account_type.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';

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

    // Sub accounts get colors based on AccountType enum — type-safe
    final accountType = AccountType.tryFromValue(account.type);
    if (accountType != null) {
      final colors = AccountColors.getColors(accountType);
      return (background: colors.background, border: colors.border, icon: colors.icon);
    }
    return (
      background: Colors.grey[100]!,
      border: Colors.grey[400]!,
      icon: Colors.grey[600]!,
    );
  }
}
