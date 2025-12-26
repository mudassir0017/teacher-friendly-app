import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Theme Colors
  static const Color lightPrimary = Color(0xFF6366F1);
  static const Color lightSecondary = Color(0xFF8B5CF6);
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  
  // Dark Theme Colors
  static const Color darkPrimary = Color(0xFF818CF8);
  static const Color darkSecondary = Color(0xFFA78BFA);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  
  // Shared Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: lightPrimary,
      secondary: lightSecondary,
      surface: lightSurface,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightTextPrimary,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: lightBackground,
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: lightTextPrimary,
      displayColor: lightTextPrimary,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: lightSurface,
      foregroundColor: lightTextPrimary,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
      ),
      iconTheme: const IconThemeData(color: lightTextPrimary),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: lightSurface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightPrimary, width: 2),
      ),
      filled: true,
      fillColor: lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 4,
      backgroundColor: lightPrimary,
      foregroundColor: Colors.white,
    ),
    iconTheme: const IconThemeData(color: lightTextSecondary),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkSecondary,
      surface: darkSurface,
      error: error,
      onPrimary: darkBackground,
      onSecondary: darkBackground,
      onSurface: darkTextPrimary,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: darkBackground,
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: darkTextPrimary,
      displayColor: darkTextPrimary,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: darkSurface,
      foregroundColor: darkTextPrimary,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
      ),
      iconTheme: const IconThemeData(color: darkTextPrimary),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: darkSurface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkPrimary, width: 2),
      ),
      filled: true,
      fillColor: darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 4,
      backgroundColor: darkPrimary,
      foregroundColor: darkBackground,
    ),
    iconTheme: const IconThemeData(color: darkTextSecondary),
  );

  // Gradient helpers
  static LinearGradient primaryGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [const Color(0xFFA78BFA), const Color(0xFF818CF8)]
          : [const Color(0xFF8B5CF6), const Color(0xFF6366F1)],
    );
  }

  static LinearGradient successGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [const Color(0xFF34D399), const Color(0xFF10B981)]
          : [const Color(0xFF10B981), const Color(0xFF059669)],
    );
  }

  static LinearGradient warningGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [const Color(0xFFFBBF24), const Color(0xFFF59E0B)]
          : [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
    );
  }

  // Border color helper
  static Color borderColor(bool isDark) {
    return isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  }

  // Card shadow helper
  static List<BoxShadow> cardShadow(bool isDark, {Color? color}) {
    return [
      BoxShadow(
        color: (color ?? (isDark ? darkPrimary : lightPrimary))
            .withValues(alpha: isDark ? 0.1 : 0.06),
        blurRadius: isDark ? 8.0 : 12.0,
        offset: Offset(0, isDark ? 2.0 : 4.0),
      ),
    ];
  }
}
