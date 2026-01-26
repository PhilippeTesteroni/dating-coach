import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Типографика приложения Dating Coach
abstract class AppTypography {
  /// Базовый TextStyle с Inter
  static TextStyle get _baseStyle => GoogleFonts.inter();

  /// Заголовок экрана (32px, normal weight)
  /// "What do you want to focus on right now?"
  static TextStyle get titleLarge => _baseStyle.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.2,
        letterSpacing: -0.5,
      );

  /// Заголовок карточки/секции (20px, semibold)
  /// "Open Chat", "Practice"
  static TextStyle get titleMedium => _baseStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// Основной текст (16px, normal)
  /// Описания под заголовками
  static TextStyle get bodyMedium => _baseStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  /// Акцентный текст (для выделенных слов)
  static TextStyle get titleLargeAccent => titleLarge.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.accent,
      );
}
