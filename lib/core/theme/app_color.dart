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
