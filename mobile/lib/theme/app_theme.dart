import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bgMain = Color(0xFFF5F7FA);
  static const bgCard = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A2138);
  static const textSecondary = Color(0xFF5A6B80);
  static const textMuted = Color(0xFF8E9AAF);
  static const textLabel = Color(0xFF4A5568);
  static const blue = Color(0xFF4A90D9);
  static const blueLight = Color(0x144A90D9);
  static const green = Color(0xFF2ECC71);
  static const greenLight = Color(0x142ECC71);
  static const red = Color(0xFFE74C3C);
  static const redLight = Color(0x14E74C3C);
  static const yellow = Color(0xFFF1C40F);
  static const yellowLight = Color(0x14F1C40F);
  static const purple = Color(0xFF6C5CE7);
  static const purpleLight = Color(0x146C5CE7);
  static const greenDark = Color(0xFF27AE60);
  static const greenDarkLight = Color(0x1427AE60);
  static const borderLight = Color(0xFFE8ECF1);

  // Status colors matching Python classifications
  static Color statusColor(String color) {
    switch (color) {
      case 'success':
        return green;
      case 'primary':
        return greenDark;
      case 'warning':
        return yellow;
      case 'danger':
        return red;
      case 'info':
        return blue;
      default:
        return textMuted;
    }
  }

  static Color statusBgColor(String color) {
    switch (color) {
      case 'success':
        return greenLight;
      case 'primary':
        return greenDarkLight;
      case 'warning':
        return yellowLight;
      case 'danger':
        return redLight;
      case 'info':
        return blueLight;
      default:
        return bgMain;
    }
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    final bodyTextStyle = GoogleFonts.inter();
    final displayTextStyle = GoogleFonts.nunito();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgMain,
      colorScheme: const ColorScheme.light(
        primary: AppColors.blue,
        secondary: AppColors.green,
        error: AppColors.red,
        surface: AppColors.bgCard,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blue,
          side: const BorderSide(color: AppColors.borderLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgMain,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgMain,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.inter(
          color: AppColors.textLabel,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: displayTextStyle.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        displayMedium: displayTextStyle.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        displaySmall: displayTextStyle.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineLarge: displayTextStyle.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: displayTextStyle.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineSmall: displayTextStyle.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: bodyTextStyle.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: bodyTextStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleSmall: bodyTextStyle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        bodyLarge: bodyTextStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: bodyTextStyle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodySmall: bodyTextStyle.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        labelLarge: bodyTextStyle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textLabel,
          letterSpacing: 0.5,
        ),
        labelMedium: bodyTextStyle.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textLabel,
          letterSpacing: 0.5,
        ),
        labelSmall: bodyTextStyle.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        selectedItemColor: AppColors.blue,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
