import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Типографика приложения Dating Coach
abstract class AppTypography {
  // ============ Font Weights ============
  /// Обычный текст
  static const FontWeight regular = FontWeight.w400;
  /// Полужирный (лейблы, кнопки)
  static const FontWeight semibold = FontWeight.w600;

  /// Базовый TextStyle с Inter
  static TextStyle get _baseStyle => GoogleFonts.inter();

  /// Большой дисплей (48px, semibold) — для чисел баланса
  static TextStyle get displayLarge => _baseStyle.copyWith(
        fontSize: 48,
        fontWeight: semibold,
        color: AppColors.textPrimary,
        height: 1.1,
        letterSpacing: -1.0,
      );

  /// Заголовок экрана (32px, normal weight)
  /// "What do you want to focus on right now?"
  static TextStyle get titleLarge => _baseStyle.copyWith(
        fontSize: 32,
        fontWeight: regular,
        color: AppColors.textPrimary,
        height: 1.2,
        letterSpacing: -0.5,
      );

  /// Заголовок карточки/секции (20px, semibold)
  /// "Open Chat", "Practice"
  static TextStyle get titleMedium => _baseStyle.copyWith(
        fontSize: 20,
        fontWeight: semibold,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// Заголовок экрана в навбаре (16px, normal, серый)
  /// "Profile", "Balance", "About" — не должен привлекать внимание
  static TextStyle get screenTitle => _baseStyle.copyWith(
        fontSize: 16,
        fontWeight: regular,
        color: AppColors.textSecondary,
        height: 1.3,
      );

  /// Основной текст (16px, normal)
  /// Описания под заголовками
  static TextStyle get bodyMedium => _baseStyle.copyWith(
        fontSize: 16,
        fontWeight: regular,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  /// Мелкий текст (14px, normal)
  /// Подписи, hints
  static TextStyle get bodySmall => _baseStyle.copyWith(
        fontSize: 14,
        fontWeight: regular,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  /// Акцентный текст (для выделенных слов типа "focus")
  static TextStyle get titleLargeAccent => titleLarge.copyWith(
        fontWeight: semibold,
        color: AppColors.accent,
      );

  // ============ Form & Profile styles ============

  /// Лейбл поля формы (Name, Age range, etc.) — полужирный
  static TextStyle get fieldLabel => bodyMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: semibold,
      );

  /// Значение поля формы (Sarah, 25-35, etc.) — обычный
  static TextStyle get fieldValue => bodyMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: regular,
      );

  /// Текст-ссылка (Privacy Policy, Terms, Delete chats)
  static TextStyle get linkText => bodyMedium.copyWith(
        color: AppColors.textSecondary,
      );

  /// Акцентная кнопка (Save, Edit)
  static TextStyle get buttonAccent => bodyMedium.copyWith(
        color: AppColors.primary,
        fontWeight: semibold,
      );
}
