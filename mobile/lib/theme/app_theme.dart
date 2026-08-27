import 'package:flutter/material.dart';

/// GitHub-Dark inspired palette — matches the desktop sftp-forge.py QSS.
class AppColors {
  static const bg = Color(0xFF0D1117);
  static const sidebar = Color(0xFF161B22);
  static const border = Color(0xFF21262D);
  static const borderStrong = Color(0xFF30363D);
  static const textPrimary = Color(0xFFE6EDF3);
  static const textSecondary = Color(0xFFC9D1D9);
  static const textMuted = Color(0xFF8B949E);
  static const textFaint = Color(0xFF484F58);
  static const accent = Color(0xFF58A6FF);
  static const accentStrong = Color(0xFF1F6FEB);
  static const green = Color(0xFF3FB950);
  static const greenStrong = Color(0xFF2EA043);
  static const red = Color(0xFFF85149);
  static const redStrong = Color(0xFF6E1C1C);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.green,
      error: AppColors.red,
      surface: AppColors.sidebar,
    ),
    fontFamily: 'monospace',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.sidebar,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
      labelStyle: const TextStyle(color: AppColors.textMuted),
      hintStyle: const TextStyle(color: AppColors.textFaint),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.border,
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.sidebar,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      selectedTileColor: Color(0xFF1A3A4A),
      selectedColor: AppColors.accent,
    ),
  );
}
