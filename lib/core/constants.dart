import 'package:flutter/material.dart';

/// Visual design tokens for the realistic exercise-book look.
class AppColors {
  // Paper
  static const paperCream = Color(0xFFFDF8EC);
  static const paperLine = Color(0xFF8FAEE0); // faint blue ruled line
  static const marginLine = Color(0xFFE05D5D); // red margin line
  static const paperShadow = Color(0x33000000);

  // Cover / chrome
  static const coverBrown = Color(0xFF5B3A29);
  static const background = Color(0xFFF2EEE3);
  static const backgroundDark = Color(0xFF14120F);
  static const surfaceDark = Color(0xFF221E18);
  static const textPrimary = Color(0xFF2A2118);
  static const textSecondary = Color(0xFF7A6F5F);
  static const accent = Color(0xFFB3552B);

  // Ink colors available to the user
  static const inkBlue = Color(0xFF1B3A8C);
  static const inkBlack = Color(0xFF101010);
  static const inkRed = Color(0xFFB02418);
  static const inkGreen = Color(0xFF1E6B3A);
  static const inkPurple = Color(0xFF6A2E8C);
  static const highlighterYellow = Color(0x66FFEB3B);

  static const List<Color> inkColors = [inkBlue, inkBlack, inkRed, inkGreen, inkPurple];

  // Sepia theme (a softer, nostalgic third theme alongside light/dark)
  static const sepiaBackground = Color(0xFFE8DCC4);
  static const sepiaPaper = Color(0xFFF3E9D2);
  static const sepiaText = Color(0xFF3E2F1C);

  // A small fixed palette of cover colors, one per notebook slot.
  static const List<Color> coverPalette = [
    Color(0xFF8E3B3B), // maroon
    Color(0xFF2E5A45), // forest green
    Color(0xFF2C4A77), // navy
    Color(0xFF7A4B96), // purple
    Color(0xFFB5752F), // tan/orange
    Color(0xFF3B6E73), // teal
    Color(0xFF6E5B3B), // brown
    Color(0xFF8A2E55), // wine
    Color(0xFF4B5C2E), // olive
  ];
}

/// Physical paper layout measurements, used by the ruled-paper painter.
class PaperLayout {
  static const double lineSpacing = 32.0;
  static const double marginFromLeft = 56.0;
  static const double topPadding = 48.0;
  static const int totalLeaves = 60;
}

enum AppThemeMode { light, dark, sepia }

class AppTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );

  static ThemeData sepia = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.sepiaBackground,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
      surface: AppColors.sepiaPaper,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.sepiaBackground,
      foregroundColor: AppColors.sepiaText,
      elevation: 0,
    ),
  );
}
