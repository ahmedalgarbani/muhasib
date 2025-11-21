import 'package:flutter/material.dart';
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
        background: const Color(0xFFFEF3C7),
        border: const Color(0xFFF59E0B),
        icon: const Color(0xFFF59E0B),
      );
    }

    // Sub accounts get colors based on their type
    return switch (account.type) {
      0 => (
        background: const Color(0xFFDCFCE7),
        border: const Color(0xFF10B981),
        icon: const Color(0xFF10B981),
      ), // أصول - Green
      1 => (
        background: const Color(0xFFFEE2E2),
        border: const Color(0xFFEF4444),
        icon: const Color(0xFFEF4444),
      ), // خصوم - Red
      2 => (
        background: const Color(0xFFE0E7FF),
        border: const Color(0xFF6366F1),
        icon: const Color(0xFF6366F1),
      ), // إيرادات - Indigo
      3 => (
        background: const Color(0xFFDCFCE7),
        border: const Color(0xFF10B981),
        icon: const Color(0xFF10B981),
      ), // مصروفات - Green
      4 => (
        background: const Color(0xFFFEE2E2),
        border: const Color(0xFFEF4444),
        icon: const Color(0xFFEF4444),
      ), // أخرى - Red
      _ => (
        background: Colors.grey[100]!,
        border: Colors.grey[400]!,
        icon: Colors.grey[600]!,
      ), // Default
    };
  }
}
