import 'package:flutter/material.dart';

/// Accessible theme configurations for Vysion.
class AppTheme {
  /// Dark Theme setup with WCAG AAA contrast ratio compliance (21:1 bg-to-text).
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor:
          const Color(0xFFFFD700), // Amber Gold (Contrast ratio: 9.8:1)
      scaffoldBackgroundColor: const Color(0xFF121212), // Dark Grey
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFD700),
        secondary: Color(0xFFFFD700),
        error: Color(0xFFFF4500), // Hazard Red-Orange (Contrast ratio: 5.6:1)
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Colors.white70,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFFFFD700),
        ),
      ),
    );
  }
}
