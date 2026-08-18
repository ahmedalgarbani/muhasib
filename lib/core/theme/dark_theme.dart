import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_color.dart';
import 'app_radius.dart';

final ThemeData appDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: 'Tajawal',
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryLight,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF004D25),
    onPrimaryContainer: AppColors.emerald200,
    secondary: AppColors.saudiGold,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF451A03),
    onSecondaryContainer: AppColors.amber200,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textPrimaryDark,
    surfaceContainerHighest: Color(0xFF334155),
    onSurfaceVariant: AppColors.textSecondaryDark,
    outline: AppColors.borderDark,
    outlineVariant: Color(0xFF475569),
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: AppColors.rose100,
  ),
  scaffoldBackgroundColor: AppColors.slate900,
  canvasColor: AppColors.slate900,
  dividerColor: AppColors.borderDark,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.slate900,
    foregroundColor: AppColors.textPrimaryDark,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
    titleTextStyle: TextStyle(
      fontFamily: 'Tajawal',
      color: AppColors.textPrimaryDark,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: AppColors.textPrimaryDark, size: 22),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surfaceDark,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: const BorderSide(color: AppColors.borderDark, width: 1),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm14),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryLight,
      side: const BorderSide(color: AppColors.borderDark, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm14),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceDark,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: const TextStyle(
      fontFamily: 'Tajawal',
      color: AppColors.textSecondaryDark,
      fontSize: 13.5,
      fontWeight: FontWeight.normal,
    ),
    labelStyle: const TextStyle(
      fontFamily: 'Tajawal',
      color: AppColors.textSecondaryDark,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm14),
      borderSide: const BorderSide(color: AppColors.borderDark, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm14),
      borderSide: const BorderSide(color: AppColors.borderDark, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm14),
      borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm14),
      borderSide: const BorderSide(color: AppColors.error, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm14),
      borderSide: const BorderSide(color: AppColors.error, width: 1.8),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.borderDark,
    selectedColor: const Color(0xFF004D25),
    side: BorderSide.none,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.xl28),
    ),
    labelStyle: const TextStyle(
      fontFamily: 'Tajawal',
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimaryDark,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.surfaceDark,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    showDragHandle: true,
    dragHandleColor: AppColors.slate600,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.surfaceDark,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg20),
    ),
    titleTextStyle: const TextStyle(
      fontFamily: 'Tajawal',
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryDark,
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.borderDark,
    thickness: 1,
    space: 1,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.primaryLight,
    foregroundColor: Colors.white,
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
  ),
);
