import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color accentOrange = Color(0xFFF2994A);
  static const Color background = Color(0xFFF7F7F2);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: primaryGreen,
      scaffoldBackgroundColor: background,
      brightness: Brightness.light,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),
    );
  }
}
