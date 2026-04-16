import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0F1419);
  static const Color surface = Color(0xFF1A1F27);
  static const Color surfaceAlt = Color(0xFF1A1F26);
  static const Color primary = Color(0xFF00D4FF);
  static const Color danger = Colors.red;
  static const Color cellEmpty = Color(0xFF2A3038);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Color(0xFF9E9E9E); // Colors.grey
}

/// Reusable dimensions so nothing is magic-numbered inline.
class AppSizes {
  AppSizes._();

  static const double pagePadding = 24.0;
  static const double cardPadding = 16.0;
  static const double borderRadius = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderWidth = 2.0;
  static const double iconSize = 32.0;
}

/// Builds the app-wide MaterialApp theme.
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.primary,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimary),
    ),
  );
}
