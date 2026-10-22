import 'package:flutter/material.dart';

class AppTheme {
  // Calculator theme colors (realistic disguise)
  static const Color calcBackground = Color(0xFF17171C);
  static const Color calcDisplayBg = Color(0xFF17171C);
  static const Color calcBtnNum = Color(0xFF2E2F3E);
  static const Color calcBtnNumText = Colors.white;
  static const Color calcBtnAction = Color(0xFF4E505F);
  static const Color calcBtnActionText = Color(0xFFD4D4D8);
  static const Color calcBtnOperator = Color(0xFFFF9500); // Standard amber
  static const Color calcBtnOperatorText = Colors.white;
  static const Color calcEquals = Color(0xFF10B981); // Subtle emerald or amber

  // Vault theme colors (cyber security obsidian theme)
  static const Color vaultBg = Color(0xFF0D1117);
  static const Color vaultSurface = Color(0xFF161B22);
  static const Color vaultSurfaceLight = Color(0xFF21262D);
  static const Color vaultBorder = Color(0xFF30363D);
  static const Color vaultAccent = Color(0xFF58A6FF);
  static const Color vaultAccentGreen = Color(0xFF238636);
  static const Color vaultDanger = Color(0xFFF85149);
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: vaultBg,
      colorScheme: const ColorScheme.dark(
        primary: vaultAccent,
        secondary: vaultAccentGreen,
        surface: vaultSurface,
        error: vaultDanger,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: vaultBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: vaultSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: vaultBorder, width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: vaultAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: vaultSurface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: vaultBorder),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
