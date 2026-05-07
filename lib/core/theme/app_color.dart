import 'package:flutter/material.dart';
import 'package:muhasib/features/accounts/data/models/account_model.dart';

class AccountColors {
  final Color background;
  final Color text;
  final Color border;
  final Color icon;

  AccountColors({
    required this.background,
    required this.text,
    required this.border,
    required this.icon,
  });

  static AccountColors getColors(AccountType type) {
    switch (type) {
      case AccountType.assets:
        return AccountColors(
          background: const Color(0xFFD1FAE5),
          text: const Color(0xFF047857),
          border: const Color(0xFFA7F3D0),
          icon: const Color(0xFF059669),
        );
      case AccountType.liabilities:
        return AccountColors(
          background: const Color(0xFFFCE7F3),
          text: const Color(0xFFBE123C),
          border: const Color(0xFFFBCFE8),
          icon: const Color(0xFFE11D48),
        );
      case AccountType.revenue:
        return AccountColors(
          background: const Color(0xFFDBEAFE),
          text: const Color(0xFF1D4ED8),
          border: const Color(0xFFBFDBFE),
          icon: const Color(0xFF2563EB),
        );
      case AccountType.expenses:
        return AccountColors(
          background: const Color(0xFFFEF3C7),
          text: const Color(0xFFB45309),
          border: const Color(0xFFFDE68A),
          icon: const Color(0xFFD97706),
        );
      case AccountType.equity:
        return AccountColors(
          background: const Color(0xFFF3E8FF),
          text: const Color(0xFF7C3AED),
          border: const Color(0xFFE9D5FF),
          icon: const Color(0xFF8B5CF6),
        );
    }
  }
}
class AppColors {
  // Primary colors
  static const primary = Color(0xFF2563EB);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Surface and Dark/Light variations
  static const surfaceDark = Color(0xFF1E293B);
  static const surfaceLight = Colors.white;
  static const borderDark = Color(0xFF334155);
  static const borderLight = Color(0xFFE2E8F0);
  static const textPrimaryDark = Color(0xFFF8FAFC);
  static const textPrimaryLight = Color(0xFF1E293B);
  static const textSecondaryDark = Color(0xFF94A3B8);
  static const textSecondaryLight = Color(0xFF64748B);

  // Grey scale
  static const grey300 = Color(0xFFD1D5DB);
  static const grey400 = Color(0xFF9CA3AF);
  static const grey500 = Color(0xFF6B7280);
  static const grey700 = Color(0xFF374151);

  // Gradients
  static const gradientPrimary = [Color(0xFF2563EB), Color(0xFF1E40AF)];
  static const gradientSuccess = [Color(0xFF10B981), Color(0xFF059669)];
  static const gradientWarning = [Color(0xFFF59E0B), Color(0xFFD97706)];
  static const gradientInfo = [Color(0xFF3B82F6), Color(0xFF2563EB)];
}
