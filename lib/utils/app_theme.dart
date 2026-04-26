import 'package:flutter/material.dart';

class AppTheme {
  static const Color midnight = Color(0xFF070B1A);
  static const Color surface = Color(0xFF111833);
  static const Color violet = Color(0xFF7759FF);
  static const Color cyan = Color(0xFF3DEBFF);
  static const Color softText = Color(0xFFD9E1FF);

  static ThemeData darkTheme() {
    const scheme = ColorScheme.dark(
      primary: violet,
      secondary: cyan,
      surface: surface,
      onSurface: softText,
      onPrimary: Colors.white,
      onSecondary: midnight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: midnight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF151E40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A234A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: violet,
        foregroundColor: Colors.white,
      ),
    );
  }
}
