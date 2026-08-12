import 'package:flutter/material.dart';
import 'package:muhasib/features/accounts/domain/enums/account_type.dart';

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
  static const primaryDark = Color(0xFF1E40AF);
  static const primaryLight = Color(0xFF3B82F6);

  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);

  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);

  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEE2E2);

  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFFDBEAFE);

  // Surface and Dark/Light variations
  static const surfaceDark = Color(0xFF1E293B);
  static const surfaceLight = Colors.white;
  static const surface = Colors.white;
  static const borderDark = Color(0xFF334155);
  static const borderLight = Color(0xFFE2E8F0);
  static const border = Color(0xFFE5E7EB);
  static const textPrimaryDark = Color(0xFFF8FAFC);
  static const textPrimaryLight = Color(0xFF1E293B);
  static const textSecondaryDark = Color(0xFF94A3B8);
  static const textSecondaryLight = Color(0xFF64748B);
  static const textDisabled = Color(0xFF9CA3AF);

  // Shared colors and aliases
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const white = Colors.white;
  static const darkSecondary = Color(0xFF475569);
  static const background = Color(0xFFF8FAFC);

  // Tailwind-like Grey scale
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray800 = Color(0xFF1F2937);
  static const gray900 = Color(0xFF111827);

  // Legacy Grey scale (for backwards compat)
  static const grey50 = Color(0xFFF9FAFB);
  static const grey100 = Color(0xFFF3F4F6);
  static const grey200 = Color(0xFFE5E7EB);
  static const grey300 = Color(0xFFD1D5DB);
  static const grey400 = Color(0xFF9CA3AF);
  static const grey500 = Color(0xFF6B7280);
  static const grey600 = Color(0xFF4B5563);
  static const grey700 = Color(0xFF374151);
  static const grey800 = Color(0xFF1F2937);
  static const grey900 = Color(0xFF111827);

  // Tailwind-like Blue scale
  static const blue50 = Color(0xFFEFF6FF);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue200 = Color(0xFFBFDBFE);
  static const blue300 = Color(0xFF93C5FD);
  static const blue400 = Color(0xFF60A5FA);
  static const blue500 = Color(0xFF3B82F6);
  static const blue600 = Color(0xFF2563EB);
  static const blue700 = Color(0xFF1D4ED8);
  static const blue800 = Color(0xFF1E40AF);
  static const blue900 = Color(0xFF1E3A8A);

  // Tailwind-like Slate scale
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);

  // Tailwind-like Emerald scale
  static const emerald50 = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald200 = Color(0xFFA7F3D0);
  static const emerald300 = Color(0xFF6EE7B7);
  static const emerald400 = Color(0xFF34D399);
  static const emerald500 = Color(0xFF10B981);
  static const emerald600 = Color(0xFF059669);
  static const emerald700 = Color(0xFF047857);
  static const emerald800 = Color(0xFF065F46);

  // Tailwind-like Green scale
  static const green100 = Color(0xFFDCFCE7);
  static const green500 = Color(0xFF22C55E);
  static const green600 = Color(0xFF16A34A);

  // Tailwind-like Sky scale
  static const sky50 = Color(0xFFF0F9FF);
  static const sky100 = Color(0xFFE0F2FE);
  static const sky200 = Color(0xFFBAE6FD);

  // Tailwind-like Teal scale
  static const teal100 = Color(0xFFCCFBF1);
  static const teal500 = Color(0xFF14B8A6);
  static const teal600 = Color(0xFF0D9488);

  // Tailwind-like Red scale
  static const red50 = Color(0xFFFEF2F2);
  static const red100 = Color(0xFFFEE2E2);
  static const red200 = Color(0xFFFECDD3);
  static const red500 = Color(0xFFEF4444);
  static const red600 = Color(0xFFDC2626);
  static const red800 = Color(0xFF991B1B);

  // Tailwind-like Rose scale
  static const rose50 = Color(0xFFFFF1F2);
  static const rose100 = Color(0xFFFFE4E6);
  static const rose600 = Color(0xFFE11D48);
  static const rose700 = Color(0xFFBE123C);

  // Tailwind-like Pink scale
  static const pink100 = Color(0xFFFCE7F3);
  static const pink200 = Color(0xFFFBCFE8);
  static const pink500 = Color(0xFFEC4899);

  // Tailwind-like Amber scale
  static const amber50 = Color(0xFFFFFBEB);
  static const amber100 = Color(0xFFFEF3C7);
  static const amber200 = Color(0xFFFDE68A);
  static const amber300 = Color(0xFFFCD34D);
  static const amber400 = Color(0xFFFBBF24);
  static const amber500 = Color(0xFFF59E0B);
  static const amber600 = Color(0xFFD97706);
  static const amber700 = Color(0xFFB45309);
  static const amber800 = Color(0xFF92400E);

  // Tailwind-like Purple scale
  static const purple100 = Color(0xFFF3E8FF);
  static const purple200 = Color(0xFFE9D5FF);
  static const purple500 = Color(0xFFA855F7);
  static const purple800 = Color(0xFF6B21A8);
  static const purple900 = Color(0xFF581C87);

  // Tailwind-like Violet scale
  static const violet500 = Color(0xFF8B5CF6);
  static const violet700 = Color(0xFF6D28D9);

  // Tailwind-like Indigo scale
  static const indigo100 = Color(0xFFE0E7FF);
  static const indigo500 = Color(0xFF6366F1);
  static const indigo600 = Color(0xFF4F46E5);

  // Neutral scale
  static const neutral100 = Color(0xFFF5F5F5);

  // Blue-Grey / Brown
  static const blueGrey500 = Color(0xFF607D8B);
  static const blueGrey600 = Color(0xFF455A64);
  static const blueGrey700 = Color(0xFF546E7A);
  static const brown500 = Color(0xFF795548);
  static const brown700 = Color(0xFF5D4037);

  // Material palette
  static const materialBlue500 = Color(0xFF2196F3);
  static const materialBlue700 = Color(0xFF1976D2);
  static const materialBlue800 = Color(0xFF1565C0);
  static const materialBlue900 = Color(0xFF0D47A1);
  static const materialCyan700 = Color(0xFF00ACC1);
  static const materialTeal600 = Color(0xFF00897B);
  static const materialGreen500 = Color(0xFF4CAF50);
  static const materialGreen700 = Color(0xFF388E3C);
  static const materialGreen800 = Color(0xFF2E7D32);
  static const materialRed500 = Color(0xFFF44336);
  static const materialPurple500 = Color(0xFF9C27B0);
  static const materialPurple700 = Color(0xFF7B1FA2);
  static const materialPurple900 = Color(0xFF4A148C);
  static const materialDeepOrange400 = Color(0xFFFF7043);
  static const materialDeepOrange500 = Color(0xFFFF5722);
  static const materialDeepOrange700 = Color(0xFFE64A19);
  static const materialDeepOrange900 = Color(0xFFE65100);
  static const materialOrange500 = Color(0xFFFF9800);
  static const materialOrange700 = Color(0xFFF57C00);
  static const materialPink500 = Color(0xFFE91E63);
  static const materialIndigo500 = Color(0xFF3F51B5);

  // Custom
  static const customBlue = Color(0xFF4A90E2);
  static const orange500Alpha = Color(0x4DFF9800);
}
