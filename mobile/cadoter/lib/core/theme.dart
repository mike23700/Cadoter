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
  static const Color error = Color(0xFFB42318);
}

/// Styles de texte des maquettes (DM Serif Display + Inter).
class T {
  static TextStyle serif(double size, {Color color = AppColors.dark, double height = 1.3}) =>
      GoogleFonts.dmSerifDisplay(fontSize: size, color: color, height: height);
  static TextStyle sans(double size,
          {Color color = AppColors.dark, FontWeight weight = FontWeight.w400, double height = 1.4}) =>
      GoogleFonts.inter(fontSize: size, color: color, fontWeight: weight, height: height);
  static TextStyle eyebrow({Color color = AppColors.gray}) =>
      GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w500, letterSpacing: .4);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: false,
      scaffoldBackgroundColor: AppColors.white,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.magenta, primary: AppColors.magenta),
      appBarTheme: const AppBarTheme(backgroundColor: AppColors.white, elevation: 0, foregroundColor: AppColors.dark),
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
          borderSide: const BorderSide(color: AppColors.magenta),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.gray),
        isDense: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.dark,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.white),
      ),
    );
  }
}
