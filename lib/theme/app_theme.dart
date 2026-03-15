import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryRed = Color(0xFFCC1F2D);
  static const Color deepRed = Color(0xFF8B0000);
  static const Color lightRed = Color(0xFFFF4444);
  static const Color accentGold = Color(0xFFD4A017);
  static const Color softPink = Color(0xFFFFE4E6);
  static const Color cardWhite = Color(0xFFFAFAFA);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color warningAmber = Color(0xFFF57C00);
  static const Color infoBlue = Color(0xFF1565C0);
  static const Color criticalOrange = Color(0xFFD84315);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        primary: primaryRed,
        secondary: accentGold,
        surface: cardWhite,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: deepRed),
        displayMedium: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w700, color: deepRed),
        headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
        titleLarge: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.poppins(fontSize: 15, height: 1.6),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, height: 1.5),
        bodySmall: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
        labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryRed,
          side: const BorderSide(color: primaryRed, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryRed, width: 2)),
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: deepRed,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
