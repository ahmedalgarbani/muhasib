import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_color.dart';
import 'app_radius.dart';

final ThemeData appLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: 'Tajawal',
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primarySurface,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.saudiGold,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.saudiGoldLight,
    onSecondaryContainer: AppColors.amber800,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textPrimaryLight,
    surfaceContainerHighest: AppColors.slate100,
    onSurfaceVariant: AppColors.textSecondaryLight,
    outline: AppColors.borderLight,
    outlineVariant: AppColors.slate300,
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: AppColors.errorLight,
    onErrorContainer: AppColors.red800,
  ),
  scaffoldBackgroundColor: AppColors.background,
  canvasColor: AppColors.background,
  dividerColor: AppColors.borderLight,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.textPrimaryLight,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
    titleTextStyle: TextStyle(
      fontFamily: 'Tajawal',
      color: AppColors.textPrimaryLight,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(
      color: AppColors.textPrimaryLight,
      size: 22,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surfaceLight,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: const BorderSide(color: AppColors.borderLight, width: 1),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
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
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.borderLight, width: 1.5),
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
      foregroundColor: AppColors.primary,
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
    fillColor: AppColors.surfaceLight,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: const TextStyle(
      fontFamily: 'Tajawal',
      color: AppColors.textSecondaryLight,
      fontSize: 13.5,
      fontWeight: FontWeight.normal,
    ),
    labelStyle: const TextStyle(
      fontFamily: 'Tajawal',
      color: AppColors.textSecondaryLight,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm14),
      borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm14),
      borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm14),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
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
    backgroundColor: AppColors.slate100,
    selectedColor: AppColors.primarySurface,
    side: BorderSide.none,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.xl28),
    ),
    labelStyle: const TextStyle(
      fontFamily: 'Tajawal',
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimaryLight,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.surfaceLight,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    showDragHandle: true,
    dragHandleColor: AppColors.slate300,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.surfaceLight,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg20),
    ),
    titleTextStyle: const TextStyle(
      fontFamily: 'Tajawal',
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryLight,
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.borderLight,
    thickness: 1,
    space: 1,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
  ),
);

