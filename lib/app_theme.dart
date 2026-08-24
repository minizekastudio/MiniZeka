import 'package:flutter/material.dart';

class MiniZekaTheme {
  // =====================================================
  // AYDINLIK TEMA
  // =====================================================

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFFFF9F4),

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7653A8),
      brightness: Brightness.light,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFF9F4),
      foregroundColor: Color(0xFF51425A),
      elevation: 0,
      centerTitle: true,
    ),

    cardColor: Colors.white,

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFF7F1FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(18),
        ),
        borderSide: BorderSide.none,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7653A8),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
        ),
      ),
    ),
  );

  // =====================================================
  // KARANLIK TEMA
  // =====================================================

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF17131F),

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF9B7BC4),
      brightness: Brightness.dark,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF17131F),
      foregroundColor: Color(0xFFF4ECFA),
      elevation: 0,
      centerTitle: true,
    ),

    cardColor: const Color(0xFF251E2E),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2437),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(18),
        ),
        borderSide: BorderSide.none,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8F6BB5),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
        ),
      ),
    ),
  );
}