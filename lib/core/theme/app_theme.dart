import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Тема приложения Dating Coach
abstract class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        
        // Цвета
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.white,
          surface: AppColors.background,
          onSurface: AppColors.textPrimary,
          secondary: AppColors.accent,
          onSecondary: AppColors.white,
        ),
        
        // Типографика
        textTheme: GoogleFonts.interTextTheme().copyWith(
          titleLarge: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            height: 1.2,
            letterSpacing: -0.5,
          ),
          titleMedium: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        
        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        
        // Splash/Ripple эффекты
        splashColor: AppColors.primary.withOpacity(0.1),
        highlightColor: AppColors.primary.withOpacity(0.05),
      );
}
