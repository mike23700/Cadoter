import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color magenta = Color(0xFFC90091);
  static const Color dark = Color(0xFF30232C);
  static const Color gray = Color(0xFF786C74);
  static const Color cream = Color(0xFFFAF7F2);
  static const Color white = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE9E1E5);
  static const Color dispoBg = Color(0xFFEAF4ED);
  static const Color dispoText = Color(0xFF356C55);
  static const Color pinkBg = Color(0xFFFCECF6);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: false,
      scaffoldBackgroundColor: AppColors.white,
      fontFamily: 'Inter',
      textTheme: TextTheme(
        displayLarge: GoogleFonts.dmSerifDisplay(
          fontSize: 52, color: AppColors.dark, height: 1.35,
        ),
        headlineLarge: GoogleFonts.dmSerifDisplay(
          fontSize: 48, color: AppColors.dark, height: 1.35,
        ),
        headlineMedium: GoogleFonts.dmSerifDisplay(
          fontSize: 36, color: AppColors.dark, height: 1.35,
        ),
        headlineSmall: GoogleFonts.dmSerifDisplay(
          fontSize: 27, color: AppColors.dark, height: 1.35,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 17, color: AppColors.gray, height: 1.35,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, color: AppColors.dark, height: 1.35,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12, color: AppColors.gray, height: 1.35,
        ),
      ),
      primaryColor: AppColors.magenta,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.magenta,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.dark,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.all(13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
